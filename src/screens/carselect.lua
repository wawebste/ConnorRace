local U = require("src.util")
local UI = require("src.ui")
local CarDraw = require("src.cardraw")
local cars = require("cars")
local lg = love.graphics

local S = {}
local STAT_NAMES = {
  { "speed", "Speed" }, { "accel", "Zoom" }, { "handling", "Turning" }, { "offroad", "Off-road" },
}
local PLAYER_COLORS = { "#e53935", "#1e88e5" }

function S.enter()
  S.t = 0
  S.sel, S.ready = {}, {}
  for p = 1, Game.numPlayers do
    S.sel[p] = Game.chosenCars[p] or p
    S.ready[p] = false
  end
end

function S.update(dt) S.t = S.t + dt end

function S.action(p, act)
  if Game.numPlayers == 1 then p = 1 end
  if p > Game.numPlayers then return end
  if act == "left" and not S.ready[p] then
    S.sel[p] = (S.sel[p] - 2) % #cars + 1
  elseif act == "right" and not S.ready[p] then
    S.sel[p] = S.sel[p] % #cars + 1
  elseif act == "ok" then
    S.ready[p] = true
    for q = 1, Game.numPlayers do
      if not S.ready[q] then return end
    end
    for q = 1, Game.numPlayers do Game.chosenCars[q] = S.sel[q] end
    Game.switch("trackselect")
  elseif act == "back" or act == "pause" then
    if S.ready[p] then S.ready[p] = false else Game.switch("title") end
  end
end

local function drawPanel(p, x, w)
  local def = cars[S.sel[p]]
  local y, h = 120, 530
  UI.panel(x + 20, y, w - 40, h, "#ffffff", 0.9)
  local cx = x + w / 2

  U.setColor(PLAYER_COLORS[p])
  lg.rectangle("fill", x + 20, y, w - 40, 50, 18, 18)
  lg.rectangle("fill", x + 20, y + 30, w - 40, 20)
  U.printOutlined("Player " .. p, Game.font(30), cx, y + 8, "#ffffff", true)

  -- big spinning car on a turntable
  U.setColor("#cfd8dc"); lg.ellipse("fill", cx, y + 185, 150, 95)
  U.setColor("#b0bec5"); lg.ellipse("fill", cx, y + 185, 120, 75)
  local spin = S.ready[p] and -math.pi / 2 or (S.t * 0.8)
  CarDraw.draw(def, cx, y + 185, spin, 3)

  -- arrows
  if not S.ready[p] then
    local wig = math.sin(S.t * 6) * 5
    U.setColor("#424242")
    lg.polygon("fill", x + 55 - wig, y + 185, x + 85 - wig, y + 160, x + 85 - wig, y + 210)
    lg.polygon("fill", x + w - 55 + wig, y + 185, x + w - 85 + wig, y + 160, x + w - 85 + wig, y + 210)
  end

  lg.setColor(0.1, 0.1, 0.1)
  U.printCenter(def.name, Game.font(36), cx, y + 300)

  for i, s in ipairs(STAT_NAMES) do
    local sy = y + 355 + (i - 1) * 36
    lg.setColor(0.25, 0.25, 0.25)
    lg.setFont(Game.font(22))
    lg.print(s[2], cx - 170, sy)
    for k = 1, 5 do
      if k <= def.stats[s[1]] then U.setColor(def.color) else U.setColor("#e0e0e0") end
      lg.rectangle("fill", cx - 30 + (k - 1) * 40, sy + 2, 34, 22, 6, 6)
    end
  end

  if S.ready[p] then
    U.setColor("#43a047", 0.9)
    lg.rectangle("fill", cx - 120, y + h - 15, 240, 56, 16, 16)
    U.printOutlined("READY!", Game.font(34), cx, y + h - 6, "#ffffff", true)
  end
end

function S.draw()
  UI.background(S.t)
  UI.title("Pick your car!", 30)
  local w = Game.W / Game.numPlayers
  if Game.numPlayers == 1 then
    drawPanel(1, Game.W / 2 - 320, 640)
  else
    for p = 1, Game.numPlayers do drawPanel(p, (p - 1) * w, w) end
  end
  UI.hint("Left / Right to choose   A to pick   B to go back")
end

return S
