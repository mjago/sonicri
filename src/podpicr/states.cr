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
    Inited
    ListAged
    ListParsed
    StationInited
    Back
    StationSeld
    TitleInited
    TitleSeld
    ProgramInited
    ProgramSeld
    Exit
  end
end
