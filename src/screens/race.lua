-- The race itself: cars, cameras, split screen, laps and the HUD.
local U = require("src.util")
local config = require("config")
local cars = require("cars")
local Car = require("src.car")
local AI = require("src.ai")
local Input = require("src.input")
local Audio = require("src.audio")
local Track = require("src.track")
local CarDraw = require("src.cardraw")
local View3D = require("src.view3d")
local lg = love.graphics

local R = {}
local function chase() return config.view ~= "top" end
local PLAYER_COLORS = { "#e53935", "#1e88e5" }
local PAUSE_ITEMS = { "Keep racing", "Start over", "Quit to menu" }

------------------------------------------------------------------ setup

local function gridSpot(track, slot)
  local row = math.floor((slot - 1) / 2)
  local side = (slot % 2 == 1) and -1 or 1
  local back = 70 + row * 110 + (side == 1 and 45 or 0)
  local idx = track:wrap(1 - math.floor(back / track.spacing + 0.5))
  local x, y = track:pointAt(idx)
  x = x + track.nx[idx] * side * 58
  y = y + track.ny[idx] * side * 58
  return x, y, track.ang[idx], idx
end

local function makeViews(n)
  local W, H = Game.W, Game.H
  if n == 1 then return { { x = 0, y = 0, w = W, h = H } } end
  if config.splitScreen == "vertical" then
    return { { x = 0, y = 0, w = W / 2 - 2, h = H }, { x = W / 2 + 2, y = 0, w = W / 2 - 2, h = H } }
  end
  return { { x = 0, y = 0, w = W, h = H / 2 - 2 }, { x = 0, y = H / 2 + 2, w = W, h = H / 2 - 2 } }
end

