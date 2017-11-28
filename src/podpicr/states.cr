module PodPicr
  enum UserState
    Init
    ListAge
    ListParse
    StationInit
    StationSelect
    ShowInit
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
    Back
    StationSelected
    ShowInit
    ShowSelected
    EpisodeInit
    EpisodeSelected
    Exit
  end
end
