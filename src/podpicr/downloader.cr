require "http/client"

module PodPicr
  class Downloader
    setter chunk_size
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

    def get_chunks2
      channel = Channel(Bytes).new
      #      chunk = Bytes.new(@chunk_size)
      chunk = Bytes.new(@chunk_size)
      spawn do
        while !@quit
          count = 0
          total_count = 0
          count = @file.read(chunk)
          #   puts "count #{count}"
          quit if count == 0
          sized = chunk[0, count]
          channel.send(sized)
        end
      end

      # HTTP::Client.get(redir) do |response|
      #  length = 0 unless length = response.headers["Content-Length"].to_i
      #  while !@quit
      #    count = response.body_io.read(chunk)
      #    quit if count == 0
      #    break if @quit
      #    total_count += count
      #    unless length == 0
      #      quit if total_count >= length
      #      break if @quit
      #    end
      #    sized = chunk[0, count]
      #       #     @file.write(sized)
      #    channel.send(sized)
      #  end
      #  break if @quit
      # end
      # STDERR.print "."
      # end
      STDERR.puts "quitting" if @quit
      return if @quit
      while chunk = channel.receive
        yield chunk
      end
    end

    def get_chunks(redir : String)
      channel = Channel(Bytes).new
      chunk = Bytes.new(@chunk_size)
      spawn do
        count = 0
        total_count = 0
        HTTP::Client.get(redir) do |response|
          length = 0 unless length = response.headers["Content-Length"].to_i
          while !@quit
            count = response.body_io.read(chunk)
            quit if count == 0
            break if @quit
            total_count += count
            unless length == 0
              quit if total_count >= length
              break if @quit
            end
            sized = chunk[0, count]
            @file.write(sized)
            channel.send(sized)
          end
          break if @quit
        end
        @file.close
        @download_done = true
      end
      STDERR.puts "quitting" if @quit
      return if @quit
      while chunk = channel.receive
        yield chunk
      end
    end
  end
end
