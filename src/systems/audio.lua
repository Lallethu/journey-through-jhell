local Events = require("src.core.events")
local Util = require("src.core.util")

local sounddata = require("src.data.audio")

---@type World
local world
local bed
local bedLevel, bedTarget, bedTimer = 0, 0, 0
local tracks = {}
local wanted = nil
local banks = {}
local started = false

local function play(name, pitch, at)
  local bank = banks[name]
  if not bank or not started then return end

  local definition, now = bank.definition, love.timer.getTime()
  if now - bank.lastPlayed < definition.cooldown then return end

  local nmbOfVariant = #bank.variations
  local pick = nmbOfVariant > 1 and
      ((bank.last - 1 + love.math.random(nmbOfVariant - 1)) % nmbOfVariant) + 1 or 1

  for _, src in ipairs(bank.variations[pick]) do
    if not src:isPlaying() then
      local volume = definition.volume * sounddata.BUSES[definition.bus]
      local player = world.player

      if at and player then
        local dx, dy = at.x - player.x, at.y - player.y
        volume = volume * Util.clamp(1 - math.sqrt(dx * dx + dy * dy) / sounddata.FALLOFF, 0.3, 1)
      end

      local jitter = definition.pitchJitter or 0
      src:setPitch((pitch or 1) * (1 + (love.math.random() * 2 - 1) * jitter))
      src:setVolume(volume)
      src:play()

      bank.last, bank.lastPlayed = pick, now
      return
    end
  end
end

local function sizePitch(jelly) return sounddata.PITCH_PER_SIZE[jelly.size] end

local function approach(value, target, step)
  if value < target then return math.min(target, value + step) end
  return math.max(target, value - step)
end

local reactions = {
  player_attacked = function() play("swing") end,
  jelly_hit = function(jelly) play("jelly_hit", sizePitch(jelly), jelly) end,
  jelly_hit_sixseven = function() play("jelly_hit", sizePitch({ size = 1 }), { x = 400, y = 200 }) end,
  jelly_died = function(jelly) play("jelly_pop", sizePitch(jelly), jelly) end,
  player_hurt = function() play("player_hurt") end,
  player_healed = function() play("heal") end,
  task_target_hit = function(_, _, streak) play("click", 1 + 0.06 * (streak - 1)) end,
  task_done = function() play("task_done") end,
  task_failed = function() play("task_failed") end,
  structure_built = function() play("wall_built") end,
  structure_destroyed = function() play("wall_broken") end,
  wave_cleared = function() play("stinger") end,
  phase_changed = function(phase)
    if phase == "day" then
      wanted = "day"
    elseif phase == "night" then
      wanted = "night"
    elseif phase == "ending" then
      wanted = nil
    end
  end,
}

---@class Audio
local Audio = {}

function Audio.load()
  local okBed, src = pcall(love.audio.newSource, sounddata.BED.files, "static")
  if okBed then
    bed = src
    bed:setLooping(true)
    bed:setVolume(0)
  else
    print("audio bed missing")
  end

  for name, definition in pairs(sounddata.MUSIC.tracks) do
    local okMusic, music = pcall(love.audio.newSource, definition.file, "stream")
    if okMusic then
      music:setLooping(true)
      music:setVolume(0)
      tracks[name] = { src = music, level = 0, volume = definition.volume }
    else
      print("music missing: " .. definition.file)
    end
  end

  for name, definition in pairs(sounddata.SFX) do
    local variations = {}
    for _, path in ipairs(definition.files) do
      local ok, base = pcall(love.audio.newSource, path, "static")

      if ok then
        local pool = { base }

        for v = 2, definition.voices do pool[v] = base:clone() end
        variations[#variations + 1] = pool
      else
        print("no matching sounds for path: " .. path)
      end
    end

    if #variations > 0 then
      banks[name] = {
        definition = definition,
        variations = variations,
        last = 0,
        lastPlayed = -math.huge
      }
    end
  end
end

---@param ctx { world: World }
function Audio.init(ctx)
  world = ctx.world
  Events.off_owner(Audio)
  for event, fn in pairs(reactions) do Events.on(event, fn, Audio) end
end

function Audio.update(dt)
  if not world or not started then return end

  bedTimer = bedTimer - dt

  if bedTimer <= 0 then
    bedTimer = 0.2
    bedTarget = Util.clamp(world:count("jelly") / sounddata.BED.fullAt, 0, 1)
  end

  if bed then
    bedLevel = Util.lerp(bedLevel, bedTarget, math.min(1, sounddata.BED.smooth * dt))
    if bedLevel > 0.01 then
      bed:setVolume(bedLevel * sounddata.BED.volume * sounddata.BUSES.bed)

      if not bed:isPlaying() then bed:play() end
      if world.player.dead then bed:pause() end
    elseif bed:isPlaying() then
      bed:pause()
    end
  end

  local step = dt / sounddata.MUSIC.FADE
  for name, track in pairs(tracks) do
    track.level = approach(track.level, name == wanted and 1 or 0, step)
    if track.level > 0 then
      track.src:setVolume(track.level * track.volume * sounddata.BUSES.music)
      if not track.src:isPlaying() then track.src:play() end
    elseif track.src:isPlaying() then
      track.src:pause()
    end
  end
end

function Audio.onUserInput()
  started = true
end

return Audio
