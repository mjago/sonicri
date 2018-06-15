module Sonicri
  enum UserState
    Init
    CategoryInit
    Category
    PodcastInit
    Podcast
    PodcastResume
    MusicInit
    Music
    RadioInit
    Radio
    #   StationInit
    #   StationResume
    #   Station
    #   ShowInit
    #   ShowResume
    #   Show
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
    CategorySelected
    PodcastSelected
    MusicSelected
    RadioSelected
    #   StationResumed
    #   StationSelected
    #   ShowResumed
    #   ShowSelected
    Resumed
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
    {st: S::Category, res: A::PodcastSelected, to: S::PodcastInit},
    {st: S::Category, res: A::MusicSelected, to: S::MusicInit},
    {st: S::Category, res: A::RadioSelected, to: S::RadioInit},
    {st: S::Category, res: A::Help, to: S::HelpInit},
    {st: S::Category, res: A::Exit, to: S::Exit},
    {st: S::PodcastInit, res: A::Init, to: S::Podcast},
    {st: S::Podcast, res: A::PodcastSelected, to: S::EpisodeInit},
    {st: S::Podcast, res: A::Back, to: S::CategoryInit},
    {st: S::Podcast, res: A::Exit, to: S::Exit},
    {st: S::PodcastResume, res: A::Resumed, to: S::Podcast},
    {st: S::EpisodeInit, res: A::Init, to: S::Episode},
    {st: S::EpisodeInit, res: A::EpisodeInitCancelled, to: S::PodcastResume},
    {st: S::Episode, res: A::Back, to: S::PodcastResume},
    {st: S::Episode, res: A::EpisodeSelected, to: S::EpisodePlay},
    {st: S::Episode, res: A::Exit, to: S::Exit},
    {st: S::EpisodePlay, res: A::Back, to: S::Episode},
    {st: S::RadioInit, res: A::Init, to: S::Radio},
    {st: S::Radio, res: A::RadioSelected, to: S::Init},
    {st: S::Radio, res: A::Back, to: S::CategoryInit},
    {st: S::Radio, res: A::Exit, to: S::Exit},
    {st: S::MusicInit, res: A::Init, to: S::Music},
    {st: S::Music, res: A::MusicSelected, to: S::Exit},
    {st: S::Music, res: A::Back, to: S::CategoryInit},
    {st: S::Music, res: A::Exit, to: S::Exit},
    {st: S::Exit, res: A::Exit, to: S::Exit},
    {st: S::HelpInit, res: A::Init, to: S::Help},
    {st: S::Help, res: A::Back, to: S::Init},
  ]
end
