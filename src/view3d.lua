-- 3D "chase camera" view: the camera sits up and behind your car.
--
-- How it works (you don't need to understand this to make tracks!):
--  * The track's normal 2D drawings are laid flat on a 3D floor by a shader.
--  * Things with a "height" (cacti, rocks, cars...) are drawn many times,
--    each copy a little higher, so they look solid. ("sprite stacking")
--  * Drawings that call S.upright() stand up and face the camera.
local U = require("src.util")
local S = require("src.scenery")
local CarDraw = require("src.cardraw")
local config = require("config")
local lg = love.graphics

local V = {}

local SHADER = [[
uniform mat4 projView;
uniform mat4 model;
uniform float lift;
uniform vec3 camPos;
uniform float flipY;
varying float vDist;
#ifdef VERTEX
vec4 position(mat4 tp, vec4 vp) {
  vec4 p = TransformMatrix * vp;
  vec4 w = model * vec4(p.x, p.y, 0.0, 1.0);
  w.z -= lift;
  vDist = distance(w.xyz, camPos);
  vec4 o = projView * w;
  o.y *= flipY;
  return o;
}
#endif
#ifdef PIXEL
uniform vec3 fogColor;
uniform vec2 fogRange;
uniform float shade;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 c = Texel(tex, tc) * color;
  c.rgb *= shade;
  float f = clamp((vDist - fogRange.x) / (fogRange.y - fogRange.x), 0.0, 1.0);
  c.rgb = mix(c.rgb, fogColor, f);
  return c;
}
#endif
]]

local shader
local IDENT = { { 1, 0, 0, 0 }, { 0, 1, 0, 0 }, { 0, 0, 1, 0 }, { 0, 0, 0, 1 } }
V.flipY = -1 -- canvases in LÖVE are upside down compared to the screen

local last = {} -- skip re-sending the same number (keeps drawing fast)
local function send(name, ...)
  local v = ...
  if type(v) == "number" then
    if last[name] == v then return end
    last[name] = v
  else
    last.lift, last.shade = nil, nil
  end
  if shader:hasUniform(name) then shader:send(name, ...) end
end

local function mul(a, b)
  local r = {}
  for i = 1, 4 do
    r[i] = {}
    for j = 1, 4 do
      local s = 0
      for k = 1, 4 do s = s + a[i][k] * b[k][j] end
      r[i][j] = s
    end
  end
  return r
end

local function perspective(fovy, aspect, n, f)
  local t = math.tan(fovy / 2)
  return {
    { 1 / (aspect * t), 0, 0, 0 },
    { 0, 1 / t, 0, 0 },
    { 0, 0, (f + n) / (n - f), 2 * f * n / (n - f) },
    { 0, 0, -1, 0 },
  }
end

local function norm(x, y, z)
  local l = math.sqrt(x * x + y * y + z * z)
  return x / l, y / l, z / l
end

local function cross(ax, ay, az, bx, by, bz)
  return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

