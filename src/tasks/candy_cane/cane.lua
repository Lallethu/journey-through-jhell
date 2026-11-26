local Util = require("src.core.util")

---@class Cane
---@field cfg table A reference of the conf table from src/data/candy_cane.lua
---@field w integer
---@field h integer
---@field cutRow integer First row of the wall piece (the cut line)
---@field wallX0 integer First column of the wall piece
---@field wallX1 integer End column (exclusive) of the wall piece
---@field tipX0 integer Columns of the hook's tip, which hangs below the cut line
---@field tipW integer
---@field shaftLeft number
---@field shaftRight number
---@field gapTotal number
---@field inside boolean[]    Cell is part of the cane
---@field outline boolean[]   Cell is the dark edge (never painted)
---@field paintable boolean[] Inside and not outline
---@field stripe boolean[]    Paintable cells that should be painted (kekw)
---@field inWall boolean[]    Cell stays after the cut (scored)
---@field shade boolean[]     Carker cell on the outer side of the tube (does not count in the painted cells)
---@field painted boolean[]
---@field cutDepth number     0..1
---@field cutY number         The height of the cut guide
---@field offTime number      seconds sawing off the line
---@field sawWaste number     worst blade waste used while cutting
---@field stripeTotal number  number of stripe as in the data
---@field onPaint? fun(x: integer, y: integer, shade: boolean)
local Cane = {}
Cane.__index = Cane

