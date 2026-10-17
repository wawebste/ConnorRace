local U = require("src.util")
local UI = require("src.ui")
local Track = require("src.track")
local tracks = require("tracks")
local lg = love.graphics

local S = {}
local previews = {}

local function preview(entry)
  if not entry.file then return nil end
  if previews[entry.file] then return previews[entry.file] end
  local data = require(entry.file)
  local pts = Track.smooth(data.points, 60)
  local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(pts) do
    minx, miny = math.min(minx, p[1]), math.min(miny, p[2])
    maxx, maxy = math.max(maxx, p[1]), math.max(maxy, p[2])
  end
  local s = 150 / math.max(maxx - minx, maxy - miny)
  local line = {}
  for _, p in ipairs(pts) do
    line[#line + 1] = (p[1] - (minx + maxx) / 2) * s
    line[#line + 1] = (p[2] - (miny + maxy) / 2) * s
  end
  line[#line + 1], line[#line + 2] = line[1], line[2]
  previews[entry.file] = line
  return line
end

function S.enter()
  S.t = 0
  S.sel = S.sel or 1
  S.shake = 0
end

function S.update(dt)
  S.t = S.t + dt
  S.shake = math.max(0, S.shake - dt)
end

function S.action(p, act)
  if act == "left" then S.sel = (S.sel - 2) % #tracks + 1
  elseif act == "right" then S.sel = S.sel % #tracks + 1
  elseif act == "up" then Game.laps = math.min(9, Game.laps + 1)
  elseif act == "down" then Game.laps = math.max(1, Game.laps - 1)
  elseif act == "ok" then
    local entry = tracks[S.sel]
    if entry.file then
      Game.switch("race", { track = require(entry.file), trackEntry = entry })
    else
      S.shake = 0.4
    end
  elseif act == "back" or act == "pause" then
    Game.switch("carselect")
  end
end

function S.draw()
  UI.background(S.t)
  UI.title("Pick a track!", 30)

  local n = #tracks
  local cw, gap = 220, 20
  local total = n * cw + (n - 1) * gap
  local x0 = (Game.W - total) / 2
  for i, entry in ipairs(tracks) do
    local on = (i == S.sel)
    local x = x0 + (i - 1) * (cw + gap)
    local y = on and 140 or 160
    if on and S.shake > 0 then x = x + math.sin(S.shake * 60) * 8 end
    UI.panel(x, y, cw, 340, on and "#ffeb3b" or "#ffffff", on and 1 or 0.8)
    U.setColor(entry.color)
    lg.rectangle("fill", x + 12, y + 12, cw - 24, 220, 12, 12)

    local line = preview(entry)
    if line then
      lg.push(); lg.translate(x + cw / 2, y + 122)
      lg.setLineJoin("bevel")
      lg.setColor(0.25, 0.2, 0.2); lg.setLineWidth(12); lg.line(line)
      lg.setColor(0.45, 0.42, 0.4); lg.setLineWidth(7); lg.line(line)
      lg.pop()
      UI.icon(entry.icon, x + cw - 45, y + 50, 40, S.t)
    else
      UI.icon(entry.icon, x + cw / 2, y + 115, 80, S.t)
    end

    lg.setColor(0.1, 0.1, 0.1)
    lg.setFont(Game.font(22))
    lg.printf(entry.name, x + 8, y + 242, cw - 16, "center")
    if not entry.file then
      U.setColor("#757575")
      U.printCenter("Coming soon!", Game.font(20), x + cw / 2, y + 304)
    end
  end

  UI.panel(Game.W / 2 - 150, 530, 300, 60, "#ffffff", 0.9)
  lg.setColor(0.1, 0.1, 0.1)
  U.printCenter("Laps: " .. Game.laps, Game.font(30), Game.W / 2, 541)
  UI.hint("Left / Right: track   Up / Down: laps   A: GO!")
end

return S
