-- ============================================================
--  CARS  -  add a car by copying one block and changing it!
--
--  style:  which drawing to use. Pick one of:
--          "muscle", "bug", "jeep", "mini", "wedge", "pickup", "cyber"
--          (drawings live in src/cardraw.lua)
--  color / accent:  hex colors like "#ff0000" (red)
--  stats: 1 (slow) to 5 (best)
--     speed    = top speed
--     accel    = how fast it gets going
--     handling = how well it turns
--     offroad  = how well it drives on sand / snow / grass
--
--  3D view (optional):
--     cabin = { length, width, offset } of the glass part, compared to the car
--             (cabin = false for no roof, like an open Jeep)
--     roof  = roof color      bodyHeight / cabinHeight = how tall
-- ============================================================
return {
  {
    name = "Ford Mustang", style = "muscle", cabin = { 0.36, 0.8, -0.12 },
    color = "#e53935", accent = "#ffffff",
    length = 66, width = 32,
    stats = { speed = 5, accel = 4, handling = 3, offroad = 1 },
  },
  {
    name = "VW Beetle", style = "bug", cabin = { 0.42, 0.7, -0.06 }, cabinHeight = 16,
    color = "#fdd835", accent = "#ffffff",
    length = 54, width = 32,
    stats = { speed = 2, accel = 3, handling = 5, offroad = 3 },
  },
  {
    name = "Jeep Wrangler", style = "jeep", cabin = false, bodyHeight = 20,
    color = "#689f38", accent = "#33691e",
    length = 58, width = 34,
    stats = { speed = 3, accel = 3, handling = 3, offroad = 5 },
  },
  {
    name = "Mini Cooper", style = "mini", cabin = { 0.52, 0.84, -0.06 }, roof = "#ffffff",
    color = "#1e88e5", accent = "#ffffff",
    length = 50, width = 30,
    stats = { speed = 3, accel = 4, handling = 5, offroad = 2 },
  },
  {
    name = "Lamborghini", style = "wedge", cabin = { 0.34, 0.66, -0.02 }, bodyHeight = 12, cabinHeight = 9,
    color = "#aeea00", accent = "#212121",
    length = 66, width = 34,
    stats = { speed = 5, accel = 5, handling = 2, offroad = 1 },
  },
  {
    name = "Ford F-150", style = "pickup", cabin = { 0.26, 0.86, 0.1 }, bodyHeight = 20,
    color = "#283593", accent = "#90a4ae",
    length = 72, width = 36,
    stats = { speed = 3, accel = 3, handling = 2, offroad = 5 },
  },
  {
    name = "Cybertruck", style = "cyber", cabin = { 0.5, 0.82, 0.02 }, bodyHeight = 18,
    color = "#b0bec5", accent = "#eceff1",
    length = 72, width = 36,
    stats = { speed = 4, accel = 5, handling = 2, offroad = 4 },
  },
}
