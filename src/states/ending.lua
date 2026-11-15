---@type Animator
local Animator            = require("src.core.animator")
---@type Events
local Events              = require("src.core.events")
---@type FX
local FX                  = require("src.systems.fx")
---@type Screen
local Screen              = require("src.core.screen")

local wavesdata           = require("src.data.waves")

local INPUT_DELAY         = 0.8
local EASTER_EGG_COOLDOWN = 0.56
local DIM                 = { 0, 0, 0, 0.8 }

local titleFont, bodyFont
local jhellysixseven      = {
  x        = Screen.width / 2 - 8,
  y        = Screen.height / 2 - 80,
  cooldown = 0,
}
--math.floor(self.hitTimer / interval) % 2 == 1

---@type State
local EndingState         = {}

---@param won boolean?
function EndingState:enter(won)
  titleFont = titleFont or love.graphics.newFont("assets/fonts/cute-dino.ttf", 22, "mono")
  bodyFont  = bodyFont or love.graphics.newFont("assets/fonts/cute-dino.ttf", 14, "mono")

  self.won  = won
  if not won and self.world.night == 6 then
    local sheet         = Animator.newSheet(require("src.data.jelly_anim"))
    jhellysixseven.anim = Animator.new(sheet) --[[@as Animator]]
    jhellysixseven.anim:play("sixseven")
  end
  self.timeLeft = 0
end

function EndingState:update(dt)
  self.timeLeft = self.timeLeft + dt
  if jhellysixseven.anim then
    jhellysixseven.cooldown = math.min(jhellysixseven.cooldown + dt, EASTER_EGG_COOLDOWN)
    jhellysixseven.anim:update(dt)
    FX.update(dt)
  end
end

function EndingState:draw()
  self.world:draw()
  Screen.fill(DIM)

  love.graphics.push("all")
  local centerX = Screen.width / 2
  local centerY = Screen.height / 2

  if jhellysixseven.anim then
    if jhellysixseven.anim.done then jhellysixseven.anim:play("sixseven") end
    jhellysixseven.anim:draw(centerX - 8, centerY - 80, false, 2, 2)
    FX.draw()
  end

  love.graphics.setFont(titleFont)
  love.graphics.printf(self.won and "Dawn breaks" or "Consumed to the last drop...", 0, centerY - 40,
    Screen.width, "center")
  love.graphics.setFont(bodyFont)
  love.graphics.printf(string.format("Night %d of %d", self.world.night, #wavesdata.NIGHTS), 0,
    centerY - 6, Screen.width, "center")

  love.graphics.printf("Thanks for playing, enjoy the rest of the jam :)", 0,
    centerY + 80, Screen.width, "center")

  if self.timeLeft > INPUT_DELAY then
    love.graphics.printf("Press Enter to play again", 0, centerY + 24, Screen.width, "center")
  end

  love.graphics.pop()
end

function EndingState:onAction(action)
  if action == "end_day" and self.timeLeft > INPUT_DELAY then
    Events.emit("restart_requested")
  end

  if jhellysixseven.anim and action == "attack" then
    if jhellysixseven.cooldown == EASTER_EGG_COOLDOWN then
      jhellysixseven.cooldown = 0
      jhellysixseven.anim:play("hurt")
      Events.emit("jelly_hit_sixseven")
      Events.emit("entity_hurt", jhellysixseven, math.floor(self.timeLeft / 5) % 2 == 1 and 67 or 69)
    end
  end
end

return EndingState
