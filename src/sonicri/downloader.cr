require "http/client"

module Sonicri
  class Downloader
    setter mode
    getter download_done

    BUF_SIZE = 4800

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
      @download_done = false
      @restart_count = 0
      @file = File.open("local.mp3", "wb")
      @mode = :podcast
      @io = IO::Memory.new
      @q = Deque(UInt8).new(BUF_SIZE)
      @chunk = Bytes.new(BUF_SIZE)
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

    def process_response(response)
      count = response.body_io.read @chunk
      if count == 0
        @file.close
        quit
      end
      count.times { |x| @q.push @chunk[x] }
      return nil if @quit
      qsize = @q.size
      if qsize >= BUF_SIZE * 3
        return Slice(UInt8).new(qsize) { @q.shift }
      end
      nil
    end

    def new_client(uri)
      begin
        client = HTTP::Client.new(uri) # do |response|
        client.read_timeout = 10
        return client
      rescue err : IO::Timeout
        raise "Error: failed to open #{uri}"
      end
    end

    def get_chunks(redir : String)
      channel = Channel(Bytes).new
      begin
        spawn do
          retry_count = 0
          @restart_count = 0
          loop do
            @restart = false
            uri = URI.parse(redir)
            if client = new_client(uri)
              begin
                client.get(uri.full_path) do |response|
                  while !@quit
                    if audio = process_response(response)
                      channel.send(audio)
                      @restart_count = 0
                      @file.write(audio) unless @mode == :radio
                    else
                      @restart_count += 1
                      if @restart_count > 20
                        @restart = true
                        retry_count += 1
                        raise "too many retries" if retry_count > 5
                        @restart_count = 0
                        puts "restarting"
                        break
                      end
                    end
                  end
                end
              rescue err : IO::Timeout
                @restart = true
                @q.clear
              end
            end
            @download_done = true unless @restart
            break unless @restart
          end
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
        sleep 0.005
      end
    end
  end
end
