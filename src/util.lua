-- Small helper functions used everywhere.
local U = {}

U.atan2 = math.atan2 or math.atan

function U.clamp(x, a, b)
  if x < a then return a elseif x > b then return b end
  return x
end

function U.lerp(a, b, t) return a + (b - a) * t end

function U.wrapAngle(a)
  while a > math.pi do a = a - 2 * math.pi end
  while a < -math.pi do a = a + 2 * math.pi end
  return a
end

function U.dist(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

-- "#ff8800" -> {1, 0.53, 0}
local hexCache = {}
function U.hex(h)
  if type(h) == "table" then return h end
  local c = hexCache[h]
  if c then return c end
  local s = h:gsub("#", "")
  c = {
    tonumber(s:sub(1, 2), 16) / 255,
    tonumber(s:sub(3, 4), 16) / 255,
    tonumber(s:sub(5, 6), 16) / 255,
  }
  hexCache[h] = c
  return c
end

function U.setColor(h, a)
  local c = U.hex(h)
  love.graphics.setColor(c[1], c[2], c[3], a or c[4] or 1)
end

-- f < 1 darkens, f > 1 lightens
local shadeCache = {}
function U.shade(h, f)
  local key = type(h) == "string" and (h .. f) or nil
  if key and shadeCache[key] then return shadeCache[key] end
  local c = U.hex(h)
  local out
  if f < 1 then
    out = { c[1] * f, c[2] * f, c[3] * f }
  else
    local t = f - 1
    out = { c[1] + (1 - c[1]) * t, c[2] + (1 - c[2]) * t, c[3] + (1 - c[3]) * t }
  end
  if key then shadeCache[key] = out end
  return out
end

function U.ordinal(n)
  local s = "th"
  if n % 100 < 11 or n % 100 > 13 then
    if n % 10 == 1 then s = "st" elseif n % 10 == 2 then s = "nd" elseif n % 10 == 3 then s = "rd" end
  end
  return n .. s
end

-- Repeatable random numbers (same seed = same scenery every time)
function U.newRng(seed)
  local s = math.floor(seed) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  local r = {}
  function r:random(a, b)
    s = (s * 16807) % 2147483647
    local f = (s - 1) / 2147483646
    if a == nil then return f end
    if b == nil then return 1 + math.floor(f * a) end
    return a + math.floor(f * (b - a + 1))
  end
  function r:float(a, b) return a + (b - a) * self:random() end
  return r
end

-- Draw text centered on x
function U.printCenter(text, font, x, y)
  love.graphics.setFont(font)
  love.graphics.print(text, math.floor(x - font:getWidth(text) / 2), math.floor(y))
end

-- Text with a dark outline so it reads on any background
function U.printOutlined(text, font, x, y, color, center)
  love.graphics.setFont(font)
  if center then x = x - font:getWidth(text) / 2 end
  x, y = math.floor(x), math.floor(y)
  local o = math.max(2, math.floor(font:getHeight() / 16))
  love.graphics.setColor(0, 0, 0, 0.75)
  for dx = -o, o, o do
    for dy = -o, o, o do
      if dx ~= 0 or dy ~= 0 then love.graphics.print(text, x + dx, y + dy) end
    end
  end
  U.setColor(color or "#ffffff")
  love.graphics.print(text, x, y)
end

return U
