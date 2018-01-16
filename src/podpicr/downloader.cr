require "http/client"

module PodPicr
  class Downloader
    setter chunk_size
    setter mode
    getter download_done

    def self.fetch(file_address, dest_name)
      begin
        HTTP::Client.get(file_address) do |response|
          File.write(dest_name, response.body_io)
        end
      rescue
        File.write(dest_name, "")
      end
    end

    def initialize
      @quit = false
      @chunk_size = 0
      @file = File.open("local.mp3", "wb")
      @download_done = false
      @mode = :podcast
    end

    def quit
      @quit = true
    end

    def follow_redirects(addr)
      location = ""
      HTTP::Client.get(addr) do |response|
        unless response.status_code == 302 || response.status_code == 301
          return addr
        end
        if response.headers["Location"]
          location = response.headers["Location"]
        end
      end
      return follow_redirects(location)
    end

    def get_chunks(redir : String)
      channel = Channel(Bytes).new
      chunk = Bytes.new(@chunk_size)
      begin
        spawn do
          count = 0
          HTTP::Client.get(redir) do |response|
            unless @mode == :radio
              length = 0 unless length = response.headers["Content-Length"].to_i
            end
            while !@quit
              count = response.body_io.read(chunk)
              if count == 0
                @file.close
                quit
                break
              end
              break if @quit
              unless @mode == :radio
                unless length == 0
                  break if @quit
                end
              end
              sized = chunk[0, count]
              @file.write(sized) unless @mode == :radio
              channel.send(sized)
            end
            break if @quit
          end
          @download_done = true
        end
      rescue
        quit
        puts "Exception raised in downloader - quitting:"
        sleep 1
      end
      STDERR.puts "quitting" if @quit
      return if @quit
      while chunk = channel.receive
        yield chunk
      end
    end
  end
end
