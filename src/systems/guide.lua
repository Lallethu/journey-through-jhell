local Events                       = require("src.core.events")
local Fonts                        = require("src.core.fonts")
local Input                        = require("src.core.input")
local Screen                       = require("src.core.screen")
local Util                         = require("src.core.util")
local guidedata                    = require("src.data.guide")

local PAD_X, PAD_Y                 = 6, 4

---@class Guide
local Guide                        = {}
Guide.seen                         = false

---@type World
local world
local pointNpc ---@type Interactable?
local font
local running, index, stepAge, bob = false, 1, 0, 0
local startX, startY               = 0, 0
local text, box                    = "", { w = 0, h = 0 }
local duskShown, duskTimer         = false, 0

local function format(str)
  return (str:gsub("{([%w_]+)}", function(action)
    return action == "move" and Input.moveLabel() or Input.label(action)
  end))
end

local function setText(str)
  text = format(str)
  local widest, wrapped = font:getWrap(text, guidedata.BOX_W - PAD_X * 2)
  box.w = math.min(guidedata.BOX_W, widest + PAD_X * 2 + 1)
  box.h = #wrapped * font:getHeight() + PAD_Y * 1.25
  stepAge = 0
end

local function finish()
  running = false
  Guide.seen = true
end

local function findNpc(taskId)
  local list = world.entities
  for i = 1, #list do
    local e = list[i] --[[@as Interactable]]
    e:refresh()
    if e.kind == "interactable" and e.taskId == taskId then return e end
  end
end

local function goTo(i, overrideText)
  index = i
  local step = guidedata.STEPS[i]
  if not step then return finish() end
  pointNpc = step.point and findNpc(step.point) or nil
  setText(overrideText or step.text)
end

local function stepIndex(id)
  for i, s in ipairs(guidedata.STEPS) do
    if s.id == id then return i end
  end
end

local function onEvent(name)
  if not running then return end
  local step = guidedata.STEPS[index]
  if not step then return end
  if step.wait == name then
    goTo(index + 1)
  elseif step.onFail and (name == "task_failed" or name == "task_cancelled") then
    goTo(assert(stepIndex(step.onFail), step.onFail),
      assert(step.failText, "step '" .. step.id .. "' needs failText"))
  end
end

---Call once per run, after Screen.init.
---@param ctx { world: World }
function Guide.init(ctx)
  world = ctx.world
  font = font or Fonts.get(14)
  running = false
  Events.off_owner(Guide)
  for _, name in ipairs({ "task_started", "task_done", "task_failed", "task_cancelled" }) do
    Events.on(
      name --[[@as GameEvent]],
      function() onEvent(name) end, Guide)
  end
end

function Guide.start()
  if Guide.seen then return end
  running, duskShown, bob = true, false, 0
  startX, startY = world.player.x, world.player.y
  goTo(1)
end

function Guide.stop()
  if running then finish() end
end

---True while a step wants the day timer to wait.
---@return boolean
function Guide.holdsTimer()
  if not running then return false end
  local step = guidedata.STEPS[index]
  return step ~= nil and step.hold == true
end

---@param dt number
---@param timeLeft number
function Guide.update(dt, timeLeft)
  if not running then return end
  stepAge, bob = stepAge + dt, bob + dt

  local step, p = guidedata.STEPS[index], world.player
  if step and step.wait == "moved" and p then
    local dx, dy = p.x - startX, p.y - startY
    if dx * dx + dy * dy > guidedata.MOVE_DISTANCE ^ 2 then goTo(index + 1) end
  end

  if not duskShown and timeLeft <= guidedata.DUSK_TIP_AT then
    duskShown, duskTimer = true, 0
    index = #guidedata.STEPS + 1
    pointNpc = nil
    setText(guidedata.DUSK_TIP)
  end
  if duskShown then
    duskTimer = duskTimer + dt
    if duskTimer >= guidedata.DUSK_TIP_TIME then finish() end
  end
end

function Guide.draw()
  if not running then return end
  local npc = pointNpc
  local a = Util.clamp(stepAge / guidedata.FADE_IN, 0, 1)
  local x = math.floor((Screen.width - box.w) / 2)

  love.graphics.push("all")
  love.graphics.setFont(font)
  love.graphics.setColor(0, 0, 0, 0.6 * a)
  love.graphics.rectangle("fill", x, guidedata.BOX_Y, box.w, box.h, 3, 3)
  love.graphics.setColor(1, 1, 1, a)
  love.graphics.printf(text, x + PAD_X, guidedata.BOX_Y + PAD_Y, box.w - PAD_X * 2, "center")

  local step = guidedata.STEPS[index]
  local npc = step and step.point and npc
  if npc then
    local nx, ay = math.floor(npc.x), math.floor(npc.y - 22 + math.sin(bob * 6) * 2)
    love.graphics.setColor(0, 0, 0, a * 0.8)
    love.graphics.polygon("fill", nx - 4, ay + 1, nx + 4, ay + 1, nx, ay + 6)
    love.graphics.setColor(1, 0.9, 0.3, a)
    love.graphics.polygon("fill", nx - 3, ay, nx + 3, ay, nx, ay + 4)
  end
  love.graphics.pop()
end

return Guide
