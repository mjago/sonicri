require "file"

module Sonicri
  class Keys

    @file : File | Nil
    DEBUG = false

    def initialize(@win : NCurses::Window)
      @file = File.open("check_keys.org", "w") if DEBUG
      debug_puts "* check_file" if DEBUG
    end

    def check_input
      @win.try do |win|
        try_key(win)
      end
    end

    def close
      if f = @file
        f.close
      end
    end

    def debug_puts(x)
      if file = @file
        file.puts x
      end
    end

    def try_key(win)
      esc = 0
      loop do
        char = win.get_char
        if char > -1
          if esc == 0
            debug_puts "get_char : esc #{esc} : char #{char}" if DEBUG
            case char
            when 27 # esc
              esc = 1
            when 10
              return {action: "selected", value: "eval"}
            when 81, 113 # 'q'
              return {action: "back", value: "no value"}
            when 127 # 'DEL'
              return {action: "back", value: "no value"}
            else
              return {action: "char", value: char.chr.to_s}
            end
          elsif esc == 2
            STDIN.flush
            esc = 0
            debug_puts "esc 2 : char #{char}" if DEBUG
            if char == 66
              debug_puts "** next" if DEBUG
              return {action: "selection", value: "next"}
            elsif char == 67
              debug_puts "** next_page" if DEBUG
              return {action: "selection", value: "next_page"}
            elsif char == 68
              debug_puts "** prev_page" if DEBUG
              return {action: "selection", value: "prev_page"}
            elsif char == 65
              debug_puts "** prev" if DEBUG
              return {action: "selection", value: "prev"}
            end
          elsif esc == 1
            debug_puts "esc 1 : char #{char}" if DEBUG
            if char == 91
              esc = 2
            else
              break
            end
          end
        elsif esc == 1
          "ESC"
          debug_puts "ESC" if DEBUG
          debug_puts "esc 1 : char #{char}" if DEBUG
          return {action: "back", value: "no value"}
          STDIN.flush
          esc = 0
        end
        sleep 0.005
      end
      return {action: "no action", value: "none"}
    end
  end
end
