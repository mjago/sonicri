require "ncurses"

module PodPicr
  class UI
    setter list : List
    getter display : Display
    getter keys : Keys

    def initialize
      @page = Page.new
      @list = List.new
      @display = Display.new(@page)
      @keys = Keys.new(@display.window)
      @station = ""
      @title = ""
    end

    def close
      @display.close
    end

    def init_list(type)
      case (type[:type])
      when "stations"
        @page.name = "Stations"
        @display.page = @page
        @display.list = @list.stations
      when "titles"
        @page.name = "Programs - " + "(#{@station})"
        @display.page = @page
        @display.list = @list.titles(type[:value])
      end
      @display.draw_list
    end

    def stations_monitor
      res = @keys.check_input
      if res.class == NamedTuple(action: String, value: String)
        case res[:action]
        when "selection"
          @display.redraw(res)
        when "selected"
          @display.redraw(res)
          @station = @list.stations[@display.selected]
          return {action: "selected", station: @station}
        when "char"
          case res[:value]
          when "q", "Q"
            return {action: "cancel", station: ""}
          end
        end
      end
      false
    end

    def titles_monitor
      res = @keys.check_input
      if res.class == NamedTuple(action: String, value: String)
        case res[:action]
        when "selection"
          @display.redraw(res)
        when "selected"
          @display.redraw(res)
          @title = @display.list[@display.selected]
          xml_link = @list.xmlUrl(@title)[0]
          return {action: "xml_link",
                  xmlUrl: xml_link}
        when "char"
          case res[:value]
          when "q", "Q"
            return {action: "cancel", xmlUrl: ""}
          end
        end
      end
      false
    end

    def programs_init(rss)
      @page.name = "Episodes - (" + @station + ": " + @title + ")"
      @display.page = @page
      @display.list = rss.results("title")
      @display.draw_list
    end

    def programs_monitor
      res = @keys.check_input
      if res.class == NamedTuple(action: String, value: String)
        case res[:action]
        when "selection"
          @display.redraw(res)
        when "selected"
          @display.redraw(res)
          program = @display.list[@display.selected]
          return {action: "select",
                  value:  @display.selected.to_s}
        when "char"
          case res[:value]
          when "q", "Q"
            return {action: "cancel", value: ""}
          end
        end
      end
      false
    end
  end
end
