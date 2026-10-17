local U = require("src.util")
local UI = require("src.ui")
local CarDraw = require("src.cardraw")
local lg = love.graphics

local S = {}
local PLAYER_COLORS = { "#e53935", "#1e88e5" }

function S.enter(data)
  S.t = 0
  S.standings = data.standings
  S.opts = data.opts
  S.confetti = {}
  local humanWon = S.standings[1] and S.standings[1].player
  if humanWon then
    for i = 1, 160 do
      S.confetti[i] = {
        x = math.random() * Game.W, y = -math.random() * Game.H,
        vy = 90 + math.random() * 140, r = math.random() * 6,
        c = ({ "#e53935", "#fdd835", "#43a047", "#1e88e5", "#ab47bc" })[math.random(5)],
      }
    end
  end
end

function S.update(dt)
  S.t = S.t + dt
  for _, c in ipairs(S.confetti) do
    c.y = c.y + c.vy * dt
    c.r = c.r + dt * 4
    if c.y > Game.H then c.y = -10 end
  end
end

function S.action(p, act)
  if S.t < 0.8 then return end
  if act == "ok" then Game.switch("race", S.opts)
  elseif act == "back" or act == "pause" then Game.switch("title") end
end

local function trophy(x, y)
  U.setColor("#ffc107")
  lg.polygon("fill", x - 22, y - 26, x + 22, y - 26, x + 14, y + 4, x - 14, y + 4)
  lg.setLineWidth(5)
  lg.arc("line", "open", x - 22, y - 14, 10, math.pi / 2, math.pi * 1.5)
  lg.arc("line", "open", x + 22, y - 14, 10, -math.pi / 2, math.pi / 2)
  lg.rectangle("fill", x - 4, y + 2, 8, 12)
  lg.rectangle("fill", x - 14, y + 12, 28, 8, 3, 3)
  lg.setLineWidth(1)
end

function S.draw()
  UI.background(S.t)
  UI.title("Race results!", 24)
  for i, car in ipairs(S.standings) do
    local y = 110 + (i - 1) * 88
    local slide = math.max(0, 1 - (S.t * 3 - i * 0.3)) * 900
    local x = Game.W / 2 - 330 + slide
    UI.panel(x, y, 660, 74, i == 1 and "#fff59d" or "#ffffff", 0.92)
    lg.setColor(0.1, 0.1, 0.1)
    lg.setFont(Game.font(40))
    lg.print(U.ordinal(i), x + 20, y + 13)
    CarDraw.draw(car.def, x + 190, y + 37, 0, 1.3)
    lg.setFont(Game.font(26))
    lg.setColor(0.1, 0.1, 0.1)
    lg.print(car.def.name, x + 260, y + 8)
    if car.player then
      U.setColor(PLAYER_COLORS[car.player])
      lg.print("Player " .. car.player, x + 260, y + 38)
    else
      lg.setColor(0.45, 0.45, 0.45)
      lg.print("Computer", x + 260, y + 38)
    end
    if i == 1 then trophy(x + 610, y + 40) end
  end
  for _, c in ipairs(S.confetti) do
    U.setColor(c.c)
    lg.push(); lg.translate(c.x + math.sin(c.r) * 20, c.y); lg.rotate(c.r)
    lg.rectangle("fill", -5, -3, 10, 6)
    lg.pop()
  end
  UI.hint("A: Race again      B: Main menu")
end

return S
