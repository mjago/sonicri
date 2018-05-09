module Sonicri
  class User
    @states : Hash(S, Proc(A))

    def initialize
      @states =
        {
          S::Init          => ->init_state,
          S::CategoryInit  => ->category_init_state,
          S::Category      => ->category_state,
          S::MusicInit     => ->music_init_state,
          S::Music         => ->music_state,
          S::RadioInit     => ->radio_init_state,
          S::Radio         => ->radio_state,
          S::StationInit   => ->station_init_state,
          S::StationResume => ->station_resume_state,
          S::Station       => ->station_state,
          S::ShowInit      => ->show_init_state,
          S::ShowResume    => ->show_resume_state,
          S::Show          => ->show_state,
          S::EpisodeInit   => ->episode_init_state,
          S::Episode       => ->episode_state,
          S::EpisodePlay   => ->episode_play_state,
          S::Exit          => ->exit_state,
          S::HelpInit      => ->help_init_state,
          S::Help          => ->help_state,
        }

      @state = State.new UserStates
      @list = List.new
      @show = ""
      @xml_url = ""
      @ui = UI.new
      @audio = Audio.new(@ui.display.progress)
      @previous_state = S::Init
    end

    def run
      loop do
        process_user_state
        do_events
      end
    end

    # private

    private def process_user_state
      if (stproc = @states[@state.state]?)
        Fiber.yield
        call_state stproc
      else
        raise "state proc is nil in User#process_user_state"
      end
    end

    private def call_state(state_proc)
      ret = state_proc.call
      unless ret.is_a? A
        raise "Error: Invalid action (#{ret}) in User#call_state!"
      end
      Fiber.yield
      action ret
    end

    private def action(act : A)
      @state.action(act)
    end

    # states

    private def init_state
      @ui.list = @list
      @list.update if @list.outdated?
      @ui.init_list({type: "categories", value: "init"})
      A::Init
    end

    private def category_init_state
      @ui.list = @list
      @list.update if @list.outdated?
      @ui.init_list({type: "categories", value: ""})
      A::Init
    end

    private def category_state
      if key = @ui.monitor("category")
        case key.action
        when "select"
          case key.value
          when "Podcasts"      ; return A::PodcastSelected
          when "Music"         ; return A::MusicSelected
          when "Radio Stations"; return A::RadioSelected
          else
            raise "Error: Invalid category! (#{key.value.inspect})"
          end
        when "back"; return A::Exit
        when "quit"; return A::Exit
        when "char"; monitor_playing key.value
        when "help"; return A::Help
        end
      end
      A::NoAction
    end

    private def music_init_state
      @ui.init_list({type: "music", value: ""})
      A::Init
    end

    private def music_state
      if key = @ui.monitor("music")
        case key.action
        when "select"
          @audio.stop if @audio.running?
          await_audio_stop
          @audio.play_music key.value
        when "back"; return A::Back
        when "char"; monitor_playing key.value
        when "quit"; return A::Exit
        end
      end
      A::NoAction
    end

    private def radio_init_state
      @ui.init_list({type: "radio", value: ""})
      A::Init
    end

    private def radio_state
      if key = @ui.monitor("radio")
        case key.action
        when "select"
          @audio.stop if @audio.running?
          await_audio_stop
          @audio.play_radio key.value
        when "back"; return A::Back
        when "char"; monitor_playing key.value
        when "quit"; return A::Exit
        end
      end
      A::NoAction
    end

    private def station_init_state
      #      @ui.list = @list
      @list.parse unless @list.parsed
      @ui.init_list({type: "stations", value: ""})
      A::Init
    end

    private def station_resume_state
      @ui.resume
      A::StationResumed
    end

    private def station_state
      if key = @ui.monitor("station")
        case key.action
        when "select"
          @show = key.value
          return A::StationSelected
        when "back"; return A::Back
        when "char"; monitor_playing key.value
        when "quit"; return A::Exit
        end
      end
      A::NoAction
    end

    private def show_init_state
      @ui.init_list({type: "shows", value: "#{@show}"})
      A::Init
    end

    private def show_resume_state
      @ui.resume
      A::ShowResumed
    end

    private def show_state
      if key = @ui.monitor("show")
        case key.action
        when "select"
          @xml_url = key.value
          return A::ShowSelected
        when "back"; return A::Back
        when "char"; monitor_playing key.value
        when "quit"; return A::Exit
        end
      end
      A::NoAction
    end

    private def episode_init_state
      if @ui.init_list({type: "episodes", value: @xml_url})
        A::EpisodeInit
      else
        A::EpisodeInitCancelled
      end
    end

    private def episode_state
      if key = @ui.monitor("episode")
        case key.action
        when "select"; return A::EpisodeSelected
        when "back"  ; return A::Back
        when "char"  ; monitor_playing key.value
        when "quit"; return A::Exit
        end
      end
      A::NoAction
    end

    private def episode_play_state
      @audio.stop if @audio.running?
      await_audio_stop
      url = @ui.episode_info[:url]
      @audio.run filename = @ui.file_friendly_name, url
      A::Back
    end

    private def exit_state
      do_exit
      A::Exit
    end

    private def help_init_state
      @ui.display_help
      A::Init
    end

    private def help_state
      if key = @ui.monitor("help")
        return A::Back
      end
      A::NoAction
    end

    private def do_events
      sleep 0.1
    end

    private def monitor_playing(value)
      if @audio.running?
        case value
        when "f"     ; @audio.jump_forward(:small)
        when "F"     ; @audio.jump_forward(:large)
        when "b"     ; @audio.jump_back(:small)
        when "B"     ; @audio.jump_back(:large)
        when "p", "P"; @audio.pause
        when "s", "S"; @audio.stop
        end
      end
    end

    private def await_audio_stop
      while @audio.running?
        sleep 0.2
      end
    end

    private def do_exit
      @ui.try { |ui| ui.close }
      puts "done"
      exit(0)
    end
  end
end
