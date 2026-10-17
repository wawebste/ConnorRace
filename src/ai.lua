-- Computer drivers: look ahead along the road and steer toward it.
local U = require("src.util")

local AI = {}

function AI.setup(car, rng)
  car.ai = {
    lane = (rng:random() - 0.5) * 80, -- each computer car likes a slightly different line
    stuck = 0,
    reverse = 0,
  }
end

function AI.controls(car, track, dt)
  local ai = car.ai
  local spd = math.max(0, car.speed)

  -- Stuck against something? Back up for a moment.
  if ai.reverse > 0 then
    ai.reverse = ai.reverse - dt
    local tx, ty = track:pointAt(car.idx + 8)
    local want = U.atan2(ty - car.y, tx - car.x)
    return 0, 1, U.clamp(-U.wrapAngle(want - car.angle) * 2, -1, 1)
  end
  if spd < 25 then ai.stuck = ai.stuck + dt else ai.stuck = 0 end
  if ai.stuck > 1.2 then ai.stuck, ai.reverse = 0, 0.9 end

  local look = 5 + math.floor(spd / 40)
  local i = car.idx + look
  local px, py = track:pointAt(i)
  local w = track:wrap(i)
  px = px + track.nx[w] * ai.lane
  py = py + track.ny[w] * ai.lane

  local want = U.atan2(py - car.y, px - car.x)
  local diff = U.wrapAngle(want - car.angle)
  local steer = U.clamp(diff * 2.6, -1, 1)

  -- Slow down for sharp corners coming up
  local bend = math.abs(U.wrapAngle(track:angleAt(car.idx + look * 2) - track:angleAt(car.idx)))
  local slip = 1 / math.max(0.4, car.envGrip) -- slow down more on ice
  local target = car.topSpeed * car.speedMul * car.envSpeed * (1 - math.min(0.6, bend * 0.5 * slip))
  if car.boost > 0 then target = target * 1.4 end
  local throttle, brake = 1, 0
  if spd > target + 60 then
    throttle, brake = 0, 0.5
  elseif spd > target then
    throttle = 0.2
  end
  return throttle, brake, steer
end

return AI
