-- How cars move. The star ratings in cars.lua turn into real numbers here.
local U = require("src.util")

local Car = {}
Car.__index = Car

function Car.new(def, x, y, angle)
  local s = def.stats
  local c = setmetatable({}, Car)
  c.def = def
  c.x, c.y, c.angle = x, y, angle
  c.vx, c.vy = 0, 0
  c.speed = 0
  c.radius = def.width * 0.62

  -- Turn stars (1-5) into physics numbers. Tweak here to change how ALL cars feel.
  c.topSpeed = 520 + s.speed * 40        -- pixels per second
  c.accel = 260 + s.accel * 55
  c.brakePower = 900
  c.turnRate = 2.3 + s.handling * 0.17   -- radians per second
  c.grip = 4.5 + s.handling * 0.9        -- higher = less sliding
  c.offroadFactor = 0.42 + s.offroad * 0.07

  c.speedMul = 1
  c.envGrip = 1   -- set by the track (ice = slippery)
  c.envSpeed = 1  -- set by the track (water = slower)
  c.boost = 0     -- seconds of boost left
  c.onRoad = true
  c.braking = false
  return c
end

function Car:update(dt, throttle, brake, steer)
  local surface = self.onRoad and 1 or self.offroadFactor
  local top = self.topSpeed * surface * self.speedMul * self.envSpeed
  if self.boost > 0 then
    self.boost = self.boost - dt
    top = top * 1.4
    throttle = 1
  end

  -- Forward speed (before turning) decides how fast we can turn
  local fx, fy = math.cos(self.angle), math.sin(self.angle)
  local fwd = self.vx * fx + self.vy * fy
  local turnAmount = U.clamp(fwd / 140, -1, 1)
  self.angle = self.angle + steer * self.turnRate * turnAmount * dt

  -- Split velocity into "forward" and "sideways" for the new heading
  fx, fy = math.cos(self.angle), math.sin(self.angle)
  local rx, ry = -fy, fx
  fwd = self.vx * fx + self.vy * fy
  local lat = self.vx * rx + self.vy * ry

  if throttle > 0 and fwd < top then
    local push = self.boost > 0 and 2.5 or 1
    fwd = math.min(top, fwd + self.accel * push * throttle * dt)
  end
  self.braking = false
  if brake > 0 then
    if fwd > 15 then
      fwd = fwd - self.brakePower * brake * dt
      self.braking = true
    else
      fwd = math.max(-top * 0.35, fwd - self.accel * 0.7 * brake * dt) -- reverse
    end
  end
  if throttle == 0 and brake == 0 then
    fwd = fwd - fwd * math.min(1, 0.9 * dt) -- coasting
  end
  if fwd > top then
    fwd = fwd - (fwd - top) * math.min(1, 2.5 * dt) -- slowing down in sand
  end

  lat = lat * math.exp(-self.grip * self.envGrip * (self.onRoad and 1 or 0.8) * dt)

  self.vx = fx * fwd + rx * lat
  self.vy = fy * fwd + ry * lat
  self.x = self.x + self.vx * dt
  self.y = self.y + self.vy * dt
  self.speed = fwd
end

-- Bounce two cars off each other
function Car.collide(a, b)
  local dx, dy = b.x - a.x, b.y - a.y
  local d = math.sqrt(dx * dx + dy * dy)
  local minD = a.radius + b.radius
  if d >= minD or d < 0.001 then return false end
  local nx, ny = dx / d, dy / d
  local push = (minD - d) / 2
  a.x, a.y = a.x - nx * push, a.y - ny * push
  b.x, b.y = b.x + nx * push, b.y + ny * push
  local rel = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny
  if rel < 0 then
    local j = -1.4 * rel / 2
    a.vx, a.vy = a.vx - j * nx, a.vy - j * ny
    b.vx, b.vy = b.vx + j * nx, b.vy + j * ny
  end
  return rel < -120
end

-- Bounce off a solid thing (rock, cactus...) at ox,oy with radius r
function Car:hitObstacle(ox, oy, r)
  local dx, dy = self.x - ox, self.y - oy
  local d = math.sqrt(dx * dx + dy * dy)
  local minD = self.radius * 0.8 + r
  if d >= minD or d < 0.001 then return false end
  local nx, ny = dx / d, dy / d
  self.x, self.y = ox + nx * minD, oy + ny * minD
  local vn = self.vx * nx + self.vy * ny
  if vn < 0 then
    self.vx = (self.vx - 1.5 * vn * nx) * 0.6
    self.vy = (self.vy - 1.5 * vn * ny) * 0.6
  end
  return vn < -100
end

return Car
