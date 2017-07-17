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
        # puts "start #{data_start}"
        # puts "end #{data_end} \r\n"
        # puts "end - start: #{data_end.to_i - data_start.to_i}"
        # puts "size #{data_size}"
        # if @file_size > 0
        #   puts "progress: #{(data_end.to_f / data_size.to_f) * 100.0}"
        # end
        # @chunk_start = data_end.to_i
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

    def get_redirect(addr)
      location = ""

      HTTP::Client.get(addr) do |response|
        unless response.status_code == 302
          raise "Error: Not redirect response (#{response.status_code}) in #get_redirect()"
        end
        if response.headers["Location"]
          location = response.headers["Location"]
        end
      end
      return location
    end

    def get_chunks(redir : String)
      channel = Channel(Bytes).new
      chunk = Bytes.new(20000)
      spawn do
        range = "bytes=0-"
        HTTP::Client.get(redir, headers: HTTP::Headers{"Range" => range}) do |io|
          while !quit?
            count = io.body_io.read(chunk)
            quit if count == 0
            sized = chunk[0, count]
            @file.write(sized)
            channel.send(sized)
          end
          #          break if quit?
        end
        STDERR.print "."
      end
      STDERR.puts "quitting" if quit?
      return if quit?
      while chunk = channel.receive
        yield chunk
      end
    end

    #    def get_next_chunk(redir : String)
    #      channel = Channel(Bytes).new
    #      range = "bytes=#{@chunk_start}-#{@chunk_start + (@chunk_size)}"
    #      spawn do
    #        HTTP::Client.get(redir, headers: HTTP::Headers{"Range" => range}) do |response|
    #          Fiber.yield
    #          if response.status_code == 200
    #            raise "Recieved response code 200"
    #          else
    #            unless response.status_code == 206
    #              raise "Error: response code #{response.status_code}"
    #            end
    #          end
    #          #          Fiber.yield
    #          p response.headers
    #          exit
    #          finished?(response.headers["Content-Range"])
    #          if s = response.body_io.peek
    #            @file.write(s)
    # #            puts "size : #{s.size} \r\n"
    #            @chunk_start += s.size
    #            unless @file_size == 0
    #              if @chunk_start >= (@file_size.to_i - 1)
    #                @complete = true
    #              end
    #            end
    #            channel.send s
    #          else
    #            raise "Error Client body is nil!"
    #          end
    #        end
    #      end
    #      channel.receive
    #    end
  end
end

# channel = Channel(Bytes).new
# chunk = Bytes.new(20000)
# spawn do
#   range = "bytes=0-"
#   HTTP::Client.get(redir, headers: HTTP::Headers{"Range" => range}) do |io|
#     loop do
#       count = io.body_io.read(chunk)
#       break if count == 0
#       sized = chunk[0, count]
#       @file.write(sized)
#       channel.send(sized)
#     end
#   end
# end
# while chunk = channel.receive
#   yield chunk
# end
