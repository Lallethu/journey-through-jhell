local Fonts  = require("src.core.fonts")
local Input  = require("src.core.input")
local Util   = require("src.core.util")
local Screen = require("src.core.screen")




local bindings                    = require("src.data.bindings")
local controldata                 = require("src.data.controls")
local tasksdata                   = require("src.data.tasks")
local wavesdata                   = require("src.data.waves")
local playerdata                  = require("src.data.player")
local daytimings                  = require("src.data.day_timings")

local MARGIN                      = 6
local SIZE_NAMES                  = { "small", "medium", "big" }
local KEY_COLOR, LABEL_COLOR      = { 0.92, 0.92, 0.97 }, { 0.72, 0.72, 0.8 }

local WHITE                       = { 1, 1, 1, 1 }
local GREY                        = { 0.77, 0.77, 0.77, 1 }
local RED                         = { 0.9, 0.3, 0.3, 1 }
local YELLOW                      = { 0.95, 0.85, 0.3, 1 }
local GREEN                       = { 0.4, 0.9, 0.4, 1 }

---@type love.Font
local font
local scratch                     = { 1, 1, 1, 1 }
local done, total                 = 0, 0
local forecastNight, forecastText = 0, ""
local rows                        = {}
local lineH

---@class HUD
local HUD                         = {}

local function text(str, x, y, color, alpha)
  alpha = alpha or 1
  color = color or WHITE

  love.graphics.setColor(0, 0, 0, alpha * 0.8)
  love.graphics.print(str, x + 1, y + 1)

  love.graphics.setColor(color[1], color[2], color[3], alpha)
  love.graphics.print(str, x, y)
end

local function printShadow(str, x, y, color, alpha)
  text(str, x, y, color, alpha)
end

local function centeredX(str)
  return math.floor((Screen.width - font:getWidth(str)) / 2)
end

local function buildControls()
  rows = {}
  for phase, items in pairs(controldata.ROWS) do
    local row, width = {}, 0
    for i, item in ipairs(items) do
      local action = item[1] --[[@as Binding]]
      local key = (action == "move" and Input.moveLabel())
          or (action == "click" and "Click")
          or Input.label(action)
      local label = " " .. item[2]
      local keyW = font:getWidth(key)
      local w = keyW + font:getWidth(label)
      row[i] = { key = key, label = label, keyW = keyW, width = w, need = item[3] }
      width = width + w + (i > 1 and controldata.GAP or 0)
    end
    row.width = width
    rows[phase] = row
  end
end

local function controls(phase, age, world)
  local row = rows[phase]
  local fade = Util.clamp((age - controldata.FADE_START) / controldata.FADE_TIME, 0, 1)
  local alpha = Util.lerp(controldata.ALPHA_HIGH, controldata.ALPHA_LOW, fade)
  local x = math.floor((Screen.width - row.width) / 2)
  local y = Screen.height - lineH - controldata.Y_FROM_BOTTOM

  for i = 1, #row do
    local item = row[i]
    local a = alpha
    if item.need and (world.stock[item.need] or 0) == 0 then a = a * 0.45 end
    printShadow(item.key, x, y, KEY_COLOR, a)
    printShadow(item.label, x + item.keyW, y, LABEL_COLOR, a)
    x = x + item.width + controldata.GAP
  end
end

local function ratioColor(t)
  local from, to, k = RED, YELLOW, t * 2
  if t >= 0.5 then from, to, k = YELLOW, GREEN, t * 2 - 1 end
  for i = 1, 3 do scratch[i] = Util.lerp(from[i], to[i], k) end
  return scratch
end

---@param e Interactable
local function tally(e)
  total = total + 1
  if e.usedToday then done = done + 1 end
end

