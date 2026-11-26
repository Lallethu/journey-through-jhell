local Fonts     = require("src.core.fonts")
local Screen    = require("src.core.screen")
local Util      = require("src.core.util")

local candydata = require("src.data.candy_cane")

local unpack    = table.unpack or unpack
local C         = candydata.COLORS
local WHITE     = { 1, 1, 1, 1 }
local GREY      = { 0.72, 0.72, 0.8, 1 }
local EDGE      = { 0.75, 0.45, 0.65, 1 }
local DIM       = { 0, 0, 0, 0.5 }

---@class CandyCaneView
local View      = {}

local font, lineH
local icons     = {}

local function ensure()
  if font then return end
  font = Fonts.get(14)
  lineH = font:getHeight()
  -- try to load them images, but for now I stick with shapes
  local paths = { paint = "assets/gfx/tool_bucket.png", saw = "assets/gfx/tool_saw.png" }
  for tool, path in pairs(paths) do
    if love.filesystem.getInfo(path) then
      local ok, img = pcall(love.graphics.newImage, path)
      if ok then
        img:setFilter("nearest", "nearest")
        icons[tool] = img
      end
    end
  end
end

---Builds the three pictures of the cane: base (cream + outline),
---guide (the dashed line or the stripes depending on the tool, shown on hover)
---and paint (starts empty, filled while playing).
---@param cane Cane
---@return table layers
function View.newLayers(cane)
  ensure()
  local w, h = cane.w, cane.h
  local base = love.image.newImageData(w, h)
  local guide = love.image.newImageData(w, h)
  local paint = love.image.newImageData(w, h)
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local i = y * w + x + 1
      if cane.outline[i] then
        base:setPixel(x, y, unpack(C.outline))
      elseif cane.inside[i] then
        base:setPixel(x, y, unpack(cane.shade[i] and C.shade or C.cream))
      end
      if cane.stripe[i] then guide:setPixel(x, y, unpack(C.guide)) end
    end
  end

  local function image(data)
    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
  end

  local layers = {
    base = image(base),
    guide = image(guide),
    paintData = paint,
    paint = image(paint),
    dirty = false,
    quads = {
      full = love.graphics.newQuad(0, 0, w, h, w, h),
      top = love.graphics.newQuad(0, 0, w, cane.cutRow, w, h),
      wall = love.graphics.newQuad(cane.wallX0, cane.cutRow, cane.wallX1 - cane.wallX0,
        h - cane.cutRow, w, h),
      tip = love.graphics.newQuad(cane.tipX0, cane.cutRow, cane.tipW, h - cane.cutRow, w, h),
    },
  }
  cane.onPaint = function(x, y, shade)
    paint:setPixel(x, y, unpack(shade and C.pinkShade or C.pink))
    layers.dirty = true
  end
  return layers
end

function View.refresh(layers)
  if layers.dirty then
    layers.paint:replacePixels(layers.paintData, 1, 1, 0, 0, false)
    layers.dirty = false
  end
end

local function text(str, x, y, color)
  color = color or WHITE
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.print(str, x + 1, y + 1)
  love.graphics.setColor(color[1], color[2], color[3], 1)
  love.graphics.print(str, x, y)
end

local function textRight(str, xRight, y, color)
  text(str, xRight - font:getWidth(str), y, color)
end

local function bar(x, y, w, ratio, color)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", x, y, w, 6)
  love.graphics.setColor(color[1], color[2], color[3], 1)
  love.graphics.rectangle("fill", x, y, math.floor(w * Util.clamp(ratio, 0, 1)), 6)
  love.graphics.setColor(EDGE[1], EDGE[2], EDGE[3], 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, 5)
end

local function percentLabel(t, key, label, pct)
  local c = t.labels[key]
  if not c or c.pct ~= pct then
    c = { pct = pct, str = label .. " " .. pct .. "%" }
    t.labels[key] = c
  end
  return c.str
