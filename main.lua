-- Connor's Race
-- Start here! Screens live in src/screens, cars in cars.lua, tracks in tracks/.
local config = require("config")
local Input = require("src.input")
local Audio = require("src.audio")

Game = {
  W = 1280, H = 800,   -- the game draws at this size and scales to fit the screen
  numPlayers = 1,
  chosenCars = { 1, 2 },
  laps = config.laps,
  scale = 1, ox = 0, oy = 0,
}

local fonts = {}
function Game.font(size)
  if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
  return fonts[size]
end

function Game.switch(name, ...)
  if Game.screen and Game.screen.leave then Game.screen.leave() end
  Game.screen = require("src.screens." .. name)
  Game.screenName = name
  if Game.screen.enter then Game.screen.enter(...) end
end

-- Game coordinates -> real screen pixels (needed for split-screen clipping)
function Game.toScreen(x, y)
  return Game.ox + x * Game.scale, Game.oy + y * Game.scale
end

function love.load()
  math.randomseed(os.time())
  love.graphics.setDefaultFilter("linear", "linear")
  if config.fullscreen == true then
    love.window.setFullscreen(true)
  elseif config.fullscreen == "auto" then
    local dw, dh = love.window.getDesktopDimensions()
    if dw <= 1280 and dh <= 800 then love.window.setFullscreen(true) end
  end
  Input.load()
  Audio.load()
  Input.onAction = function(p, act)
    if Game.screen and Game.screen.action then Game.screen.action(p, act) end
  end
  Game.switch("title")
end

function love.update(dt)
  dt = math.min(dt, 1 / 30)
  Input.update(dt)
  if Game.screen.update then Game.screen.update(dt) end
end

function love.draw()
  local w, h = love.graphics.getDimensions()
  local s = math.min(w / Game.W, h / Game.H)
  Game.scale, Game.ox, Game.oy = s, (w - Game.W * s) / 2, (h - Game.H * s) / 2
  love.graphics.clear(0, 0, 0)
  love.graphics.push()
  love.graphics.translate(Game.ox, Game.oy)
  love.graphics.scale(s)
  Game.screen.draw()
  love.graphics.pop()
end

function love.keypressed(key)
  if key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
    love.window.setFullscreen(not love.window.getFullscreen())
    return
  end
  Input.keypressed(key)
end

function love.gamepadpressed(js, button) Input.gamepadpressed(js, button) end
function love.joystickadded() Input.refresh() end
function love.joystickremoved() Input.refresh() end
