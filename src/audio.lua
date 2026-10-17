-- Sounds are made with math, so there are no sound files to lose.
-- (Want real sounds? Put .ogg files in an "assets" folder and load them here.)
local config = require("config")

local Audio = { enabled = false }
local RATE = 22050

local function tone(freq, length, wave)
  local n = math.floor(RATE * length)
  local sd = love.sound.newSoundData(n, RATE, 16, 1)
  for i = 0, n - 1 do
    local t = i / RATE
    local env = math.min(1, i / 300) * math.min(1, (n - i) / 1500)
    local v
    if wave == "noise" then
      v = (math.random() * 2 - 1) * (1 - i / n)
    else
      v = math.sin(2 * math.pi * freq * t) > 0 and 0.6 or -0.6
    end
    sd:setSample(i, v * env * 0.4)
  end
  return love.audio.newSource(sd, "static")
end

function Audio.load()
  local ok = pcall(function()
    -- Engine hum: a looped buzzy wave. Pitch goes up with speed.
    local n = 4500 -- exact number of wave cycles so the loop is smooth
    local sd = love.sound.newSoundData(n, RATE, 16, 1)
    for i = 0, n - 1 do
      local ph = (i % 450) / 450
      local saw = ph * 2 - 1
      local v = 0.55 * saw + 0.25 * math.sin(2 * math.pi * 98 * i / RATE) + 0.2 * (ph < 0.5 and 1 or -1)
      sd:setSample(i, v * 0.3)
    end
    Audio.engineData = sd
    Audio.sounds = {
      beep = tone(440, 0.2),
      go = tone(880, 0.5),
      bump = tone(0, 0.15, "noise"),
      lap = tone(660, 0.25),
      boost = tone(1200, 0.25),
    }
  end)
  Audio.enabled = ok
end

function Audio.play(name)
  if not Audio.enabled then return end
  local s = Audio.sounds[name]
  if s then
    s:stop()
    s:setVolume(config.volume)
    s:play()
  end
end

function Audio.newEngine(volume)
  if not Audio.enabled then return nil end
  local s = love.audio.newSource(Audio.engineData, "static")
  s:setLooping(true)
  s:setVolume((volume or 0.25) * config.volume)
  return s
end

return Audio
