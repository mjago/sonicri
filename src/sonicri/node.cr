require "opml"

module Sonicri
  class Node
    @root_outlines : Array(Outline) = Array(Outline).new
    getter? parsed
    getter current_outlines : Array(Outline) = @root_outlines

    def initialize
      @outlines_stack = Deque(Array(Outline)).new
    end

    def root?
      @current_outlines == @root_outlines
    end

    def reset
      @current_outlines = @root_outlines
      @outlines_stack.clear
    end

    def push
      @outlines_stack.push @current_outlines
    end

    def pop
      @current_outlines = @outlines_stack.pop
    end

    def children?(selection)
      current = @current_outlines[selection]
      current.outlines?
    end

    def parse(file)
      @root_outlines += Opml.parse_file(file)
      @root_outlines = sort_outlines_by_name(@root_outlines)
      names = Array(String).new
      @current_outlines = @root_outlines
      @current_outlines.each do |outline|
        names << outline.name
      end
      @parsed = true
    end

    def select(selection, names)
      current = @current_outlines[selection]
      if current.outlines?
        @current_outlines = sort_outlines_by_name(current.outlines)
        return "list"
      else
        value = ""
        names.each do |name|
          if current.attributes.has_key?(name)
            return current.attributes[name]
          end
        end
      end
      return ""
    end

    def content
      temp = [] of String
      @current_outlines.each do |ol|
        temp << ol.name
      end
      temp
    end

    private def sort_outlines_by_name(ol)
      ol.sort { |x, y| x.name <=> y.name }
    end
  end
end
