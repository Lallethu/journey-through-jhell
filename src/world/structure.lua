---@type Events
local Events = require("src.core.events")
local Util = require("src.core.util")

local structuresdata = require("src.data.structures")

local WHITE = { 1, 1, 1, 1 }
local scratch = { 1, 1, 1, 1 }
local images = {}

---Cache image after loading
local function imageFor(id)
  local img = images[id]
  if not img then
    local def = structuresdata[id]
    img = love.graphics.newImage(def.sprite)
    img:setFilter("nearest", "nearest")
    assert(img:getWidth() == def.w and img:getHeight() == def.h,
      ("%s: sprite is %dx%d but data says %dx%d"):format(
        id, img:getWidth(), img:getHeight(), def.w, def.h))
    images[id] = img
  end
  return img
end


---@class Structure : Entity
---@field structureId StructureId
---@field hw number Half width
---@field hh number Half height
---@field vertical boolean
---@field sprite love.Image
---@field maxHp number
local Structure = {}
Structure.__index = Structure

---@param structureId StructureId
---@param x number
---@param y number
---@param vertical boolean
function Structure.new(structureId, x, y, vertical)
  local def = assert(structuresdata[structureId], "unknown structure: " .. tostring(structureId))
  local w, h = def.w, def.h
  if vertical then w, h = h, w end

  return setmetatable({
    -- entity
    x = x,
    y = y,
    kind = "structure",
    hp = def.hp,
    dead = false,
    -- structure
    structureId = structureId,
    vertical = vertical or false,
    hw = w / 2,
    hh = h / 2,
    maxHp = def.hp,
  }, Structure)
end

function Structure:chew(amount)
  if self.dead then return end

  self.hp = math.max(self.hp - amount, 0)
  if self.hp == 0 then
    self.dead = true
    Events.emit("structure_destroyed", self)
  end
end

function Structure:update(dt) end

function Structure:draw()
  local def = structuresdata[self.structureId]
  local img = imageFor(self.structureId)
  love.graphics.setColor(Util.mixColor(def.damaged, WHITE, self.hp / self.maxHp, scratch))
  love.graphics.draw(img, math.floor(self.x), math.floor(self.y),
    self.vertical and math.pi / 2 or 0, 1, 1, img:getWidth() / 2, img:getHeight() / 2)
  love.graphics.setColor(1, 1, 1, 1)
end

return Structure
