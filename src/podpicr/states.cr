module PodPicr
  enum UserState
    Init
    ListAge
    ListParse
    StationInit
    StationSelect
    EpisodeInit
    EpisodeSelect
    ProgramInit
    ProgramSelect
    ProgramPlay
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
    EpisodeInit
    EpisodeSelected
    ProgramInit
    ProgramSelected
    Exit
  end
end