-- In this world "up" is -z (so the old top-down view isn't mirrored)
local function lookDir(ex, ey, ez, fx, fy, fz)
  local rx, ry, rz = norm(cross(fx, fy, fz, 0, 0, -1))
  local ux, uy, uz = cross(rx, ry, rz, fx, fy, fz)
  return {
    { rx, ry, rz, -(rx * ex + ry * ey + rz * ez) },
    { ux, uy, uz, -(ux * ex + uy * ey + uz * ez) },
    { -fx, -fy, -fz, (fx * ex + fy * ey + fz * ez) },
    { 0, 0, 0, 1 },
  }
end

function V.load()
  if shader then return end
  shader = lg.newShader(SHADER)
end

------------------------------------------------------------------ camera

function V.setupCamera(v, car, cam, pw, ph)
  local aspect = pw / ph
  local fovy = U.clamp(2 * math.atan(1 / aspect), math.rad(40), math.rad(62))
  local dist = config.chaseDistance or 210
  local h = config.chaseHeight or 210
  local a = cam.angle
  local fx, fy = math.cos(a), math.sin(a)
  local ex, ey, ez = car.x - fx * dist, car.y - fy * dist, -h
  -- tilt the camera so the car sits at "cameraBehind" down the screen
  local down = math.atan(h / dist)
  local anchor = config.cameraBehind or 0.78
  local pitch = down - math.atan((2 * anchor - 1) * math.tan(fovy / 2))
  local cp = math.cos(pitch)
  cam.eye = { ex, ey, ez }
  cam.fwd = { fx, fy }
  cam.right = { -fy, fx }
  cam.projView = mul(perspective(fovy, aspect, 4, 8000), lookDir(ex, ey, ez, fx * cp, fy * cp, math.sin(pitch)))
end

-- World point -> position inside the view (for name tags). nil if behind camera.
function V.project(v, cam, x, y, z)
  local m = cam.projView
  local X = m[1][1] * x + m[1][2] * y + m[1][3] * z + m[1][4]
  local Y = m[2][1] * x + m[2][2] * y + m[2][3] * z + m[2][4]
  local W = m[4][1] * x + m[4][2] * y + m[4][3] * z + m[4][4]
  if W <= 1 then return nil end
  return v.x + (X / W + 1) / 2 * v.w, v.y + (1 - Y / W) / 2 * v.h
end

------------------------------------------------------------------ drawing

local current -- the scenery item being drawn (for billboards)
local function billboard()
  S.usedUpright = true
  lg.setDepthMode("lequal", false) -- hidden behind solid things, drawn back-to-front
  local cam = V.cam
  send("model", "row", {
    { cam.right[1], 0, 0, current.x },
    { cam.right[2], 0, 0, current.y },
    { 0, 1, 0, 0 },
    { 0, 0, 0, 1 },
  })
  lg.origin()
end

local function itemHeight(d)
  return d.height or 0
end

-- Draw one item, stacked into a solid shape if it has a height
local function drawItem(fn, d, t, base)
  current = d
  local h = itemHeight(d)
  if h > 0 and not d.isUpright then
    lg.setDepthMode("lequal", true)
    -- fewer layers for things far away (they're small on screen anyway)
    local dist2 = (d.x - V.cam.eye[1]) ^ 2 + (d.y - V.cam.eye[2]) ^ 2
    local step, maxN = 3, 24
    if dist2 > 1600 * 1600 then step, maxN = 14, 5
    elseif dist2 > 800 * 800 then step, maxN = 7, 10 end
    local n = U.clamp(math.floor(h / step), 2, maxN)
    n = math.min(30, math.max(n, math.ceil(h / 12))) -- big things (mountains) need enough layers
    for k = 0, n do
      S.lifted, S.usedUpright = k > 0, false
      S.sliceT = k / n
      send("lift", base + h * k / n)
      send("shade", 0.68 + 0.32 * k / n)
      local sc = 1 - (d.taper or 0) * k / n
      lg.push(); lg.translate(d.x, d.y); lg.scale(sc)
      fn(d, t, -math.pi / 2)
      lg.pop()
      if S.usedUpright then
        d.isUpright = true
        send("model", "row", IDENT)
        break
      end
    end
    S.lifted, S.sliceT = false, nil
    send("shade", 1)
  else
    -- flat things lie on the ground; they hide behind solid things but don't hide anything
    lg.setDepthMode("lequal", false)
    S.usedUpright = false
    send("lift", base)
    lg.push(); lg.translate(d.x, d.y)
    fn(d, t, -math.pi / 2)
    lg.pop()
    if S.usedUpright then send("model", "row", IDENT) end
  end
end

-- Stand-up pictures are saved for last, then drawn far-to-near
local standUps = {}

local function drawLayer(track, name, cx, cy, r)
  local draw = track.data.draw
  local t = track.time
  for _, d in ipairs(track.layers[name]) do
    local dx, dy = d.x - cx, d.y - cy
    local rr = r + d.size * 2
    if dx * dx + dy * dy < rr * rr then
      local fn = draw[d.kind]
      if fn then
        local base = d.float or (name == "high" and 30 or 0)
        if d.isUpright then
          standUps[#standUps + 1] = { d = d, fn = fn, base = base }
        else
          drawItem(fn, d, t, base)
          if S.usedUpright then d.isUpright = true end
        end
      end
    end
  end
  send("lift", 0)
  lg.setLineWidth(1)
end

local function drawStandUps(track)
  local ex, ey = V.cam.eye[1], V.cam.eye[2]
  for _, it in ipairs(standUps) do
    it.dist = (it.d.x - ex) ^ 2 + (it.d.y - ey) ^ 2
  end
  table.sort(standUps, function(a, b) return a.dist > b.dist end)
  for _, it in ipairs(standUps) do drawItem(it.fn, it.d, track.time, it.base) end
  standUps = {}
  send("lift", 0)
  lg.setLineWidth(1)
end

local function drawCar(car)
  if car.boost > 0 then -- rocket flames
    send("lift", 6)
    local fx, fy = math.cos(car.angle), math.sin(car.angle)
    local bx, by = car.x - fx * car.def.length * 0.55, car.y - fy * car.def.length * 0.55
    local flick = 0.8 + math.random() * 0.4
    lg.push(); lg.translate(bx, by); lg.rotate(car.angle)
    U.setColor("#ff6d00", 0.85); lg.ellipse("fill", -10 * flick, 0, 14 * flick, 8)
    U.setColor("#ffea00", 0.95); lg.ellipse("fill", -6 * flick, 0, 8 * flick, 4)
    lg.pop()
  end
  lg.setDepthMode("lequal", true)
  local def = car.def
  local L, W = def.length, def.width
  local bodyH = def.bodyHeight or W * 0.5
  local cabH = def.cabinHeight or W * 0.4

  -- body: plain-colored layers, wheels on the bottom ones, full picture on top
  local n = 8
  for k = 0, n do
    S.lifted = k > 0
    S.noWheels = k > 4
    S.plain = (k < n) and def.color or nil
    send("lift", bodyH * k / n)
    send("shade", 0.62 + 0.38 * k / n)
    CarDraw.draw(def, car.x, car.y, car.angle, 1, car)
  end
  S.lifted, S.noWheels, S.plain = false, false, nil

  -- cabin: glass sides and a roof
  local cab = def.cabin
  if cab ~= false then
    cab = cab or { 0.45, 0.8, -0.08 }
    local cl, cw, co = L * cab[1], W * cab[2], L * cab[3]
    lg.push(); lg.translate(car.x, car.y); lg.rotate(car.angle)
    local m = 6
    for k = 1, m do
      send("lift", bodyH + cabH * k / m)
      local sc = 1 - 0.12 * k / m
      if k < m then
        send("shade", 0.8 + 0.2 * k / m)
        U.setColor("#3d5a6c")
      else
        send("shade", 1.08)
        U.setColor(def.roof or def.color)
      end
      lg.rectangle("fill", co - cl * sc / 2, -cw * sc / 2, cl * sc, cw * sc, 6, 6)
    end
    lg.pop()
  end
  send("shade", 1)
  send("lift", 0)
end

local skyMesh
local function drawSky(pw, ph, colors, cam)
  local top = U.hex(colors.sky or colors.ground)
  local bot = U.hex(colors.fog or colors.sky or colors.ground)
  skyMesh = skyMesh or lg.newMesh(4, "fan", "dynamic")
  skyMesh:setVertices({
    { 0, 0, 0, 0, top[1], top[2], top[3], 1 },
    { pw, 0, 0, 0, top[1], top[2], top[3], 1 },
    { pw, ph * 0.5, 0, 0, bot[1], bot[2], bot[3], 1 },
    { 0, ph * 0.5, 0, 0, bot[1], bot[2], bot[3], 1 },
  })
  lg.setColor(bot[1], bot[2], bot[3])
  lg.rectangle("fill", 0, 0, pw, ph)
  lg.setColor(1, 1, 1)
  lg.draw(skyMesh)
  if colors.skyStars then -- twinkly stars that slide as you turn
    local shift = (cam.angle / (math.pi * 2)) * pw * 4
    for i = 1, 140 do
      local x = (i * 97.3 + shift) % pw
      local y = (i * 53.7) % (ph * 0.6)
      lg.setColor(1, 1, 1, 0.4 + 0.6 * ((i * 7) % 10) / 10)
      lg.circle("fill", x, y, 1 + (i % 3) * 0.6)
    end
  end
end

-- Draw everything for one player's view into its own picture (canvas)
function V.render(v, cam, me, track, cars)
  V.load()
  local pw, ph = math.max(16, math.floor(v.w * Game.scale)), math.max(16, math.floor(v.h * Game.scale))
  if not v.canvas or v.canvas:getWidth() ~= pw or v.canvas:getHeight() ~= ph then
    local ok, c = pcall(lg.newCanvas, pw, ph, { msaa = 4 })
    v.canvas = ok and c or lg.newCanvas(pw, ph)
  end
  V.setupCamera(v, me, cam, pw, ph)
  V.cam = cam
  local colors = track.data.colors
  local fog = U.hex(colors.fog or colors.sky or colors.ground)
  local fogRange = track.data.fog or { config.fogStart or 1500, config.fogEnd or 3400 }

  lg.push("all")
  S.billboard3d = billboard
  lg.setCanvas({ v.canvas, depth = true })
  lg.origin()
  lg.clear(0, 0, 0, 1)
  drawSky(pw, ph, colors, cam)

  lg.setShader(shader)
  last = {}
  send("projView", "row", cam.projView)
  send("model", "row", IDENT)
  send("camPos", cam.eye)
  send("fogColor", { fog[1], fog[2], fog[3] })
  send("fogRange", fogRange)
  send("flipY", V.flipY)
  send("lift", 0)
  send("shade", 1)
  -- the floor, ground bits and road are flat: just paint them in order
  lg.setDepthMode("always", false)

  -- the floor
  U.setColor(colors.ground)
  lg.rectangle("fill", me.x - 9000, me.y - 9000, 18000, 18000)

  -- only draw what's in front of the camera
  local cx, cy = me.x + cam.fwd[1] * 1000, me.y + cam.fwd[2] * 1000
  local r = 2300
  drawLayer(track, "ground", cx, cy, r)
  track:drawRoad()
  drawLayer(track, "low", cx, cy, r)
  for _, car in ipairs(cars) do drawCar(car) end
  drawLayer(track, "high", cx, cy, r)
  drawStandUps(track)

  lg.setDepthMode()
  lg.setShader()
  S.billboard3d = nil
  lg.pop()
  return v.canvas
end

return V
