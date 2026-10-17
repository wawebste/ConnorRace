-- ============================================================
--  GAME SETTINGS  -  change these numbers and restart the game
-- ============================================================
return {
  laps = 3,                 -- default number of laps (can change on track screen)
  totalRacers = 4,          -- players + computer cars (try 6!)

  -- Computer drivers
  aiSkill = 0.90,           -- 0.80 = easy, 0.90 = normal, 1.0 = hard
  catchUp = true,           -- computer cars slow down if way ahead, speed up if way behind

  -- Two-player split screen: "horizontal" = top/bottom, "vertical" = side by side
  splitScreen = "horizontal",

  -- "chase" = 3D camera low and behind your car
  -- "top"   = looking straight down from above
  view = "chase",

  -- Chase camera: how far behind and how high up (same = 45 degrees)
  chaseDistance = 210,
  chaseHeight = 210,

  -- How far you can see before things fade into the fog
  fogStart = 1500,
  fogEnd = 3400,

  -- true  = screen turns with your car (car always points up)
  -- false = map stays still, north is always up
  cameraTurns = true,

  -- Where your car sits on screen: 0.5 = middle, 0.8 = near the bottom
  cameraBehind = 0.8,

  -- Top view only: 1.0 = normal, 0.8 = zoomed out, 1.2 = zoomed in
  cameraZoom = 0.95,

  -- "auto" = fullscreen on small screens like the Steam Deck
  fullscreen = "auto",

  volume = 0.6,             -- 0 to 1
  countdown = 3,            -- seconds of 3-2-1 before GO
}
