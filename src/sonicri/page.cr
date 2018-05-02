module Sonicri
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

    def next_item(list_size)
      @selection += 1
      if @selection > (list_size - 1)
        @selection = 0
        @page_start = 0
      elsif @selection > @page_start + @page_size - 1
        @page_start += @page_size
      end
    end

    def previous_item(list_size)
      @selection -= 1
      if @selection < 0
        @selection = (list_size - 1)
        @page_start = start_of_last_page(list_size)
      elsif @selection < @page_start
        @page_start -= @page_size
      end
    end

    private def start_of_last_page(list_size)
      (list_size - 1) / @page_size * @page_size
    end

    def next_page(list_size)
      @page_start += @page_size
      unless @page_start < list_size
        @page_start = 0
        @selection %= @page_size
      else
        @selection += @page_size
        @selection = (list_size - 1) if (@selection > (list_size - 1))
      end
    end

    def previous_page(list_size)
      @page_start -= @page_size
      if @page_start < 0
        @page_start = start_of_last_page(list_size)
        @selection = start_of_last_page(list_size) +
                     (@selection %= @page_size)
        @selection = (list_size - 1) if (@selection > (list_size - 1))
      else
        @selection -= @page_size
      end
    end

    def select_item
      @selected = @selection
    end
  end
end
