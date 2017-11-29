module PodPicr
  struct ListStruct
    property station, text, description, version
    property xmlUrl, htmlUrl

    def initialize
      @station = ""
      @text = ""
      @description = ""
      @version = ""
      @xmlUrl = ""
      @htmlUrl = ""
    end

    def self.names
      %w[@text @description @version @xmlUrl @htmlUrl]
    end

    def assign(hash : Hash(String, String))
      @station = hash["station"]
      @text = hash["text"]
      @description = hash["description"]
      @version = hash["version"]
      @xmlUrl = hash["xmlUrl"]
      @htmlUrl = hash["htmlUrl"]
    end
  end
end
