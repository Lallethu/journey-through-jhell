local guidedata = {
  INTRO_LINE = "The village is quiet... For now.",
  BOX_W = 210,
  BOX_Y = 42,
  FADE_IN = 0.25,
  MOVE_DISTANCE = 40,
  DUSK_TIP_AT = 20,
  DUSK_TIP_TIME = 12,
  DUSK_TIP =
  "Dusk is near. Press {end_day} to skip the rest of the day. At night {attack} swing, {heal} heal, {place_wall} wall.",

  STEPS = {
    { id = "move",   text = "Walk around with {move}",                                                               wait = "moved",        hold = true },
    { id = "gather", text = "Visit the Sugar daddy Pep Hermint and press {interact}.",                               wait = "task_started", hold = true, point = "gatherer" },
    { id = "click",  text = "Click the circles before they close in!",                                               wait = "task_done",    hold = true, onFail = "gather", failText = "Try again (if you're on touch pad... Gouud luck.)" },
    { id = "wall",   text = "Go see Wallther the baker, he'll make you paint and saw your walls, press {interact}.", wait = "task_done",    hold = true, point = "wall" },
    { id = "spend",  text = "Sugar buys healing and walls. Spend it now, or save it for later nights!",              wait = "task_done" },
  }
}

return guidedata
