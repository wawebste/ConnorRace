# Connor's Race

A 3D racing game made with **LÖVE 11.x** (Lua). 1 or 2 players (split screen), computer racers, real cars drawn simply.

The camera rides behind your car (like a real racing game). Want the old look from straight above? Set `view = "top"` in `config.lua`.

## Tracks
| Track | What's special |
|---|---|
| Desert Dash | Mesas, cacti, tumbleweeds |
| Under the Sea | Water slows everyone a bit; coral, shipwreck, fish, a whale |
| Outer Space | Low gravity = cars slide more; asteroids, planets, UFOs, rockets |
| Snowy Mountain | ICY road = slippery! Zig-zag switchbacks, snowmen, cabins |
| Around the World | 8 countries + bridges over the ocean, landmarks, signs |

Every track has glowing **boost pads** — drive over the arrows for a rocket boost!

## Play it on a computer
1. Install LÖVE 11.4 or 11.5 from https://love2d.org
2. Drag the `connors-race` folder (or `connors-race.love`) onto LÖVE.

## Play it on Steam Deck / Steam Machine
1. Switch to Desktop Mode.
2. Download the LÖVE **Linux AppImage** from https://love2d.org and put it plus `connors-race.love` in a folder like `~/Games/`.
3. Right-click the AppImage → Properties → Permissions → "Is executable".
4. In Steam: **Games → Add a Non-Steam Game** → pick the AppImage.
5. Open that new entry's Properties and set **Launch Options** to the full path of the game, e.g. `/home/deck/Games/connors-race.love`
6. Back to Gaming Mode — it's in your library. For 2 players, connect a second controller.

## Controls
| | Controller (Steam Deck) | Keyboard P1 | Keyboard P2 |
|---|---|---|---|
| Gas | Right trigger or A | W | Up |
| Brake / reverse | Left trigger, B or X | S | Down |
| Steer | Left stick or D-pad | A / D | Left / Right |
| Back on the road | Y | R | Right Shift |
| Pause | Start | Esc | |

F11 = fullscreen.

## Changing things (start here!)
| Want to... | Edit |
|---|---|
| Laps, number of racers, difficulty, split-screen direction | `config.lua` |
| Camera: 3D chase or top-down, how far behind / how high, fog | `config.lua` (`view`, `chaseDistance`, `chaseHeight`, `fogEnd`) |
| Add a car or change colors/stats | `cars.lua` (copy a block) |
| New car drawing style | `src/cardraw.lua` (copy a style function) |
| Change the desert track shape or scenery | `tracks/desert.lua` |
| Make a new track | copy `tracks/desert.lua` → e.g. `tracks/jungle.lua`, then add `file = "tracks.jungle"` in `tracks/init.lua` |
| How cars drive (speed, grip) | top of `Car.new` in `src/car.lua` |
| Computer driver brains | `src/ai.lua` |

### Track tips
- `boosts = { 0.1, 0.5 }` puts boost pads 10% and 50% of the way around.
- `physics = { grip = 0.6, speed = 0.9 }` makes the track slippery (grip) or slower (speed).
- `at = { { t = 0.3, side = 1, off = 400 } }` in a scenery line puts something at an exact spot: 30% around the track, right side, 400 from the middle of the road.
- Drawings that call `S.upright(cam)` stand up on the screen like stickers (snowmen, landmarks, seaweed).
- `overlay` draws over the whole screen (the blue water tint under the sea).
- **3D view:** `heightScale = 2` makes something stand tall (2x its size), `taper = 0.9` makes it pointy like a cone (pine trees, mountains), `float = 100` makes it hover (fish, UFOs). `sky` and `fog` colors set the sky.
- In the 3D view, solid things are built from stacked copies of their drawing. A drawing can check `S.sliceT` (0 = bottom, 1 = top) to change with height — the cactus uses it to put its arms partway up.
- `points` is the road's path. The race starts at the first point. Keep points at least ~500 apart from other parts of the road so roads don't overlap.
- `scenery` lists what to sprinkle; `draw` says how each thing looks; `solid = true` means cars bump into it.

## Files
```
main.lua          starts the game, switches screens
config.lua        settings
cars.lua          the cars
tracks/           one file per track + the track list
src/track.lua     builds roads from points
src/car.lua       car movement
src/cardraw.lua   car drawings
src/ai.lua        computer drivers
src/input.lua     controllers + keyboard
src/audio.lua     beeps and engine sound
src/scenery.lua   drawing helpers for track files
src/view3d.lua    the 3D chase camera
src/screens/      title, car pick, track pick, race, results
```

## Make a .love file
Zip the *contents* of this folder (main.lua must be at the top of the zip) and rename `.zip` to `.love`.
