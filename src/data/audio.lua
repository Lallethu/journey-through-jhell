local audiodata = {
  BUSES = { player = 1.0, ui = 0.9, jelly = 0.7, bed = 0.35, music = 0.4 },
  FALLOFF = 260,
  PITCH_PER_SIZE = { [1] = 1.25, [2] = 1.0, [3] = 0.8 },

  SFX = {
    swing = {
      files = { "assets/sfx/swoop-1.ogg", "assets/sfx/swoop-2.ogg" },
      voices = 2,
      cooldown = 0,
      volume = 0.9,
      bus =
      "player"
    },
    jelly_hit = {
      files = { "assets/sfx/jelly-hit-1.ogg", "assets/sfx/jelly-hit-2.ogg", "assets/sfx/jelly-hit-3.ogg" },
      voices = 4,
      cooldown = 0.04,
      volume = 0.9,
      bus = "jelly",
      pitchJitter = 0.08,
    },
    jelly_pop = {
      files = { "assets/sfx/jelly-died-1.ogg", "assets/sfx/jelly-died-2.ogg" },
      voices = 6,
      cooldown = 0.05,
      volume = 0.6,
      bus = "jelly",
      pitchJitter = 0.08
    },
    player_hurt = {
      files = { "assets/sfx/player-hurt.ogg" },
      voices = 2,
      cooldown = 0.2,
      volume = 0.8,
      bus = "player"
    },
    heal = {
      files = { "assets/sfx/heal.ogg" },
      voices = 2,
      cooldown = 0.1,
      volume = 0.7,
      bus = "player"
    },
    click = {
      files = { "assets/sfx/click.ogg" },
      voices = 4,
      cooldown = 0.03,
      volume = 0.8,
      bus = "ui"
    },
    task_done = {
      files = { "assets/sfx/taadaa.ogg" },
      voices = 2,
      cooldown = 0.1,
      volume = 0.7,
      bus = "ui"
    },
    task_failed = {
      files = { "assets/sfx/tuudun.ogg" },
      voices = 1,
      cooldown = 0.2,
      volume = 0.7,
      bus = "ui"
    },
    wall_built = {
      files = { "assets/sfx/wall-up.ogg" },
      voices = 1,
      cooldown = 0,
      volume = 0.6,
      bus = "player"
    },
    wall_broken = {
      files = { "assets/sfx/wall-down.ogg" },
      voices = 2,
      cooldown = 0,
      volume = 0.9,
      bus = "jelly"
    },
    stinger = {
      files = { "assets/sfx/clear.ogg" },
      voices = 1,
      cooldown = 0,
      volume = 0.8,
      bus = "ui"
    },
  },

  BED = { files = "assets/sfx/horde-loop.ogg", volume = 1.0, fullAt = 20, smooth = 3 },
  MUSIC = {
    FADE = 1.0,
    tracks = {
      day = { file = "assets/music/day.ogg", volume = 1.0 },
      night = { file = "assets/music/night.ogg", volume = 1.0 },
    },
  },
}

return audiodata