---@param cfg table config from src/data/candy_cane.lua
---@param stripeCount integer stripes along the wall piece
---@return Cane
function Cane.new(cfg, stripeCount)
  assert(stripeCount >= 1, "Cane.new: stripeCount must be at least 1")
  local w, h = cfg.GRID_W, cfg.GRID_H
  local arcCenterX, arcCenterY = w / 2, cfg.ARC_CY
  local hookRaduis, half, shaftLength = cfg.HOOK_R, cfg.TUBE / 2, cfg.SHAFT_LEN
  local shaftX = arcCenterX - hookRaduis
  local bottom = arcCenterY + shaftLength
  assert(bottom <= h, "Cane.new: GRID_H is too small for the shaft")

  local sweep = math.rad(cfg.HOOK_SWEEP)
  local tipTheta = math.pi - sweep -- where the hook ends (y up)
  local tipX, tipY = arcCenterX + hookRaduis * math.cos(tipTheta),
      arcCenterY - hookRaduis * math.sin(tipTheta)

  local cutRow = math.floor(arcCenterY + cfg.CUT_BELOW + 0.5)
  local wallCols = math.floor(shaftX + half + 0.5)

  -- For a point: is it on the cane, how far along the cane (from the bottom
  -- of the shaft, up and around the hook), and how far to the outer side.
  local function sample(px, py)
    if py >= arcCenterY and py <= bottom and math.abs(px - shaftX) <= half then
      return true, bottom - py, shaftX - px
    end

    local dx, dy = px - arcCenterX, py - arcCenterY
    local targetFallingRadius = math.sqrt(dx * dx + dy * dy)

    if math.abs(targetFallingRadius - hookRaduis) <= half then
      local phi = (math.pi - math.atan2(-dy, dx)) % (2 * math.pi)
      if phi <= sweep then
        return true,
            shaftLength + phi * hookRaduis,
            targetFallingRadius - hookRaduis
      end
    end

    local ex, ey = px - tipX, py - tipY
    if ex * ex + ey * ey <= half * half then return true, shaftLength + sweep * hookRaduis, 0 end
    return false
  end

  local inside, along, side = {}, {}, {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local i = y * w + x + 1
      local px = x + 0.5

      if cfg.MIRROR then px = w - px end
      local ok, s, t = sample(px, y + 0.5)
      inside[i] = ok
      along[i], side[i] = s, t
    end
  end

  local function isInside(x, y)
    return x >= 0 and y >= 0 and x < w and y < h and inside[y * w + x + 1]
  end

  local self = setmetatable({
    cfg = cfg,
    w = w,
    h = h,
    cutRow = cutRow,
    cutY = cutRow,
    wallX0 = cfg.MIRROR and (w - wallCols) or 0,
    wallX1 = cfg.MIRROR and w or wallCols,
    tipX0 = cfg.MIRROR and 0 or wallCols,
    tipW = w - wallCols,
    shaftLeft = cfg.MIRROR and (w - (shaftX + half)) or (shaftX - half),
    shaftRight = cfg.MIRROR and (w - (shaftX - half)) or (shaftX + half),
    inside = inside,
    outline = {},
    paintable = {},
    stripe = {},
    inWall = {},
    shade = {},
    painted = {},
    stripeTotal = 0,
    gapTotal = 0,
    paintedStripe = 0,
    paintedSpill = 0,
    cutDepth = 0,
    offTime = 0,
    sawWaste = 0,
  }, Cane)

  -- frequency as distance for the stripes
  local period = (bottom - cutRow) / stripeCount
  local fill, slant = cfg.STRIPE.fill, cfg.STRIPE.slant
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local i = y * w + x + 1
      if inside[i] then
        local edge = not (isInside(x - 1, y) and isInside(x + 1, y)
          and isInside(x, y - 1) and isInside(x, y + 1))
        self.outline[i] = edge
        self.paintable[i] = not edge
        if not edge then
          self.stripe[i] = ((along[i] + slant * side[i]) % period) < period * fill
          self.shade[i] = side[i] > half - 4
        end
        local ux = cfg.MIRROR and (w - 1 - x) or x
        if y >= cutRow and ux < wallCols then
          self.inWall[i] = true
          if not edge then
            if self.stripe[i] then
              self.stripeTotal = self.stripeTotal + 1
            else
              self.gapTotal = self.gapTotal + 1
            end
          end
        end
      end
    end
  end
  assert(self.stripeTotal > 0 and self.gapTotal > 0,
    "Cane.new: no stripes or no gaps; check STRIPE in src/data/candy_cane.lua")
  return self
end

---Paints a disc
---
---Returns how many cells changed
---@param cx number grid coordinates
---@param cy number
---@param r number
---@return integer
function Cane:stamp(cx, cy, r)
  local w, h = self.w, self.h
  local x0, x1 = math.max(0, math.floor(cx - r)), math.min(w - 1, math.ceil(cx + r))
  local y0, y1 = math.max(0, math.floor(cy - r)), math.min(h - 1, math.ceil(cy + r))
  local r2, changed = r * r, 0
  for y = y0, y1 do
    for x = x0, x1 do
      local i = y * w + x + 1
      if self.paintable[i] and not self.painted[i] then
        local dx, dy = x + 0.5 - cx, y + 0.5 - cy
        if dx * dx + dy * dy <= r2 then
          self.painted[i] = true
          changed = changed + 1
          if self.inWall[i] then
            if self.stripe[i] then
              self.paintedStripe = self.paintedStripe + 1
            else
              self.paintedSpill = self.paintedSpill + 1
            end
          end
          if self.onPaint then self.onPaint(x, y, self.shade[i]) end
        end
      end
    end
  end
  return changed
end

---Paints a stroke without gaps, even when the mouse moves fast
---@return integer
function Cane:stampLine(x0, y0, x1, y1, r)
  local dx, dy = x1 - x0, y1 - y0
  local dist = math.sqrt(dx * dx + dy * dy)
  local steps = math.max(1, math.ceil(dist / math.max(1, r * 0.5)))
  local changed = 0
  for s = 0, steps do
    local t = s / steps
    changed = changed + self:stamp(x0 + dx * t, y0 + dy * t, r)
  end
  return changed
end

---One frame of sawing. The depth grows with sideways travel on the line,
---so the player saws back and forth
---@param mx number cursor, grid coordinates
---@param my number
---@param prevX number cursor x of the previous frame
---@param saw table one entry of cfg.SAWS
---@param dt number
---@return "on"|"off"|"none"
function Cane:saw(mx, my, prevX, saw, dt)
  local cfg = self.cfg
  local dy = math.abs(my - self.cutY)
  if mx < self.shaftLeft - cfg.SAW_SLACK or mx > self.shaftRight + cfg.SAW_SLACK
      or dy > cfg.OFF_RANGE then
    return "none" -- not trying to cut here
  end
  local travel = math.abs(mx - prevX)
  if dy <= saw.r then
    if travel > 0 then
      self.cutDepth = math.min(1, self.cutDepth + travel * saw.rate)
      if saw.waste > self.sawWaste then self.sawWaste = saw.waste end
    end
    return "on"
  end
  if travel > 0 then self.offTime = self.offTime + dt end
  return "off"
end

---@return number 0..1 part of the stripes that is painted
function Cane:coverage() return self.paintedStripe / self.stripeTotal end

---@return number 0..1 part of the gaps that is painted (as a mistake)
function Cane:spill() return self.paintedSpill / self.gapTotal end

---@return boolean
function Cane:isDone()
  return self:coverage() >= self.cfg.TARGET and self.cutDepth >= 1
end

---1 = perfect. Painting the gaps, sawing off the line and wide blades cost points
---@return number
function Cane:quality()
  local cfg = self.cfg
  local paintScore = Util.clamp(self:coverage() - self:spill() * cfg.SPILL_WEIGHT, 0, 1)
  local cutScore = Util.clamp(1 - self.offTime / cfg.OFFLINE_LIMIT - self.sawWaste, 0, 1)
  return Util.clamp(cfg.WEIGHTS.paint * paintScore + cfg.WEIGHTS.cut * cutScore, 0, 1)
end

return Cane
