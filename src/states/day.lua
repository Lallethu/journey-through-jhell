---@type Banner
local Banner     = require("src.ui.banner")
---@type Collision
local Collision  = require("src.systems.collision")
---@type Commands
local Commands   = require("src.commands.player")
---@type Events
local Events     = require("src.core.events")
---@type FX
local FX         = require("src.systems.fx")
---@type Guide
local Guide      = require("src.systems.guide")
---@type HUD
local HUD        = require("src.ui.hud")
---@type Screen
local Screen     = require("src.core.screen")
---@type Tasks
local Tasks      = require("src.tasks")
local Util       = require("src.core.util")
local Profiler   = require("src.core.profiler")

local guidedata  = require("src.data.guide")
local daytimings = require("src.data.day_timings")
local palettes   = require("src.data.palettes")
local taskdata   = require("src.data.tasks")

local sky        = { 1, 1, 1, 1 }
local background = love.graphics.newImage("assets/gfx/journey-through-jhell-day-map.png")
background:setFilter("nearest", "nearest")

---@type State
local DayState = {}

function DayState:enter()
  self.age = 0
  self:closeTask()
  self.timeLeft = daytimings.DAY_LENGTH
  self.world:eachOfKind("interactable",
    ---@param e Interactable
    function(e)
      e:refresh()
    end)
  Events.emit("phase_changed", "day")
  Banner.show("Day " .. self.world.night, self.world.night == 1 and guidedata.INTRO_LINE or nil)
  if self.world.night == 1 then Guide.start() end
end

function DayState:exit()
  self:closeTask()
  Guide.stop()
end

---@param target Interactable
function DayState:startTask(target)
  local def = taskdata[target.taskId]
  local task = Tasks.create(def.minigame, function(result)
    self:closeTask()
    if result.success and target:tryUse() then
      Events.emit("task_done", target.taskId, result)
    else
      Events.emit("task_failed", target.taskId)
    end
  end)
  self.activeTask = task
  Events.emit("task_started", target.taskId)
end

function DayState:closeTask()
  local task = self.activeTask --[[@as Task]]
  self.activeTask = nil
  if task and task.close then task:close() end
end

function DayState:update(dt)
  self.age = self.age + dt
  Banner.update(dt)
  if self.activeTask then
    self.activeTask:update(dt)
  else
    self.world:update(dt)
    Collision.resolve(dt, self.world)
    FX.update(dt)
  end
  Guide.update(dt, self.timeLeft)
  if not Guide.holdsTimer() then self.timeLeft = self.timeLeft - dt end
  if self.timeLeft <= 0 then self.machine:switch("dusk") end
end

function DayState:draw()
  local task = self.activeTask
  local k = Util.clamp(1 - self.timeLeft / daytimings.WARNING_TIME, 0, 1)
  Screen.fill(Util.mixColor(palettes.DAY, palettes.DUSK, k, sky))
  self.world:draw(background)
  if task then task:draw() end
  FX.draw()
  HUD.drawDay(self.world, self.timeLeft, self.age, task)

  if not (task and task.panel) then
    Guide.draw()
    Banner.draw()
  end
end

function DayState:onAction(action)
  if self.activeTask then
    if action == "cancel" then
      Events.emit("task_cancelled")
      self:closeTask()
    end
    return
  end
  if action == "interact" then
    local target = Commands.interact(self.world) --[[@as Interactable]]
    if target then self:startTask(target) end
  elseif action == "end_day" then
    self.machine:switch("dusk")
  end

  -- the if block shadows this implementation
  -- local command = keymap[action]
  -- if command then command(self.world) end
end

---@param x number
---@param y number
---@param button integer
function DayState:mousepressed(x, y, button)
  if self.activeTask and button == 1 then self.activeTask:mousepressed(x, y, button) end
end

function DayState:mousereleased(x, y, button)
  if self.activeTask and self.activeTask.mousereleased then
    self.activeTask:mousereleased(x, y,
      button)
  end
end

function DayState:wheelmoved(dx, dy)
  if self.activeTask and self.activeTask.wheelmoved then self.activeTask:wheelmoved(dx, dy) end
end

function DayState:focus(focused)
  if self.activeTask and not focused and self.activeTask.blur then self.activeTask:blur() end
end

return DayState
