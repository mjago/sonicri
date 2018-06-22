require "yaml"

module Sonicri
  class Podcast
    TEMP_OPML  = "temp.opml"
    OPML_YAML  = "opml/podcast/opml.yml"
    OPML_FILES = "opml/podcast"

    property channels

    def initialize
      @channels = OpmlDataset.new
      parse_opml
    end

    def select(selection)
      attr_names = ["xmlUrl", "url"]
      @channels.select selection, attr_names
    end

    # private

    private def parse_opml
      fetch_opml_from_yaml_list
      parse_from_opml_directory
    end

    private def fetch_opml_from_yaml_list
      yml = YAML.parse File.read(OPML_YAML)
      files = [] of String
      if yml["version"] == "0.1.0"
        sources = yml["sources"].as_a
        sources.each do |source|
          name = source[0].as_s
          path = source[1].as_s
          Downloader.fetch(path, TEMP_OPML)
          if name == ""
            @channels.parse TEMP_OPML
          else
            @channels.parse_into name, TEMP_OPML
          end
        end
      else
        raise "Error: Can't parse this version of opml.yml config file!"
      end
    end

    private def parse_from_opml_directory
      Dir.glob(OPML_FILES + "/**/*.opml").each do |path|
        @channels.parse path
      end
    end
  end
end
