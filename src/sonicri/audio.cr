# coding: utf-8

require "libao"
require "libmpg123"
require "time"

module Sonicri
  class Audio
    BYTE_FORMAT  = LibAO::Byte_Format::AO_FMT_BIG
    LOCAL_MP3    = "local.mp3"
    BUF_SIZE     = 4 * 1024
    INFO_POS_ROW = 0
    INFO_POS_COL = 0

    setter win : NCurses::Window | Nil
    property progress : Display::Progress
    include Libao
    include Libmpg123

    def initialize(@progress)
      @source = :feed
      @done = 0_i64
      @rate = 0_i64
      @running = @quit = false
      @ao = Ao.new
      @dl = Downloader.new
      @ch_play = Channel(Nil).new
      @ao_buf = Bytes.new(BUF_SIZE)
      @mpg = Mpg123.new
      @mpg.new(nil)
      @mpg.param(:flags, :quiet)
      @cache_name = ""
      @file_size = 0_i64
      @sample_length = 0_i64
      @q = Deque(UInt8).new(BUF_SIZE)
    end

    def reinitialize
      @source = :feed
      @running = @quit = false
      @dl = Downloader.new
      @ch_play = Channel(Nil).new
      @cache_name = ""
      @file_size = 0_i64
      @sample_length = 0_i64
      @q.clear
    end

    def stop
      quit
      sleep 0.2
      reinitialize
      @running = false
    end

    def quit
      @mpg.exit
      @dl.quit
      @quit = true
      @q.clear
      clear_progress
    end

    def running?
      @running
    end

    def move_to_file_cache(filename = LOCAL_MP3, from_start = false)
      current_pos = from_start ? 0_i64 : current_sample_offset
      @mpg.open(filename)
      @mpg.param(:flags, :quiet, 0.0)
      @sample_length = @mpg.length
      @mpg.seek(current_pos)
      @source = :file
    end

    def make_cache_name(cache_name)
      "cache/#{cache_name}.mp3"
    end

    def play_radio(url)
      display_initializing
      redir = @dl.follow_redirects(url.not_nil!)
      @mpg.open_feed
      @dl.mode = :radio
      fiber_start_fibers(redir)
      @running = true
      @pause = false
    end

    def play_music(file)
      if file
        display_initializing
        @mpg.open(file)
        @mpg.param(:flags, :quiet, 0.0)
        @sample_length = @mpg.length
        @mpg.seek(0_i64)
        @source = :file
        fiber_start_fibers
        @running = true
        @pause = false
      end
    end

    def run(name, addr)
      display_initializing
      @cache_name = make_cache_name(name)
      if File.exists? @cache_name
        move_to_file_cache(@cache_name, from_start: true)
        fiber_start_fibers
        @running = true
        @pause = false
      else
        redir = @dl.follow_redirects(addr)
        @mpg.open_feed
        fiber_start_fibers(redir)
        @running = true
        @pause = false
      end
    end

    def current_sample_offset
      @mpg.sample_offset
    end

    def calc_offset(distance)
      multiplier =
        case distance
        when :large
          60_i64
        else
          10_i64
        end
      44_000_i64 * multiplier
    end

    def jump_back(distance = :small)
      if @source == :file
        offset = calc_offset(distance)
        sample_offset = @mpg.sample_offset
        unless sample_offset - offset < 0
          jump_relative -offset
        end
      end
    end

    def jump_forward(distance = :small)
      if @source == :file
        offset = calc_offset(distance)
        new_offset = current_sample_offset + offset
        if new_offset < @sample_length
          jump_to new_offset
        end
      end
    end

    def jump_relative(offset)
      @mpg.seek(offset, :seek_cur)
    end

    def jump_to(offset)
      @mpg.seek(offset, :seek_set)
    end

    def record
      @dl.record
    end

    def pause
      @pause = @pause ? false : true
    end

    # private

    private def set_audio_format
      @rate = 0_i64
      @done = 0_i64
      channels = encoding = 0
      @mpg.get_format(pointerof(@rate), pointerof(channels), pointerof(encoding))
      bits = @mpg.encsize(encoding) * 8
      @ao.set_format(bits, @rate, channels, BYTE_FORMAT, matrix = nil)
      @ao.open_live
    end

    private def decode(inp, insize, outsize)
      if input = inp
        @mpg.decode(input, insize.to_i64,
          @ao_buf,
          outsize.to_i64,
          pointerof(@done))
      end
    end

    private def fiber_get_chunks(redir)
      spawn do
        @dl.get_chunks(redir) do |chunk|
          chunk.each { |x| @q.push x }
          break if @quit
          Fiber.yield
        end
      end
    end

    private def now
      ::Time.now.epoch
    end

    private def fiber_update_display
      spawn do
        while !@quit
          display_progress
          sleep 0.9
        end
      end
    end

    private def display_progress
      if @running && @rate > 0_i64
        if @source == :file
          print_time_progressed
        else
          print_time_and_rate
        end
      end
    end

    private def print_time_progressed
      @file_size = @sample_length / @rate
      @progress.print("#{time_str}/#{size_str}")
    end

    private def print_time_and_rate
      @progress.print("#{time_str}, #{rate_str}")
    end

    private def time_str
      sec = seconds
      "Time: #{sec/60}:#{"%02d" % (sec % 60)}"
    end

    private def rate_str
      "Rate: #{@rate}"
    end

    private def size_str
      "#{@file_size/60}:#{"%02d" % (@file_size % 60)}"
    end

    private def seconds
      offset = @mpg.sample_offset
      offset / @rate
    end

    private def display_initializing
      @progress.print("Initializing...")
    end

    private def clear_progress
      @progress.clear
    end

    private def fiber_monitor_download
      spawn do
        while !@quit
          if @dl && @dl.download_done
            if @source == :feed
              move_to_file_cache
              FileUtils.mkdir_p File.dirname(@cache_name)
              FileUtils.cp LOCAL_MP3, @cache_name
              break
            end
          end
          sleep 0.1
        end
      end
    end

    private def process_result(result)
      case result
      when LibMPG::Errors::DONE.value
        quit
      when LibMPG::Errors::NEW_FORMAT.value
        set_audio_format
      when LibMPG::Errors::OK.value
        @ch_play.send(nil)
      when LibMPG::Errors::NEED_MORE.value
      when LibMPG::Errors::BAD_HANDLE.value
        raise("Error: Bad Handle in PlayAudio")
      end
      Fiber.yield
    end

    private def fiber_decode_chunks
      spawn do
        while !@quit
          while @pause
            sleep 0.1
            break if @quit
          end
          break if @quit
          size = @q.size
          data = Bytes.new(size) { @q.shift }
          result = decode(inp: data, insize: size, outsize: BUF_SIZE)
          process_result(result)
          Fiber.yield
        end
      end
    end

    private def fiber_play_chunks
      spawn do
        ptr = 0
        while !@quit
          @ch_play.receive
          @ao.play(@ao_buf, @done)
          Fiber.yield
        end
      end
    end

    private def close
      sleep 0.1
      quit
      @ao.exit
      @win = nil
    end

    private def fiber_start_fibers(redir = nil)
      fiber_update_display
      fiber_get_chunks(redir) if redir
      fiber_decode_chunks
      fiber_play_chunks
      fiber_monitor_download
    end
  end
end
