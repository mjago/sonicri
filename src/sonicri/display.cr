require "ncurses"

module Sonicri
  class Display
    TitleColor        = 1
    SelectColor       = 2
    NonSelectColor    = 3
    SelectionColor    = 4
    InstructionColor  = 5
    ItemColor         = 6
    HeadingColor      = 7
    ItemInactiveColor = 8

    HIT_SPACE = 29

    getter window
    getter list
    property page

    def initialize(@page : Page)
      NCurses.init
      NCurses.attempt_remove_cursor
      NCurses.cbreak
      NCurses.no_echo
      NCurses.start_color
      generate_colors
      @window = NCurses::Window.new
      @list = [] of String
    end

    def load_list(list)
      @list = list
    end

    def close
      NCurses.end_win
      exit 0
    end

    def draw_list
      draw_heading
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
      draw_instruction
      @window.refresh
    end

    def draw_items
      list_offset = 2
      item_offset = 5
      selection = @page.selection % @page.page_size
      from = @page.descending? ? (@page.selection) - 1 : @page.selection
      to = from + list_offset
      (from...to).each do |line_num|
        @window.move((line_num % @page.page_size) + list_offset, item_offset)
        if line_num < @list.size
          draw_line(line_num)
        else
          draw_blank_line(line_num, NonSelectColor)
        end
      end
      @window.refresh
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
    end

    def selected
      @page.selected
    end

    def selection
      @page.selection
    end

    # private...

    private def draw_heading
      @window.move(0, 0)
      @window.with_color(HeadingColor) do
        @window.print(" " * ((@page.line_size) + 6))
        @window.move(0, (@page.line_size / 2) - 3)
        @window.with_attr(:bold) do
          @window.print("Sonicri")
        end
        @window.move(1, 0)
      end
    end

    private def draw_title
      @window.with_color(TitleColor) do
        page_name = @page.name.size > 78 ? @page.name[0..74] + "...)" : @page.name
        @window.with_attr(:bold) do
          @window.print(" " * 6 + page_name)
          @window.print(" " * (@page.line_size - page_name.size))
        end
        @window.print("\n")
      end
    end

    private def draw_item_num(line_num)
      if line_num < @list.size
        @window.with_color(ItemColor) do
          @window.print format_item_num(line_num)
        end
      else
        @window.with_color(ItemInactiveColor) do
          @window.print format_item_num(line_num)
        end
      end
    end

    private def draw_line(line_num)
      attributes = get_line_attributes(line_num)
      color = get_line_color(line_num)
      @window.with_attr(attributes) do
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
      @window.with_color(color) do
        @window.print("#{line_length_correction(line_num)}\n")
      end
    end

    private def draw_blank_line(line_num, color)
      @window.with_color(color) do
        @window.print((" " * (@page.line_size + 1)) + "\n")
      end
    end

    private def draw_instruction
      @window.print("\n" + (" " * HIT_SPACE) + "Hit ")
      @window.with_color(InstructionColor) { @window.print(" Arrow Keys ") }
      @window.print(" to cycle, ")
      @window.with_color(InstructionColor) { @window.print(" ESC ") }
      @window.print(" to quit, ")
      @window.with_color(InstructionColor) { @window.print(" H ") }
      @window.print(" for help...\n")
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
          generate_color(InstructionColor, 1, 15)
          generate_color(HeadingColor, 16, 226)
          generate_color(ItemInactiveColor, 238, 68)
        elsif NCurses.colors >= 8
          generate_color(TitleColor, 7, 4)
          generate_color(ItemColor, 7, 4)
          generate_color(SelectColor, 7, 2)
          generate_color(SelectionColor, 4, 2)
          generate_color(NonSelectColor, 7, 0)
          generate_color(InstructionColor, 1, 7)
          generate_color(HeadingColor, 0, 7)
          generate_color(ItemInactiveColor, 7, 0)
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
