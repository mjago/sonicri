require "file"

module Sonicri
  record Key, action : String, value : String = "no value"

  class Keys
    LETTER_q              =  81
    LETTER_Q              = 113
    BACKSPACE             = 127
    SCROLL_WHEEL_FORWARD  =  96
    SCROLL_WHEEL_BACKWARD =  97
    SCROLL_WHEEL_SWITCH   =  33
    MOUSE_KEY_LEFT        =  32
    MOUSE_KEY_RIGHT       =  34
    KEY_UP                =  65
    KEY_DOWN              =  66
    KEY_RIGHT             =  67
    KEY_LEFT              =  68
    DEBUG                 = false
    @file : File | Nil
    @new_mask : UInt64

    def initialize(@win : NCurses::Window)
      @new_mask = LibNCurses::MouseMask::ALL_MOUSE_EVENTS.value.to_u64 |
                  LibNCurses::MouseMask::REPORT_MOUSE_POSITION.value.to_u64
      @old_mask = 0_u64
      @key_stack = Deque(Key).new
      monitor_keyboard
      @file = File.open("check_keys.org", "w") if DEBUG
      debug_puts "* check_file" if DEBUG
      NCurses.mouse_mask(@new_mask, pointerof(@old_mask))
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
              return Key.new("key selected")
            when LETTER_q, LETTER_Q
              return Key.new("quit")
            when BACKSPACE
              return Key.new("back")
            when SCROLL_WHEEL_FORWARD
              debug_puts "scroll wheel forward"
              return Key.new("selection", "next_page")
            when SCROLL_WHEEL_BACKWARD
              debug_puts "scroll wheel backward"
              return Key.new("selection", "prev_page")
            when SCROLL_WHEEL_SWITCH
              return Key.new("no action")
            when MOUSE_KEY_RIGHT
              if get_position(win)
                debug_puts "mouse key right"
                return Key.new("back")
              end
            when MOUSE_KEY_LEFT
              if x = get_position(win)
                debug_puts "pos #{x}"
                col = x.first
                row = x.last
                debug_puts "mouse key left"
                return Key.new("mouse selected", row.to_s)
              end
            else
              # debug_puts "key #{char}"
              if char.chr.to_s.downcase == "h"
                return Key.new("help")
              else
                return Key.new("char", char.chr.to_s)
              end
            end
          elsif esc == 2
            STDIN.flush
            esc = 0
            debug_puts "esc 2 : char #{char}" if DEBUG
            if char == KEY_DOWN
              debug_puts "** next" if DEBUG
              return Key.new("selection", "next")
            elsif char == KEY_RIGHT
              debug_puts "** next_page" if DEBUG
              return Key.new("selection", "next_page")
            elsif char == KEY_LEFT
              debug_puts "** prev_page" if DEBUG
              return Key.new("selection", "prev_page")
            elsif char == KEY_UP
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

    # private

    private def get_position(win)
      col = win.get_char
      row = win.get_char
      if row.is_a?(Int32) && col.is_a?(Int32)
        if (col >= 38) && (col < 38 + 81)
          if (row >= 35) && (row < 35 + 20)
            row -= 35
            return col, row
          end
        end
      end
    end
  end
end
