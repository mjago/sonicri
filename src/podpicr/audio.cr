# coding: utf-8

require "libao"
require "libmpg123"
require "time"

module PodPicr
  class Audio
    @win : NCurses::Window | Nil
    @then : Int64
    @length : Int64
    @total_size : Int64
    setter win

    include Libao
    include Libmpg123

    BUF_SIZE         = 4096
    BUF_COUNT        =    2
    INFO_LINE_LENGTH =   55
    INFO_POS_ROW     =   23
    INFO_POS_COL     =    0

    def initialize
      @mpg = Mp.new
      @mpg.new(nil)
      @ao = Ao.new
      @ch_play = Channel(Nil).new
      @dl = Downloader.new
      @dl.chunk_size = BUF_SIZE
      @io = IO::Memory.new
      @io_readpos = 0_i64
      @quit = false
      @inslice = Bytes.new(BUF_SIZE)
      @auxslice = Bytes.new(BUF_SIZE)
      @ao_buf = Bytes.new(BUF_SIZE)
      @done = 0_i64
      @rate = 0_i64
      @bits = 0
      @then = ::Time.now.epoch.to_i64
      @length = 0_i64
      @total_size = 0_i64
    end

    def feed(url)
      @mpg.new(nil)
    end

    def quit
      @io.flush
      @dl.quit
      @quit = true
    end

    def io_write(slice : Bytes)
      @io.pos = @io.size
      @io.write(slice)
    end

    def io_read(slice)
      @io.pos = @io_readpos
      @io.read(slice)
      @io_readpos = @io.pos.to_i64
      slice
    end

    def io_bytes_count
      @io.size - @io_readpos
    end

    def run(addr, @length = length)
      io = IO::Memory.new
      redir = @dl.get_redirect(addr)
      @mpg.open_feed
      fiber_get_chunks(redir)
      fiber_update_display
      fiber_decode_chunks
      fiber_play_chunks
    end

    private def set_audio_format
      @rate, channels, encoding = 0_i64, 0, 0
      @mpg.get_format(pointerof(@rate), pointerof(channels), pointerof(encoding))
      @bits = @mpg.encsize(encoding) * 8
      byte_format = LibAO::Byte_Format::AO_FMT_BIG
      matrix = nil
      @ao.set_format(@bits, @rate, channels, byte_format, matrix)
      @ao.open_live
      @done = 0_i64
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
        end
      end
    end

    private def now
      ::Time.now.epoch
    end

    private def display(str)
      if win = @win
        win.move(INFO_POS_ROW, INFO_POS_COL)
        win.print(str)
        win.refresh
      else
        raise "Error: no Window!"
      end
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
      # display_buffering
      spawn do
        loop do
          break if @quit
          display_progress
          sleep 0.5
        end
      end
    end

    private def display_progress
      if win = @win
        if @total_size > 0_i64
          win.move(INFO_POS_ROW, INFO_POS_COL)
          win.print(info_line)
          win.refresh
        end
      else
        raise "Error: no Window!"
      end
    end

    private def info_line
      info = "Rate: #{@rate}/#{@bits}, Size: #{@total_size}, Length: #{@length}"
      while info.size < INFO_LINE_LENGTH
        info += " "
      end
      info
    end

    private def process_result(result)
      case result
      when LibMP::MP_Errors::MP_NEW_FORMAT.value
        set_audio_format
      when LibMP::MP_Errors::MP_OK.value
        @ch_play.send(nil)
      when LibMP::MP_Errors::MP_NEED_MORE.value
        quit if @total_size >= @length
      when LibMP::MP_Errors::MP_BAD_HANDLE.value
        raise("Error: Bad Handle in PlayAudio")
      else
        raise("Error: Unexpected error in PlayAudio")
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
        loop do
          outsize = BUF_SIZE
          break if @quit
          data = nil
          size = get_data_size
          unless size == 0
            data = io_read @inslice
            @total_size += size
          else
            #            sleep 2
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
        loop do
          break if @quit
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
