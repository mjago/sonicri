module PodPicr
  enum UserState
    Init
    ListAge
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
    ListAged
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
    {st: S::EpisodeInit, res: A::EpisodeInitCancelled, to: S::ShowResume},
    {st: S::EpisodeSelect, res: A::EpisodeSelected, to: S::EpisodePlay},
    {st: S::EpisodeSelect, res: A::Back, to: S::ShowResume},
    {st: S::EpisodePlay, res: A::Back, to: S::EpisodeSelect},
    {st: S::Exit, res: A::Exit, to: S::Exit},
  ]
end
