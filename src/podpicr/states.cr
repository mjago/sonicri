module PodPicr
  enum UserState
    Init
    ListAge
    ListParse
    StationInit
    StationMon
    TitleInit
    TitleMon
    ProgramInit
    ProgramMon
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
    StationSeld
    TitleInit
    TitleSeld
    ProgramInit
    ProgramSeld
    Exit
  end
end
