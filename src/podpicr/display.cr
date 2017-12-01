require "ncurses"

module PodPicr
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
    property list
    property page

    def initialize(@page : Page)
      NCurses.init
      NCurses.cbreak
      NCurses.no_echo
      NCurses.start_color
      generate_colors
      @window = NCurses::Window.new
      @list = [] of String
    end

    def close
      NCurses.end_win
      exit 0
    end

    def draw_heading
      @window.move(0, 0)
      @window.with_color(HeadingColor) do
        @window.print(" " * ((@page.line_size) + 6))
        @window.move(0, (@page.line_size / 2) - 3)
        @window.with_attr(:bold) do
          @window.print("Pod Picr")
        end
        @window.move(1, 0)
        @window.refresh
      end
    end

    def draw_title
      @window.with_color(TitleColor) do
        page_name = @page.name.size > 78 ? @page.name[0..74] + "...)" : @page.name
        @window.with_attr(:bold) do
          @window.print(" " * 6 + page_name)
          @window.print(" " * (@page.line_size - page_name.size))
        end
        @window.print("\n")
        @window.refresh
      end
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
        @window.refresh
      end
      draw_instruction
    end

    def redraw(act)
      case act[:action]
      when "selection"
        if act[:action] == "return"
          close
        else
          move_to(act[:value])
        end
      when "selected"
        select_item(act[:value])
        #        draw_list
        #        sleep 0.2
        #        @page.selected = 0
      end
      draw_list
    end

    def selected
      @page.selected
    end

    # private...

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

    private def line_length_correction(line_num)
      temp = ""
      line = @list[line_num]
      if (line.size > @page.line_size)
        temp = (line[0..(@page.line_size - 4)] + "...")
      else
        temp = line
      end
      line_format temp
    end

    private def line_format(str)
      if @page.line_size > str.size
        str = str + (" " * (@page.line_size - str.size))
      end
      " " + str
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
      @window.refresh
    end

    private def move_to(move)
      case move
      when "next"      then move_to_next_item
      when "prev"      then move_to_previous_item
      when "next_page" then move_to_next_page
      when "prev_page" then move_to_previous_page
      when "return"    then close
      end
    end

    private def select_item(value)
      if value == "eval"
        @page.selected = @page.selection
      end
    end

    private def move_to_next_item
      @page.selection += 1
      if @page.selection > last_item
        @page.selection = 0
        @page.page_start = 0
      elsif @page.selection > @page.page_start + @page.page_size - 1
        @page.page_start += @page.page_size
      end
    end

    private def move_to_previous_item
      @page.selection -= 1
      if @page.selection < 0
        @page.selection = last_item
        @page.page_start = start_of_last_page
      elsif @page.selection < @page.page_start
        @page.page_start -= @page.page_size
      end
    end

    private def move_to_next_page
      @page.page_start += @page.page_size
      unless @page.page_start < @list.size
        @page.page_start = 0
        @page.selection %= @page.page_size
      else
        @page.selection += @page.page_size
        @page.selection = last_item if (@page.selection > last_item)
      end
    end

    private def move_to_previous_page
      @page.page_start -= @page.page_size
      if @page.page_start < 0
        @page.page_start = start_of_last_page
        @page.selection = start_of_last_page + (@page.selection %= @page.page_size)
        @page.selection = last_item if (@page.selection > last_item)
      else
        @page.selection -= @page.page_size
      end
    end

    private def start_of_last_page
      (@list.size - 1)/@page.page_size * @page.page_size
    end

    private def last_item
      @list.size - 1
    end

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

    def program
      true
    end
  end
end
