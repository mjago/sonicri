require "ncurses"

module Sonicri
  class UI
    setter list
    getter display
    getter keys

    def initialize
      @page = Page.new
      @podcast_page = Page.new
      @display = Display.new(@page)
      @keys = Keys.new(@display.list_win)
      @categories = %w[Podcasts Music Radio\ Stations]
      @station = ""
      @title = ""
      @title_array = [] of String
      @program = ""
      @display_stack = Deque(Display).new
      @rss = RSS.new
      @podcast = Podcast.new
      @music = Music.new
      @radio = Radio.new
      @depth = 0
    end

    def close
      @keys.close
      @display.close
    end

    def init_list(kind)
      return_val = false
      case (kind[:type])
      when "category"; category_init
      when "podcast" ; podcast_init
      when "music"   ; music_init
      when "radio"   ; radio_init
      when "episode"
        return_val = episode_init(kind)
      else
        raise "ERROR! invalid kind (#{kind[:type]}) in UI#init_list"
      end
      case kind["value"]
      when "init"; @display.draw_page
      else
        @display.draw_partial_page
      end
      return_val
    end

    def monitor(source)
      if @keys.key_available?
        key = @keys.next_key
        case source
        when "category"; category_monitor(key)
        when "podcast" ; podcast_monitor(key)
        when "episode" ; episode_monitor(key)
        when "music"   ; music_monitor(key)
        when "radio"   ; radio_monitor(key)
        when "help"    ; help_monitor(key)
        else
          raise "Error! Unknown monitor in UI"
        end
      end
    end

    def file_friendly_name
      temp = @title_array.map { |n| sanitize_name n }.join("/")
      temp + "/" + @program
    end

    def episode_info
      urls = @rss.results("url")
      lengths = @rss.results("length")
      idx = @display.selected.to_i
      url = urls[idx]
      length = lengths[idx].to_i64
      {url: url, length: length}
    end

    # private

    # init

    private def category_init
      @page.name = "Categories"
      @display.page = @page
      @display.load_list @categories
      @title_array.clear
    end

    private def podcast_init
      unless @podcast.parsed?
        @podcast = Podcast.new
      end
      @podcast.reset
      @page.name = "Podcasts"
      @display.page = @page
      @display.load_list @podcast.content
    end

    private def episode_init(kind)
      if @rss.parse kind[:value]
        list = @rss.results("title")
        @page.name = "Episodes"
        @display.page = @page
        @display.load_list list
      else
        return false
      end
      true
    end

    private def music_init
      @music = Music.new
      @page.name = "Music"
      @display.page = @page
      @display.load_list @music.albums
    end

    private def radio_init
      @page.name = "Radio"
      @display.page = @page
      @display.load_list @radio.station_list
    end

    # monitors

    private def category_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        save_display
        @display.redraw(key)
        category = @categories[@display.selected]
        return Key.new("select", category)
      when "mouse selected"
        if @display.select_maybe(key)
          save_display
          category = @categories[@display.selected]
          return Key.new("select", category)
        end
      else
        return key
      end
    end

    private def podcast_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        return podcast_select
      when "mouse selected"
        return podcast_select if @display.select_maybe(key)
      when "back"
        @title_array.pop?
        if @podcast.root?
          @podcast.reset
          return Key.new("back")
        else
          resume "podcast"
          return Key.new("no action")
        end
      else
        return key
      end
    end

    private def episode_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        @display.redraw(key)
        return episode_select
      when "mouse selected"
        return episode_select if @display.select_maybe(key)
      when "back"
        @title_array.pop
        @display.page = @podcast_page
        @display.load_list @podcast.content
        @display.draw_partial_page
        return key
      else
        return key
      end
    end

    private def music_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        return music_select
      when "mouse selected"
        return music_select if @display.select_maybe(key)
      when "back"
        if @music.root?
          return Key.new("back")
        else
          resume "music"
          @display.load_list @music.contents
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
      when "key selected"
        return radio_select
      when "mouse selected"
        return radio_select if @display.select_maybe(key)
      when "back"
        return Key.new("back")
      else
        return key
      end
    end

    private def help_monitor(key)
      return key if key.action
    end

    # select

    private def podcast_select
      selection = @display.selection
      @title_array << @podcast.current_outlines[@display.selection].name
      if @podcast.children?(selection)
        save_display
        @podcast.push
      end
      resp = @podcast.select(selection)
      case resp
      when "list"
        @depth += 1
        @display.load_list @podcast.content
        @display.page = @page
        @display.draw_partial_page
      when ""
        raise "Invalid error in #podcast_select"
      else
        @depth += 1
        @podcast_page = @display.page
        return Key.new("select", resp)
      end
      return Key.new("no action")
    end

    private def episode_select
      @program = @display.list[@display.selection]
      return Key.new("select", @display.selection.to_s)
    end

    private def music_select
      file = @music.albums[@display.selection]
      if @music.directory? file
        save_display
        @music.push file
        @display.load_list @music.contents
        @page.name = file
        @display.page = @page
        @display.draw_partial_page
        return Key.new("no action")
      elsif @music.mp3_file?(file)
        filename = @music.file_with_path(file)
        return Key.new("select", filename)
      else
        raise "Error: Unexpected file in UI#music_select!"
      end
    end

    private def radio_select
      name = @radio.station_list[@display.selection]
      if url = @radio.url_of(name)
        return Key.new("select", url)
      end
    end

    # miscellaneous

    private def resume(type)
      @podcast.pop if type == "podcast"
      @music.pop if type == "music"
      @display = @display_stack.pop unless @display_stack.empty?
      @display.draw_partial_page
    end

    def display_help
      @display.draw_help
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
