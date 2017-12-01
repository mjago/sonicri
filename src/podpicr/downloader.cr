require "http/client"

module PodPicr
  class Downloader
    setter chunk_size
    getter complete

    def initialize
      @chunk_size = 0
      @file = File.open("local.mp3", "w")
      @quit = false
    end

    def quit
      @quit = true
    end

    def fetch(file_address, dest_name)
      HTTP::Client.get(file_address) do |response|
        File.write(dest_name, response.body_io)
      end
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
      spawn do
        # range = "bytes=wn0-"
        # HTTP::Client.get(redir, headers: HTTP::Headers{"Range" => range}) do |io|
        HTTP::Client.get(redir) do |io|
          while !quit?
            count = io.body_io.read(chunk)
            quit if count == 0
            sized = chunk[0, count]
            @file.write(sized)
            channel.send(sized)
          end
        end
        STDERR.print "."
      end
      STDERR.puts "quitting" if quit?
      return if quit?
      while chunk = channel.receive
        yield chunk
      end
    end

    private def quit?
      @quit == true
    end
  end
end
