require "ncurses"

module Sonicri
  class UI
    PAGE_TITLES = {"category" => "Categories",
                   "podcast"  => "Podcasts",
                   "music"    => "Music",
                   "radio"    => "Internet Radio"}
    setter list
    getter display
    getter keys

    def initialize
      @page = Page.new
      @cache_page = Page.new
      @display = Display.new(@page)
      @keys = Keys.new(@display.list_win)
      @title = ""
      @title_array = [] of String
      @program = ""
      @display_stack = Deque(Display).new
      @rss = RSS.new
      @depth = 0
      @category = Category.new
      @podcast = Podcast.new
      @music = Music.new
      @radio = Radio.new
      @media_objs = {"category" => @category,
                     "podcast"  => @podcast,
                     "music"    => @music,
                     "radio"    => @radio}
    end

    def close
      @keys.close
      @display.close
    end

    def init_list(kind)
      return_val = false
      case (kind[:type])
      when "episode"
        return_val = episode_init(kind)
      else
        init kind[:type]
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
        monitor_media(source, key)
      end
    end

    def display_help
      @display.draw_help
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

    private def init(kind)
      obj = media_obj(kind)
      obj.channels.reset
      @page.name = page_title(kind)
      @display.page = @page
      @display.load_list obj.channels.content
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

    private def monitor_media(kind, key)
      case kind
      when "category"; monitor_category(key)
      when "episode" ; monitor_episode(key)
      when "help"    ; return key if key.action
      else
        case key.action
        when "selection"
          @display.redraw(key)
        when "key selected"
          return select_media(kind)
        when "mouse selected"
          return select_media(kind) if @display.select_maybe(key)
        when "back"
          @title_array.pop?
          media = media_obj(kind)
          if media.channels.root?
            media.channels.reset unless (kind == "music")
            return Key.new("back")
          else
            resume kind
            @display.load_list(media.channels.content) if (kind == "music")
            return Key.new("no action")
          end
        else
          return key
        end
      end
    end

    private def monitor_category(key)
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

    private def monitor_episode(key)
      case key.action
      when "selection"
        @display.redraw(key)
      when "key selected"
        @display.redraw(key)
        return select_media("episode")
      when "mouse selected"
        return select_media("episode") if @display.select_maybe(key)
      when "back"
        @title_array.pop
        @display.page = @cache_page
        @display.load_list @podcast.channels.content
        @display.draw_partial_page
        return key
      else
        return key
      end
    end

    # select

    private def select_media(kind)
      case kind
      when "episode"; episode_select
      when "music"  ; music_select
      else
        media = media_obj(kind)
        if media.is_a?(Podcast) || media.is_a?(Radio)
          selection = @display.selection
          @title_array << media.channels.title(@display.selection)
          if media.channels.children? selection
            save_display
            media.channels.push
          end
          resp = media.select selection
          @depth += 1
          case resp
          when "list"
            @display.load_list media.channels.content
            @display.page = @page
            @display.draw_partial_page
          when ""
            return Key.new("no action")
          else
            @cache_page = @display.page
            return Key.new("select", resp)
          end
        end
        return Key.new("no action")
      end
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
        @display.load_list @music.channels.content
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

    private def media_obj(kind)
      @media_objs[kind]
    end

    private def page_title(kind)
      PAGE_TITLES[kind]
    end
  end
end
