require "file"

module Sonicri
  record Key, action : String, value : String = "no value"

  class Keys
    @file : File | Nil
    DEBUG = false

    def initialize(@win : NCurses::Window)
      @key_stack = Deque(Key).new
      monitor_keyboard
      @file = File.open("check_keys.org", "w") if DEBUG
      debug_puts "* check_file" if DEBUG
    end

    private def monitor_keyboard
      spawn do
        loop do
          key = check_input
          if valid_key? key
            if @key_stack.empty?
              @key_stack.push key
            end
          end
        end
      end
    end

    private def valid_key?(key)
      unless key.is_a? Key
        raise "Error! Invalid key (Keys#valid_key?)"
      end
      return true
    end

    def next_key
      @key_stack.shift
    end

    def key_available?
      !@key_stack.empty?
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
              return Key.new("selected")
            when 81, 113 # 'q'
              return Key.new("back")
            when 127 # 'DEL'
              return Key.new("back")
            else
              return Key.new("char", char.chr.to_s)
            end
          elsif esc == 2
            STDIN.flush
            esc = 0
            debug_puts "esc 2 : char #{char}" if DEBUG
            if char == 66
              debug_puts "** next" if DEBUG
              return Key.new("selection", "next")
            elsif char == 67
              debug_puts "** next_page" if DEBUG
              return Key.new("selection", "next_page")
            elsif char == 68
              debug_puts "** prev_page" if DEBUG
              return Key.new("selection", "prev_page")
            elsif char == 65
              debug_puts "** prev" if DEBUG
              return Key.new("selection", "prev")
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
          return Key.new("back")
          STDIN.flush
          esc = 0
        end
        sleep 0.005
      end
      return Key.new("no action")
    end
  end
end
