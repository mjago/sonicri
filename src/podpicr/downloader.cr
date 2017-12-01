require "http/client"

module PodPicr
  class Downloader
    setter chunk_size
    getter complete

    def initialize
      @chunk_start = 0
      @chunk_size = 0
      @file_size = 0
      @complete = false
      @data_end = 0
      @file = File.open("local.mp3", "w")
      @quit = false
    end

    def quit?
      @quit == true
    end

    def quit
      @quit = true
    end

    def fetch(file_address, dest_name)
      HTTP::Client.get(file_address) do |response|
        File.write(dest_name, response.body_io)
      end
    end

    def match_data_sizes(content_range)
      if md = content_range.match(/bytes (\d*)\-(\d*)\/(\d*)$/)
        {md[1], md[2], md[3]}
      else
        false
      end
    end

    def progress
      if @file_size == 0
        "(starting)          "
      else
        percentage = ((@chunk_start.to_f / @file_size.to_f) * 100.0).to_i
        if percentage >= 99
          "(concluding)      "
        else
          "(progress: #{percentage}/100)"
        end
      end
    end

    def finished?(content_range)
      match = match_data_sizes(content_range)
      if match.is_a?(Tuple(String, String, String))
        data_start, data_end, data_size = match
        @data_end = data_end.to_i
        if data_size.to_i != @file_size
          @file_size = data_size.to_i
        end
        if data_end.to_i >= (data_size.to_i - 1)
          @complete = true
        end
      else
        raise "Error: match failed in #match_data_sizes!"
      end
      false
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
        # range = "bytes=0-"
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
  end
end
