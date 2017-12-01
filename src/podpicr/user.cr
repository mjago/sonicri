module PodPicr
  class User
    @states : Hash(S, Proc(A))

    def initialize
      @states =
        {S::Init          => ->init_state,
         S::ListAge       => ->list_age_state,
         S::ListParse     => ->list_parse_state,
         S::StationInit   => ->station_init_state,
         S::StationResume => ->station_resume_state,
         S::StationSelect => ->station_select_state,
         S::ShowInit      => ->show_init_state,
         S::ShowResume    => ->show_resume_state,
         S::ShowSelect    => ->show_select_state,
         S::EpisodeInit   => ->episode_init_state,
         S::EpisodeSelect => ->episode_select_state,
         S::EpisodePlay   => ->episode_play_state,
         S::Exit          => ->exit_state}

      @state = State.new UserStates
      @list = List.new
      @show = ""
      @xml_url = ""
      @ui = UI.new
      @audio = Audio.new
      @audio.win = @ui.display.window
    end

    def run
      #     @list.update
      #      @list.parse
      #      do_exit
      loop do
        process_user_state
        do_events()
      end
    end

    # private

    private def process_user_state
      if stproc = @states[@state.state]?
        call_state stproc
      else
        raise "state proc is nil in User#process_state"
      end
    end

    private def call_state(state_proc)
      ret = state_proc.call
      unless ret.is_a? A
        raise "Error: Invalid action (#{ret}) in User#process_state!"
      end
      action ret
    end

    private def action(act : A)
      @state.action(act)
    end

    private def action_if(res, act : A)
      action act unless (res == false)
    end

    # states

    private def init_state
      A::Init
    end

    private def list_age_state
      @list.update if @list.outdated?
      A::ListAged
    end

    private def list_parse_state
      @list.parse
      A::ListParsed
    end

    private def station_init_state
      @ui.list = @list
      @ui.init_list({type: "stations", value: ""})
      A::StationInit
    end

    private def station_resume_state
      @ui.resume
      A::StationResumed
    end

    private def station_select_state
      case station_select
      when :selected; A::StationSelected
      when :back    ; A::Exit
      else
        A::NoAction
      end
    end

    private def show_init_state
      @ui.init_list({type: "shows", value: "#{@show}"})
      A::ShowInit
    end

    private def show_resume_state
      @ui.resume
      A::ShowResumed
    end

    private def show_select_state
      case show_select
      when :selected; A::ShowSelected
      when :back    ; A::Back
      else
        A::NoAction
      end
    end

    private def episode_init_state
      if @ui.init_list({type: "episodes", value: @xml_url})
        A::EpisodeInit
      else
        A::EpisodeInitCancelled
      end
    end

    private def episode_select_state
      case episode_select
      when :selected; A::EpisodeSelected
      when :back    ; A::Back
      else
        A::NoAction
      end
    end

    private def episode_play_state
      episode_play
      A::Back
    end

    private def exit_state
      do_exit
      A::Exit
    end

    private def do_events
      sleep(0.001)
    end

    private def station_select
      res = @ui.stations_monitor
      if (res.is_a?({action: String, station: String}))
        case res[:action]
        when "select"
          @show = res[:station]
          return :selected
        when "back"
          return :back
        end
      end
      :no_action
    end

    private def show_select
      res = @ui.shows_monitor
      if (res.is_a?({action: String, xmlUrl: String}))
        case res[:action]
        when "select"
          @xml_url = res[:xmlUrl]
          return :selected
        when "back"
          return :back
        end
      end
      :no_action
    end

    private def episode_select
      res = @ui.episodes_monitor
      if (res.is_a?({action: String, value: String}))
        case res[:action]
        when "select"
          return :selected
        when "back"
          return :back
        end
      end
      :no_action
    end

    private def episode_play
      @audio.stop if @audio.running?
      await_audio_stop
      url = @ui.episode_info[:url]
      @audio.run url
    end

    private def await_audio_stop
      while @audio.running?
        sleep 0.2
      end
    end

    private def do_exit
      @ui.try { |ui| ui.close }
      NCurses.end_win
      puts "done"
      exit(0)
    end
  end
end
