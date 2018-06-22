module Sonicri
  class Radio
    INTERNET_RADIO_OPML = "opml/internet_radio/stations.opml"

    def initialize
      @node = Node.new
      parse_opml
    end

    def current_outlines
      @node.current_outlines
    end

    def root?
      @node.root?
    end

    def parsed?
      @node.parsed?
    end

    def reset
      @node.reset
    end

    def push
      @node.push
    end

    def pop
      @node.pop
    end

    def children?(selection)
      @node.children?(selection)
    end

    def select(selection)
      attr_names = ["htmlUrl", "url"]
      @node.select(selection, attr_names)
    end

    def parse_opml
      @node.parse INTERNET_RADIO_OPML
    end

    def content
      @node.content
    end
  end
end
