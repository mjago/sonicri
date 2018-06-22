require "opml"

module Sonicri
  class OpmlDataset
    @root_outlines : Array(Outline) = Array(Outline).new
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
    end

    def title(selection)
      @current_outlines[selection].name
    end

    def parse_into(name, file)
      parent = Outline.new
      parent.name = name
      parent.outlines = Opml.parse_file(file, parent)
      @root_outlines << parent
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
