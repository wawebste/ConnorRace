-- Drawings for each car "style". Cars are drawn from above, nose pointing RIGHT (+x).
-- To make a new look: copy a style function, rename it, and use that name in cars.lua.
local U = require("src.util")
local S = require("src.scenery")
local lg = love.graphics

local CD = {}

local GLASS = "#3d5a6c"
local TIRE = "#1a1a1a"
local LIGHT = "#fff8c4"
local TAIL = "#c62828"
local TAIL_ON = "#ff5252"

local function col(c, a)
  -- 3D view: the sides of the car are plain body color (lights and tires keep their color)
  if S.plain and c ~= TIRE and c ~= TAIL and c ~= TAIL_ON and c ~= LIGHT then c = S.plain end
  U.setColor(c, a)
end
local function rr(x, y, w, h, r) lg.rectangle("fill", x, y, w, h, r, r) end

local function wheels(L, W, front, back)
  if S.noWheels then return end -- 3D view: wheels only on the bottom layers
  col(TIRE)
  local wl, ww = L * 0.2, W * 0.24
  for _, sx in ipairs({ front or 0.3, -(back or 0.3) }) do
    for _, sy in ipairs({ 1, -1 }) do
      rr(sx * L - wl / 2, sy * (W / 2 - ww * 0.3) - ww / 2, wl, ww, 2)
    end
  end
end

local function lights(L, W, state, spread)
  spread = spread or 0.3
  col(LIGHT)
  rr(L / 2 - 5, -W * spread - 3, 5, 6, 2)
  rr(L / 2 - 5, W * spread - 3, 5, 6, 2)
  col(state and state.braking and TAIL_ON or TAIL)
  rr(-L / 2, -W * spread - 4, 4, 8, 1)
  rr(-L / 2, W * spread - 4, 4, 8, 1)
end

local function mirrors(L, W, c, x)
  col(c)
  rr(L * (x or 0.08) - 3, -W / 2 - 3, 6, 4, 1)
  rr(L * (x or 0.08) - 3, W / 2 - 1, 6, 4, 1)
end

CD.styles = {}

-- Ford Mustang: long hood, racing stripes
CD.styles.muscle = function(L, W, c, a, st)
  wheels(L, W, 0.3, 0.3)
  col(c); rr(-L / 2, -W / 2, L, W, 7)
  mirrors(L, W, c, 0.06)
  col(U.shade(c, 0.85)); rr(L * 0.14, -W * 0.14, L * 0.2, W * 0.28, 3) -- hood scoop
  col(U.shade(c, 0.92)); rr(-L * 0.26, -W * 0.38, L * 0.26, W * 0.76, 4) -- roof
  col(a)
  lg.rectangle("fill", -L / 2, -W * 0.17, L, W * 0.1)
  lg.rectangle("fill", -L / 2, W * 0.07, L, W * 0.1)
  col(GLASS)
  lg.polygon("fill", L * 0.1, -W * 0.42, L * 0.1, W * 0.42, 0, W * 0.36, 0, -W * 0.36)
  lg.polygon("fill", -L * 0.26, -W * 0.34, -L * 0.26, W * 0.34, -L * 0.34, W * 0.3, -L * 0.34, -W * 0.3)
  lights(L, W, st, 0.32)
end

-- VW Beetle: round body with bubble fenders
CD.styles.bug = function(L, W, c, a, st)
  wheels(L, W, 0.28, 0.3)
  col(U.shade(c, 0.88))
  for _, x in ipairs({ L * 0.28, -L * 0.3 }) do
    lg.ellipse("fill", x, -W * 0.36, L * 0.15, W * 0.2)
    lg.ellipse("fill", x, W * 0.36, L * 0.15, W * 0.2)
  end
  col(c); lg.ellipse("fill", 0, 0, L * 0.5, W * 0.44)
  col(GLASS); lg.ellipse("fill", -L * 0.02, 0, L * 0.24, W * 0.34)
  col(U.shade(c, 1.08)); lg.ellipse("fill", -L * 0.07, 0, L * 0.18, W * 0.3) -- round roof
  col(LIGHT)
  lg.circle("fill", L * 0.38, -W * 0.33, 3.5)
  lg.circle("fill", L * 0.38, W * 0.33, 3.5)
  col(st and st.braking and TAIL_ON or TAIL)
  lg.circle("fill", -L * 0.4, -W * 0.33, 3)
  lg.circle("fill", -L * 0.4, W * 0.33, 3)
