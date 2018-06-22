module Sonicri
  class Radio
    INTERNET_RADIO_OPML = "opml/internet_radio/stations.opml"

    property channels

    def initialize
      @channels = OpmlDataset.new
      @channels.parse INTERNET_RADIO_OPML
    end

    def select(selection)
      attr_names = ["htmlUrl", "url"]
      @channels.select selection, attr_names
    end
  end
end
