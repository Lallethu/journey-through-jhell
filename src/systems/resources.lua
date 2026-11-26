local Events = require("src.core.events")

local tasksdata = require("src.data.tasks")
local jellydata = require("src.data.jelly")

---@type World
local world

---@class Resources
local Resources = {}

---@param taskId TaskId
---@param taskResults TaskResult
local function onTaskDone(taskId, taskResults)
  local task = tasksdata[taskId]
  if task.earns then
    world.sugar = world.sugar + task.earns
    Events.emit("sugar_changed", task.earns, true, world.player)
  end
  if task.cost then
    world.sugar = world.sugar - task.cost
    Events.emit("sugar_changed", task.cost, false, world.player)
  end
  if task.gives then
    local rewardWalls = ((world.stock[task.gives] or 0) + 1 + (taskResults.quality >= 0.5 and 1 or 0))
    world.stock[task.gives] = rewardWalls
    Events.emit("token_gained", task.gives, rewardWalls, world.player)
  end
end

---@param jelly Jelly
local function onJellyDied(jelly)
  local amount = math.random(jellydata.SUGAR_REWARD.min, jellydata.SUGAR_REWARD.max) +
      jelly.size
  world.sugar = world.sugar + amount

  Events.emit("sugar_changed", amount, true, world.player)
end

---@param p_world World
function Resources.init(p_world)
  world = p_world
  Events.off_owner(Resources)
  Events.on("task_done", onTaskDone, Resources)
  Events.on("jelly_died", onJellyDied, Resources)
end

return Resources
