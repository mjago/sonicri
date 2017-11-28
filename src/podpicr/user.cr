module PodPicr
  class User
    alias S = UserState
    alias A = UserAction

    @user_state : Array({st: S, res: A, to: S})
    @states : Array({st: S, fn: Proc(A)})

    def initialize
      @user_state = [
        {st: S::Init, res: A::Init, to: S::ListAge},
        {st: S::ListAge, res: A::ListAged, to: S::ListParse},
        {st: S::ListParse, res: A::ListParsed, to: S::StationInit},
        {st: S::StationInit, res: A::StationInit, to: S::StationSelect},
        {st: S::StationResume, res: A::StationResumed, to: S::StationSelect},
        {st: S::StationSelect, res: A::StationSelected, to: S::ShowInit},
        {st: S::StationSelect, res: A::Exit, to: S::Exit},
        {st: S::ShowInit, res: A::ShowInit, to: S::ShowSelect},
        {st: S::ShowResume, res: A::ShowResumed, to: S::ShowSelect},
        {st: S::ShowSelect, res: A::ShowSelected, to: S::EpisodeInit},
        {st: S::ShowSelect, res: A::Back, to: S::StationResume},
        {st: S::EpisodeInit, res: A::EpisodeInit, to: S::EpisodeSelect},
        {st: S::EpisodeSelect, res: A::EpisodeSelected, to: S::EpisodePlay},
        {st: S::EpisodeSelect, res: A::Back, to: S::ShowResume},
        {st: S::EpisodePlay, res: A::Back, to: S::EpisodeSelect},
        {st: S::Exit, res: A::Exit, to: S::Exit},
      ]

      @states = [
        {st: S::Init, fn: ->init_state},
        {st: S::ListAge, fn: ->list_age_state},
        {st: S::ListParse, fn: ->list_parse_state},
        {st: S::StationInit, fn: ->station_init_state},
        {st: S::StationResume, fn: ->station_resume_state},
        {st: S::StationSelect, fn: ->station_select_state},
        {st: S::ShowInit, fn: ->show_init_state},
        {st: S::ShowResume, fn: ->show_resume_state},
        {st: S::ShowSelect, fn: ->show_select_state},
        {st: S::EpisodeInit, fn: ->episode_init_state},
        {st: S::EpisodeSelect, fn: ->episode_select_state},
        {st: S::EpisodePlay, fn: ->episode_play_state},
        {st: S::Exit, fn: ->exit_state},
      ]

      @state = State.new @user_state
      @list = List.new
      @show = ""
      @xml_url = ""
      @ui = UI.new
      @audio = Audio.new
      @audio.win = @ui.display.window
    end

    def run
      loop do
        process_state
        do_events()
      end
    end

    # private

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
      @ui.init_list({type: "episodes", value: @xml_url})
      A::EpisodeInit
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
      length = @ui.episode_info[:length]
      @audio.run url, length
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
