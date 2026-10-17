-- Shared bits for the menu screens.
local U = require("src.util")
local lg = love.graphics

local UI = {}

-- Sunset sky + checkered stripe
function UI.background(t)
  local W, H = Game.W, Game.H
  local bands = { "#ff7e5f", "#fd9a5a", "#feb47b", "#ffd194", "#ffe7b0" }
  for i, c in ipairs(bands) do
    U.setColor(c)
    lg.rectangle("fill", 0, (i - 1) * H / #bands, W, H / #bands + 1)
  end
  local sq = 32
  local off = (t * 60) % (sq * 2)
  for row = 0, 1 do
    for x = -2, W / sq + 2 do
      if (x + row) % 2 == 0 then lg.setColor(0.1, 0.1, 0.1) else lg.setColor(1, 1, 1) end
      lg.rectangle("fill", x * sq - off, H - 70 + row * sq * 0.6, sq, sq * 0.6)
    end
  end
end

function UI.title(text, y)
  U.printOutlined(text, Game.font(56), Game.W / 2, y or 40, "#ffffff", true)
end

function UI.hint(text)
  U.printOutlined(text, Game.font(22), Game.W / 2, Game.H - 110, "#ffffff", true)
end

-- Rounded panel
function UI.panel(x, y, w, h, color, alpha)
  U.setColor("#000000", 0.25)
  lg.rectangle("fill", x + 6, y + 8, w, h, 18, 18)
  U.setColor(color or "#ffffff", alpha or 0.9)
  lg.rectangle("fill", x, y, w, h, 18, 18)
end

-- Little picture for each track theme
function UI.icon(name, x, y, s, t)
  t = t or 0
  if name == "sun" then
    U.setColor("#ffeb3b")
    for i = 0, 7 do
      local a = i * math.pi / 4 + t * 0.5
      lg.setLineWidth(s * 0.12)
      lg.line(x + math.cos(a) * s * 0.55, y + math.sin(a) * s * 0.55, x + math.cos(a) * s * 0.85, y + math.sin(a) * s * 0.85)
    end
    lg.circle("fill", x, y, s * 0.42)
  elseif name == "bubbles" then
    U.setColor("#ffffff", 0.85); lg.setLineWidth(3)
    for i = 0, 3 do
      local by = y + s * 0.6 - ((t * 30 + i * 25) % (s * 1.2))
      lg.circle("line", x + math.sin(i * 2 + t) * s * 0.3, by, s * (0.12 + i * 0.05))
    end
  elseif name == "stars" then
    U.setColor("#fff59d")
    for i = 0, 5 do
      local a = i * 1.1
      lg.circle("fill", x + math.cos(a) * s * 0.6, y + math.sin(a * 1.7) * s * 0.5, 2 + (math.sin(t * 3 + i) + 1) * 2)
    end
    U.setColor("#ff7043"); lg.circle("fill", x, y, s * 0.3)
    U.setColor("#ffab91"); lg.ellipse("fill", x, y, s * 0.55, s * 0.1)
  elseif name == "snow" then
    U.setColor("#78909c")
    lg.polygon("fill", x - s * 0.8, y + s * 0.5, x, y - s * 0.6, x + s * 0.8, y + s * 0.5)
    U.setColor("#ffffff")
    lg.polygon("fill", x - s * 0.27, y - s * 0.23, x, y - s * 0.6, x + s * 0.27, y - s * 0.23)
  elseif name == "globe" then
    U.setColor("#1e88e5"); lg.circle("fill", x, y, s * 0.6)
    U.setColor("#66bb6a")
    lg.ellipse("fill", x - s * 0.2, y - s * 0.15, s * 0.22, s * 0.3)
    lg.ellipse("fill", x + s * 0.25, y + s * 0.15, s * 0.2, s * 0.25)
  end
  lg.setLineWidth(1)
end

return UI