end

-- Jeep Wrangler: boxy, open top, spare tire on the back
CD.styles.jeep = function(L, W, c, a, st)
  wheels(L, W, 0.32, 0.3)
  col(a) -- black fender flares
  rr(L * 0.18, -W / 2 - 2, L * 0.26, W + 4, 3)
  rr(-L * 0.44, -W / 2 - 2, L * 0.26, W + 4, 3)
  col(c); rr(-L / 2, -W / 2, L, W, 3)
  col("#2b2b2b"); rr(-L * 0.36, -W * 0.38, L * 0.42, W * 0.76, 2) -- open top inside
  col("#5d4037") -- seats
  rr(-L * 0.06, -W * 0.32, L * 0.1, W * 0.26, 2)
  rr(-L * 0.06, W * 0.06, L * 0.1, W * 0.26, 2)
  rr(-L * 0.3, -W * 0.3, L * 0.12, W * 0.6, 2)
  col("#9e9e9e"); lg.setLineWidth(3) -- roll bar
  lg.line(-L * 0.14, -W * 0.4, -L * 0.14, W * 0.4)
  col(GLASS); rr(L * 0.08, -W * 0.44, 4, W * 0.88, 1) -- windshield
  col(U.shade(c, 0.85)) -- hood lines
  lg.rectangle("fill", L * 0.2, -W * 0.25, L * 0.24, 2)
  lg.rectangle("fill", L * 0.2, W * 0.25 - 2, L * 0.24, 2)
  lights(L, W, st, 0.34)
  col(TIRE); lg.circle("fill", -L / 2 - 2, 0, W * 0.24) -- spare tire
  col("#616161"); lg.circle("fill", -L / 2 - 2, 0, W * 0.11)
end

-- Mini Cooper: short and round with a white roof
CD.styles.mini = function(L, W, c, a, st)
  wheels(L, W, 0.32, 0.32)
  col(c); rr(-L / 2, -W / 2, L, W, 10)
  mirrors(L, W, a, 0.1)
  col(GLASS); rr(-L * 0.32, -W * 0.42, L * 0.5, W * 0.84, 6)
  col(a); rr(-L * 0.27, -W * 0.36, L * 0.38, W * 0.72, 5) -- white roof
  col(U.shade(c, 0.85)); lg.rectangle("fill", L * 0.28, -W * 0.06, L * 0.18, W * 0.12) -- bonnet stripe
  col(LIGHT)
  lg.circle("fill", L * 0.42, -W * 0.3, 3.5)
  lg.circle("fill", L * 0.42, W * 0.3, 3.5)
  col(st and st.braking and TAIL_ON or TAIL)
  rr(-L / 2, -W * 0.36, 3, 7, 1)
  rr(-L / 2, W * 0.36 - 7, 3, 7, 1)
end

