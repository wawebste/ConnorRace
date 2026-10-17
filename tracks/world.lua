-- ============================================================
--  AROUND THE WORLD
--  Race through 8 countries and over the oceans between them!
--  To add a country: add it to COUNTRIES, then add a landmark
--  and a sign at the same t (how far around the track, 0 to 1).
-- ============================================================
local S = require("src.scenery")
local lg = love.graphics
local col = S.col

-- Countries! t = where on the track (0 to 1), size = how big the land is
local COUNTRIES = {
  { t = 0.00, size = 1300, color = "#7cb342" },   -- USA
  { t = 0.95, size = 1100, color = "#7cb342" },   -- USA (west)
  { t = 0.16, size = 760,  color = "#66bb6a" },   -- England
  { t = 0.21, size = 700,  color = "#9ccc65" },   -- France
  { t = 0.335, size = 1100, color = "#e6c27a", desert = true }, -- Egypt
  { t = 0.45, size = 900,  color = "#aed581" },   -- India
  { t = 0.55, size = 1100, color = "#8bc34a" },   -- China
  { t = 0.66, size = 700,  color = "#81c784" },   -- Japan
  { t = 0.80, size = 1250, color = "#d9a35f", desert = true }, -- Australia
}

-- Landmarks stand up on screen. Each one is drawn with its bottom at 0,0.
local landmarks = {}

landmarks.liberty = function(s, t)
  col("#8d8d8d"); lg.rectangle("fill", -s * 0.8, -s * 1.4, s * 1.6, s * 1.4)       -- pedestal
  col("#9e9e9e"); lg.rectangle("fill", -s, -s * 0.3, s * 2, s * 0.3)
  col("#4db6ac")
  lg.polygon("fill", -s * 0.55, -s * 1.4, s * 0.55, -s * 1.4, s * 0.25, -s * 3.6, -s * 0.25, -s * 3.6) -- robe
  lg.circle("fill", 0, -s * 3.85, s * 0.3)                                            -- head
  for i = -2, 2 do                                                                     -- crown
    lg.polygon("fill", i * s * 0.12 - 4, -s * 4.05, i * s * 0.12 + 4, -s * 4.05, i * s * 0.25, -s * 4.5)
  end
  lg.setLineWidth(s * 0.18); lg.line(s * 0.2, -s * 3.4, s * 0.55, -s * 4.6)          -- arm
  col("#ffb300"); lg.circle("fill", s * 0.6, -s * 4.85 + math.sin(t * 8) * 2, s * 0.2) -- torch flame
  col("#26a69a"); lg.rectangle("fill", -s * 0.5, -s * 2.7, s * 0.35, s * 0.5)         -- book
end

landmarks.bigben = function(s)
  col("#c8a96a"); lg.rectangle("fill", -s * 0.5, -s * 4.2, s, s * 4.2)
  col("#b08f52")
  for i = 1, 6 do lg.rectangle("fill", -s * 0.5, -i * s * 0.6, s, 3) end
  col("#fafafa"); lg.circle("fill", 0, -s * 3.6, s * 0.38)
  col("#212121"); lg.setLineWidth(3)
  lg.circle("line", 0, -s * 3.6, s * 0.38)
  lg.line(0, -s * 3.6, 0, -s * 3.85); lg.line(0, -s * 3.6, s * 0.18, -s * 3.6)
  col("#546e7a"); lg.polygon("fill", -s * 0.55, -s * 4.2, s * 0.55, -s * 4.2, 0, -s * 5.6)
  col("#ffd54f"); lg.circle("fill", 0, -s * 5.6, 4)
end

landmarks.eiffel = function(s)
  col("#8d6e63")
  lg.polygon("fill", -s * 1.1, 0, -s * 0.7, 0, -s * 0.15, -s * 3, -s * 0.35, -s * 3)   -- left leg
  lg.polygon("fill", s * 1.1, 0, s * 0.7, 0, s * 0.15, -s * 3, s * 0.35, -s * 3)       -- right leg
  lg.polygon("fill", -s * 0.35, -s * 3, s * 0.35, -s * 3, s * 0.08, -s * 5, -s * 0.08, -s * 5)
  lg.rectangle("fill", -s * 0.85, -s * 1.15, s * 1.7, s * 0.18)                          -- 1st floor
  lg.rectangle("fill", -s * 0.45, -s * 2.6, s * 0.9, s * 0.15)                           -- 2nd floor
  lg.setLineWidth(3); lg.line(0, -s * 5, 0, -s * 5.5)
  col("#e8d6c9"); lg.arc("fill", 0, 0, s * 0.55, math.pi, math.pi * 2)                   -- arch
  col("#6d4c41"); lg.setLineWidth(1)
  for i = 0, 5 do lg.line(-s * 0.7 + i * s * 0.12, -i * s * 0.5, s * 0.7 - i * s * 0.12, -i * s * 0.5 - s * 0.5) end
