require "ncurses"

module PodPicr
  class UI
    setter list : List
    getter display : Display
    getter keys : Keys

    def initialize
      @page = Page.new
      @back_page = Page.new
      @list = List.new
      @back_list = [] of String
      @display = Display.new(@page)
      @keys = Keys.new(@display.window)
      @station = ""
      @title = ""
    end

    def close
      @keys.close
      @display.close
    end

    def init_list(kind)
      case (kind[:type])
      when "stations"
        backup
        @page.name = "Stations"
        @display.page = @page
        @display.list = @list.stations
      when "shows"
        backup
        @page.name = "Shows - " + "(#{@station})"
        @display.page = @page
        @display.list = @list.shows(kind[:value])
      end
      @display.draw_list
    end

    def episodes_init(rss)
      backup
      @page.name = "Episodes - (" + @station + ": " + @title + ")"
      @display.page = @page
      @display.list = rss.results("title")
      @display.draw_list
    end

    def stations_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
        when "selected"
          @display.redraw(response)
          @station = @list.stations[@display.selected]
          return {action: "select", station: @station}
        when "back"
          recall
          return {action: "back", station: ""}
        end
      end
    end

    def shows_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
        when "selected"
          @display.redraw(response)
          @title = @display.list[@display.selected]
          xml_link = @list.xmlUrl(@title)[0]
          return {action: "select", xmlUrl: xml_link}
        when "back"
          recall
          return {action: "back", xmlUrl: ""}
        end
      end
    end

    def episodes_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
        when "selected"
          @display.redraw(response)
          program = @display.list[@display.selected]
          return {action: "select", value: @display.selected.to_s}
        when "back"
          #          @page = @back_page.dup
          #          @list = @back_list.dup
          recall
          return {action: "back", value: ""}
        end
      end
    end

    private def backup
      #      @back_page = @display.page
      #      @back_list = @display.list
    end

    private def recall
      #      @display.page = @back_page
      #      @display.list = @back_list
      #      @display.draw_list
    end

    private def valid_response?(response)
      response.class == NamedTuple(action: String, value: String)
    end
  end
end
