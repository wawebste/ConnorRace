-- Turns a track file (tracks/*.lua) into a drivable road with scenery.
-- You normally don't need to edit this: make new tracks in the tracks folder.
local U = require("src.util")
local lg = love.graphics

local Track = {}
Track.__index = Track

local SPACING = 20 -- distance between road points

local function catmull(p0, p1, p2, p3, t)
  local t2, t3 = t * t, t * t * t
  local function f(a, b, c, d)
    return 0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
  end
  return f(p0[1], p1[1], p2[1], p3[1]), f(p0[2], p1[2], p2[2], p3[2])
end

local function resample(pts, spacing)
  local res = { { pts[1][1], pts[1][2] } }
  local n = #pts
  local carry = 0
  local px, py = pts[1][1], pts[1][2]
  for i = 2, n + 1 do
    local q = pts[(i - 1) % n + 1]
    local qx, qy = q[1], q[2]
    local seg = U.dist(px, py, qx, qy)
    while carry + seg >= spacing and seg > 0 do
      local t = (spacing - carry) / seg
      px, py = px + (qx - px) * t, py + (qy - py) * t
      res[#res + 1] = { px, py }
      seg = U.dist(px, py, qx, qy)
      carry = 0
    end
    carry = carry + seg
    px, py = qx, qy
  end
  local l = res[#res]
  if U.dist(l[1], l[2], res[1][1], res[1][2]) < spacing * 0.5 then res[#res] = nil end
  return res
end

-- Smooth curve through the control points (a closed loop)
function Track.smooth(ctrl, spacing)
  local n, out = #ctrl, {}
  for i = 1, n do
    local p0, p1 = ctrl[(i - 2) % n + 1], ctrl[i]
    local p2, p3 = ctrl[i % n + 1], ctrl[(i + 1) % n + 1]
    local steps = math.max(4, math.ceil(U.dist(p1[1], p1[2], p2[1], p2[2]) / 5))
    for s = 0, steps - 1 do
      local x, y = catmull(p0, p1, p2, p3, s / steps)
      out[#out + 1] = { x, y }
    end
  end
  return resample(out, spacing or SPACING)
end

function Track.new(data)
  local t = setmetatable({ data = data }, Track)
  t.width = data.roadWidth or 260
  t.half = t.width / 2
  t.spacing = SPACING
  t.pts = Track.smooth(data.points, SPACING)
  t.N = #t.pts
  t.nx, t.ny, t.ang = {}, {}, {}
  local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
  for i = 1, t.N do
    local a = t.pts[(i - 2) % t.N + 1]
    local b = t.pts[i % t.N + 1]
    local tx, ty = b[1] - a[1], b[2] - a[2]
    local l = math.sqrt(tx * tx + ty * ty)
    tx, ty = tx / l, ty / l
    t.nx[i], t.ny[i] = -ty, tx
    t.ang[i] = U.atan2(ty, tx)
    local p = t.pts[i]
    minx, miny = math.min(minx, p[1]), math.min(miny, p[2])
    maxx, maxy = math.max(maxx, p[1]), math.max(maxy, p[2])
  end
  local m = data.margin or 900
  t.minx, t.miny, t.maxx, t.maxy = minx - m, miny - m, maxx + m, maxy + m
  t.time = 0
  -- speed boost pads: list of spots (0 to 1 around the track)
  t.boosts = {}
  for _, b in ipairs(data.boosts or {}) do
    t.boosts[#t.boosts + 1] = t:wrap(math.floor(b * t.N) + 1)
  end
  t.physics = data.physics or {}
  t:generateScenery()
  t:buildMeshes()
  return t
end

function Track:wrap(i) return (i - 1) % self.N + 1 end

function Track:pointAt(i)
  local p = self.pts[self:wrap(i)]
  return p[1], p[2]
end

function Track:angleAt(i) return self.ang[self:wrap(i)] end

-- Closest road point. Pass "hint" (last known index) to search only nearby.
function Track:nearest(x, y, hint, window)
  local best, bd = 1, math.huge
  local pts = self.pts
  if hint then
    window = window or 40
    for k = -window, window do
      local i = (hint - 1 + k) % self.N + 1
      local p = pts[i]
      local dx, dy = p[1] - x, p[2] - y
      local d = dx * dx + dy * dy
      if d < bd then bd, best = d, i end
    end
  else
    for i = 1, self.N do
      local p = pts[i]
      local dx, dy = p[1] - x, p[2] - y
      local d = dx * dx + dy * dy
      if d < bd then bd, best = d, i end
    end
  end
  return best, math.sqrt(bd)
end

------------------------------------------------------------------ scenery

local CELL = 256
local function cellKey(cx, cy) return cx * 100000 + cy end

function Track:addSolid(d)
  self.solids[#self.solids + 1] = d
  local cx, cy = math.floor(d.x / CELL), math.floor(d.y / CELL)
  local k = cellKey(cx, cy)
  self.grid[k] = self.grid[k] or {}
  table.insert(self.grid[k], d)
end

function Track:solidsNear(x, y, fn)
  local cx, cy = math.floor(x / CELL), math.floor(y / CELL)
  for gx = cx - 2, cx + 2 do
    for gy = cy - 2, cy + 2 do
      local list = self.grid[cellKey(gx, gy)]
      if list then
        for _, d in ipairs(list) do fn(d) end
      end
    end
  end
end

-- 3D view settings for scenery (ignored in the top-down view):
--   heightScale = how tall compared to its size (cactus 2.5 = tall and thin)
--   height      = exact height instead
--   taper       = 0 straight sides, 0.9 = pointy like a cone
--   float       = how high off the ground it hovers (fish, UFOs)
function Track.setHeight(d, spec)
  d.height = spec.height or (spec.heightScale and d.size * spec.heightScale) or nil
  d.taper = spec.taper
  d.float = spec.float
end

function Track:generateScenery()
  local rng = U.newRng(self.data.seed or 1234)
  self.layers = { ground = {}, low = {}, high = {} }
  self.solids, self.grid = {}, {}
  for _, spec in ipairs(self.data.scenery or {}) do
    local placed, tries = 0, 0
    local layer = self.layers[spec.layer or "low"]

    -- "at" = put things in exact spots. Each spot is either {x=, y=} or
    -- {t=0.25, side=1, off=300}: t = how far around the track (0 to 1),
    -- side = 1 or -1 (which side of the road), off = distance from the middle of the road.
    for _, e in ipairs(spec.at or {}) do
      local x, y = e.x, e.y
      if e.t then
        local i = self:wrap(math.floor(e.t * self.N) + 1)
        local off = (e.off or 0) * (e.side or 1)
        x = self.pts[i][1] + self.nx[i] * off
        y = self.pts[i][2] + self.ny[i] * off
      end
      local size = e.size or (spec.size[1] + spec.size[2]) / 2
      local d = {
        kind = e.kind or spec.kind, x = x, y = y, size = size,
        rot = e.rot or rng:float(0, math.pi * 2), seed = rng:random(1, 100000),
        solid = spec.solid, r = size * (spec.solidScale or 1),
      }
      Track.setHeight(d, spec)
      for k, v in pairs(e) do
        if d[k] == nil then d[k] = v end
      end
      layer[#layer + 1] = d
      if spec.solid then self:addSolid(d) end
    end

    while placed < (spec.count or 0) and tries < (spec.count or 0) * 40 do
      tries = tries + 1
      local size = rng:float(spec.size[1], spec.size[2])
      local x, y
      if spec.placement == "roadside" then
        local i = rng:random(1, self.N)
        local side = rng:random() < 0.5 and -1 or 1
        local off = self.half + (spec.gap or 40) + size + rng:float(0, spec.spread or 300)
        x = self.pts[i][1] + self.nx[i] * off * side
        y = self.pts[i][2] + self.ny[i] * off * side
      else
        x = rng:float(self.minx, self.maxx)
        y = rng:float(self.miny, self.maxy)
      end
      local ok = true
      if not spec.anywhere then
        local _, dist = self:nearest(x, y)
        ok = dist > self.half + (spec.gap or 40) + size
      end
      if ok and spec.solid then
        self:solidsNear(x, y, function(o)
          if U.dist(x, y, o.x, o.y) < o.r + size + 20 then ok = false end
        end)
      end
      if ok then
        local d = {
          kind = spec.kind, x = x, y = y, size = size,
          rot = rng:float(0, math.pi * 2), seed = rng:random(1, 100000),
          solid = spec.solid, r = size * (spec.solidScale or 1),
        }
        Track.setHeight(d, spec)
        layer[#layer + 1] = d
        if spec.solid then self:addSolid(d) end
        placed = placed + 1
      end
    end
  end
end

------------------------------------------------------------------ drawing

function Track:buildMeshes()
  if not (lg and lg.newMesh) then return end
  local c = self.data.colors
  local N, pts, nx, ny = self.N, self.pts, self.nx, self.ny

  local function band(verts, i, a, b, color)
    local j = i % N + 1
    local p, q = pts[i], pts[j]
    local col = U.hex(color)
    local r, g, bl = col[1], col[2], col[3]
    local x1, y1 = p[1] + nx[i] * a, p[2] + ny[i] * a
    local x2, y2 = p[1] + nx[i] * b, p[2] + ny[i] * b
    local x3, y3 = q[1] + nx[j] * b, q[2] + ny[j] * b
    local x4, y4 = q[1] + nx[j] * a, q[2] + ny[j] * a
    local function v(x, y) verts[#verts + 1] = { x, y, 0, 0, r, g, bl, 1 } end
    v(x1, y1); v(x2, y2); v(x3, y3)
    v(x1, y1); v(x3, y3); v(x4, y4)
  end

  local h = self.half
  local shoulder, road, curbs, lines = {}, {}, {}, {}
  for i = 1, N do
    band(shoulder, i, -h - 45, h + 45, c.shoulder)
    band(road, i, -h, h, (math.floor(i / 6) % 2 == 0) and c.road or (c.road2 or c.road))
    local cc = (math.floor(i / 2) % 2 == 0) and c.curbA or c.curbB
    band(curbs, i, h - 2, h + 16, cc)
    band(curbs, i, -h - 16, -h + 2, cc)
    if i % 6 < 3 then band(lines, i, -4, 4, c.line) end
  end
  self.meshes = {}
  for _, v in ipairs({ shoulder, road, curbs, lines }) do
    table.insert(self.meshes, lg.newMesh(v, "triangles", "static"))
  end
end

function Track:drawRoad()
  lg.setColor(1, 1, 1)
  for _, m in ipairs(self.meshes) do lg.draw(m) end
  self:drawBoosts()
  -- checkered finish line
  local p = self.pts[1]
  local tx, ty = math.cos(self.ang[1]), math.sin(self.ang[1])
  local nx, ny = self.nx[1], self.ny[1]
  local sq = self.width / 16
  for row = 0, 1 do
    for colI = 0, 15 do
      if (row + colI) % 2 == 0 then lg.setColor(1, 1, 1) else lg.setColor(0.1, 0.1, 0.1) end
      local a, b = -self.half + colI * sq, (row - 1) * sq
      lg.polygon("fill",
        p[1] + nx * a + tx * b, p[2] + ny * a + ty * b,
        p[1] + nx * (a + sq) + tx * b, p[2] + ny * (a + sq) + ty * b,
        p[1] + nx * (a + sq) + tx * (b + sq), p[2] + ny * (a + sq) + ty * (b + sq),
        p[1] + nx * a + tx * (b + sq), p[2] + ny * a + ty * (b + sq))
    end
  end
end

-- Is this car driving over a boost pad?
function Track:onBoost(car)
  for _, bi in ipairs(self.boosts) do
    local d = car.idx - bi
    if d >= -1 and d <= 2 then
      local p = self.pts[bi]
      local side = (car.x - p[1]) * self.nx[bi] + (car.y - p[2]) * self.ny[bi]
      if math.abs(side) < 75 then return true end
    end
  end
  return false
end

function Track:drawBoosts()
  local color = U.hex(self.data.colors.boost or "#00e5ff")
  for _, bi in ipairs(self.boosts) do
    local p = self.pts[bi]
    local tx, ty = math.cos(self.ang[bi]), math.sin(self.ang[bi])
    local nx, ny = self.nx[bi], self.ny[bi]
    lg.setColor(0, 0, 0, 0.35)
    lg.polygon("fill",
      p[1] - nx * 75 - tx * 30, p[2] - ny * 75 - ty * 30,
      p[1] + nx * 75 - tx * 30, p[2] + ny * 75 - ty * 30,
      p[1] + nx * 75 + tx * 80, p[2] + ny * 75 + ty * 80,
      p[1] - nx * 75 + tx * 80, p[2] - ny * 75 + ty * 80)
    for k = 0, 2 do
      local glow = 0.5 + 0.5 * math.sin(self.time * 10 - k * 1.3)
      lg.setColor(color[1], color[2], color[3], 0.45 + 0.55 * glow)
      local b = -15 + k * 30
      for _, s in ipairs({ -1, 1 }) do -- each arrow is two slanted bars
        lg.polygon("fill",
          p[1] + s * nx * 60 + tx * b, p[2] + s * ny * 60 + ty * b,
          p[1] + tx * (b + 30), p[2] + ty * (b + 30),
          p[1] + tx * (b + 44), p[2] + ty * (b + 44),
          p[1] + s * nx * 60 + tx * (b + 14), p[2] + s * ny * 60 + ty * (b + 14))
      end
    end
  end
end

-- Draw one scenery layer, skipping things that are off screen
function Track:drawLayer(name, cx, cy, radius, camAngle)
  local draw = self.data.draw
  local t = self.time
  for _, d in ipairs(self.layers[name]) do
    local dx, dy = d.x - cx, d.y - cy
    local rr = radius + d.size * 2
    if dx * dx + dy * dy < rr * rr then
      local fn = draw[d.kind]
      if fn then
        lg.push()
        lg.translate(d.x, d.y)
        fn(d, t, camAngle)
        lg.pop()
      end
    end
  end
  lg.setLineWidth(1)
end

function Track:update(dt)
  self.time = self.time + dt
  if self.data.update then self.data.update(self, dt) end
end

return Track
