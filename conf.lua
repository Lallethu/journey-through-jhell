local love = require("love")

function love.conf(t)
  t.identity = "journey-trough-jhell"
  t.version = "11.5"
  t.console = false

  t.window.title = "Journey Trough Jhell"
  t.window.width = 960
  t.window.height = 540
  t.window.resizable = true
  t.window.fullscreen = true
  t.window.vsync = 1
  t.window.msaa = 0
  t.window.highdpi = false

  t.modules.thread = false
  t.modules.video = false
  t.modules.physics = false
  t.modules.joystick = false
  t.modules.touch = false
end
