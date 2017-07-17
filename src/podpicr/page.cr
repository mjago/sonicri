module PodPicr
  struct Page
    property line_size, page_size, page_start
    property selection, selected
    property list_size, name

    def initialize
      @name = ""
      @line_size = 80
      @page_size = 20
      @page_start = 0
      @list_size = 0
      @selection = 0
      @selected = -1
    end
  end
end
