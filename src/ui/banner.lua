local Fonts = require("src.core.fonts")
local Screen = require("src.core.screen")
local Util = require("src.core.util")

local FADE_IN, HOLD, FADE_OUT = 0.35, 1.8, 0.7
local TOTAL = FADE_IN + HOLD + FADE_OUT
local PAD, BASE_Y = 6, 82

---@class Banner
local Banner = {}
local titleFont, subFont
local title, sub, t = nil, nil, 0
local titleH, subH

function Banner.init()
  titleFont = Fonts.get(20)
  subFont = Fonts.get(14)
  titleH, subH = titleFont:getHeight(), subFont:getHeight()
end

function Banner.show(titleText, subText)
  title, sub, t = titleText, subText, 0
end

function Banner.update(dt)
  if not title then return end
  t = t + dt
  if t >= TOTAL then title = nil end
end

function Banner.draw()
  if not title then return end
  local textH = titleH + (sub and subH or 0)
  local a = 1

  if t < FADE_IN then
    a = t / FADE_IN
  elseif t > FADE_IN + HOLD then
    a = 1 - (t - FADE_IN - HOLD) / FADE_OUT
  end
  a = Util.clamp(a, 0, 1)
  local y = math.floor(BASE_Y - (1 - Util.easeOutCubic(Util.clamp(t / FADE_IN, 0, 1))) * 6)

  love.graphics.push("all")
  love.graphics.setColor(0, 0, 0, 0.45 * a)
  love.graphics.rectangle("fill", 0, y - PAD, Screen.width, textH + PAD * 2)
  love.graphics.setFont(titleFont)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.printf(title, 0, y, Screen.width, "center")
  if sub then
    love.graphics.setFont(subFont)
    love.graphics.setColor(0.85, 0.85, 0.92, a)
    love.graphics.printf(sub, 0, y + titleFont:getHeight(), Screen.width, "center")
  end
  love.graphics.pop()
end

return Banner
