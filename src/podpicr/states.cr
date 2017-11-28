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
    EpisodeSelected
    Exit
  end
end
