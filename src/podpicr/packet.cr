module PodPicr
  struct Packet
    property slice
    property size

    def initialize(@slice : Slice(UInt8), @size : Int32)
    end
  end
end
