require "ncurses"

module Sonicri
  class UI
    setter list
    getter display
    getter keys

    def initialize
      @category = Category.new
      @page = Page.new
      @podcast_page = Page.new
      @radio_page = Page.new
      @display = Display.new(@page)
      @keys = Keys.new(@display.list_win)
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
      when "category"; init(@category, "Categories")
      when "podcast" ; init(@podcast, "Podcasts")
      when "music"   ; init(@music, "Music")
      when "radio"   ; init(@radio, "Internet Radio")
      when "episode" ; return_val = episode_init(kind)
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

    private def init(kind, title)
      kind.channels.reset
      @page.name = title
      @display.page = @page
      @display.load_list kind.channels.content
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

    # monitors

    private def category_monitor(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        save_display
        @display.redraw(key)
        category = @category.channels.content[@display.selected]
        return Key.new("select", category)
      when "mouse selected"
        if @display.select_maybe(key)
          save_display
          category = @category.channels.content[@display.selected]
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
        if @podcast.channels.root?
          @podcast.channels.reset
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
        @display.load_list @podcast.channels.content
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
        if @music.channels.root?
          return Key.new("back")
        else
          resume "music"
          @display.load_list @music.channels.contents
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
        @title_array.pop?
        if @radio.channels.root?
          @radio.channels.reset
          return Key.new("back")
        else
          resume "radio"
          return Key.new("no action")
        end
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
      @title_array << @podcast.channels.title(@display.selection)
      if @podcast.channels.children? selection
        save_display
        @podcast.channels.push
      end
      resp = @podcast.select selection
      case resp
      when "list"
        @depth += 1
        @display.load_list @podcast.channels.content
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

    private def radio_select
      selection = @display.selection
      @title_array << @radio.channels.title(@display.selection)
      if @radio.channels.children? selection
        save_display
        @radio.channels.push
      end
      resp = @radio.select(selection)
      case resp
      when "list"
        @depth += 1
        @display.load_list @radio.channels.content
        @display.page = @page
        @display.draw_partial_page
      when ""
        raise "Invalid error in #radio_select"
      else
        @depth += 1
        @radio_page = @display.page
        return Key.new("select", resp)
      end
      return Key.new("no action")
    end

    private def episode_select
      @program = @display.list[@display.selection]
      return Key.new("select", @display.selection.to_s)
    end

    private def music_select
      file = @music.channels.content[@display.selection]
      if @music.channels.directory? file
        save_display
        @music.channels.push file
        @display.load_list @music.channels.contents
        @page.name = file
        @display.page = @page
        @display.draw_partial_page
        return Key.new("no action")
      elsif @music.channels.mp3_file? file
        filename = @music.file_with_path(file)
        return Key.new("select", filename)
      else
        raise "Error: Unexpected file in UI#music_select!"
      end
    end

    # miscellaneous

    private def resume(type)
      @podcast.channels.pop if type == "podcast"
      @radio.channels.pop if type == "radio"
      @music.channels.pop if type == "music"
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
