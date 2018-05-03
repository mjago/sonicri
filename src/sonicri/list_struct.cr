module Sonicri
  struct ListStruct
    property station = ""
    property text = ""
    property description = ""
    property url = ""

    def self.names
      %w[@text @description @url]
    end

    def assign(hash : Hash(String, String))
      @station = hash["station"]
      @text = hash["text"]
      @description = hash["description"]
      @url = hash["url"]
    end
  end
end
