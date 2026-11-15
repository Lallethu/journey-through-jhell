local tasksdata      = require("src.data.tasks")
local Animator       = require("src.core.animator")

local BODY_RADIUS    = 10

local sheet          = Animator.newSheet(require("src.data.interactable_anim"))

---@class Interactable : Entity
---@field taskId TaskId Key into data/tasks.lua (!= to the entity id)
---@field radius number
---@field usedToday boolean
---@field anim Animator
---@field flip boolean
local Interactable   = {}
Interactable.__index = Interactable

---@param taskId TaskId
---@param x number Center
---@param y number Center
---@param flip boolean?
---@return Interactable
function Interactable.new(taskId, x, y, flip)
  flip = flip or false
  assert(tasksdata[taskId], "unknown task: " .. tostring(taskId))
  local instance = {
    -- entity
    x = x,
    y = y,
    kind = "interactable",
    dead = false,
    -- interactable
    taskId = taskId,
    radius = BODY_RADIUS,
    usedToday = false,
    anim = Animator.new(sheet),
    flip = flip,
  }

  instance.anim:play("idle", true)
  return setmetatable(instance, Interactable)
end

---@return boolean used True if the interaction was available
function Interactable:tryUse()
  if self.usedToday then return false end
  self.usedToday = true
  return true
end

function Interactable:refresh()
  self.usedToday = false
end

function Interactable:update(dt)
  self.anim:update(dt)
end

function Interactable:draw()
  local color = tasksdata[self.taskId].color
  love.graphics.setColor(color[1], color[2], color[3], self.usedToday and 0.35 or 1)
  self.anim:draw(self.x, self.y, self.flip)
  love.graphics.setColor(1, 1, 1, 1)
end

return Interactable
