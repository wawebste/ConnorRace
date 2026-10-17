-- Controls for keyboard and game controllers (Steam Deck counts as a controller).
--
--  Controller:  Right trigger or A = gas   Left trigger, B or X = brake
--               Left stick / D-pad = steer   Y = put car back on road   Start = pause
--  Keyboard P1: W gas, S brake, A/D steer, R reset, Space ok, Esc pause
--  Keyboard P2: Arrows, Right Shift reset, Enter ok
local U = require("src.util")

local Input = {}
Input.pads = {}
Input.onAction = nil -- set by main.lua: function(player, action)

local DEAD = 0.22

local DRIVE_KEYS = {
  { gas = { "w" }, brake = { "s" }, left = { "a" }, right = { "d" }, reset = { "r" } },
  { gas = { "up" }, brake = { "down" }, left = { "left" }, right = { "right" }, reset = { "rshift", "/" } },
}

local MENU_KEYS = {
  a = { 1, "left" }, d = { 1, "right" }, w = { 1, "up" }, s = { 1, "down" },
  space = { 1, "ok" }, q = { 1, "back" }, escape = { 1, "pause" }, p = { 1, "pause" },
  left = { 2, "left" }, right = { 2, "right" }, up = { 2, "up" }, down = { 2, "down" },
  ["return"] = { 2, "ok" }, kpenter = { 2, "ok" }, backspace = { 2, "back" },
}

local PAD_BUTTONS = {
  a = "ok", b = "back", start = "pause", back = "pause",
  dpleft = "left", dpright = "right", dpup = "up", dpdown = "down",
}

local stick = {}

function Input.refresh()
  Input.pads = {}
  for _, js in ipairs(love.joystick.getJoysticks()) do
    if js:isGamepad() then table.insert(Input.pads, js) end
  end
end

function Input.load() Input.refresh() end

local function emit(p, act)
  if Input.onAction then Input.onAction(p, act) end
end

local function padIndex(js)
  for i, p in ipairs(Input.pads) do
    if p == js then return i end
  end
  return nil
end

function Input.keypressed(key)
  local m = MENU_KEYS[key]
  if m then emit(m[1], m[2]) end
end

function Input.gamepadpressed(js, button)
  local i = padIndex(js)
  local act = PAD_BUTTONS[button]
  if i and act then emit(i, act) end
end

-- Lets the analog stick move through menus too
function Input.update(dt)
  for i, js in ipairs(Input.pads) do
    local st = stick[i] or { dir = nil, t = 0 }
    stick[i] = st
    local ax, ay = js:getGamepadAxis("leftx"), js:getGamepadAxis("lefty")
    local dir
    if math.abs(ax) > 0.6 and math.abs(ax) > math.abs(ay) then
      dir = ax > 0 and "right" or "left"
    elseif math.abs(ay) > 0.6 then
      dir = ay > 0 and "down" or "up"
    end
    if dir ~= st.dir then
      st.dir, st.t = dir, 0.4
      if dir then emit(i, dir) end
    elseif dir then
      st.t = st.t - dt
      if st.t <= 0 then st.t = 0.18; emit(i, dir) end
    end
  end
end

local function anyDown(list)
  for _, k in ipairs(list) do
    if love.keyboard.isDown(k) then return true end
  end
  return false
end

-- Returns throttle (0..1), brake (0..1), steer (-1..1), reset (bool)
function Input.drive(p, numPlayers)
  local throttle, brake, steer, reset = 0, 0, 0, false

  local sets = numPlayers == 1 and DRIVE_KEYS or { DRIVE_KEYS[p] }
  for _, set in ipairs(sets) do
    if anyDown(set.gas) then throttle = 1 end
    if anyDown(set.brake) then brake = 1 end
    if anyDown(set.left) then steer = steer - 1 end
    if anyDown(set.right) then steer = steer + 1 end
    if anyDown(set.reset) then reset = true end
  end

  local pads = numPlayers == 1 and Input.pads or { Input.pads[p] }
  for _, js in ipairs(pads) do
    local ax = js:getGamepadAxis("leftx")
    if math.abs(ax) > DEAD then
      local s = ax > 0 and 1 or -1
      steer = steer + s * (math.abs(ax) - DEAD) / (1 - DEAD)
    end
    if js:isGamepadDown("dpleft") then steer = steer - 1 end
    if js:isGamepadDown("dpright") then steer = steer + 1 end
    throttle = math.max(throttle, js:getGamepadAxis("triggerright"), js:isGamepadDown("a") and 1 or 0)
    brake = math.max(brake, js:getGamepadAxis("triggerleft"), js:isGamepadDown("b", "x") and 1 or 0)
    if js:isGamepadDown("y") then reset = true end
  end

  return U.clamp(throttle, 0, 1), U.clamp(brake, 0, 1), U.clamp(steer, -1, 1), reset
end

return Input