end

landmarks.pyramids = function(s)
  local function pyr(x, w)
    col("#e0b866"); lg.polygon("fill", x - w, 0, x + w, 0, x, -w * 0.95)
    col("#c49a4a"); lg.polygon("fill", x, 0, x + w, 0, x, -w * 0.95)
  end
  pyr(s * 1.4, s * 0.7)
  pyr(-s * 0.2, s * 1.2)
  pyr(-s * 1.6, s * 0.55)
end

landmarks.taj = function(s)
  col("#fafafa")
  lg.rectangle("fill", -s * 1.3, -s * 0.15, s * 2.6, s * 0.15)
  lg.rectangle("fill", -s * 0.8, -s * 1.3, s * 1.6, s * 1.2)
  lg.circle("fill", 0, -s * 1.6, s * 0.6)                    -- big dome
  lg.polygon("fill", -s * 0.2, -s * 2.1, s * 0.2, -s * 2.1, 0, -s * 2.6)
  for _, x in ipairs({ -1.15, 1.15 }) do                     -- towers
    lg.rectangle("fill", x * s - s * 0.08, -s * 2.1, s * 0.16, s * 2)
    lg.circle("fill", x * s, -s * 2.15, s * 0.13)
  end
  col("#b0bec5"); lg.arc("fill", 0, -s * 0.15, s * 0.3, math.pi, math.pi * 2) -- door arch
  col("#90caf9", 0.6); lg.rectangle("fill", -s * 1.2, 0, s * 2.4, s * 0.25)  -- reflecting pool
end

landmarks.greatwall = function(s)
  col("#a1887f")
  lg.polygon("fill", -s * 2, 0, s * 2, -s * 0.6, s * 2, 0, -s * 2, s * 0.6)
  lg.polygon("fill", -s * 2, -s * 0.6, s * 2, -s * 1.2, s * 2, -s * 0.6, -s * 2, 0)
  col("#8d6e63")
  for i = 0, 9 do -- bumpy top
    local x = -s * 2 + i * s * 0.42
    lg.rectangle("fill", x, -s * 0.6 - (x + s * 2) / (s * 4) * s * 0.6 - s * 0.12, s * 0.2, s * 0.16)
  end
  col("#795548") -- watch towers
  lg.rectangle("fill", -s * 1.9, -s * 1.1, s * 0.5, s * 1.1)
  lg.rectangle("fill", s * 1.2, -s * 1.6, s * 0.5, s * 1.1)
  col("#5d4037")
  lg.rectangle("fill", -s * 1.75, -s * 0.85, s * 0.2, s * 0.25)
  lg.rectangle("fill", s * 1.35, -s * 1.35, s * 0.2, s * 0.25)
end

landmarks.fuji = function(s)
  col("#5c6bc0"); lg.polygon("fill", -s * 1.8, 0, -s * 0.35, -s * 1.5, s * 0.35, -s * 1.5, s * 1.8, 0)
  col("#ffffff")
  lg.polygon("fill", -s * 0.35, -s * 1.5, s * 0.35, -s * 1.5, s * 0.6, -s * 1.15, s * 0.3, -s * 1.25,
    0, -s * 1.1, -s * 0.3, -s * 1.25, -s * 0.6, -s * 1.15)
  col("#e53935"); lg.circle("fill", s * 1.2, -s * 1.6, s * 0.25) -- rising sun
  col("#f48fb1") -- cherry blossom tree
  lg.circle("fill", -s * 1.5, -s * 0.5, s * 0.25)
  lg.circle("fill", -s * 1.3, -s * 0.6, s * 0.22)
  col("#6d4c41"); lg.rectangle("fill", -s * 1.43, -s * 0.35, 5, s * 0.35)
end

