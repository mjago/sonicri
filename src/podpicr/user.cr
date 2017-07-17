module PodPicr
  class User
    alias S = UserState
    alias A = UserAction

    @user_state : Array({st: S, res: A, to: S})
    @states : Array({st: S, fn: Proc(A)})

    def initialize
      @user_state = [
        {st: S::Init, res: A::Inited, to: S::ListAge},
        {st: S::ListAge, res: A::ListAged, to: S::ListParse},
        {st: S::ListParse, res: A::ListParsed, to: S::StationInit},
        {st: S::StationInit, res: A::StationInited, to: S::StationMon},
        {st: S::StationMon, res: A::StationSeld, to: S::TitleInit},
        {st: S::StationMon, res: A::Exit, to: S::Exit},
        {st: S::TitleInit, res: A::TitleInited, to: S::TitleMon},
        {st: S::TitleMon, res: A::TitleSeld, to: S::ProgramInit},
        {st: S::TitleMon, res: A::Back, to: S::StationInit},
        {st: S::ProgramInit, res: A::ProgramInited, to: S::ProgramMon},
        {st: S::ProgramMon, res: A::ProgramSeld, to: S::ProgramPlay},
        {st: S::ProgramMon, res: A::Back, to: S::TitleInit},
        {st: S::ProgramPlay, res: A::Back, to: S::ProgramInit},
        {st: S::Exit, res: A::Exit, to: S::Exit},
      ]

      @states = [
        {st: S::Init, fn: ->st_initialize},
        {st: S::ListAge, fn: ->st_list_check_age},
        {st: S::ListParse, fn: ->st_list_parse},
        {st: S::StationInit, fn: ->st_stations_init},
        {st: S::StationMon, fn: ->st_stations_monitor},
        {st: S::TitleInit, fn: ->st_titles_init},
        {st: S::TitleMon, fn: ->st_titles_monitor},
        {st: S::ProgramInit, fn: ->st_programs_init},
        {st: S::ProgramMon, fn: ->st_programs_monitor},
        {st: S::ProgramPlay, fn: ->st_play_program},
        {st: S::Exit, fn: ->st_exit},
      ]

      @state = State.new @user_state
      @list = List.new
      @rss = RSS.new
      @program_url = ""
      @length = 0_i64
      @title = ""
      @xmlUrl = ""
      @ui = UI.new
    end

    private def process_state
      check = false
      @states.each do |st|
        if st[:st] == state
          check = true
          ret = st[:fn].call
          if ret.is_a? A
            action ret
            break
          else
            raise "Error: Invalid action (#{ret}) in User#process_state!"
          end
        end
      end
      raise "Error: invalid state (#{state}) in User#process_state!" unless check
    end

    def run
      loop do
        process_state
        do_events()
      end
    end

    private def state
      @state.state
    end

    private def action(act : A)
      @state.action(act)
    end

    private def action_if(res, act : A)
      action act unless (res == false)
    end

    # states

    private def st_initialize
      A::Inited
    end

    private def st_list_check_age
      @list.update if @list.outdated?
      A::ListAged
    end

    private def st_list_parse
      @list.parse
      A::ListParsed
    end

    private def st_stations_init
      @ui.list = @list
      if ui = @ui
        ui.init_list({type: "stations", value: ""})
      else
        raise("Error: Invalid list in User#st_stations_init")
      end
      A::StationInited
    end

    private def st_stations_monitor
      if (ui = @ui)
        res = ui.stations_monitor
        if (res.is_a?({action: String, station: String}))
          case res[:action]
          when "selected"
            @title = res[:station]
            return A::StationSeld
          when "cancel"
            return A::Exit
          end
        end
      end
      A::NoAction
    end

    private def st_titles_init
      if (list = @list)
        if ui = @ui
          ui.init_list({type: "titles", value: "#{@title}"})
        else
          raise("Error: Invalid list in User#st_titles_init")
        end
      end
      A::TitleInited
    end

    private def st_titles_monitor
      if (ui = @ui)
        res = ui.titles_monitor
        if (res.is_a?({action: String, xmlUrl: String}))
          case res[:action]
          when "xml_link"
            @xmlUrl = res[:xmlUrl]
            return A::TitleSeld
          when "cancel"
            return A::Back
          end
        end
      end
      A::NoAction
    end

    private def st_programs_init
      @rss.parse(@xmlUrl)
      if (list = @list)
        @ui.list = list
        if ui = @ui
          ui.programs_init(@rss)
        end
      end
      A::ProgramInited
    end

    private def st_programs_monitor
      if (ui = @ui)
        res = ui.programs_monitor
        if (res.is_a?({action: String, value: String}))
          case res[:action]
          when "select"
            urls = @rss.results("url")
            lengths = @rss.results("length")
            idx = res[:value].to_i
            @program_url = urls[idx]
            @length = lengths[idx].to_i64
            return A::ProgramSeld
          when "cancel"
            return A::Back
          end
        end
      end
      A::NoAction
    end

    private def st_play_program
      audio = Audio.new
      keys = @ui.keys
      win = @ui.display.window
      audio.keys = keys
      audio.win = win
      audio.run @program_url, @length
      A::Back
    end

    private def st_exit
      @ui.try { |ui| ui.close }
      NCurses.end_win
      puts "done"
      exit(0)
      A::Exit
    end

    private def do_events
      sleep(0.001)
    end
  end
end