end
---@TODO: In fix-polishing-touch replace the polygon shenanigans with proper images
local function drawBucket(x, y)
  love.graphics.setColor(0.65, 0.65, 0.72, 1)
  love.graphics.polygon("fill", x + 9, y + 14, x + 27, y + 14, x + 24, y + 30, x + 12, y + 30)
  love.graphics.setColor(C.pink[1], C.pink[2], C.pink[3], 1)
  love.graphics.rectangle("fill", x + 9, y + 12, 18, 4)
  love.graphics.setColor(0.4, 0.4, 0.48, 1)
  love.graphics.line(x + 10, y + 14, x + 13, y + 7, x + 23, y + 7, x + 26, y + 14)
end

---@TODO: In fix-polishing-touch replace the polygon shenanigans with proper images
local function drawSaw(x, y)
  love.graphics.setColor(0.8, 0.82, 0.88, 1)
  love.graphics.rectangle("fill", x + 11, y + 13, 21, 7)
  for i = 0, 4 do
    love.graphics.polygon("fill", x + 12 + i * 4, y + 20, x + 16 + i * 4, y + 20, x + 14 + i * 4,
      y + 25)
  end
  love.graphics.setColor(0.35, 0.25, 0.2, 1)
  love.graphics.rectangle("fill", x + 4, y + 11, 8, 11)
end

local function drawSlot(def, tool, t)
  local d = candydata
  local x, y, s = def.x, def.y, d.SLOT
  local selected, hovered = t.tool == tool, t.hover == tool

  love.graphics.setColor(0.12, 0.06, 0.18, 0.95)
  love.graphics.rectangle("fill", x, y, s, s, 4, 4)
  if selected then
    love.graphics.setColor(1, 0.5, 0.7, 1)
  elseif hovered then
    love.graphics.setColor(0.9, 0.8, 0.95, 1)
  else
    love.graphics.setColor(0.5, 0.35, 0.6, 1)
  end
  love.graphics.rectangle("line", x + 0.5, y + 0.5, s - 1, s - 1, 4, 4)

  love.graphics.setColor(1, 1, 1, 1)

  ---@TODO: In fix-polishing-touch replace this if block with the marked line
  if icons[tool] then
    love.graphics.draw(icons[tool], x + 2, y + 2) ---@MarkedLine
  elseif tool == "paint" then
    drawBucket(x, y)
  else
    drawSaw(x, y)
  end

  local count = tool == "paint" and #d.BRUSHES or #d.SAWS
  local index = tool == "paint" and t.brushIndex or t.sawIndex
  for i = 1, count do
    love.graphics.setColor(1, 1, 1, i == index and 1 or 0.3)
    love.graphics.circle("fill", x + s / 2 + (i - (count + 1) / 2) * 8, y + s + 5, 2)
  end
end

local function drawLayers(t, quad, x, y)
  local L = t.layers
  love.graphics.draw(L.base, quad, x, y)
  if t.showGuide then love.graphics.draw(L.guide, quad, x, y) end
  love.graphics.draw(L.paint, quad, x, y)
end