function R.enter(opts)
  R.opts = opts
  local track = Track.new(opts.track)
  R.track = track
  R.laps = Game.laps
  R.time = -config.countdown
  R.lastBeep = nil
  R.paused, R.pauseSel = false, 1
  R.endTimer = nil
  R.nextPlace = 1
  R.cars, R.humans = {}, {}
  local rng = U.newRng(os.time())

  -- Who races: humans + computer cars with cars nobody picked
  local entries = {}
  for p = 1, Game.numPlayers do
    entries[#entries + 1] = { def = cars[Game.chosenCars[p]], player = p }
  end
  local pool = {}
  for i, def in ipairs(cars) do
    local taken = false
    for p = 1, Game.numPlayers do if Game.chosenCars[p] == i then taken = true end end
    if not taken then pool[#pool + 1] = def end
  end
  while #entries < config.totalRacers do
    if #pool == 0 then for _, d in ipairs(cars) do pool[#pool + 1] = d end end
    local def = table.remove(pool, rng:random(1, #pool))
    entries[#entries + 1] = { def = def }
  end

  -- Starting grid: one computer car in front, then players, then the rest
  local order = {}
  for _, e in ipairs(entries) do if not e.player then order[#order + 1] = e; break end end
  for _, e in ipairs(entries) do if e.player then order[#order + 1] = e end end
  for _, e in ipairs(entries) do
    local used = false
    for _, o in ipairs(order) do if o == e then used = true end end
    if not used then order[#order + 1] = e end
  end

  for slot, e in ipairs(order) do
    local x, y, a, idx = gridSpot(track, slot)
    local car = Car.new(e.def, x, y, a)
    car.idx = idx
    car.progress = (idx - 1 < track.N / 2) and (idx - 1) or (idx - 1 - track.N)
    car.lapsDone = 0
    car.player = e.player
    car.wrongWay = 0
    car.envGrip = track.physics.grip or 1
    car.envSpeed = track.physics.speed or 1
    if e.player then
      R.humans[e.player] = car
      car.engine = Audio.newEngine(Game.numPlayers == 1 and 0.25 or 0.16)
    else
      AI.setup(car, rng)
      car.speedMul = config.aiSkill + (rng:random() - 0.5) * 0.06
      car.baseMul = car.speedMul
    end
    R.cars[#R.cars + 1] = car
  end
  for _, car in ipairs(R.cars) do
    if car.player == nil then car.ai.lane = car.ai.lane end
  end

  R.views = makeViews(Game.numPlayers)
  for p, v in ipairs(R.views) do
    local c = R.humans[p]
    v.cam = { x = c.x, y = c.y, angle = c.angle, zoom = 1 }
  end

  -- minimap scale
  local w, h = track.maxx - track.minx, track.maxy - track.miny
  R.mapScale = 170 / math.max(w, h)
  R.mapLine = {}
  for i = 1, track.N, 3 do
    local p = track.pts[i]
    R.mapLine[#R.mapLine + 1] = (p[1] - track.minx) * R.mapScale
    R.mapLine[#R.mapLine + 1] = (p[2] - track.miny) * R.mapScale
  end
  R.mapLine[#R.mapLine + 1], R.mapLine[#R.mapLine + 2] = R.mapLine[1], R.mapLine[2]
  R.rankCars()
end

function R.leave()
  for _, car in ipairs(R.cars or {}) do
    if car.engine then car.engine:stop() end
  end
end

------------------------------------------------------------------ helpers

function R.rankCars()
  local list = {}
  for _, c in ipairs(R.cars) do list[#list + 1] = c end
  table.sort(list, function(a, b)
    if a.place and b.place then return a.place < b.place end
    if a.place then return true end
    if b.place then return false end
    return a.progress > b.progress
  end)
  for i, c in ipairs(list) do c.rank = i end
  R.ranked = list
end

local function resetCar(car)
  local idx = car.idx
  local x, y = R.track:pointAt(idx)
  car.x, car.y, car.angle = x, y, R.track.ang[idx]
  car.vx, car.vy, car.speed = 0, 0, 0
end

local function setEngines(on)
  for _, car in ipairs(R.cars) do
    if car.engine then
      if on then car.engine:play() else car.engine:pause() end
    end
  end
end

------------------------------------------------------------------ update

function R.update(dt)
  if R.paused then return end
  local track = R.track
  R.time = R.time + dt
  track:update(dt)

  -- 3, 2, 1, GO!
  if R.time < 0 then
    local n = math.ceil(-R.time)
    if n ~= R.lastBeep then R.lastBeep = n; Audio.play("beep") end
  elseif R.lastBeep ~= 0 then
    R.lastBeep = 0
    Audio.play("go")
    setEngines(true)
  end

  -- Catch-up: computer cars ease off if far ahead of the best human
  local bestHuman = -math.huge
  for _, h in pairs(R.humans) do bestHuman = math.max(bestHuman, h.progress) end

  for _, car in ipairs(R.cars) do
    local throttle, brake, steer, reset = 0, 0, 0, false
    if R.time >= 0 then
      if car.player and not car.place then
        throttle, brake, steer, reset = Input.drive(car.player, Game.numPlayers)
      else
        if not car.ai then AI.setup(car, U.newRng(car.player or 1)) end
        if config.catchUp and not car.player and car.baseMul then
          local ahead = (car.progress - bestHuman) / track.N
          car.speedMul = car.baseMul - U.clamp(ahead * 0.6, -0.12, 0.15)
        end
        throttle, brake, steer = AI.controls(car, track, dt)
      end
    end
    if reset and not car.resetHeld then resetCar(car) end
    car.resetHeld = reset
    car:update(dt, throttle, brake, steer)

    -- keep inside the map
    if car.x < track.minx or car.x > track.maxx then car.vx = 0 end
    if car.y < track.miny or car.y > track.maxy then car.vy = 0 end
    car.x = U.clamp(car.x, track.minx, track.maxx)
    car.y = U.clamp(car.y, track.miny, track.maxy)

    -- bump into rocks and cacti
    track:solidsNear(car.x, car.y, function(o)
      if car:hitObstacle(o.x, o.y, o.r) and car.player then Audio.play("bump") end
    end)
  end

  -- cars bumping each other
  for i = 1, #R.cars do
    for j = i + 1, #R.cars do
      local a, b = R.cars[i], R.cars[j]
      if Car.collide(a, b) and (a.player or b.player) then Audio.play("bump") end
    end
  end

  -- where is everyone on the track?
  for _, car in ipairs(R.cars) do
    local idx, dist = track:nearest(car.x, car.y, car.idx)
    if dist > track.half * 3 then idx, dist = track:nearest(car.x, car.y, car.idx, 120) end
    local diff = idx - car.idx
    if diff > track.N / 2 then diff = diff - track.N elseif diff < -track.N / 2 then diff = diff + track.N end
    car.progress = car.progress + diff
    car.idx = idx
    car.onRoad = dist <= track.half + 18
    if car.boost < 0.5 and track:onBoost(car) then
      car.boost = 1.3
      if car.player then Audio.play("boost") end
    end

    if car.progress >= (car.lapsDone + 1) * track.N then
      car.lapsDone = car.lapsDone + 1
      if car.lapsDone >= R.laps and not car.place then
        car.place = R.nextPlace
        R.nextPlace = R.nextPlace + 1
        car.finishTime = R.time
        if car.player then Audio.play("go") end
      elseif car.player then
        Audio.play("lap")
      end
    end

    -- driving the wrong way?
    local dot = math.cos(car.angle) * math.cos(track.ang[idx]) + math.sin(car.angle) * math.sin(track.ang[idx])
    if dot < -0.4 and car.speed > 60 then car.wrongWay = car.wrongWay + dt else car.wrongWay = 0 end

    if car.engine then
      car.engine:setPitch(0.55 + math.abs(car.speed) / car.topSpeed * 1.3)
    end
  end
  R.rankCars()

  -- cameras follow their player
  for p, v in ipairs(R.views) do
    local car, cam = R.humans[p], v.cam
    local k = math.min(1, 6 * dt)
    cam.x = U.lerp(cam.x, car.x + car.vx * 0.05, k)
    cam.y = U.lerp(cam.y, car.y + car.vy * 0.05, k)
    local target = config.cameraTurns and car.angle or -math.pi / 2
    if chase() then target = car.angle end
    cam.angle = cam.angle + U.wrapAngle(target - cam.angle) * math.min(1, (chase() and 5 or 3.5) * dt)
    local base = v.h / 820 * (config.cameraZoom or 1)
    if Game.numPlayers == 2 and config.splitScreen == "horizontal" then base = v.h / 500 * (config.cameraZoom or 1) end
    local z = base * (1 - 0.15 * math.min(1, math.abs(car.speed) / car.topSpeed))
    cam.zoom = U.lerp(cam.zoom, z, math.min(1, 2 * dt))
  end

  -- everyone (human) finished? show results after a moment
  local allDone = true
  for _, h in pairs(R.humans) do if not h.place then allDone = false end end
  if allDone then
    R.endTimer = (R.endTimer or 0) + dt
    if R.endTimer > 3 then
      R.rankCars()
      Game.switch("results", { standings = R.ranked, opts = R.opts })
    end
  end
end

------------------------------------------------------------------ input

function R.action(p, act)
  if act == "pause" then
    R.paused = not R.paused
    R.pauseSel = 1
    setEngines(not R.paused and R.time >= 0)
    return
  end
  if not R.paused then return end
  if act == "up" then R.pauseSel = (R.pauseSel - 2) % #PAUSE_ITEMS + 1
  elseif act == "down" then R.pauseSel = R.pauseSel % #PAUSE_ITEMS + 1
  elseif act == "back" then R.paused = false; setEngines(R.time >= 0)
  elseif act == "ok" then
    if R.pauseSel == 1 then
      R.paused = false; setEngines(R.time >= 0)
    elseif R.pauseSel == 2 then
      Game.switch("race", R.opts)
    else
      Game.switch("title")
    end
  end
end

------------------------------------------------------------------ drawing

-- How far down the screen your car sits (0.5 = middle, 0.8 = near the bottom)
local function camAnchor()
  if not config.cameraTurns then return 0.5 end
  return config.cameraBehind or 0.78
end

local function worldToView(v, wx, wy)
  local cam = v.cam
  local dx, dy = (wx - cam.x) * cam.zoom, (wy - cam.y) * cam.zoom
  local r = -math.pi / 2 - cam.angle
  local c, s = math.cos(r), math.sin(r)
  return v.x + v.w / 2 + dx * c - dy * s, v.y + v.h * camAnchor() + dx * s + dy * c
end

local function drawMinimap(v, me)
  local track = R.track
  local mw = (track.maxx - track.minx) * R.mapScale
  local mh = (track.maxy - track.miny) * R.mapScale
  local x0, y0 = v.x + v.w - mw - 20, v.y + 16
  lg.setColor(0, 0, 0, 0.35)
  lg.rectangle("fill", x0 - 10, y0 - 10, mw + 20, mh + 20, 10, 10)
  lg.push(); lg.translate(x0, y0)
  lg.setLineJoin("bevel")
  lg.setColor(0.15, 0.15, 0.15); lg.setLineWidth(7); lg.line(R.mapLine)
  lg.setColor(0.85, 0.85, 0.85); lg.setLineWidth(3); lg.line(R.mapLine)
  local p = track.pts[1]
  lg.setColor(1, 1, 1); lg.circle("fill", (p[1] - track.minx) * R.mapScale, (p[2] - track.miny) * R.mapScale, 4)
  for _, car in ipairs(R.cars) do
    local mx, my = (car.x - track.minx) * R.mapScale, (car.y - track.miny) * R.mapScale
    local r = car == me and 7 or 5
    lg.setColor(0, 0, 0); lg.circle("fill", mx, my, r + 2)
    U.setColor(car.player and PLAYER_COLORS[car.player] or car.def.color)
    lg.circle("fill", mx, my, r)
  end
  lg.pop()
  lg.setLineWidth(1)
end

local function drawHUD(v, car)
  local big = v.h > 500 and 72 or 52
  local small = v.h > 500 and 30 or 24
  local rankText = U.ordinal(car.rank)
  U.printOutlined(rankText, Game.font(big), v.x + 24, v.y + 10, car.rank == 1 and "#ffeb3b" or "#ffffff")
  local lap = math.min(car.lapsDone + 1, R.laps)
  U.printOutlined("Lap " .. lap .. " / " .. R.laps, Game.font(small), v.x + 26, v.y + 14 + big, "#ffffff")
  if Game.numPlayers > 1 then
    U.printOutlined("P" .. car.player, Game.font(small), v.x + 26, v.y + 20 + big + small, PLAYER_COLORS[car.player])
  end

  -- speed bar
  local frac = U.clamp(math.abs(car.speed) / car.topSpeed, 0, 1)
  local bw = 200
  local bx, by = v.x + 24, v.y + v.h - 40
  lg.setColor(0, 0, 0, 0.4); lg.rectangle("fill", bx - 4, by - 4, bw + 8, 26, 8, 8)
  if frac > 0.04 then
    U.setColor(frac > 0.9 and "#ff7043" or "#66bb6a"); lg.rectangle("fill", bx, by, bw * frac, 18, 6, 6)
  end

  drawMinimap(v, car)

  local cx, cy = v.x + v.w / 2, v.y + v.h / 2
  if car.place then
    U.printOutlined("FINISHED!", Game.font(big), cx, cy - big, "#ffeb3b", true)
    U.printOutlined(U.ordinal(car.place) .. " place", Game.font(small + 10), cx, cy + 6, "#ffffff", true)
  elseif car.wrongWay > 0.8 and math.floor(R.time * 3) % 2 == 0 then
    U.printOutlined("WRONG WAY!", Game.font(big), cx, cy - big / 2, "#ff5252", true)
  elseif not car.onRoad and R.time > 2 then
    U.printOutlined("Press Y to get back on the road", Game.font(20), cx, v.y + v.h - 44, "#ffffff", true)
  end
  if car.lapsDone == R.laps - 1 and R.laps > 1 and not car.place and car.progress % R.track.N < R.track.N * 0.08 then
    U.printOutlined("FINAL LAP!", Game.font(big), cx, v.y + v.h * 0.22, "#ffeb3b", true)
  end
end

local function drawView(p, v)
  local track, cam = R.track, v.cam
  local c = track.data.colors
  local canvas
  if chase() then canvas = View3D.render(v, cam, R.humans[p], track, R.cars) end
  local sx, sy = Game.toScreen(v.x, v.y)
  lg.setScissor(sx, sy, v.w * Game.scale, v.h * Game.scale)
  if canvas then
    lg.setColor(1, 1, 1)
    lg.draw(canvas, v.x, v.y, 0, 1 / Game.scale)
  else
  U.setColor(c.ground)
  lg.rectangle("fill", v.x, v.y, v.w, v.h)

  lg.push()
  lg.translate(v.x + v.w / 2, v.y + v.h * camAnchor())
  lg.scale(cam.zoom)
  lg.rotate(-math.pi / 2 - cam.angle)
  lg.translate(-cam.x, -cam.y)
  local radius = math.sqrt(v.w * v.w + v.h * v.h) / cam.zoom * 0.7 + 100

  track:drawLayer("ground", cam.x, cam.y, radius, cam.angle)
  track:drawRoad()
  track:drawLayer("low", cam.x, cam.y, radius, cam.angle)
  for _, car in ipairs(R.cars) do
    if car.boost > 0 then -- rocket flames!
      local fx, fy = math.cos(car.angle), math.sin(car.angle)
      local bx, by = car.x - fx * car.def.length * 0.55, car.y - fy * car.def.length * 0.55
      local flick = 0.8 + math.random() * 0.4
      lg.push(); lg.translate(bx, by); lg.rotate(car.angle)
      U.setColor("#ff6d00", 0.85); lg.ellipse("fill", -14 * flick, 0, 22 * flick, 11)
      U.setColor("#ffea00", 0.95); lg.ellipse("fill", -8 * flick, 0, 12 * flick, 6)
      lg.pop()
    end
    CarDraw.draw(car.def, car.x, car.y, car.angle, 1, car)
  end
  track:drawLayer("high", cam.x, cam.y, radius, cam.angle)
  lg.pop()
  end

  -- whole-screen effects (water tint, etc.)
  if track.data.overlay then track.data.overlay(v.x, v.y, v.w, v.h, track.time) end

  -- name tags over the human cars
  if Game.numPlayers > 1 then
    for q, hc in pairs(R.humans) do
      local tx, ty
      if canvas then
        tx, ty = View3D.project(v, cam, hc.x, hc.y, -60)
        if ty then ty = ty - 24 end
      else
        tx, ty = worldToView(v, hc.x, hc.y)
        ty = ty - 40 * cam.zoom - 10
      end
      if tx then
      U.setColor(PLAYER_COLORS[q])
      lg.polygon("fill", tx - 8, ty + 14, tx + 8, ty + 14, tx, ty + 24)
      U.printOutlined("P" .. q, Game.font(18), tx, ty - 8, PLAYER_COLORS[q], true)
      end
    end
  end

  drawHUD(v, R.humans[p])
  lg.setScissor()
end

function R.draw()
  for p, v in ipairs(R.views) do drawView(p, v) end
  if #R.views > 1 then
    lg.setColor(0.1, 0.1, 0.1)
    if config.splitScreen == "vertical" then
      lg.rectangle("fill", Game.W / 2 - 2, 0, 4, Game.H)
    else
      lg.rectangle("fill", 0, Game.H / 2 - 2, Game.W, 4)
    end
  end

  -- countdown
  if R.time < 1 then
    local text, color
    if R.time < 0 then
      text, color = tostring(math.ceil(-R.time)), "#ffffff"
    else
      text, color = "GO!", "#76ff03"
    end
    local frac = R.time < 0 and (-R.time % 1) or (1 - R.time)
    local f = Game.font(math.floor(120 + 60 * frac))
    U.printOutlined(text, f, Game.W / 2, Game.H / 2 - f:getHeight() / 2, color, true)
  end

  if R.paused then
    lg.setColor(0, 0, 0, 0.55)
    lg.rectangle("fill", 0, 0, Game.W, Game.H)
    U.printOutlined("PAUSED", Game.font(72), Game.W / 2, 180, "#ffffff", true)
    for i, item in ipairs(PAUSE_ITEMS) do
      local on = i == R.pauseSel
      local y = 320 + (i - 1) * 80
      U.setColor(on and "#ffeb3b" or "#ffffff", on and 1 or 0.8)
      lg.rectangle("fill", Game.W / 2 - 170, y, 340, 62, 16, 16)
      lg.setColor(0.1, 0.1, 0.1)
      U.printCenter(item, Game.font(30), Game.W / 2, y + 13)
    end
  end
end

return R
