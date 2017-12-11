module PodPicr
  enum UserState
    Init
    Categories
    Podcast
    Music
    Radio
    ListParse
    StationInit
    StationResume
    StationSelect
    ShowInit
    ShowResume
    ShowSelect
    EpisodeInit
    EpisodeSelect
    EpisodePlay
    Exit
  end

  enum UserAction
    NoAction
    Init
    PodcastSelected
    MusicSelected
    RadioSelected
    ListParsed
    StationInit
    StationResumed
    Back
    StationSelected
    ShowInit
    ShowResumed
    ShowSelected
    EpisodeInit
    EpisodeInitCancelled
    EpisodeSelected
    Exit
  end

  alias S = UserState
  alias A = UserAction

  UserStates = [
    {st: S::Init, res: A::Init, to: S::Categories},
    {st: S::Categories, res: A::PodcastSelected, to: S::Podcast},
    {st: S::Categories, res: A::MusicSelected, to: S::Music},
    {st: S::Categories, res: A::RadioSelected, to: S::Radio},
    {st: S::Categories, res: A::Exit, to: S::Exit},
    {st: S::Podcast, res: A::Init, to: S::ListParse},
    {st: S::Music, res: A::Init, to: S::ListParse},
    {st: S::Radio, res: A::Init, to: S::ListParse},
    {st: S::ListParse, res: A::ListParsed, to: S::StationInit},
    {st: S::StationInit, res: A::StationInit, to: S::StationSelect},
    {st: S::StationResume, res: A::StationResumed, to: S::StationSelect},
    {st: S::StationSelect, res: A::StationSelected, to: S::ShowInit},
    {st: S::StationSelect, res: A::Back, to: S::Init},
    {st: S::ShowInit, res: A::ShowInit, to: S::ShowSelect},
    {st: S::ShowResume, res: A::ShowResumed, to: S::ShowSelect},
    {st: S::ShowSelect, res: A::ShowSelected, to: S::EpisodeInit},
    {st: S::ShowSelect, res: A::Back, to: S::StationResume},
    {st: S::EpisodeInit, res: A::EpisodeInit, to: S::EpisodeSelect},
    {st: S::EpisodeInit, res: A::EpisodeInitCancelled, to: S::ShowResume},
    {st: S::EpisodeSelect, res: A::EpisodeSelected, to: S::EpisodePlay},
    {st: S::EpisodeSelect, res: A::Back, to: S::ShowResume},
    {st: S::EpisodePlay, res: A::Back, to: S::EpisodeSelect},
    {st: S::Exit, res: A::Exit, to: S::Exit},
  ]
end