---@param night integer
---@return string
local function forecast(night)
  if night ~= forecastNight then
    local config = wavesdata.NIGHTS[math.min(night, #wavesdata.NIGHTS)]
    local parts = {}

    for _, g in ipairs(config.groups) do
      parts[#parts + 1] = g.count .. " " .. SIZE_NAMES[g.size]
    end

    forecastText = table.concat(parts, ", ")
    forecastNight = night
  end
  return forecastText
end

---@param world World
local function status(world)
  local player = world.player

  if player then
    local w, h = 60, 6
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", MARGIN, MARGIN, w, h)
    love.graphics.setColor(0.9, 0.3, 0.4, 1)
    love.graphics.rectangle("fill", MARGIN, MARGIN, w * (player.hp / playerdata.MAX_HP), h)
  end


  love.graphics.setColor(0.04, 0.3, 0.4, 0.4)
  love.graphics.rectangle("fill", MARGIN, MARGIN + 12,
    font:getWidth("Walls " .. (world.stock.wall or 0) .. "  Heals " .. (world.stock.heal or 0)) + 6,
    38)
  text("Sugar " .. world.sugar, MARGIN + 3, MARGIN + 15)
  text("Walls " .. (world.stock.wall or 0) .. "  Heals " .. (world.stock.heal or 0),
    MARGIN + 3, MARGIN + 31)
end

---@param world World
local function hint(world)
  local player = world.player
  if not player or player.dead then return end

  local target = world:nearest(player.x, player.y, playerdata.INTERACT_REACH, "interactable") --[[@as Interactable]]
  if not target then return end

  local task = tasksdata[target.taskId]
  local label = string.format("[%s] %s", bindings.interact[1]:upper(), task.name)
  local color = WHITE

  if target.usedToday then
    label, color = task.name .. " (done today)", GREY
  elseif task.cost then
    label = label .. " - " .. task.cost .. " sugar"
    if world.sugar < task.cost then color = RED end
  end
  text(label, centeredX(label), Screen.height - lineH * 3 - 5, color)
end

---@param world World
local function counter(world)
  done, total = 0, 0
  world:eachOfKind("interactable", tally)

  local label = "Tasks " .. done .. "/" .. total
  text(label, centeredX(label), Screen.height - lineH * 2 - 4,
    ratioColor(total > 0 and done / total or 0))
end

local function timer(timeLeft)
  local w, h = 100, 5
  local x, ratio = math.floor((Screen.width - w) / 2),
      Util.clamp(timeLeft / daytimings.DAY_LENGTH, 0, 1)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", x, MARGIN, w, h)
  love.graphics.setColor(ratioColor(ratio))
  love.graphics.rectangle("fill", x, MARGIN, w * ratio, h)
  local label = tostring(math.ceil(timeLeft))
  text(label, centeredX(label), MARGIN + h)
end

-- TODO: uncomment when key map rebind is implemented
-- HUD.rebuildControl = buildControls

function HUD.init()
  font = Fonts.get(14)
  lineH = font:getHeight()
  buildControls()
end

---@param world World
---@param timeLeft number
---@param busy boolean
function HUD.drawDay(world, timeLeft, busy, age)
  love.graphics.push("all")
  love.graphics.setFont(font)
  status(world)

  local title = "Night " .. world.night .. "/" .. #wavesdata.NIGHTS
  local info = forecast(world.night)
  text(title, Screen.width - MARGIN - font:getWidth(title), MARGIN)
  text(info, Screen.width - MARGIN - font:getWidth(info), MARGIN + 12, GREY)

  if not busy then hint(world) end
  counter(world)
  timer(timeLeft)
  controls(busy and "task" or "day", busy and 0 or age, world)
  love.graphics.pop()
end

---@param world World
function HUD.drawNight(world, age)
  love.graphics.push("all")
  love.graphics.setFont(font)
  status(world)

  local title = "Night " .. world.night
  local info = world:count("jelly") .. " jellies remaining"
  text(title, Screen.width - MARGIN - font:getWidth(title), MARGIN)
  text(info, Screen.width - MARGIN - font:getWidth(info), MARGIN + 12, GREY)
  controls("night", age, world)

  love.graphics.pop()
end

return HUD
