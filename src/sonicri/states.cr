module Sonicri
  enum UserState
    Init
    CategoryInit
    Category
    MusicInit
    Music
    RadioInit
    Radio
    StationInit
    StationResume
    Station
    ShowInit
    ShowResume
    Show
    EpisodeInit
    Episode
    EpisodePlay
    Exit
    HelpInit
    Help
  end

  enum UserAction
    NoAction
    Init
    Back
    Exit
    PodcastSelected
    MusicSelected
    RadioSelected
    StationResumed
    StationSelected
    ShowResumed
    ShowSelected
    EpisodeInit
    EpisodeInitCancelled
    EpisodeSelected
    Help
  end

  alias S = UserState
  alias A = UserAction

  UserStates = [
    {st: S::Init, res: A::Init, to: S::CategoryInit},
    {st: S::CategoryInit, res: A::Init, to: S::Category},
    {st: S::Category, res: A::PodcastSelected, to: S::StationInit},
    {st: S::Category, res: A::MusicSelected, to: S::MusicInit},
    {st: S::Category, res: A::RadioSelected, to: S::RadioInit},
    {st: S::Category, res: A::Help, to: S::HelpInit},
    {st: S::Category, res: A::Exit, to: S::Exit},
    {st: S::RadioInit, res: A::Init, to: S::Radio},
    {st: S::Radio, res: A::RadioSelected, to: S::Init},
    {st: S::Radio, res: A::Back, to: S::CategoryInit},
    {st: S::Radio, res: A::Exit, to: S::Exit},
    {st: S::StationInit, res: A::Init, to: S::Station},
    {st: S::MusicInit, res: A::Init, to: S::Music},
    {st: S::Music, res: A::MusicSelected, to: S::Exit},
    {st: S::Music, res: A::Back, to: S::CategoryInit},
    {st: S::Music, res: A::Exit, to: S::Exit},
    {st: S::StationResume, res: A::StationResumed, to: S::Station},
    {st: S::Station, res: A::StationSelected, to: S::ShowInit},
    {st: S::Station, res: A::Back, to: S::CategoryInit},
    {st: S::Station, res: A::Exit, to: S::Exit},
    {st: S::ShowInit, res: A::Init, to: S::Show},
    {st: S::ShowResume, res: A::ShowResumed, to: S::Show},
    {st: S::Show, res: A::ShowSelected, to: S::EpisodeInit},
    {st: S::Show, res: A::Exit, to: S::Exit},
    {st: S::Show, res: A::Back, to: S::StationResume},
    {st: S::EpisodeInit, res: A::EpisodeInit, to: S::Episode},
    {st: S::EpisodeInit, res: A::EpisodeInitCancelled, to: S::ShowResume},
    {st: S::Episode, res: A::EpisodeSelected, to: S::EpisodePlay},
    {st: S::Episode, res: A::Back, to: S::ShowResume},
    {st: S::Episode, res: A::Exit, to: S::Exit},
    {st: S::EpisodePlay, res: A::Back, to: S::Episode},
    {st: S::Exit, res: A::Exit, to: S::Exit},
    {st: S::HelpInit, res: A::Init, to: S::Help},
    {st: S::Help, res: A::Back, to: S::Init},
  ]
end