---@param t CandyCaneTask
function View.draw(t)
  ensure()
  Screen.fill(DIM)

  local d, cane, P = candydata, t.cane, candydata.PANEL
  local ox, oy = t.ox, t.oy
  love.graphics.push("all")
  love.graphics.setFont(font)

  -- draw the panel and them outlines
  love.graphics.setColor(0.05, 0.03, 0.1, 0.94)
  love.graphics.rectangle("fill", P.x, P.y, P.w, P.h, 6, 6)
  love.graphics.setColor(EDGE[1], EDGE[2], EDGE[3], 1)
  love.graphics.rectangle("line", P.x + 0.5, P.y + 0.5, P.w - 1, P.h - 1, 6, 6)
  local plateW, plateY = font:getWidth(t.title) + 10, P.y - math.floor(lineH / 2)
  love.graphics.setColor(0.18, 0.09, 0.24, 1)
  love.graphics.rectangle("fill", P.x + 12, plateY, plateW, lineH + 2, 3, 3)
  love.graphics.setColor(EDGE[1], EDGE[2], EDGE[3], 1)
  love.graphics.rectangle("line", P.x + 12.5, plateY + 0.5, plateW - 1, lineH + 1, 3, 3)
  text(t.title, P.x + 17, plateY + 2)

  drawSlot(d.PAINT_SLOT, "paint", t)
  drawSlot(d.SAW_SLOT, "saw", t)
  text("Candy paint", d.PAINT_SLOT.x + d.SLOT + 6, d.PAINT_SLOT.y)
  text(t.paintLine, d.PAINT_SLOT.x + d.SLOT + 6, d.PAINT_SLOT.y + lineH, GREY)
  textRight(t.sawLine, d.SAW_SLOT.x - 6, d.SAW_SLOT.y)
  textRight("along the line", d.SAW_SLOT.x - 6, d.SAW_SLOT.y + lineH, GREY)

  local working = t.phase == "working"
  local q = t.layers.quads
  if working then
    drawLayers(t, q.full, ox, oy)

    local y = oy + cane.cutRow
    local band = math.floor(cane.cutDepth * 4)
    if band > 0 then
      love.graphics.setColor(C.outline[1], C.outline[2], C.outline[3], 1)
      love.graphics.rectangle("fill", ox + cane.shaftLeft, y - math.floor(band / 2),
        cane.shaftRight - cane.shaftLeft, band)
    end
    if t.showCutGuide then
      love.graphics.setColor(1, 1, 1, 0.9)
      for x = ox + cane.shaftLeft - 6, ox + cane.shaftRight + 6, 7 do
        love.graphics.rectangle("fill", math.floor(x), y, 4, 1)
      end
      local sx = math.floor(ox + cane.shaftRight + 12)
      love.graphics.line(sx, y - 3, sx + 2, y, sx + 4, y - 3, sx + 6, y, sx + 8, y - 3)
    end
  else
    drawLayers(t, q.wall, ox + cane.wallX0, oy + cane.cutRow)
    local k = Util.clamp(t.doneT / d.DONE_TIME, 0, 1)
    local px, py = ox + cane.w / 2, oy + cane.cutRow - 20
    love.graphics.push()
    -- put the hook falling in a push pop block because of the translates
    love.graphics.translate(px + (d.MIRROR and -1 or 1) * k * 18, py + k * k * d.FALL_PX)
    love.graphics.rotate((d.MIRROR and -1 or 1) * k * 0.7)
    love.graphics.translate(-px, -py)
    love.graphics.setColor(1, 1, 1, 1 - k * k)
    drawLayers(t, q.top, ox, oy)
    drawLayers(t, q.tip, ox + cane.tipX0, oy + cane.cutRow)
    love.graphics.pop()
  end

  -- draw the progress bars as well as the caption
  local by = P.y + P.h - 14
  local lx, rx = P.x + 16, P.x + P.w - 16 - d.BAR_W
  local paintPct = math.floor(math.min(1, cane:coverage() / d.TARGET) * 100)
  text(percentLabel(t, "paint", "Paint", paintPct), lx, by - lineH - 1)
  bar(lx, by, d.BAR_W, paintPct / 100, C.pink)
  text(percentLabel(t, "cut", "Cut", math.floor(cane.cutDepth * 100)), rx, by - lineH - 1)
  bar(rx, by, d.BAR_W, cane.cutDepth, { 0.75, 0.78, 0.9 })
  local cw = font:getWidth(t.caption)
  text(t.caption, math.floor((Screen.width - cw) / 2), P.y + P.h - lineH - 6)

  -- handle the fake cursor style when the task is on
  if working then
    local mx, my = math.floor(t.mx), math.floor(t.my)
    if t.hover then
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle("fill", mx, my, 1.5)
    elseif t.tool == "paint" then
      love.graphics.setColor(C.pink[1], C.pink[2], C.pink[3], 0.95)
      love.graphics.circle("line", mx + 0.5, my + 0.5, t:brush().r)
    else
      -- red while sawing off of the line
      local offSawLine = t.sawState == "off"
      love.graphics.setColor(offSawLine and 1 or 0.9, offSawLine and 0.35 or 0.9,
        offSawLine and 0.35 or 0.95, 0.95)
      love.graphics.circle("line", mx + 0.5, my + 0.5, t:saw().r)
    end
  end
  love.graphics.pop()
end

return View