-- Lamborghini: pointy wedge supercar
CD.styles.wedge = function(L, W, c, a, st)
  wheels(L, W, 0.3, 0.3)
  col(c)
  lg.polygon("fill",
    L / 2, -W * 0.28, L / 2, W * 0.28,
    L * 0.2, W / 2, -L / 2, W / 2,
    -L / 2, -W / 2, L * 0.2, -W / 2)
  col(GLASS)
  lg.polygon("fill", L * 0.2, -W * 0.3, L * 0.2, W * 0.3, -L * 0.12, W * 0.36, -L * 0.12, -W * 0.36)
  col(a) -- engine vents
  for i = 0, 3 do
    lg.rectangle("fill", -L * 0.2 - i * L * 0.06, -W * 0.28, L * 0.03, W * 0.56)
  end
  rr(-L * 0.18, -W / 2, L * 0.16, 3, 1) -- side intakes
  rr(-L * 0.18, W / 2 - 3, L * 0.16, 3, 1)
  col(LIGHT)
  lg.polygon("fill", L / 2 - 1, -W * 0.26, L / 2 - 9, -W * 0.38, L / 2 - 11, -W * 0.3)
  lg.polygon("fill", L / 2 - 1, W * 0.26, L / 2 - 9, W * 0.38, L / 2 - 11, W * 0.3)
  col(st and st.braking and TAIL_ON or TAIL)
  lg.rectangle("fill", -L / 2, -W * 0.4, 3, W * 0.8)
end

-- Ford F-150: pickup truck with a bed in the back
CD.styles.pickup = function(L, W, c, a, st)
  wheels(L, W, 0.32, 0.3)
  col(c); rr(-L / 2, -W / 2, L, W, 4)
  mirrors(L, W, c, 0.12)
  col(U.shade(c, 0.6)); rr(-L * 0.46, -W * 0.4, L * 0.4, W * 0.8, 2) -- truck bed
  col(U.shade(c, 0.75))
  for i = 1, 3 do
    lg.rectangle("fill", -L * 0.46, -W * 0.4 + i * W * 0.2 - 1, L * 0.4, 2)
  end
  col(GLASS); rr(-L * 0.02, -W * 0.42, L * 0.24, W * 0.84, 3)
  col(U.shade(c, 1.1)); rr(0, -W * 0.36, L * 0.15, W * 0.72, 3) -- cab roof
  col(a); rr(L / 2 - 4, -W * 0.3, 4, W * 0.6, 1) -- grille
  lights(L, W, st, 0.38)
end

-- Cybertruck: flat angled steel panels
CD.styles.cyber = function(L, W, c, a, st)
  wheels(L, W, 0.32, 0.32)
  col(c)
  lg.polygon("fill",
    L / 2, -W * 0.44, L / 2, W * 0.44,
    L * 0.4, W / 2, -L / 2, W / 2,
    -L / 2, -W / 2, L * 0.4, -W / 2)
  col(U.shade(c, 0.85))
  lg.polygon("fill", -L * 0.48, -W * 0.42, -L * 0.48, W * 0.42, -L * 0.05, W * 0.38, -L * 0.05, -W * 0.38)
  col(GLASS)
  lg.polygon("fill", L * 0.25, -W * 0.3, L * 0.25, W * 0.3, -L * 0.05, W * 0.38, -L * 0.05, -W * 0.38)
  col(a); lg.setLineWidth(1)
  lg.line(L * 0.25, -W * 0.3, L * 0.25, W * 0.3)
  col("#ffffff"); lg.rectangle("fill", L / 2 - 3, -W * 0.44, 3, W * 0.88) -- light bar
  col(st and st.braking and TAIL_ON or TAIL); lg.rectangle("fill", -L / 2, -W * 0.46, 3, W * 0.92)
end

-- Draw a car definition at x,y facing angle (radians, 0 = right). scale is optional.
function CD.draw(def, x, y, angle, scale, state)
  local L, W = def.length, def.width
  lg.push()
  lg.translate(x, y)
  lg.rotate(angle or 0)
  if scale then lg.scale(scale) end
  if not S.lifted then
    col("#000000", 0.22)
    rr(-L / 2 + 3, -W / 2 + 5, L, W, 8)
  end
  local fn = CD.styles[def.style] or CD.styles.muscle
  fn(L, W, def.color, def.accent or "#ffffff", state)
  lg.setLineWidth(1)
  lg.pop()
end

return CD
