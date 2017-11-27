module PodPicr
  class Keys

    def initialize(@win : NCurses::Window)
    end

    def check_input
      @win.try do |win|
        try_key(win)
      end
    end

    def try_key(win)
      esc = 0
      loop do
        char = win.get_char
        if char > -1
          if esc == 2
            STDIN.flush
            esc = 0
            if char == 66
              return {action: "selection", value: "next"}
            elsif char == 67
              return {action: "selection", value: "next_page"}
            elsif char == 68
              return {action: "selection", value: "prev_page"}
            elsif char == 65
              return {action: "selection", value: "prev"}
            end
          elsif esc == 1
            if char == 91
              esc = 2
            else
              break
            end
          elsif char == 27
            esc = 1
          elsif char == 10
            return {action: "selected", value: "eval"}
          else
            return {action: "char", value: char.chr.to_s}
          end
        elsif esc == 1
          # ESC key
          STDIN.flush
          esc = 0
          return {action: "char", value: "q"}
        end
        sleep 0.01
      end
      return {action: "no action", value: "none"}
    end
  end
end
