require "ncurses"

module Sonicri
  class Display
    TitleColor        =  1
    SelectColor       =  2
    NonSelectColor    =  3
    SelectionColor    =  4
    InfoColor         =  5
    ItemColor         =  6
    HeadingColor      =  7
    ItemInactiveColor =  8
    KeyColor          =  9
    ProgressColor     = 10
    HIT_SPACE         =  0

    property progress : Progress
    property list_win
    getter list
    property page

    struct Progress
      def initialize(@win : NCurses::Window)
        clear
      end

      def print(progress : String = "")
        @win.move(1, 0)
        @win.with_color(ProgressColor) do
          @win.print " " + progress + (" " * (30 - progress.size))
        end
        @win.refresh
      end

      def clear
        @win.with_color(ProgressColor) do
          3.times do |x|
            @win.move(x, 0)
            @win.print(" " * 31)
          end
        end
        @win.refresh
      end
    end

    def draw_help
      title_offset_row = 1
      title_offset_col = 6
      help_offset_row = 6
      help_offset_col = 7
      help_data = [
        ["", ""],
        [" \[arrow keys\] :", "Menu navigation"],
        [" \[return\] :", "Play or enter selection menu"],
        ["", ""],
        [" p :", "Pause"],
        [" f :", "Skip-forward (10 sec)"],
        [" F :", "Skip-forward (1 minute)"],
        [" b :", "Skip-backward (10 sec)"],
        [" B :", "Skip-backward (1 minute)"],
        [" s :", "Stop"],
        [" q :", "Quit"],
        ["", ""],
        [" \[backspace\] :", "Back up menu"],
        [" \[escape\] :", "Back up menu"],
        ["", ""],
      ]

      20.times do |count|
        @list_win.move(2 + count, 0)
        @list_win.with_color(TitleColor) do
          @list_win.print(" " * 5)
        end
        @list_win.with_color(NonSelectColor) do
          @list_win.print(" " * 81)
        end
      end
      @list_win.move(title_offset_row, title_offset_col)
      @list_win.with_color(TitleColor) do
        @list_win.with_attr(:bold) do
          @list_win.print("Instructions for use" + " " * (@page.line_size - 20))
        end
      end
      (0...help_data.size).each do |row|
        @list_win.with_color(InfoColor) do
          #         @list_win.with_attr(:bold) do
          @list_win.move(help_offset_row + row, help_offset_col)
          @list_win.print(" " * (15 - help_data[row][0].size) + help_data[row][0] + " ")
          #         end
        end
        @list_win.with_color(NonSelectColor) do
          @list_win.with_attr(:bold) do
            @list_win.print(" " + help_data[row][1] + " " * (62 - help_data[row][1].size))
          end
        end
      end
    end

    def initialize(@page : Page)
      NCurses.init
      NCurses.attempt_remove_cursor
      NCurses.cbreak
      NCurses.no_echo
      NCurses.start_color
      generate_colors
      @list_win = NCurses::Window.new(height = 22, width = 87, row = 0, col = 0)
      @info_win = NCurses::Window.new(height = 3, width = 58, row = 22, col = 28)
      @progress_win = NCurses::Window.new(height = 3, width = 28, row = 22, col = 0)
      @progress = Progress.new(@progress_win)
      @list = [] of String
    end

    def load_list(list)
      @list = list
    end

    def close
      NCurses.end_win
      exit 0
    end

    def draw_partial_page
      draw_list
      @list_win.refresh
    end

    def draw_page
      draw_heading
      draw_list
      draw_info
      @list_win.refresh
    end

    def redraw(key)
      case key.action
      when "selection"
        move_to(key.value)
      when "selected"
        @page.select_item
      end
      draw_items unless @page.redraw_page?
      draw_list if @page.redraw_page?
      @list_win.refresh
    end

    def selected
      @page.selected
    end

    def selection
      @page.selection
    end

    # private...

    private def draw_list
      title_offset_row = 1
      title_offset_col = 0
      @list_win.move(title_offset_row, title_offset_col)
      draw_title
      from = @page.page_start
      to = from + @page.page_size
      (from...to).each do |line_num|
        draw_item_num(line_num)
        if line_num < @list.size
          draw_line(line_num)
        else
          draw_blank_line(line_num, NonSelectColor)
        end
      end
    end

    private def draw_items
      list_offset = 2
      item_offset = 5
      selection = @page.selection % @page.page_size
      from = @page.descending? ? (@page.selection) - 1 : @page.selection
      to = from + list_offset
      (from...to).each do |line_num|
        @list_win.move((line_num % @page.page_size) + list_offset, item_offset)
        if line_num < @list.size
          draw_line(line_num)
        else
          draw_blank_line(line_num, NonSelectColor)
        end
      end
    end

    private def draw_heading
      @list_win.move(0, 0)
      @list_win.with_color(HeadingColor) do
        @list_win.print(" " * ((@page.line_size) + 6))
        @list_win.move(0, (@page.line_size / 2) - 10)
        @list_win.with_attr(:bold) do
          @list_win.print("Sonicri Audio Player")
        end
        @list_win.move(1, 0)
      end
    end

    private def draw_title
      @list_win.with_color(TitleColor) do
        page_name = @page.name.size > 78 ? @page.name[0..74] + "...)" : @page.name
        @list_win.with_attr(:bold) do
          @list_win.print(" " * 6 + page_name)
          @list_win.print(" " * (@page.line_size - page_name.size))
        end
        @list_win.print("\n")
      end
    end

    private def draw_item_num(line_num)
      if line_num < @list.size
        @list_win.with_color(ItemColor) do
          @list_win.print format_item_num(line_num)
        end
      else
        @list_win.with_color(ItemInactiveColor) do
          @list_win.print format_item_num(line_num)
        end
      end
    end

    private def draw_line(line_num)
      attributes = get_line_attributes(line_num)
      color = get_line_color(line_num)
      @list_win.with_attr(attributes) do
        draw_color_line(line_num, color)
      end
    end

    private def get_line_color(line_num)
      color =
        case line_num
        when @page.selected
          SelectColor
        when @page.selection
          SelectionColor
        else
          NonSelectColor
        end
    end

    private def get_line_attributes(line_num)
      attributes =
        case line_num
        when @page.selected, @page.selection
          :bold
        else
          :normal
        end
    end

    private def line_size(str)
      # don't count combining accents
      str.delete("\u0300\u0301\u0302\u0308").size
    end

    private def line_length_correction(line_num)
      temp = ""
      line = @list[line_num]
      if (line.size > @page.line_size)
        temp = (line[0..(@page.line_size - 5)] + "...")
      else
        temp = line
      end
      line_format temp
    end

    private def line_format(str)
      size = line_size(str)
      if @page.line_size > size
        str = str + (" " * (@page.line_size - size))
      end
      " " + str.gsub('_', ' ')
    end

    private def draw_color_line(line_num, color)
      @list_win.with_color(color) do
        @list_win.print("#{line_length_correction(line_num)}\n")
      end
    end

    private def draw_blank_line(line_num, color)
      @list_win.with_color(color) do
        @list_win.print((" " * (@page.line_size + 1)) + "\n")
      end
    end

    private def draw_info
      @info_win.move(0, 0)
      @info_win.with_color(InfoColor) do
        3.times do |x|
          @info_win.move(x, 0)
          @info_win.print(" " * 58)
        end
        @info_win.move(1, 1)
        @info_win.with_attr(:bold) do
          @info_win.print("Hit ")
          @info_win.with_color(KeyColor) { @info_win.print(" Arrow Keys ") }
          @info_win.print(" to Cycle, ")
          @info_win.with_color(KeyColor) { @info_win.print(" ESC ") }
          @info_win.print(" to Quit, ")
          @info_win.with_color(KeyColor) { @info_win.print(" H ") }
          @info_win.print(" for Help.")
        end
      end
      @info_win.refresh
    end

    private def move_to(move)
      case move
      when "next"      then @page.next_item(@list.size)
      when "prev"      then @page.previous_item(@list.size)
      when "next_page" then @page.next_page(@list.size)
      when "prev_page" then @page.previous_page(@list.size)
      end
    end

    # private

    private def format_item_num(count)
      num = (count + 1).to_s
      str = " " * (4 - num.size)
      str + num + " "
    end

    private def quit?(char)
      char == 'q'
    end

    private def generate_color(slot, fg, bg)
      NCurses.init_color_pair(slot, fg, bg)
    end

    private def generate_colors
      if NCurses.has_colors?
        if NCurses.colors >= 256
          NCurses.curs_set(NCurses::Cursor::INVISIBLE)
          generate_color(TitleColor, 15, 18)
          generate_color(ItemColor, 15, 18)
          generate_color(SelectColor, 15, 34)
          generate_color(SelectionColor, 20, 155)
          generate_color(NonSelectColor, 7, 21)
          generate_color(KeyColor, 1, 15)
          generate_color(HeadingColor, 16, 226)
          generate_color(ItemInactiveColor, 238, 68)
          generate_color(InfoColor, 0x10, 0x7)
          generate_color(ProgressColor, 230, 8)
        elsif NCurses.colors >= 8
          generate_color(TitleColor, 7, 4)
          generate_color(ItemColor, 7, 4)
          generate_color(SelectColor, 7, 2)
          generate_color(SelectionColor, 4, 2)
          generate_color(NonSelectColor, 7, 0)
          generate_color(KeyColor, 1, 7)
          generate_color(HeadingColor, 0, 7)
          generate_color(ItemInactiveColor, 7, 0)
          generate_color(InfoColor, 1, 7)
          generate_color(ProgressColor, 14, 8)
        else
          raise("Error: require at least 64 colors!")
          exit 1
        end
      else
        raise("Error: Terminal hasn't any colors!")
        exit 1
      end
    end
  end
end
