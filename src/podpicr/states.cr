module PodPicr
  enum UserState
    Init
    Categories
    MusicInit
    MusicSelect
    RadioInit
    RadioSelect
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
  end

  alias S = UserState
  alias A = UserAction

  UserStates = [
    {st: S::Init, res: A::Init, to: S::Categories},
    {st: S::Categories, res: A::PodcastSelected, to: S::StationInit},
    {st: S::Categories, res: A::MusicSelected, to: S::MusicInit},
    {st: S::Categories, res: A::RadioSelected, to: S::RadioInit},
    {st: S::Categories, res: A::Exit, to: S::Exit},
    {st: S::RadioInit, res: A::Init, to: S::RadioSelect},
    {st: S::RadioSelect, res: A::RadioSelected, to: S::Init},
    {st: S::RadioSelect, res: A::Back, to: S::Init},
    {st: S::StationInit, res: A::Init, to: S::StationSelect},
    {st: S::MusicInit, res: A::Init, to: S::MusicSelect},
    {st: S::MusicSelect, res: A::MusicSelected, to: S::Exit},
    {st: S::MusicSelect, res: A::Back, to: S::Init},
    {st: S::StationResume, res: A::StationResumed, to: S::StationSelect},
    {st: S::StationSelect, res: A::StationSelected, to: S::ShowInit},
    {st: S::StationSelect, res: A::Back, to: S::Init},
    {st: S::ShowInit, res: A::Init, to: S::ShowSelect},
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
