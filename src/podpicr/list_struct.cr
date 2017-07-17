module PodPicr
  struct ListStruct
    property station, description, text
    property xmlUrl, htmlUrl

    def initialize
      @station = ""
      @description = ""
      @text = ""
      @version = ""
      @typicalDurationMins = ""
      @xmlUrl = ""
      @htmlUrl = ""
      @imageHref = ""
      @keyname = ""
      @page = ""
      @allow = ""
      @active = ""
      @flavour = ""
      @bbcgenres = ""
    end

    def self.names
      %w(@description @text @version @typicalDurationMins
        @xmlUrl @htmlUrl @imageHref @keyname @page @allow
        @active @flavour @bbcgenres)
    end

    def assign(hash : Hash(String, String))
      @station = hash["station"]
      @description = hash["description"]
      @text = hash["text"]
      @version = hash["version"]
      @typicalDurationMins = hash["typicalDurationMins"]
      @xmlUrl = hash["xmlUrl"]
      @htmlUrl = hash["htmlUrl"]
      @imageHref = hash["imageHref"]
      @keyname = hash["keyname"]
      @page = hash["page"]
      @allow = hash["allow"]
      @active = hash["active"]
      @flavour = hash["flavour"]
      @bbcgenres = hash["bbcgenres"]
    end
  end
end
