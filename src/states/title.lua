local Events = require("src.core.events")
local Screen = require("src.core.screen")
local Util = require("src.core.util")

local palettes = require("src.data.palettes")
local titlescreendata = require("src.data.title_screen")

local logo = love.graphics.newImage(titlescreendata.LOGO_PATH)
logo:setFilter("nearest", "nearest")
local cover = love.graphics.newImage(titlescreendata.COVER_PATH)
cover:setFilter("nearest", "nearest")

local LOGO_WIDTH = logo:getWidth()
local font

local IGNORED_KEYS = {}
for _, k in ipairs({ "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
  "lgui", "rgui", "capslock", "numlock", "escape" }) do
  IGNORED_KEYS[k] = true
end
for i = 1, 12 do IGNORED_KEYS["f" .. i] = true end

---@type State
local TitleScreenState = {}

function TitleScreenState:enter()
  font = font or love.graphics.newFont("assets/fonts/cute-dino.ttf", 14, "mono")

  self.t = 0
  self.leaving = nil
  Events.emit("phase_changed", "title")
end

function TitleScreenState:update(dt)
  self.t = self.t + dt
  if self.leaving then
    self.leaving = self.leaving + dt
    if self.leaving >= titlescreendata.LEAVE then self.machine:switch("day") end
  end
end

function TitleScreenState:start()
  if self.leaving or self.t < titlescreendata.INPUT_DELAY then return end
  self.leaving = 0
end

function TitleScreenState:keypressed(k)
  if not IGNORED_KEYS[k] then self:start() end
end

function TitleScreenState:mousepressed(_, _, button)
  if button == 1 then self:start() end
end

function TitleScreenState:draw()
  Screen.fill(palettes.NIGHT)

  local p = Util.easeOutCubic(Util.clamp(self.t / titlescreendata.INTRO, 0, 1))
  local float = math.sin(self.t * 2 * math.pi / titlescreendata.LOGO_PERIOD) *
      titlescreendata.LOGO_FLOAT
  love.graphics.setColor(1, 1, 1, p)
  love.graphics.draw(cover, 0, -90, 0, 0.8, 0.8)
  love.graphics.draw(logo, math.floor((Screen.width - LOGO_WIDTH) / 2),
    math.floor(titlescreendata.LOGO_Y - (1 - p) * 16 + float))

  local t = self.t - titlescreendata.PROMPT_DELAY
  local a = Util.clamp(t / titlescreendata.PROMPT_FADE, 0, 1)
  if a > 0 then
    local wave = math.sin(t * 2 * math.pi / titlescreendata.PROMPT_PERIOD) -- -1..1
    local y = math.floor(titlescreendata.PROMPT_Y + wave * titlescreendata.PROMPT_BOB)
    local alpha = a * (0.75 + 0.25 * wave)
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0, alpha * 0.8)
    love.graphics.printf(titlescreendata.PROMPT_TEXT, 1, y + 1, Screen.width, "center") -- shadow
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(titlescreendata.PROMPT_TEXT, 0, y, Screen.width, "center")
  end

  if self.leaving then
    love.graphics.setColor(0, 0, 0, Util.clamp(self.leaving / titlescreendata.LEAVE, 0, 1))
    love.graphics.rectangle("fill", 0, 0, Screen.width, Screen.height)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return TitleScreenState
