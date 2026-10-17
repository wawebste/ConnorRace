-- Handy drawing helpers for track scenery (used by the track files).
local U = require("src.util")
local lg = love.graphics

local S = {}

function S.col(c, a) U.setColor(c, a) end

-- In the 3D view, solid things are drawn as a stack of layers.
--   S.lifted = true for every layer except the bottom one
--   S.sliceT = 0 (bottom) to 1 (top) while stacking, nil otherwise
-- Drawings can use these, e.g. cactus arms only in the middle layers.

-- Bumpy blob shape (made once per item, then reused)
function S.blob(d, corners, wobble, key)
  key = key or "poly"
  if d[key] then return d[key] end
  local rng = U.newRng(d.seed + #key)
  local pts = {}
  for i = 1, corners do
    local a = (i / corners) * math.pi * 2
    local r = d.size * (1 - wobble + rng:random() * wobble)
    pts[#pts + 1] = math.cos(a) * r
    pts[#pts + 1] = math.sin(a) * r
  end
  d[key] = pts
  return pts
end

function S.scaled(pts, s, ox, oy)
  local out = {}
  for i = 1, #pts, 2 do
    out[i] = pts[i] * s + (ox or 0)
    out[i + 1] = pts[i + 1] * s + (oy or 0)
  end
  return out
end

-- Soft shadow on the ground
-- (In the 3D view, stacked copies above the ground skip their shadow.)
function S.shadow(w, h, ox, oy, a)
  if S.lifted then return end
  lg.setColor(0, 0, 0, a or 0.2)
  lg.ellipse("fill", ox or 0, oy or 0, w, h)
end

-- Call this inside a scenery drawing to make it stand UP on the screen
-- (like a sticker) instead of being seen from above. "up" is negative y.
function S.upright(camAngle)
  if S.billboard3d then S.billboard3d() return end -- 3D view: face the camera
  lg.rotate((camAngle or -math.pi / 2) + math.pi / 2)
end

-- Text drawn in the world (for signs)
function S.text(str, size, x, y, color)
  local f = Game.font(size)
  lg.setFont(f)
  S.col(color or "#ffffff")
  lg.print(str, math.floor(x - f:getWidth(str) / 2), math.floor(y - f:getHeight() / 2))
end

-- Make things wrap around the map edges (for things that move)
function S.wrap(d, track)
  if d.x > track.maxx then d.x = track.minx elseif d.x < track.minx then d.x = track.maxx end
  if d.y > track.maxy then d.y = track.miny elseif d.y < track.miny then d.y = track.maxy end
end

return S
