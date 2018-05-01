require "ncurses"

module Sonicri
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
      @music = Music.new
      @radio = Radio.new
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
      when "music"
        @music = Music.new
        @page.name = "Music"
        @display.page = @page
        @display.list = @music.albums
      when "radio"
        @page.name = "Radio"
        @display.page = @page
        @display.list = @radio.station_list
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

    def monitor(source)
      if @keys.key_available?
        key = @keys.next_key
        case source
        when "category"
          category_monitor(key)
        when "music"
          music_monitor(key)
        when "radio"
          radio_monitor(key)
        when "station"
          station_monitor(key)
        when "show"
          show_monitor(key)
        when "episode"
          episode_monitor(key)
        else
          raise "Error! Unknown monitor in UI"
        end
      end
    end

    def file_friendly_name
      [@station, @title, @program].map { |n| sanitize_name n }.join("/")
    end

    private def station_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        save_display
        @display.redraw(key)
        @station = @list.stations[@display.selected]
        return Key.new("select", @station)
      else
        return key
      end
    end

    private def category_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        save_display
        @display.redraw(key)
        category = @categories[@display.selected]
        return Key.new("select", category)
      else
        return key
      end
    end

    private def music_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        file = @music.albums[@display.selection]
        if @music.directory? file
          save_display
          @music.push_level file
          @display.list = @music.contents
          @page.name = file
          @display.page = @page
          @display.draw_list
          return Key.new("no action")
        elsif @music.mp3_file?(file)
          filename = @music.file_with_path(file)
          return Key.new("select", filename)
        else
          raise "Error: Unexpected file in music_monitor!"
        end
      when "back"
        if @music.top_level?
          return Key.new("back")
        else
          @music.pop_level
          resume
          @display.list = @music.contents
          return Key.new("no action")
        end
      else
        return key
      end
    end

    private def radio_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        name = @radio.station_list[@display.selection]
        if url = @radio.url_of(name)
          return Key.new("select", url)
        end
      when "back"
        return Key.new("back")
      else
        return key
      end
    end

    private def show_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        save_display
        @display.redraw(key)
        @title = @display.list[@display.selected]
        xml_link = @list.xmlUrl(@title)[0]
        return Key.new("select", xml_link)
      else
        return key
      end
    end

    private def episode_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "selected"
        @display.redraw(key)
        @program = @display.list[@display.selected]
        return Key.new("select", @display.selected.to_s)
      else
        return key
      end
    end

    private def save_display
      @display_stack.push @display.dup
    end

    private def sanitize_name(name)
      array = [] of Char
      name.each_char do |char|
        array <<
          case char
          when 'a'..'z', 'A'..'Z', '0'..'9'
            char
          else '_'
          end
      end
      array.join
    end
  end
end
