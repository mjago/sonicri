module Sonicri
  class Terminal
    # Attempt to resize, clear, set title, move to top left of the terminal
    COMMANDS = {resize:         "printf \e[8;26;88t",
                title:          "echo -ne \"\033]0;Sonicri Audio Player\007\"",
                to_left_corner: "printf \033[H",
                clear_screen:   "printf \033[2J"}

    def self.setup
      COMMANDS.each_value { |x| STDOUT.puts x }
    end
  end
end