landmarks.opera = function(s)
  col("#90a4ae"); lg.rectangle("fill", -s * 1.6, -s * 0.3, s * 3.2, s * 0.3)
  local function sail(x, w, h)
    col("#fafafa"); lg.polygon("fill", x - w, -s * 0.3, x + w * 0.6, -s * 0.3, x + w * 0.2, -s * 0.3 - h)
    col("#e0e0e0"); lg.polygon("fill", x + w * 0.2, -s * 0.3 - h, x + w * 0.6, -s * 0.3, x + w * 0.1, -s * 0.3)
  end
  sail(-s * 0.9, s * 0.45, s * 0.9)
  sail(-s * 0.2, s * 0.55, s * 1.3)
  sail(s * 0.6, s * 0.5, s * 1.1)
  sail(s * 1.2, s * 0.35, s * 0.7)
end

-- Same bumpy shape for a country's beach and its land
local function landShape(d)
  if not d.shape then
    d.shape = S.blob({ seed = math.floor(d.t * 1000) + 7, size = d.size }, 16, 0.22)
  end
  return d.shape
end

-- Little picture for each place that you see while driving
local function sign(d, cam)
  local w = Game.font(30):getWidth(d.text) / 2 + 16
  S.shadow(30, 10)
  S.upright(cam)
  col("#6d4c41"); lg.rectangle("fill", -5, -90, 10, 90)
  col("#000000", 0.3); lg.rectangle("fill", -w + 4, -150, w * 2, 56, 10, 10)
  col(d.color or "#1565c0"); lg.rectangle("fill", -w, -154, w * 2, 56, 10, 10)
  S.text(d.text, 30, 0, -126, "#ffffff")
end

