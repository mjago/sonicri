# coding: utf-8

require "libao"
require "libmpg123"
require "time"

module PodPicr
  class Audio
    setter win : NCurses::Window | Nil
    include Libao
    include Libmpg123

    BUF_SIZE         = 4800
    INFO_LINE_LENGTH =   55
    INFO_POS_ROW     =   23
    INFO_POS_COL     =    0

    def initialize
      @source = :feed
      @io_readpos = @done = @rate =
        @total_size = @file_end = 0_i64
      @channels = @bits = 0
      @running = @quit = false
      @ao = Ao.new
      @dl = Downloader.new
      @dl.chunk_size = BUF_SIZE
      @ch_play = Channel(Nil).new
      @io = IO::Memory.new
      @inslice = Bytes.new(BUF_SIZE)
      @auxslice = Bytes.new(BUF_SIZE)
      @ao_buf = Bytes.new(BUF_SIZE)
      @read_count = 1
      @seek_value = 0_i64
      @mpg = Mpg123.new
      @mpg.new(nil)
    end

    def stop
      quit
      @dl.quit
      sleep 0.2
      initialize
      @running = false
    end

    def quit
      #      stop
      @mpg.exit
      @dl.quit
      @quit = true
      @io.flush
    end

    def running?
      @running
    end

    def run(addr)
      io = IO::Memory.new
      redir = @dl.follow_redirects(addr)
      @mpg.open_feed
      fiber_get_chunks(redir)
      fiber_update_display
      fiber_decode_chunks
      fiber_play_chunks
      fiber_monitor_download
      @running = true
      @pause = false
    end

    def current_sample_offset
      @mpg.sample_offset
    end

    def update_end_position
      current_pos = current_sample_offset
      @file_end = @mpg.seek(0_i64, :seek_end)
      @mpg.seek(current_pos)
    end

    def move_to_file_cache
      current_position = current_sample_offset
      @mpg.open("local.mp3")
      update_end_position
      jump_to(current_position)
      @source = :file
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
        if new_offset < @file_end
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

    def pause
      @pause = @pause ? false : true
    end

    private def io_write(slice : Bytes)
      @io.pos = @io.size
      @io.write(slice)
    end

    private def io_read(slice)
      @io.pos = @io_readpos
      @io.read(slice)
      @io_readpos = @io.pos.to_i64
      slice
    end

    private def io_bytes_count
      @io.size - @io_readpos
    end

    private def set_audio_format
      @rate = @done = 0_i64
      @channels = encoding = 0
      @mpg.get_format(pointerof(@rate), pointerof(@channels), pointerof(encoding))
      @bits = @mpg.encsize(encoding) * 8
      byte_format = LibAO::Byte_Format::AO_FMT_BIG
      @ao.set_format(@bits, @rate, @channels, byte_format, matrix = nil)
      @ao.open_live
    end

    private def decode(inp, insize, outsize)
      @mpg.decode(inp, insize.to_i64,
        @ao_buf,
        outsize.to_i64,
        pointerof(@done))
    end

    private def fiber_get_chunks(redir)
      spawn do
        @dl.get_chunks(redir) do |chunk|
          io_write chunk
          break if @quit
        end
      end
    end

    private def fiber_get_chunks
      spawn do
        @dl.get_chunks do |chunk|
          io_write chunk
          break if @quit
        end
      end
    end

    private def now
      ::Time.now.epoch
    end

    private def display_buffering
      display("Buffering...              ")
    end

    private def display_playing
      display("Playing (streaming)...    ")
    end

    private def update_display?(then)
      epoch = now
      if (then + 5) < epoch
        return true
      end
      false
    end

    private def fiber_update_display
      spawn do
        while !@quit
          display_progress
          sleep 0.5
        end
      end
    end

    private def fiber_monitor_download
      spawn do
        while !@quit
          if @dl && @dl.download_done
            move_to_file_cache if @source == :feed
            break
          end
          sleep 0.1
        end
      end
    end

    private def display_progress
      if win = @win
        win.not_nil!.move(INFO_POS_ROW, INFO_POS_COL)
        if (rate = @rate) > 0
          offset = @mpg.sample_offset
          sec = offset / @rate
          if @source == :file
            finish = @file_end / @rate
            win.print("time: #{sec/60}:#{"%02d" % (sec % 60)}/#{finish/60}:#{"%02d" % (finish % 60)}")
          else
            win.print("time: #{sec/60}:#{"%02d" % (sec % 60)}, rate: #{@rate}")
          end
          #          win.print("offset: #{offset}")
          win.refresh
        end

        #        if @total_size > 0_i64
        #          win.not_nil!.move(INFO_POS_ROW, INFO_POS_COL)
        #          win.print(info_line)
        #          win.refresh
        #        end
      else
        raise "Error: no Window!"
      end
    end

    private def info_line
      info = "Rate: #{@rate}/#{@bits}, Size: #{@total_size}"
      while info.size < INFO_LINE_LENGTH
        info += " "
      end
      info
    end

    private def process_result(result)
      case result
      when LibMPG::Errors::DONE.value
        #        quit
      when LibMPG::Errors::NEW_FORMAT.value
        set_audio_format
      when LibMPG::Errors::OK.value
        @ch_play.send(nil)
      when LibMPG::Errors::NEED_MORE.value
        #        quit if @source == :file
      when LibMPG::Errors::BAD_HANDLE.value
        raise("Error: Bad Handle in PlayAudio")
      end
      sleep 0
    end

    private def get_data_size
      size = 0
      unless io_bytes_count == 0
        size = io_bytes_count > BUF_SIZE ? BUF_SIZE : io_bytes_count
      end
      size
    end

    private def fiber_decode_chunks
      spawn do
        while !@quit
          while @pause
            sleep 0.1
            break if @quit
          end
          break if @quit
          outsize = BUF_SIZE
          data = nil
          size = get_data_size
          unless size == 0
            data = io_read @inslice
            @total_size += size
          else
            size = 0_i64
            data = @auxslice
          end
          result = decode(data, size, outsize)
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
          sleep 0
        end
      end
    end

    private def close
      sleep 0.1
      @mpg.exit
      @ao.exit
      @win = nil
    end
  end
end
