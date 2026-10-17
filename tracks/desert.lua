-- ============================================================
--  DESERT DASH
--  To make a NEW track: copy this file (e.g. snow.lua), change the
--  points, colors and scenery, then add it to tracks/init.lua.
-- ============================================================
local U = require("src.util")
local S = require("src.scenery")
local lg = love.graphics

local function col(c, a) U.setColor(c, a) end

-- Bumpy blob shape for rocks and mesas (made once, then reused)
local function blob(d, corners, wobble)
  if d.poly then return d.poly end
  local rng = U.newRng(d.seed)
  local pts = {}
  for i = 1, corners do
    local a = (i / corners) * math.pi * 2
    local r = d.size * (1 - wobble + rng:random() * wobble)
    pts[#pts + 1] = math.cos(a) * r
    pts[#pts + 1] = math.sin(a) * r
  end
  d.poly = pts
  return pts
end

local function scaled(pts, s, ox, oy)
  local out = {}
  for i = 1, #pts, 2 do
    out[i] = pts[i] * s + (ox or 0)
    out[i + 1] = pts[i + 1] * s + (oy or 0)
  end
  return out
end

return {
  name = "Desert Dash",
  seed = 2026,
  roadWidth = 260,

  -- The road goes through these points in order (and loops back to the first).
  -- The race starts at the FIRST point, driving toward the second.
  points = {
    { 0, 0 }, { 1200, 0 }, { 2000, 150 }, { 2500, 600 }, { 2500, 1200 },
    { 2100, 1600 }, { 1500, 1600 }, { 1200, 1950 }, { 1300, 2400 },
    { 1900, 2700 }, { 2600, 2600 }, { 3200, 2900 }, { 3300, 3500 },
    { 2800, 3900 }, { 1600, 3900 }, { 600, 3700 }, { 0, 3200 },
    { -300, 2500 }, { -100, 1900 }, { -500, 1300 }, { -550, 600 },
  },

  -- Speed boost pads (0 = start line, 0.5 = halfway around)
  boosts = { 0.04, 0.42, 0.78 },

  colors = {
    sky = "#8ecae6",      -- 3D view: sky at the top...
    fog = "#f3dfb6",      -- ...and the haze far away
    ground = "#eccd8f",   -- sand
    shoulder = "#d4ab6a", -- dirt beside the road
    road = "#5f5853",
    road2 = "#635c57",
    curbA = "#e53935",
    curbB = "#fafafa",
    line = "#ffd54f",
  },

  -- What to sprinkle around the map.
  --   count = how many, size = {smallest, biggest}
  --   solid = true means cars bump into it
  --   layer = "ground" (under road), "low" (under cars), "high" (over cars)
  --   placement = "roadside" puts them near the road, otherwise anywhere
  scenery = {
    { kind = "speck", count = 1800, size = { 2, 5 }, layer = "ground", anywhere = true },
    { kind = "dune", count = 45, size = { 90, 180 }, layer = "ground", gap = 0 },
    { kind = "mesa", count = 12, size = { 170, 300 }, solid = true, solidScale = 0.9, gap = 120,
      heightScale = 0.55, taper = 0.12 },
    { kind = "oasis", count = 3, size = { 110, 140 }, gap = 140 },
    -- heightScale / taper are for the 3D view (how tall, how pointy)
    { kind = "cactus", count = 70, size = { 14, 22 }, solid = true, solidScale = 0.9,
      placement = "roadside", gap = 60, spread = 350, heightScale = 3.2 },
    { kind = "cactus", count = 50, size = { 14, 22 }, solid = true, solidScale = 0.9, gap = 60, heightScale = 3.2 },
    { kind = "rock", count = 45, size = { 18, 40 }, solid = true, solidScale = 0.85,
      placement = "roadside", gap = 50, spread = 400, heightScale = 0.8, taper = 0.55 },
    { kind = "skull", count = 8, size = { 14, 14 }, placement = "roadside", gap = 30, spread = 200 },
    { kind = "tumbleweed", count = 16, size = { 14, 20 }, layer = "high", anywhere = true, float = 0 },
  },

  -- How each kind of scenery looks (drawn at 0,0 = its middle)
  draw = {
    speck = function(d)
      col(d.seed % 2 == 0 and "#d6b475" or "#f6e0ad", 0.8)
      lg.circle("fill", 0, 0, d.size)
    end,

    dune = function(d)
      lg.rotate(d.rot)
      col("#e3c07f"); lg.ellipse("fill", 0, 0, d.size * 1.7, d.size)
      col("#f3d9a2"); lg.ellipse("fill", -d.size * 0.3, -d.size * 0.25, d.size * 1.2, d.size * 0.55)
    end,

    mesa = function(d)
      local p = blob(d, 11, 0.3)
      lg.rotate(d.rot)
      if not S.lifted then col("#000000", 0.18); lg.polygon("fill", scaled(p, 1.02, 18, 24)) end
      col("#9c4f2b"); lg.polygon("fill", scaled(p, 1.0))
      col("#c0663a"); lg.polygon("fill", scaled(p, 0.86))
      col("#d98455"); lg.polygon("fill", scaled(p, 0.7, -6, -6))
      col("#e8a173"); lg.polygon("fill", scaled(p, 0.42, -12, -12))
    end,

    rock = function(d)
      local p = blob(d, 8, 0.35)
      lg.rotate(d.rot)
      if not S.lifted then col("#000000", 0.2); lg.polygon("fill", scaled(p, 1, 5, 7)) end
      col("#8d6e63"); lg.polygon("fill", p)
      col("#a98d82"); lg.polygon("fill", scaled(p, 0.6, -d.size * 0.15, -d.size * 0.15))
    end,

    cactus = function(d)
      local s = d.size
      if not S.lifted then col("#000000", 0.2); lg.circle("fill", 5, 7, s) end
      lg.rotate(d.rot)
      -- 3D view: arms stick out only part way up (one higher than the other)
      local t3 = S.sliceT
      local armA = not t3 or (t3 > 0.35 and t3 < 0.75)
      local armB = not t3 or (t3 > 0.5 and t3 < 0.9)
      if t3 then s = s * 0.75 end
      col("#2e7d32")
      if armA then lg.circle("fill", s * 1.1, 0, s * 0.55) end   -- arms
      if armB then lg.circle("fill", -s * 1.0, s * 0.3, s * 0.5) end
      lg.circle("fill", 0, 0, s)
      col("#43a047")
      if armA then lg.circle("fill", s * 1.1, 0, s * 0.35) end
      if armB then lg.circle("fill", -s * 1.0, s * 0.3, s * 0.3) end
      lg.circle("fill", 0, 0, s * 0.7)
      col("#81c784"); lg.circle("fill", -s * 0.2, -s * 0.2, s * 0.3)
      col("#fff59d") -- little flower on top
      if d.seed % 3 == 0 then lg.circle("fill", s * 0.2, s * 0.1, s * 0.22) end
    end,

    oasis = function(d)
      local s = d.size
      col("#9ccc65"); lg.ellipse("fill", 0, 0, s * 1.35, s * 1.05)
      col("#0277bd"); lg.ellipse("fill", 0, 0, s, s * 0.7)
      col("#4fc3f7"); lg.ellipse("fill", -s * 0.1, -s * 0.08, s * 0.82, s * 0.55)
      col("#ffffff", 0.5); lg.ellipse("fill", -s * 0.35, -s * 0.25, s * 0.2, s * 0.06)
      -- palm trees
      for k = 0, 2 do
        local a = d.rot + k * 2.1
        local px, py = math.cos(a) * s * 1.15, math.sin(a) * s * 0.9
        col("#000000", 0.2); lg.circle("fill", px + 8, py + 10, s * 0.35)
        col("#2e7d32")
        for leaf = 0, 5 do
          local la = leaf * math.pi / 3 + k
          lg.push(); lg.translate(px, py); lg.rotate(la)
          lg.ellipse("fill", s * 0.22, 0, s * 0.24, s * 0.08)
          lg.pop()
        end
        col("#795548"); lg.circle("fill", px, py, s * 0.07)
      end
    end,

    skull = function(d)
      lg.rotate(d.rot)
      col("#fafafa")
      lg.ellipse("fill", 0, 0, 8, 10)
      lg.setLineWidth(3)
      lg.line(-6, -6, -16, -14, -20, -10) -- horns
      lg.line(6, -6, 16, -14, 20, -10)
      col("#5d4037")
      lg.circle("fill", -3, -1, 2); lg.circle("fill", 3, -1, 2)
    end,

    tumbleweed = function(d, t, cam)
      S.shadow(d.size, d.size * 0.4)
      S.upright(cam)
      lg.translate(0, -d.size - math.abs(math.sin(t * 4 + d.seed)) * 12) -- bouncing
      lg.rotate(t * 3 + d.rot)
      col("#a1887f"); lg.setLineWidth(2)
      lg.circle("line", 0, 0, d.size)
      lg.circle("line", d.size * 0.2, 0, d.size * 0.65)
      lg.line(-d.size, 0, d.size, 0)
      lg.line(0, -d.size, 0, d.size)
      lg.line(-d.size * 0.7, -d.size * 0.7, d.size * 0.7, d.size * 0.7)
    end,
  },

  -- Things that move: tumbleweeds blow across the desert
  update = function(track, dt)
    for _, d in ipairs(track.layers.high) do
      if d.kind == "tumbleweed" then
        d.x = d.x + (70 + d.seed % 50) * dt
        d.y = d.y + math.sin(track.time * 1.5 + d.seed) * 25 * dt
        if d.x > track.maxx then d.x = track.minx end
      end
    end
  end,
}
