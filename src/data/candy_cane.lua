local candydata = {
  PANEL         = { x = 40, y = 34, w = 400, h = 212 },
  SLOT          = 36,
  PAINT_SLOT    = { x = 56, y = 56 },
  SAW_SLOT      = { x = 388, y = 56 },
  BAR_W         = 90,

  CENTER_X      = 240,
  GRID_TOP      = 80,
  GRID_W        = 80,
  GRID_H        = 140,

  MIRROR        = true,
  TUBE          = 32,
  HOOK_R        = 20,
  HOOK_SWEEP    = 220,
  ARC_CY        = 38,
  SHAFT_LEN     = 96,
  CUT_BELOW     = 8,

  STRIPE        = { spacing = 8, fill = 0.5, slant = 0.5 },

  BRUSHES       = {
    { name = "Small",  r = 3 },
    { name = "Medium", r = 5 },
    { name = "Big",    r = 8 },
  },
  SAWS          = {
    { name = "Thin",   r = 3, rate = 0.0030, waste = 0.00 },
    { name = "Medium", r = 5, rate = 0.0050, waste = 0.06 },
    { name = "Wide",   r = 8, rate = 0.0085, waste = 0.14 },
  },
  START_BRUSH   = 2,
  START_SAW     = 2,

  TARGET        = 0.85,
  SPILL_WEIGHT  = 1.0,
  OFFLINE_LIMIT = 1.5,
  WEIGHTS       = { paint = 0.6, cut = 0.4 },
  SAW_SLACK     = 6,
  OFF_RANGE     = 14,
  DONE_TIME     = 1.15,
  FALL_PX       = 60,

  COLORS        = {
    cream     = { 0.97, 0.93, 0.85, 1 },
    shade     = { 0.86, 0.80, 0.72, 1 },
    outline   = { 0.08, 0.04, 0.18, 1 },
    pink      = { 1.00, 0.45, 0.65, 1 },
    pinkShade = { 0.85, 0.30, 0.52, 1 },
    guide     = { 1.00, 0.72, 0.82, 0.55 },
  },
}

return candydata
