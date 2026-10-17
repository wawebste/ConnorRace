local U = require("src.util")
local UI = require("src.ui")
local CarDraw = require("src.cardraw")
local cars = require("cars")
local lg = love.graphics

local S = {}
local items = { "1 Player", "2 Players", "Quit" }

function S.enter()
  S.t = 0
  S.sel = S.sel or 1
end

function S.update(dt) S.t = S.t + dt end

function S.action(p, act)
  if act == "up" then S.sel = (S.sel - 2) % #items + 1
  elseif act == "down" then S.sel = S.sel % #items + 1
  elseif act == "ok" then
    if S.sel == 3 then love.event.quit() return end
    Game.numPlayers = S.sel
    Game.switch("carselect")
  end
end

function S.draw()
  UI.background(S.t)
  -- cars parading along the bottom
  for i, def in ipairs(cars) do
    local x = ((S.t * 220 + i * 190) % (Game.W + 300)) - 150
    CarDraw.draw(def, x, Game.H - 160 + math.sin(S.t * 4 + i) * 2, 0, 1.6)
  end

  local bob = math.sin(S.t * 2) * 6
  U.printOutlined("CONNOR'S", Game.font(64), Game.W / 2, 60 + bob, "#ffeb3b", true)
  U.printOutlined("RACE", Game.font(110), Game.W / 2, 120 + bob, "#ffffff", true)

  for i, name in ipairs(items) do
    local y = 330 + (i - 1) * 85
    local on = (i == S.sel)
    UI.panel(Game.W / 2 - 180, y, 360, 66, on and "#ffeb3b" or "#ffffff", on and 1 or 0.75)
    lg.setColor(0.1, 0.1, 0.1)
    U.printCenter(name, Game.font(34), Game.W / 2, y + 12)
    if on then
      U.setColor("#e53935")
      local ax = Game.W / 2 - 160 + math.sin(S.t * 8) * 4
      lg.polygon("fill", ax, y + 20, ax + 20, y + 33, ax, y + 46)
    end
  end
end

return S