return {
  name = "Around the World",
  seed = 8080,
  roadWidth = 280,
  margin = 1400,

  points = {
    { 0, 0 }, { 1500, 0 }, { 2800, -300 }, { 4000, 0 }, { 5000, 600 }, { 5600, 1500 },
    { 5400, 2600 }, { 5800, 3600 }, { 5300, 4600 }, { 4000, 5000 }, { 2600, 4700 },
    { 1500, 5100 }, { 300, 4800 }, { -500, 4000 }, { -400, 3000 }, { -900, 2000 }, { -700, 900 },
  },

  boosts = { 0.1, 0.27, 0.4, 0.6, 0.72, 0.88 },
  physics = { speed = 1.0, grip = 1.0 },

  colors = {
    sky = "#7cc6f2",      -- 3D view
    fog = "#cde8fb",
    ground = "#1e88e5",   -- ocean (the land is drawn on top)
    shoulder = "#b0bec5", -- bridge edges
    road = "#4e5459",
    road2 = "#53595e",
    curbA = "#ffffff",
    curbB = "#e53935",
    line = "#ffeb3b",
    boost = "#00e5ff",
  },

  scenery = {
    { kind = "wave", count = 900, size = { 8, 16 }, layer = "ground", anywhere = true },

    -- Countries are listed in COUNTRIES at the top of this file
    { kind = "beach", layer = "ground", size = { 1000, 1000 }, at = COUNTRIES },
    { kind = "land", layer = "ground", size = { 1000, 1000 }, at = COUNTRIES },

    { kind = "landmark", solid = true, solidScale = 0.5, size = { 50, 50 }, at = {
      { t = 0.03, side = -1, off = 420, size = 55, which = "liberty" },
      { t = 0.16, side = 1, off = 400, size = 55, which = "bigben" },
      { t = 0.21, side = -1, off = 420, size = 60, which = "eiffel" },
      { t = 0.335, side = 1, off = 560, size = 110, which = "pyramids" },
      { t = 0.45, side = -1, off = 460, size = 80, which = "taj" },
      { t = 0.55, side = 1, off = 480, size = 110, which = "greatwall" },
      { t = 0.66, side = -1, off = 520, size = 130, which = "fuji" },
      { t = 0.80, side = 1, off = 520, size = 110, which = "opera" },
    } },

    { kind = "sign", size = { 30, 30 }, at = {
      { t = 0.012, side = 1, off = 240, text = "USA", color = "#1565c0" },
      { t = 0.145, side = -1, off = 240, text = "ENGLAND", color = "#c62828" },
      { t = 0.195, side = 1, off = 240, text = "FRANCE", color = "#1565c0" },
      { t = 0.295, side = -1, off = 240, text = "EGYPT", color = "#f9a825" },
      { t = 0.435, side = 1, off = 240, text = "INDIA", color = "#ef6c00" },
      { t = 0.535, side = -1, off = 240, text = "CHINA", color = "#c62828" },
      { t = 0.645, side = 1, off = 240, text = "JAPAN", color = "#c62828" },
      { t = 0.78, side = -1, off = 240, text = "AUSTRALIA", color = "#2e7d32" },
    } },

    { kind = "camel", size = { 28, 28 }, at = {
      { t = 0.35, side = -1, off = 330 }, { t = 0.36, side = -1, off = 420 },
    } },
    { kind = "kangaroo", size = { 26, 26 }, at = {
      { t = 0.82, side = -1, off = 300 }, { t = 0.77, side = 1, off = 330 },
    } },
    { kind = "boat", size = { 40, 60 }, height = 14, at = {
      { t = 0.08, side = 1, off = 650 }, { t = 0.1, side = -1, off = 800 },
      { t = 0.265, side = -1, off = 600 }, { t = 0.71, side = 1, off = 700 },
      { t = 0.875, side = -1, off = 650 }, { t = 0.89, side = 1, off = 900 },
    } },
    { kind = "whale", size = { 50, 50 }, at = { { t = 0.09, side = -1, off = 450 }, { t = 0.715, side = -1, off = 500 } } },

    { kind = "cloud", count = 22, size = { 90, 170 }, layer = "high", anywhere = true, float = 420 },
    { kind = "plane", count = 3, size = { 40, 40 }, layer = "high", anywhere = true, float = 300 },
  },

  draw = {
    wave = function(d)
      col("#90caf9", 0.6); lg.setLineWidth(2)
      lg.arc("line", "open", 0, 0, d.size, math.pi * 1.2, math.pi * 1.8)
      lg.arc("line", "open", d.size * 1.6, 0, d.size, math.pi * 1.2, math.pi * 1.8)
    end,

    beach = function(d)
      col("#f5e0a8"); lg.polygon("fill", S.scaled(landShape(d), 1.06))
    end,

    land = function(d)
      local p = landShape(d)
      col(d.color); lg.polygon("fill", p)
      -- trees (or dunes in the desert)
      if not d.trees then
        local rng = require("src.util").newRng(d.seed)
        d.trees = {}
        for i = 1, math.floor(d.size / 25) do
          local a, r = rng:float(0, 6.28), rng:float(0, d.size * 0.8)
          d.trees[i] = { math.cos(a) * r, math.sin(a) * r, rng:float(14, 26) }
        end
      end
      for _, tr in ipairs(d.trees) do
        if d.desert then
          col("#f0d494"); lg.ellipse("fill", tr[1], tr[2], tr[3] * 2.5, tr[3])
        else
          lg.setColor(0, 0, 0, 0.15); lg.circle("fill", tr[1] + 5, tr[2] + 6, tr[3])
          col("#388e3c"); lg.circle("fill", tr[1], tr[2], tr[3])
          col("#66bb6a"); lg.circle("fill", tr[1] - 4, tr[2] - 4, tr[3] * 0.5)
        end
      end
    end,

    landmark = function(d, t, cam)
      S.shadow(d.size * 1.6, d.size * 0.45)
      S.upright(cam)
      landmarks[d.which](d.size, t)
    end,

    sign = function(d, t, cam) sign(d, cam) end,

    camel = function(d, t, cam)
      local s = d.size
      S.shadow(s * 1.2, s * 0.3)
      S.upright(cam)
      local step = math.sin(t * 4 + d.seed) * 4
      col("#c19a5b")
      lg.setLineWidth(5)
      lg.line(-s * 0.6, 0, -s * 0.6 + step, -s * 1.1); lg.line(s * 0.6, 0, s * 0.6 - step, -s * 1.1)
      lg.ellipse("fill", 0, -s * 1.3, s, s * 0.45)
      lg.ellipse("fill", -s * 0.1, -s * 1.7, s * 0.4, s * 0.35) -- hump
      lg.line(s * 0.8, -s * 1.3, s * 1.2, -s * 2.1)            -- neck
      lg.ellipse("fill", s * 1.35, -s * 2.15, s * 0.3, s * 0.18)
      col("#212121"); lg.circle("fill", s * 1.4, -s * 2.22, 2)
    end,

    kangaroo = function(d, t, cam)
      local s = d.size
      local hop = math.abs(math.sin(t * 4 + d.seed)) * s * 0.8
      S.shadow(s * 0.8, s * 0.25)
      S.upright(cam)
      lg.translate(0, -hop)
      col("#a1683a")
      lg.setLineWidth(6); lg.line(-s * 0.3, -s * 0.8, -s * 1.3, -s * 0.1) -- tail
      lg.ellipse("fill", 0, -s * 1.0, s * 0.45, s * 0.75)                -- body
      lg.ellipse("fill", s * 0.25, -s * 0.15, s * 0.45, s * 0.15)        -- foot
      lg.circle("fill", s * 0.3, -s * 1.85, s * 0.3)                     -- head
      lg.ellipse("fill", s * 0.15, -s * 2.25, s * 0.08, s * 0.22)        -- ears
      lg.ellipse("fill", s * 0.35, -s * 2.25, s * 0.08, s * 0.22)
      col("#212121"); lg.circle("fill", s * 0.4, -s * 1.9, 2)
    end,

    boat = function(d, t)
      lg.rotate(d.rot + math.sin(t * 0.3 + d.seed) * 0.3)
      local s = d.size
      col("#ffffff", 0.5); lg.ellipse("fill", -s * 1.3, 0, s * 0.6, s * 0.25) -- wake
      col("#6d4c41"); lg.polygon("fill", s, 0, s * 0.5, -s * 0.35, -s * 0.9, -s * 0.35, -s * 0.9, s * 0.35, s * 0.5, s * 0.35)
      col("#fafafa"); lg.polygon("fill", s * 0.4, -s * 0.05, -s * 0.5, -s * 0.9, -s * 0.5, -s * 0.05)
      col("#ef5350"); lg.polygon("fill", s * 0.4, s * 0.05, -s * 0.5, s * 0.8, -s * 0.5, s * 0.05)
    end,

    whale = function(d, t)
      local s = d.size
      local up = (math.sin(t * 0.7 + d.seed) + 1) / 2
      col("#37474f"); lg.ellipse("fill", 0, 0, s * 1.8, s * 0.7)
      col("#546e7a"); lg.ellipse("fill", -s * 0.3, -s * 0.15, s * 1.1, s * 0.35)
      col("#e3f2fd", up) -- water spout!
      for i = 0, 3 do lg.circle("fill", s * 0.8 + math.cos(i * 1.6) * 14 * up, math.sin(i * 1.6) * 14 * up, 8 * up) end
    end,

    cloud = function(d)
      lg.setColor(0, 0, 0, 0.08) -- shadow far below
      lg.ellipse("fill", 120, 160, d.size * 1.3, d.size * 0.6)
      lg.setColor(1, 1, 1, 0.35)
      lg.circle("fill", 0, 0, d.size * 0.6)
      lg.circle("fill", d.size * 0.6, d.size * 0.1, d.size * 0.45)
      lg.circle("fill", -d.size * 0.6, d.size * 0.15, d.size * 0.4)
    end,

    plane = function(d)
      local s = d.size
      lg.rotate(d.dir or 0)
      lg.setColor(0, 0, 0, 0.12); lg.ellipse("fill", 90, 120, s * 1.2, s * 0.3)
      col("#eceff1")
      lg.ellipse("fill", 0, 0, s * 1.3, s * 0.2)
      lg.polygon("fill", s * 0.2, 0, -s * 0.3, -s * 1.2, -s * 0.5, -s * 1.2, -s * 0.2, 0)
      lg.polygon("fill", s * 0.2, 0, -s * 0.3, s * 1.2, -s * 0.5, s * 1.2, -s * 0.2, 0)
      lg.polygon("fill", -s * 1, 0, -s * 1.3, -s * 0.45, -s * 1.4, -s * 0.45, -s * 1.25, 0)
      lg.polygon("fill", -s * 1, 0, -s * 1.3, s * 0.45, -s * 1.4, s * 0.45, -s * 1.25, 0)
      col("#e53935"); lg.ellipse("fill", s * 1.05, 0, s * 0.2, s * 0.12)
    end,
  },

  update = function(track, dt)
    for _, d in ipairs(track.layers.high) do
      if d.kind == "cloud" then
        d.x = d.x + 40 * dt
        S.wrap(d, track)
      elseif d.kind == "plane" then
        d.dir = d.dir or d.rot
        d.x = d.x + math.cos(d.dir) * 300 * dt
        d.y = d.y + math.sin(d.dir) * 300 * dt
        S.wrap(d, track)
      end
    end
  end,
}
