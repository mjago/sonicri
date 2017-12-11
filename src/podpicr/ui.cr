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
      @categories = ["Podcasts", "Music", "Radio Stations"]
      @station = ""
      @title = ""
      @program = ""
      @display_stack = Deque(Display).new
      @rss = RSS.new
    end

    def close
      @keys.close
      @display.close
    end

    def init_list(kind)
      case (kind[:type])
      when "categories"
        @page.name = "Categories"
        @display.page = @page
        @display.list = @categories
      when "stations"
        @page.name = "Stations"
        @display.page = @page
        @display.list = @list.stations
      when "shows"
        @page.name = "Shows - " + "(#{@station})"
        @display.page = @page
        @display.list = @list.shows(kind[:value])
      when "episodes"
        if @rss.parse kind[:value]
          list = @rss.results("title")
          @page.name = "Episodes - (" + @station + ": " + @title + ")"
          @display.page = @page
          @display.list = @rss.results("title")
        else
          return false
        end
      else
        raise "ERROR! invalid kind (#{kind[:type]}) in UI#init_list"
      end
      @display.draw_list
      true
    end

    def resume
      @display = @display_stack.pop
      @display.draw_list
    end

    def episode_info
      urls = @rss.results("url")
      lengths = @rss.results("length")
      idx = @display.selected.to_i
      url = urls[idx]
      length = lengths[idx].to_i64
      {url: url, length: length}
    end

    def category_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
        when "selected"
          @display_stack.push @display.dup
          @display.redraw(response)
          category = @categories[@display.selected]
          return {action: "select", value: category}
        when "back"
          return {action: "back", value: ""}
        when "char"
          return {action: "char", value: response[:value]}
        end
      end
    end

    def stations_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
        when "selected"
          @display_stack.push @display.dup
          @display.redraw(response)
          @station = @list.stations[@display.selected]
          return {action: "select", value: @station}
        when "back"
          return {action: "back", value: ""}
        when "char"
          return {action: "char", value: response[:value]}
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
          @display_stack.push @display.dup
          @display.redraw(response)
          @title = @display.list[@display.selected]
          xml_link = @list.xmlUrl(@title)[0]
          return {action: "select", value: xml_link}
        when "back"
          return {action: "back", value: ""}
        when "char"
          return {action: "char", value: response[:value]}
        end
      end
    end

    def episodes_monitor
      response = @keys.check_input
      if valid_response? response
        case response[:action]
        when "selection"
          @display.redraw(response)
#          puts "\n\n\r#{@display.list.inspect}"
        when "selected"
          @display.redraw(response)

          @program = @display.list[@display.selected]
#          puts "\n\n\r#{file_friendly_name}"

          return {action: "select", value: @display.selected.to_s}
        when "back"
          return {action: "back", value: ""}
        when "char"
          return {action: "char", value: response[:value]}
        end
      end
    end

    def file_friendly_name
      [@station, @title, @program].map { |n| sanitize_name n }.join("/")
    end

    private def sanitize_name(name)
      array = [] of Char
      name.each_char do |char|
        array << case char
                 when 'a'..'z', 'A'..'Z', '0'..'9'; char
                 else '_'
                 end
      end
      array.join
    end

    private def valid_response?(response)
      response.class == NamedTuple(action: String, value: String)
    end
  end
end
