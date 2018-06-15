require "opml"
require "yaml"

module Sonicri
  class Podcast
    TEMP_OPML = "temp.opml"

    @root_outlines : Array(Outline) = Array(Outline).new
    getter? parsed
    getter current_outlines : Array(Outline) = @root_outlines

    def initialize
      @outlines_stack = Deque(Array(Outline)).new
      @count = 0
      parse_opml
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

    def content
      temp = [] of String
      @current_outlines.each do |ol|
        temp << ol.name
      end
      temp
    end

    def children?(selection)
      current = @current_outlines[selection]
      current.outlines?
    end

    def select(selection)
      current = @current_outlines[selection]
      if current.outlines?
        @current_outlines = sort_outlines_by_name(current.outlines)
        return "list"
      else
        value = ""
        if current.attributes.has_key?("xmlUrl")
          return current.attributes["xmlUrl"]
        elsif current.attributes.has_key?("url")
          return current.attributes["url"]
        end
      end
      return ""
    end

    def parse_opml
      fetch_opml_from_yaml_list
      parse_from_opml_directory
      @root_outlines = sort_outlines_by_name(@root_outlines)
      names = Array(String).new
      @current_outlines = @root_outlines
      @current_outlines.each do |outline|
        names << outline.name
      end
      @parsed = true
    end

    # private

    private def sort_outlines_by_name(ol)
      ol.sort { |x, y| x.name <=> y.name }
    end

    private def update(addr)
      Downloader.fetch(addr, TEMP_OPML)
      @document = XML.parse(TEMP_OPML)
    end

    private def parse_OPML_local(file)
      Downloader.fetch(file, TEMP_OPML)
      @root_outlines += Opml.parse_file(TEMP_OPML)
    end

    private def fetch_opml_from_yaml_list
      yml = YAML.parse File.read("opml/opml.yml")
      files = [] of String
      if yml["version"] == "0.1.0"
        sources = yml["sources"].as_a
        sources.each do |source|
          name = source[0].as_s
          path = source[1].as_s
          Downloader.fetch(path, TEMP_OPML)
          if name == ""
            @root_outlines += Opml.parse_file(TEMP_OPML)
          else
            parent = Outline.new
            parent.name = name
            parent.outlines = Opml.parse_file(TEMP_OPML, parent)
            @root_outlines << parent
          end
        end
      else
        raise "Error: Can't parse this version of opml.yml config file!"
      end
    end

    private def parse_from_opml_directory
      Dir.glob("opml/**/*.opml").each do |path|
        @root_outlines += Opml.parse_file(path)
      end
    end
  end
end
