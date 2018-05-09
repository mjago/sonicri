module Sonicri
  struct Page
    getter line_size = 80
    property name = ""
    property page_size = 20
    property page_start = 0
    property selection = 0
    property selected = -1
    property? descending = true
    property? redraw_page = true

    def select_maybe(key, list_size)
      val = key.value.to_i + page_start
      return false if val >= list_size
      @selection = val
      @selected = val
      @redraw_page = true
      true
    end

    def next_item(list_size)
      @redraw_page = false
      @descending = true
      @selection += 1
      if @selection > (list_size - 1)
        @redraw_page = true
        @selection = 0
        @page_start = 0
      elsif @selection > @page_start + @page_size - 1
        @redraw_page = true
        @page_start += @page_size
      end
    end

    def previous_item(list_size)
      @redraw_page = false
      @descending = false
      @selection -= 1
      if @selection < 0
        @redraw_page = true
        @selection = (list_size - 1)
        @page_start = start_of_last_page(list_size)
      elsif @selection < @page_start
        @redraw_page = true
        @page_start -= @page_size
      end
    end

    private def start_of_last_page(list_size)
      (list_size - 1) / @page_size * @page_size
    end

    def next_page(list_size)
      @redraw_page = true
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
      @redraw_page = true
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
