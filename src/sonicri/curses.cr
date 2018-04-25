module NCurses
  def attempt_remove_cursor
    LibNCurses.curs_set(0)
  end
end
