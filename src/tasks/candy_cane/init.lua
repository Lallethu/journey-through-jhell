local Screen = require("src.core.screen")
local Cane = require("src.tasks.candy_cane.cane")
local View = require("src.tasks.candy_cane.view")

local candydata = require("src.data.candy_cane")
local structuresdata = require("src.data.structures")

---@class CandyCaneTask: Task
---@field cane Cane
---@field ox number
---@field oy number
---@field title string
---@field layers table
---@field onFinish fun(result: TaskResult)
---@field tool "paint"|"saw"
---@field brushIndex integer
---@field sawIndex integer
---@field held boolean
---@field phase "working"|"done"
local Task = {}
Task.__index = Task

Task.controls = "candy_cane"
Task.panel = true

---@param config table minigame entry: { kind, structure, title }
---@param onFinish fun(result: TaskResult)
---@return CandyCaneTask
function Task.new(config, onFinish)
  local def = assert(structuresdata[config.structure],
    "candy_cane: unknown structure '" .. tostring(config.structure) .. "'")
  local stripeCount = math.max(1, math.floor(def.w / candydata.STRIPE.spacing))
  local cane = Cane.new(candydata, stripeCount)

  local self = setmetatable({
    cane = cane,
    layers = View.newLayers(cane),
    onFinish = onFinish,
    title = config.title or "Wall maker",
    ox = candydata.CENTER_X - candydata.GRID_W / 2,
    oy = candydata.GRID_TOP,
    tool = "paint",
    brushIndex = candydata.START_BRUSH,
    sawIndex = candydata.START_SAW,
    held = false,
    lastX = 0,
    lastY = 0,
    mx = 0,
    my = 0,
    hover = nil,
    sawState = "none",
    phase = "working",
    doneT = 0,
    finished = false,
    quality = 0,
    caption = "Paint & Saw",
    labels = {},
  }, Task)
  self:refreshLabels()
  love.mouse.setVisible(false)
  return self
end

---@return table
function Task:brush() return candydata.BRUSHES[self.brushIndex] end

---@return table
function Task:saw() return candydata.SAWS[self.sawIndex] end

function Task:refreshLabels()
  self.paintLine = self:brush().name .. " brush"
  self.sawLine = self:saw().name .. " blade"
end

local function inside(rect, size, x, y)
  return x >= rect.x and x < rect.x + size and y >= rect.y and y < rect.y + size
end

---@return "paint"|"saw"|nil
function Task:slotAt(x, y)
  if inside(candydata.PAINT_SLOT, candydata.SLOT, x, y) then return "paint" end
  if inside(candydata.SAW_SLOT, candydata.SLOT, x, y) then return "saw" end
  return nil
end

---@param tool "paint"|"saw"
---@param dir integer 1 or -1
function Task:cycleSize(tool, dir)
  if tool == "paint" then
    self.brushIndex = (self.brushIndex - 1 + dir) % #candydata.BRUSHES + 1
  else
    self.sawIndex = (self.sawIndex - 1 + dir) % #candydata.SAWS + 1
  end
  self:refreshLabels()
end

function Task:complete()
  self.phase = "done"
  self.held = false
  self.showGuide, self.showCutGuide = false, false
  self.doneT = 0
  self.quality = math.floor(self.cane:quality() * 100 + 0.5) / 100
  self.caption = ("Done!  Quality %d%%"):format(math.floor(self.quality * 100 + 0.5))
end

---@param dt number
function Task:update(dt)
  local mx, my = Screen.toGameCoordinates(love.mouse.getPosition())
  self.mx, self.my = mx, my

  if self.phase == "done" then
    self.hover = nil
    self.doneT = self.doneT + dt
    if self.doneT >= candydata.DONE_TIME and not self.finished then
      self.finished = true
      self.onFinish({ success = true, quality = self.quality })
    end
    return
  end

  self.hover = self:slotAt(mx, my)
  self.showGuide = self.tool == "paint" or self.hover == "paint"
  self.showCutGuide = self.tool == "saw" or self.hover == "saw"

  if self.held and not love.mouse.isDown(1) then self.held = false end

  self.sawState = "none"
  if self.held then
    local lx, ly = mx - self.ox, my - self.oy
    if self.tool == "paint" then
      self.cane:stampLine(self.lastX, self.lastY, lx, ly, self:brush().r)
    else
      self.sawState = self.cane:saw(lx, ly, self.lastX, self:saw(), dt)
    end
    self.lastX, self.lastY = lx, ly
  end

  View.refresh(self.layers)
  if self.cane:isDone() then self:complete() end
end

function Task:draw()
  View.draw(self)
end

---Right click changes the size,
---Left click selects a tool
---@param x number canvas coordinates
---@param y number
---@param button integer
function Task:mousepressed(x, y, button)
  if self.phase ~= "working" then return end
  local slot = self:slotAt(x, y)
  if slot then
    if button == 1 then
      self.tool = slot
    elseif button == 2 then
      self:cycleSize(slot, 1)
    end
    return
  end
  if button == 1 then
    self.held = true
    self.lastX, self.lastY = x - self.ox, y - self.oy
    if self.tool == "paint" then
      self.cane:stamp(self.lastX, self.lastY, self:brush().r)
    end
  end
end

function Task:mousereleased(_, _, button)
  if button == 1 then self.held = false end
end

---@param dy number wheel up is positive
function Task:wheelmoved(_, dy)
  if dy ~= 0 and self.phase == "working" then
    self:cycleSize(self.tool, dy > 0 and 1 or -1)
  end
end

---The window lost focus: a release may never arrive, so it let go
function Task:blur()
  self.held = false
end

---Called by DayState on every exit path (finish, cancel, end of day)
---It ensure the cursor is back on
function Task:close()
  self.held = false
  love.mouse.setVisible(true)
end

return Task
