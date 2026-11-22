local controldata = {
  Y_FROM_BOTTOM = 4,
  GAP = 12,
  FADE_START = 5,
  FADE_TIME = 2,
  ALPHA_HIGH = 0.85,
  ALPHA_LOW = 0.46,
  ROWS = {
    day = {
      { "move", "move" }, { "interact", "interact" }, { "end_day", "end day" }
    },
    task = {
      { "click", "click the circles" }, { "cancel", "cancel" }
    },
    night = {
      { "attack", "swing" }, { "heal", "heal", "heal" }, { "place_wall", "wall", "wall" }
    }
  }
}

return controldata
