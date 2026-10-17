-- ============================================================
--  UNDER THE SEA
--  Drive along the ocean floor past coral, a shipwreck and a whale!
--  Water slows the cars down a little (see "physics").
-- ============================================================
local S = require("src.scenery")
local lg = love.graphics
local col = S.col

return {
  name = "Under the Sea",
  seed = 777,
  roadWidth = 260,

  points = {
    { 0, 0 }, { 1000, -100 }, { 1800, 200 }, { 2200, 800 }, { 1900, 1400 },
    { 2300, 2000 }, { 3000, 2100 }, { 3500, 2700 }, { 3200, 3400 }, { 2400, 3600 },
    { 1700, 3200 }, { 1100, 3600 }, { 300, 3500 }, { -300, 3000 }, { -200, 2300 },
    { -700, 1700 }, { -600, 900 }, { -400, 300 },
  },

  boosts = { 0.05, 0.33, 0.62, 0.86 },

  -- speed = 0.92 means water makes everyone 8% slower
  physics = { speed = 0.92, grip = 1.0 },

  -- 3D view: you can't see as far under water
  fog = { 700, 2300 },

  colors = {
    sky = "#0a2f55",      -- 3D view: deep water above...
    fog = "#1d6f96",      -- ...and murky water far away
    ground = "#2c86a8",   -- sea floor
    shoulder = "#7fbfcf", -- sand beside the road
    road = "#34495e",
    road2 = "#37506a",
    curbA = "#ff7043",    -- coral orange
    curbB = "#fff3e0",
    line = "#80deea",
    boost = "#ffee58",
  },

  scenery = {
    { kind = "sand", count = 70, size = { 80, 200 }, layer = "ground", anywhere = true },
    { kind = "ripple", count = 400, size = { 10, 22 }, layer = "ground", anywhere = true },
    { kind = "shipwreck", size = { 230, 230 }, solid = true, solidScale = 0.55, height = 50, taper = 0.1,
      at = { { t = 0.23, side = -1, off = 520, rot = 0.6 } } },
    { kind = "chest", size = { 26, 26 }, solid = true, heightScale = 1,
      at = { { t = 0.23, side = -1, off = 270 }, { t = 0.7, side = 1, off = 230 } } },
    { kind = "coral", count = 60, size = { 24, 46 }, solid = true, solidScale = 0.8,
      placement = "roadside", gap = 50, spread = 350, heightScale = 1.3, taper = 0.2 },
    { kind = "coral", count = 40, size = { 24, 46 }, solid = true, solidScale = 0.8, gap = 60,
      heightScale = 1.3, taper = 0.2 },
    { kind = "rock", count = 35, size = { 22, 44 }, solid = true, solidScale = 0.85,
      placement = "roadside", gap = 50, spread = 400, heightScale = 0.8, taper = 0.5 },
    { kind = "clam", count = 14, size = { 14, 18 }, placement = "roadside", gap = 30, spread = 250 },
    { kind = "starfish", count = 30, size = { 10, 15 }, placement = "roadside", gap = 20, spread = 300 },
    { kind = "seaweed", count = 70, size = { 50, 90 }, placement = "roadside", gap = 30, spread = 300 },
    { kind = "fish", count = 22, size = { 10, 16 }, layer = "high", anywhere = true, float = 45 },
    { kind = "jelly", count = 10, size = { 22, 32 }, layer = "high", anywhere = true, float = 100 },
    { kind = "bubbles", count = 40, size = { 4, 9 }, layer = "high", anywhere = true },
    { kind = "whale", size = { 380, 380 }, layer = "high", float = 160, at = { { x = 1500, y = 1800 } } },
  },

  draw = {
    sand = function(d)
      lg.rotate(d.rot)
      col("#3d97b8", 0.8); lg.ellipse("fill", 0, 0, d.size * 1.5, d.size)
    end,

    ripple = function(d)
      lg.rotate(0.3)
      col("#5fb0cc", 0.6); lg.setLineWidth(2)
      lg.arc("line", "open", 0, 0, d.size, math.pi * 1.15, math.pi * 1.85)
    end,

    shipwreck = function(d)
      local s = d.size
      lg.rotate(d.rot)
      S.shadow(s * 1.05, s * 0.4, 20, 25)
      col("#5d4037")
      lg.polygon("fill", s, 0, s * 0.6, -s * 0.38, -s, -s * 0.35, -s, s * 0.35, s * 0.6, s * 0.38)
      col("#8d6e63")
      lg.polygon("fill", s * 0.85, 0, s * 0.5, -s * 0.28, -s * 0.9, -s * 0.26, -s * 0.9, s * 0.26, s * 0.5, s * 0.28)
      col("#6d4c41"); lg.setLineWidth(3)
      for i = -3, 3 do lg.line(-s * 0.9, i * s * 0.07, s * 0.6, i * s * 0.07) end
      col("#263238"); lg.polygon("fill", -s * 0.1, -s * 0.15, s * 0.15, -s * 0.05, 0, s * 0.18) -- hole
      col("#4e342e"); lg.setLineWidth(10)
      lg.line(s * 0.3, 0, s * 0.8, -s * 0.6) -- broken mast
      lg.line(-s * 0.4, 0, -s * 0.5, s * 0.7)
      col("#eceff1", 0.85) -- torn sail
      lg.polygon("fill", s * 0.55, -s * 0.3, s * 0.75, -s * 0.5, s * 0.4, -s * 0.55)
      col("#7cb342") -- moss
      lg.circle("fill", -s * 0.6, s * 0.2, s * 0.08)
      lg.circle("fill", s * 0.2, -s * 0.22, s * 0.06)
    end,

    chest = function(d, t)
      local s = d.size
      S.shadow(s * 1.2, s * 0.6, 5, 8)
      col("#6d4c41"); lg.rectangle("fill", -s, -s * 0.7, s * 2, s * 1.4, 4, 4)
      col("#ffca28"); lg.rectangle("fill", -s, -s * 0.7, s * 2, s * 0.35, 4, 4)
      lg.rectangle("fill", -s * 0.15, -s * 0.5, s * 0.3, s * 0.6)
      col("#fff59d", 0.5 + 0.5 * math.sin(t * 5 + d.seed))
      lg.circle("fill", s * 0.7, -s * 0.9, 4) -- sparkle
    end,

    coral = function(d, t)
      local colors = { "#ff7043", "#ec407a", "#ab47bc", "#ffca28" }
      local c = colors[d.seed % 4 + 1]
      local s = d.size
      S.shadow(s, s * 0.8, 6, 8)
      lg.rotate(d.rot)
      for i = 0, 5 do
        local a = i * 1.05
        local r = s * (0.45 + (d.seed * (i + 1)) % 7 * 0.05)
        col(c); lg.circle("fill", math.cos(a) * r, math.sin(a) * r, s * 0.32)
        col("#ffffff", 0.35); lg.circle("fill", math.cos(a) * r - 2, math.sin(a) * r - 2, s * 0.12)
      end
      col(c); lg.circle("fill", 0, 0, s * 0.45)
    end,

    rock = function(d)
      local p = S.blob(d, 8, 0.35)
      lg.rotate(d.rot)
      if not S.lifted then lg.setColor(0, 0, 0, 0.2); lg.polygon("fill", S.scaled(p, 1, 5, 7)) end
      col("#546e7a"); lg.polygon("fill", p)
      col("#78909c"); lg.polygon("fill", S.scaled(p, 0.6, -d.size * 0.15, -d.size * 0.15))
      col("#66bb6a"); lg.circle("fill", d.size * 0.3, d.size * 0.2, d.size * 0.15) -- algae
    end,

    clam = function(d, t)
      local s = d.size
      local open = 0.5 + 0.5 * math.sin(t * 1.5 + d.seed)
      lg.rotate(d.rot)
      col("#f8bbd0"); lg.arc("fill", 0, 0, s, 0, math.pi)
      col("#fafafa"); lg.circle("fill", 0, s * 0.2, s * 0.3 * open) -- pearl
      col("#f48fb1"); lg.arc("fill", 0, -s * 0.2 * open, s, math.pi, math.pi * 2)
    end,

    starfish = function(d)
      lg.rotate(d.rot)
      col(d.seed % 2 == 0 and "#ff8a65" or "#fdd835")
      for i = 0, 4 do
        local a = i * math.pi * 2 / 5
        lg.polygon("fill", 0, 0, math.cos(a - 0.3) * d.size * 0.4, math.sin(a - 0.3) * d.size * 0.4,
          math.cos(a) * d.size, math.sin(a) * d.size,
          math.cos(a + 0.3) * d.size * 0.4, math.sin(a + 0.3) * d.size * 0.4)
      end
    end,

    -- Seaweed stands up on screen and sways
    seaweed = function(d, t, cam)
      S.shadow(14, 6)
      S.upright(cam)
      lg.setLineWidth(6)
      for k = -1, 1 do
        col(k == 0 and "#43a047" or "#2e7d32")
        local pts = {}
        for i = 0, 6 do
          local y = -i * d.size / 6
          pts[#pts + 1] = k * 8 + math.sin(t * 2 + i * 0.7 + d.seed + k) * i * 2.2
          pts[#pts + 1] = y * (1 - math.abs(k) * 0.25)
        end
        lg.line(pts)
      end
    end,

    fish = function(d, t)
      lg.rotate(d.dir or 0)
      local wig = math.sin(t * 12 + d.seed) * 0.3
      for k = 0, 2 do -- a little school of 3
        local ox, oy = -k * 26, (k % 2 == 0 and 1 or -1) * k * 14
        lg.setColor(0, 0, 0, 0.15); lg.ellipse("fill", ox + 6, oy + 10, d.size, d.size * 0.5)
        col(d.seed % 3 == 0 and "#ffeb3b" or (d.seed % 3 == 1 and "#ff7043" or "#4dd0e1"))
        lg.ellipse("fill", ox, oy, d.size, d.size * 0.55)
        lg.push(); lg.translate(ox - d.size, oy); lg.rotate(wig)
        lg.polygon("fill", 0, 0, -d.size * 0.7, -d.size * 0.5, -d.size * 0.7, d.size * 0.5)
        lg.pop()
        col("#212121"); lg.circle("fill", ox + d.size * 0.5, oy - d.size * 0.15, 2)
      end
    end,

    jelly = function(d, t)
      local s = d.size
      local pulse = 1 + math.sin(t * 3 + d.seed) * 0.12
      col("#f48fb1", 0.35); lg.setLineWidth(3)
      for i = -2, 2 do
        lg.line(i * s * 0.25, 0, i * s * 0.3 + math.sin(t * 4 + i) * 6, s * 1.6)
      end
      col("#f8bbd0", 0.7); lg.circle("fill", 0, 0, s * pulse)
      col("#ffffff", 0.5); lg.circle("fill", -s * 0.3, -s * 0.3, s * 0.3)
    end,

    bubbles = function(d, t)
      local grow = ((t * 0.5 + d.seed * 0.01) % 1)
      col("#e1f5fe", 0.8 * (1 - grow)); lg.setLineWidth(2)
      lg.circle("line", 0, 0, d.size * (0.5 + grow))
      lg.circle("line", 10, -12, d.size * 0.6 * (0.5 + grow))
    end,

    -- A big whale shadow swimming over the track
    whale = function(d, t)
      local s = d.size
      lg.rotate(d.dir or 0)
      lg.setColor(0, 0.05, 0.15, 0.22)
      lg.ellipse("fill", 0, 0, s, s * 0.35)
      lg.polygon("fill", -s * 0.9, 0, -s * 1.35, -s * 0.3 + math.sin(t * 2) * 15, -s * 1.35, s * 0.3 + math.sin(t * 2) * 15)
      lg.ellipse("fill", s * 0.1, s * 0.4, s * 0.3, s * 0.08)
      lg.ellipse("fill", s * 0.1, -s * 0.4, s * 0.3, s * 0.08)
    end,
  },

  update = function(track, dt)
    for _, d in ipairs(track.layers.high) do
      if d.kind == "fish" then
        d.dir = d.dir or (d.seed % 628) / 100
        d.dir = d.dir + math.sin(track.time * 0.5 + d.seed) * 0.4 * dt
        d.x = d.x + math.cos(d.dir) * 90 * dt
        d.y = d.y + math.sin(d.dir) * 90 * dt
        S.wrap(d, track)
      elseif d.kind == "bubbles" then
        d.float = ((d.float or d.seed % 200) + 40 * dt) % 220 -- rising (3D view)
      elseif d.kind == "jelly" then
        d.y = d.y - (20 + math.sin(track.time * 3 + d.seed) * 15) * dt
        S.wrap(d, track)
      elseif d.kind == "whale" then
        d.dir = (d.dir or 0) + 0.06 * dt
        d.x = d.x + math.cos(d.dir) * 70 * dt
        d.y = d.y + math.sin(d.dir) * 70 * dt
      end
    end
  end,

  -- Blue water tint with wobbly light over the whole screen
  overlay = function(x, y, w, h, t)
    lg.setColor(0.1, 0.45, 0.9, 0.12)
    lg.rectangle("fill", x, y, w, h)
    lg.setColor(1, 1, 1, 0.05)
    for i = 0, 5 do
      local lx = x + ((i * 260 + t * 40) % (w + 400)) - 200
      lg.polygon("fill", lx, y, lx + 90, y, lx + 30, y + h, lx - 60, y + h)
    end
  end,
}
