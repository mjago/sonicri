require "file"

module PodPicr
  class Keys
    def initialize(@win : NCurses::Window)
      @file = File.open("check_keys.org", "w")
      @file.puts "* check_file"
    end

    def check_input
      @win.try do |win|
        try_key(win)
      end
    end

    def close
      @file.close
    end

    def try_key(win)
      esc = 0
      loop do
        char = win.get_char

        if char > -1
          if esc == 0
            @file.puts "get_char : esc #{esc} : char #{char}"
            case char
            when 27 # esc
              esc = 1
            when 10
              return {action: "selected", value: "eval"}
            when 66, 98 # 'b'
              return {action: "selection", value: "prev"}
            when 70, 102 # 'f'
              return {action: "selection", value: "next"}
            when 78, 110 # 'n'
              return {action: "selection", value: "next_page"}
            when 80, 112 # 'p'
              return {action: "selection", value: "prev_page"}
            when 81, 113 # 'q'
              return {action: "back", value: "no value"}
            when 127 # 'DEL'
              return {action: "back", value: "no value"}
            else
              return {action: "char", value: char.chr.to_s}
            end

            #          if esc == 0
            #            @file.puts "esc 0 : char #{char}"
          elsif esc == 2
            STDIN.flush
            esc = 0
            @file.puts "esc 2 : char #{char}"
            if char == 66
              @file.puts "** next"
              return {action: "selection", value: "next"}
            elsif char == 67
              @file.puts "** next_page"
              return {action: "selection", value: "next_page"}
            elsif char == 68
              @file.puts "** prev_page"
              return {action: "selection", value: "prev_page"}
            elsif char == 65
              @file.puts "** prev"
              return {action: "selection", value: "prev"}
            end
          elsif esc == 1
            @file.puts "esc 1 : char #{char}"
            if char == 91
              esc = 2
            else
              break
            end
          end
        elsif esc == 1
          "ESC"
          @file.puts "ESC"
          @file.puts "esc 1 : char #{char}"
          return {action: "back", value: "no value"}
          STDIN.flush
          esc = 0
        end
        sleep 0.01
      end
      return {action: "no action", value: "none"}
    end
  end
end
