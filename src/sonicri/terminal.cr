module Sonicri
  class Terminal

    # Attempt to resize, clear, move to top left of the terminal

    def self.setup
      STDOUT.puts "printf \e[8;25;88t"
      STDOUT.puts "printf \033[H"
      STDOUT.puts "printf \033[2J"
    end
  end
end
