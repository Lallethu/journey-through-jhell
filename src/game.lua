local Screen          = require("src.core.screen")
local AudioSystem     = require("src.systems.audio")
local Input           = require("src.core.input")
local StateMachine    = require("src.core.statemachine")
local Player          = require("src.world.player")
local World           = require("src.world.world")
local ResourcesSystem = require("src.systems.resources")
local SplittingSystem = require("src.systems.splitting")
local Interactable    = require("src.world.interactable")
local Events          = require("src.core.events")
local HUD             = require("src.ui.hud")
local FX              = require("src.systems.fx")
local Profiler        = require("src.core.profiler")

---@class Game
local Game            = {}

local IS_WEB          = love.system.getOS() == "Web"

---@type StateMachine
local stateMachine
---@type World

local function newRun()
  local world = World.new()
  world.player = world:add(Player.new(Screen.width / 2, Screen.height / 2)) --[[@as Hittable]]


  world:add(Interactable.new("wall", 72, 200))
  world:add(Interactable.new("healer", 408, 220, true))
  world:add(Interactable.new("gatherer", 240, 128))

  AudioSystem.init { world = world }
  SplittingSystem.init(world)
  ResourcesSystem.init(world)
  FX.init()

  stateMachine = StateMachine.new {
    world = world,
    states = {
      day    = require("src.states.day"),
      dusk   = require("src.states.dusk"),
      night  = require("src.states.night"),
      ending = require("src.states.ending"),
    },
  }
  stateMachine:switch("day")
end

function Game.load()
  Screen.init()
  AudioSystem.load()
  HUD.init()
  Events.on("restart_requested", newRun, Game)
  newRun()
end

function Game.update(dt)
  Profiler.beginFrame(dt)

  dt = math.min(dt, 1 / 20) -- cheeky way of capping dt compounding to insane values and break movement/timer/ect...
  Profiler.beginSection("Game Update")
  stateMachine:update(dt)
  Profiler.endSection("Game Update")

  Profiler.beginSection("audio")
  AudioSystem.update(dt)
  Profiler.endSection("audio")
end

function Game.draw()
  Profiler.beginSection("Game Draw")
  Screen.begin()
  stateMachine:draw()
  Screen.finish()
  Profiler.endSection("Game Draw")

  Profiler.draw()
end

---@param k love.KeyConstant
---@param sc love.Scancode
function Game.keypressed(k, sc)
  AudioSystem.onUserInput()
  local action = Input.keypressed(k, sc)
  if action == "toggle_fullscreen" and not IS_WEB then
    love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
  end
  if action then stateMachine:onAction(action) end
end

---@param x number
---@param y number
---@param button integer
function Game.mousepressed(x, y, button)
  local gx, gy = Screen.toGameCoordinates(x, y)
  if gx < 0 or gy < 0 or gx > Screen.width or gy > Screen.height then return end
  stateMachine:mousepressed(gx, gy, button)
end

function Game.resize(w, h) Screen.resize(w, h) end

return Game
