-- ============================================================
--  SNOWY MOUNTAIN
--  Zig-zag switchbacks down a snowy mountain. The road is ICY,
--  so cars slide around corners (grip 0.6). Watch for snowmen!
-- ============================================================
local S = require("src.scenery")
local lg = love.graphics
local col = S.col

return {
  name = "Snowy Mountain",
  seed = 1225,
  roadWidth = 270,

  points = {
    { 0, 0 }, { 1200, 0 }, { 1700, 400 }, { 1300, 800 }, { 400, 800 }, { 0, 1200 },
    { 400, 1600 }, { 1500, 1600 }, { 2000, 2000 }, { 1600, 2400 }, { 500, 2400 },
    { 100, 2800 }, { 500, 3300 }, { 1800, 3300 }, { 2700, 2900 }, { 3000, 2000 },
    { 3000, 1000 }, { 2700, 0 }, { 2000, -550 }, { 800, -650 }, { -200, -650 },
    { -750, -450 }, { -800, -50 }, { -450, 50 },
  },

  boosts = { 0.05, 0.36, 0.66, 0.84 },

  -- grip 0.6 = slippery ice!
  physics = { speed = 1.0, grip = 0.6 },
  fog = { 1200, 3000 }, -- snowy haze (3D view)

  colors = {
    sky = "#9fd0f5",      -- 3D view
    fog = "#eef6fc",
    ground = "#eef5fb",   -- snow
    shoulder = "#cfdde9", -- packed snow by the road
    road = "#5d6a75",
    road2 = "#62707b",
    curbA = "#d32f2f",
    curbB = "#ffffff",
    line = "#b3e5fc",
    boost = "#ff4081",
  },

  scenery = {
    { kind = "drift", count = 70, size = { 80, 200 }, layer = "ground", anywhere = true },
    { kind = "sparkle", count = 600, size = { 1.5, 3 }, layer = "ground", anywhere = true },
    { kind = "lake", size = { 200, 200 }, layer = "ground", at = { { x = 1300, y = 2000 } } },
    { kind = "peak", count = 8, size = { 220, 340 }, solid = true, solidScale = 0.9, gap = 150,
      heightScale = 1.1, taper = 0.85 },
    { kind = "pine", count = 120, size = { 26, 42 }, solid = true, solidScale = 0.55,
      placement = "roadside", gap = 50, spread = 420, heightScale = 3, taper = 0.95 },
    { kind = "pine", count = 80, size = { 26, 42 }, solid = true, solidScale = 0.55, gap = 60,
      heightScale = 3, taper = 0.95 },
    { kind = "boulder", count = 30, size = { 20, 40 }, solid = true, solidScale = 0.85,
      placement = "roadside", gap = 50, spread = 300, heightScale = 0.7, taper = 0.5 },
    { kind = "snowman", size = { 30, 30 }, solid = true, solidScale = 0.8,
      at = { { t = 0.1, side = 1, off = 230 }, { t = 0.3, side = -1, off = 230 },
             { t = 0.55, side = 1, off = 240 }, { t = 0.8, side = -1, off = 230 } } },
    { kind = "cabin", size = { 70, 70 }, solid = true, solidScale = 0.9,
      at = { { t = 0.45, side = -1, off = 360 }, { t = 0.93, side = 1, off = 360 } } },
    { kind = "flake", count = 260, size = { 2, 5 }, layer = "high", anywhere = true },
  },

  draw = {
    drift = function(d)
      lg.rotate(d.rot)
      col("#dfeaf4"); lg.ellipse("fill", 0, 0, d.size * 1.6, d.size)
      col("#f7fbff"); lg.ellipse("fill", -d.size * 0.25, -d.size * 0.2, d.size * 1.1, d.size * 0.55)
    end,

    sparkle = function(d, t)
      lg.setColor(0.7, 0.85, 1, 0.3 + 0.4 * math.max(0, math.sin(t * 3 + d.seed)))
      lg.circle("fill", 0, 0, d.size)
    end,

    lake = function(d, t)
      local s = d.size
      col("#a7d8f0"); lg.ellipse("fill", 0, 0, s * 1.4, s)
      col("#cbeaf8"); lg.ellipse("fill", -s * 0.2, -s * 0.15, s * 1.0, s * 0.65)
      col("#ffffff", 0.7); lg.setLineWidth(2)
      lg.line(-s * 0.6, -s * 0.2, -s * 0.2, 0, -s * 0.3, s * 0.4)
      lg.line(s * 0.3, -s * 0.5, s * 0.5, -s * 0.1, s * 0.9, 0)
      -- a skater going in circles
      local a = t * 0.8
      local kx, ky = math.cos(a) * s * 0.7, math.sin(a) * s * 0.45
      col("#e53935"); lg.circle("fill", kx, ky, 9)
      col("#ffccbc"); lg.circle("fill", kx, ky, 5)
    end,

    peak = function(d)
      local p = S.blob(d, 10, 0.3)
      lg.rotate(d.rot)
      if not S.lifted then lg.setColor(0, 0, 0, 0.15); lg.polygon("fill", S.scaled(p, 1.02, 22, 28)) end
      col("#78909c"); lg.polygon("fill", p)
      col("#90a4ae"); lg.polygon("fill", S.scaled(p, 0.8, -10, -10))
      col("#ffffff"); lg.polygon("fill", S.scaled(p, 0.55, -18, -18))
      col("#e3f2fd"); lg.polygon("fill", S.scaled(p, 0.25, -24, -24))
    end,

    pine = function(d)
      local s = d.size
      S.shadow(s * 0.9, s * 0.7, 10, 14)
      lg.rotate(d.rot)
      for layer = 0, (S.sliceT and 0 or 2) do -- 3D view: one layer per slice is enough
        local r = s * (1 - layer * 0.28)
        local pts = {}
        for i = 0, 15 do
          local a = i * math.pi / 8
          local rr = (i % 2 == 0) and r or r * 0.6
          pts[#pts + 1] = math.cos(a) * rr
          pts[#pts + 1] = math.sin(a) * rr
        end
        col(layer == 1 and "#2e7d32" or "#1b5e20")
        lg.polygon("fill", S.scaled(pts, 1))
        col("#ffffff", 0.9) -- snow on the branches
        lg.circle("fill", -r * 0.35, -r * 0.3, r * 0.18)
        lg.circle("fill", r * 0.3, r * 0.15, r * 0.14)
      end
      col("#ffffff"); lg.circle("fill", 0, 0, s * 0.12)
    end,

    boulder = function(d)
      local p = S.blob(d, 8, 0.3)
      lg.rotate(d.rot)
      if not S.lifted then lg.setColor(0, 0, 0, 0.15); lg.polygon("fill", S.scaled(p, 1, 5, 7)) end
      col("#757575"); lg.polygon("fill", p)
      col("#ffffff"); lg.polygon("fill", S.scaled(p, 0.6, -d.size * 0.15, -d.size * 0.15))
    end,

    -- Snowman stands up on screen
    snowman = function(d, t, cam)
      local s = d.size
      S.shadow(s * 1.1, s * 0.5)
      S.upright(cam)
      col("#ffffff")
      lg.circle("fill", 0, -s * 0.9, s)
      lg.circle("fill", 0, -s * 2.3, s * 0.75)
      lg.circle("fill", 0, -s * 3.3, s * 0.55)
      col("#cfd8dc"); lg.setLineWidth(2)
      lg.circle("line", 0, -s * 0.9, s); lg.circle("line", 0, -s * 2.3, s * 0.75); lg.circle("line", 0, -s * 3.3, s * 0.55)
      col("#212121") -- eyes, buttons, hat
      lg.circle("fill", -s * 0.18, -s * 3.4, 3); lg.circle("fill", s * 0.18, -s * 3.4, 3)
      lg.circle("fill", 0, -s * 2.4, 3); lg.circle("fill", 0, -s * 2.1, 3)
      lg.rectangle("fill", -s * 0.55, -s * 3.85, s * 1.1, s * 0.12)
      lg.rectangle("fill", -s * 0.35, -s * 4.4, s * 0.7, s * 0.6)
      col("#ff6f00"); lg.polygon("fill", 0, -s * 3.3, s * 0.45, -s * 3.22, 0, -s * 3.15) -- carrot
      col("#e53935"); lg.rectangle("fill", -s * 0.6, -s * 2.9, s * 1.2, s * 0.18) -- scarf
      col("#5d4037"); lg.setLineWidth(3) -- stick arms (waving!)
      local wave = math.sin(t * 4 + d.seed) * s * 0.3
      lg.line(-s * 0.7, -s * 2.4, -s * 1.6, -s * 2.9 + wave)
      lg.line(s * 0.7, -s * 2.4, s * 1.6, -s * 2.8)
    end,

    -- Log cabin with smoke
    cabin = function(d, t, cam)
      local s = d.size
      S.shadow(s * 1.3, s * 0.4)
      S.upright(cam)
      col("#6d4c41"); lg.rectangle("fill", -s, -s * 1.1, s * 2, s * 1.1)
      col("#5d4037"); lg.setLineWidth(3)
      for i = 1, 4 do lg.line(-s, -i * s * 0.22, s, -i * s * 0.22) end
      col("#ffe082"); lg.rectangle("fill", -s * 0.7, -s * 0.8, s * 0.4, s * 0.35) -- window glow
      col("#4e342e"); lg.rectangle("fill", s * 0.25, -s * 0.7, s * 0.4, s * 0.7) -- door
      col("#8d6e63"); lg.rectangle("fill", s * 0.4, -s * 2, s * 0.3, s * 0.7) -- chimney
      col("#ffffff"); lg.polygon("fill", -s * 1.25, -s * 1.05, 0, -s * 1.9, s * 1.25, -s * 1.05) -- snowy roof
      for i = 0, 3 do -- smoke puffs
        local k = (t * 0.5 + i * 0.25) % 1
        lg.setColor(0.8, 0.8, 0.85, 0.7 * (1 - k))
        lg.circle("fill", s * 0.55 + math.sin(t + i) * 10 + k * 30, -s * 2.1 - k * s * 1.5, 8 + k * 16)
      end
    end,

    flake = function(d)
      col("#ffffff", 0.9); lg.circle("fill", 0, 0, d.size)
    end,
  },

  update = function(track, dt)
    for _, d in ipairs(track.layers.high) do
      if d.kind == "flake" then
        d.y = d.y + (60 + d.size * 15) * dt
        d.x = d.x + math.sin(track.time + d.seed) * 30 * dt
        S.wrap(d, track)
        d.float = ((d.float or d.seed % 260) - 50 * dt) % 260 -- falling (3D view)
      end
    end
  end,

  -- gentle cold-blue tint
  overlay = function(x, y, w, h)
    lg.setColor(0.7, 0.85, 1, 0.08)
    lg.rectangle("fill", x, y, w, h)
  end,
}
