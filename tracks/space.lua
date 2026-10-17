-- ============================================================
--  OUTER SPACE
--  A floating road past planets, asteroids, UFOs and rockets.
--  Low gravity = cars slide more (grip 0.75).
-- ============================================================
local S = require("src.scenery")
local lg = love.graphics
local col = S.col

return {
  name = "Outer Space",
  seed = 4242,
  roadWidth = 260,

  points = {
    { 0, 0 }, { 1400, 0 }, { 2400, -300 }, { 3400, 0 }, { 3800, 800 }, { 3300, 1500 },
    { 2400, 1500 }, { 2000, 2100 }, { 2500, 2800 }, { 3500, 2900 }, { 4000, 3600 },
    { 3500, 4300 }, { 2200, 4400 }, { 1000, 4100 }, { 400, 3400 }, { 900, 2700 },
    { 700, 1900 }, { -200, 1600 }, { -600, 900 },
  },

  boosts = { 0.06, 0.27, 0.5, 0.72, 0.9 },

  -- grip below 1 = slidey, like driving with low gravity
  physics = { speed = 1.0, grip = 0.75 },

  -- 3D view: space is clear, you can see far
  fog = { 2600, 6000 },

  colors = {
    sky = "#05061a",      -- 3D view
    fog = "#0b0d2a",
    skyStars = true,      -- stars in the sky
    ground = "#0b0d2a",   -- space!
    shoulder = "#1c1f4a", -- glow under the road
    road = "#2b2d42",
    road2 = "#30324a",
    curbA = "#00e5ff",
    curbB = "#ff4081",
    line = "#ffffff",
    boost = "#76ff03",
  },

  scenery = {
    { kind = "nebula", count = 14, size = { 400, 800 }, layer = "ground", anywhere = true },
    { kind = "star", count = 1500, size = { 1, 3 }, layer = "ground", anywhere = true },
    { kind = "planet", count = 9, size = { 120, 260 }, layer = "high", gap = 300, float = 260 },
    { kind = "moon", size = { 180, 180 }, solid = true, solidScale = 0.95, height = 80, taper = 0.6,
      at = { { t = 0.42, side = 1, off = 420 } } },
    { kind = "asteroid", count = 55, size = { 20, 50 }, solid = true, solidScale = 0.85,
      placement = "roadside", gap = 50, spread = 380, heightScale = 1.1, taper = 0.55 },
    { kind = "asteroid", count = 40, size = { 30, 70 }, solid = true, solidScale = 0.85, gap = 80,
      heightScale = 1.1, taper = 0.55 },
    { kind = "satellite", count = 6, size = { 30, 30 }, layer = "high", anywhere = true, float = 150 },
    { kind = "ufo", count = 5, size = { 40, 40 }, layer = "high", anywhere = true, float = 110, height = 16, taper = 0.6 },
    { kind = "rocket", count = 4, size = { 34, 34 }, layer = "high", anywhere = true, float = 80 },
    { kind = "comet", count = 3, size = { 18, 18 }, layer = "high", anywhere = true, float = 230 },
  },

  draw = {
    nebula = function(d)
      local colors = { { 0.6, 0.2, 0.9 }, { 0.9, 0.2, 0.6 }, { 0.1, 0.7, 0.8 } }
      local c = colors[d.seed % 3 + 1]
      lg.rotate(d.rot)
      lg.setColor(c[1], c[2], c[3], 0.08); lg.ellipse("fill", 0, 0, d.size, d.size * 0.6)
      lg.setColor(c[1], c[2], c[3], 0.08); lg.ellipse("fill", d.size * 0.2, 0, d.size * 0.6, d.size * 0.4)
    end,

    star = function(d, t)
      local tw = 0.5 + 0.5 * math.sin(t * 2 + d.seed)
      local c = d.seed % 5 == 0 and { 1, 0.9, 0.5 } or (d.seed % 7 == 0 and { 0.6, 0.8, 1 } or { 1, 1, 1 })
      lg.setColor(c[1], c[2], c[3], 0.35 + 0.65 * tw)
      lg.circle("fill", 0, 0, d.size)
    end,

    -- planets stand up and hang in the sky in the 3D view
    planet = function(d, t, cam)
      S.upright(cam)
      local colors = { "#ff7043", "#42a5f5", "#ab47bc", "#66bb6a", "#ffca28", "#ec407a", "#26c6da" }
      local c = colors[d.seed % #colors + 1]
      local s = d.size
      local ringed = d.seed % 3 == 0
      lg.rotate(d.rot)
      if ringed then
        col("#ffe0b2", 0.6); lg.setLineWidth(s * 0.1)
        lg.ellipse("line", 0, 0, s * 1.6, s * 0.45)
      end
      col(c); lg.circle("fill", 0, 0, s)
      col("#ffffff", 0.18) -- stripes
      lg.ellipse("fill", 0, -s * 0.35, s * 0.85, s * 0.1)
      lg.ellipse("fill", 0, s * 0.25, s * 0.9, s * 0.12)
      lg.setColor(0, 0, 0, 0.3) -- shady side
      lg.arc("fill", 0, 0, s, -math.pi / 2, math.pi / 2)
      if ringed then
        col("#ffe0b2", 0.6); lg.setLineWidth(s * 0.1)
        lg.arc("line", "open", 0, 0, s * 1.6, 0, math.pi) -- front of ring (approx.)
      end
    end,

    moon = function(d)
      local s = d.size
      col("#bdbdbd"); lg.circle("fill", 0, 0, s)
      col("#9e9e9e")
      lg.circle("fill", -s * 0.3, -s * 0.2, s * 0.25)
      lg.circle("fill", s * 0.35, s * 0.3, s * 0.18)
      lg.circle("fill", s * 0.1, -s * 0.55, s * 0.12)
      -- tiny flag!
      col("#eeeeee"); lg.setLineWidth(3); lg.line(s * 0.2, -s * 0.1, s * 0.2, -s * 0.45)
      col("#e53935"); lg.polygon("fill", s * 0.2, -s * 0.45, s * 0.42, -s * 0.38, s * 0.2, -s * 0.31)
    end,

    asteroid = function(d)
      local p = S.blob(d, 9, 0.4)
      lg.rotate(d.rot)
      if not S.lifted then lg.setColor(0, 0, 0, 0.35); lg.polygon("fill", S.scaled(p, 1, 6, 8)) end
      col("#6d5f57"); lg.polygon("fill", p)
      col("#8a7a70"); lg.polygon("fill", S.scaled(p, 0.65, -d.size * 0.12, -d.size * 0.12))
      col("#5a4d46")
      lg.circle("fill", d.size * 0.25, d.size * 0.2, d.size * 0.18)
      lg.circle("fill", -d.size * 0.3, d.size * 0.1, d.size * 0.1)
    end,

    satellite = function(d, t)
      lg.rotate(t * 0.4 + d.rot)
      local s = d.size
      col("#90caf9"); lg.rectangle("fill", -s * 2, -s * 0.4, s * 1.4, s * 0.8)
      lg.rectangle("fill", s * 0.6, -s * 0.4, s * 1.4, s * 0.8)
      col("#1565c0"); lg.setLineWidth(1)
      for i = 1, 3 do
        lg.line(-s * 2 + i * s * 0.35, -s * 0.4, -s * 2 + i * s * 0.35, s * 0.4)
        lg.line(s * 0.6 + i * s * 0.35, -s * 0.4, s * 0.6 + i * s * 0.35, s * 0.4)
      end
      col("#ffd54f"); lg.rectangle("fill", -s * 0.6, -s * 0.5, s * 1.2, s, 4, 4)
      col("#e0e0e0"); lg.circle("fill", 0, 0, s * 0.3)
    end,

    ufo = function(d, t)
      local s = d.size
      if not S.lifted then
        lg.setColor(0.4, 1, 0.5, 0.15) -- tractor beam
        lg.circle("fill", 0, 0, s * 1.6)
      end
      col("#b0bec5"); lg.circle("fill", 0, 0, s)
      col("#78909c"); lg.circle("line", 0, 0, s * 0.8)
      col("#80deea", 0.9); lg.circle("fill", 0, 0, s * 0.45)
      col("#a5d6a7"); lg.circle("fill", -s * 0.1, -s * 0.05, s * 0.15) -- little alien
      for i = 0, 7 do
        local a = i * math.pi / 4 + t * 2
        local on = math.floor(t * 6 + i) % 2 == 0
        col(on and "#ffeb3b" or "#ff5252")
        lg.circle("fill", math.cos(a) * s * 0.85, math.sin(a) * s * 0.85, 4)
      end
    end,

    rocket = function(d, t)
      local s = d.size
      lg.rotate(d.dir or 0)
      local f = 0.8 + 0.4 * math.sin(t * 30 + d.seed)
      col("#ff6d00", 0.9); lg.ellipse("fill", -s * 1.6 * f, 0, s * 0.8 * f, s * 0.35)
      col("#ffea00"); lg.ellipse("fill", -s * 1.2, 0, s * 0.4, s * 0.2)
      col("#e53935")
      lg.polygon("fill", -s * 0.9, 0, -s * 1.2, -s * 0.6, -s * 0.5, -s * 0.3)
      lg.polygon("fill", -s * 0.9, 0, -s * 1.2, s * 0.6, -s * 0.5, s * 0.3)
      col("#eceff1"); lg.ellipse("fill", 0, 0, s, s * 0.32)
      col("#e53935"); lg.polygon("fill", s * 0.7, -s * 0.24, s * 1.25, 0, s * 0.7, s * 0.24)
      col("#4fc3f7"); lg.circle("fill", s * 0.2, 0, s * 0.14)
    end,

    comet = function(d)
      lg.rotate(d.dir or 0)
      for i = 1, 10 do
        lg.setColor(0.7, 0.9, 1, 0.5 * (1 - i / 10))
        lg.circle("fill", -i * 22, 0, d.size * (1 - i / 14))
      end
      col("#ffffff"); lg.circle("fill", 0, 0, d.size)
    end,
  },

  update = function(track, dt)
    for _, d in ipairs(track.layers.high) do
      if d.kind == "ufo" then
        d.x = d.x + math.cos(track.time * 0.4 + d.seed) * 120 * dt
        d.y = d.y + math.sin(track.time * 0.3 + d.seed * 2) * 120 * dt
      elseif d.kind == "rocket" or d.kind == "comet" then
        d.dir = d.dir or d.rot
        local sp = d.kind == "comet" and 500 or 220
        d.x = d.x + math.cos(d.dir) * sp * dt
        d.y = d.y + math.sin(d.dir) * sp * dt
        S.wrap(d, track)
      elseif d.kind == "satellite" then
        d.x = d.x + 25 * dt
        S.wrap(d, track)
      end
    end
  end,
}
