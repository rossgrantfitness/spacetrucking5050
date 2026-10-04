# tools/

Helper scripts for development. You never need these to play or edit the
game. They're mostly how Claude builds placeholder assets and checks the
project on a machine without a screen.

## Asset makers (run once; their results are committed)

| File | What it makes |
|---|---|
| `setup_input_map.gd` | The default controls in `project.godot`. Re-running resets those actions to the defaults. |
| `generate_placeholder_textures.gd` | Small PS1-style textures in `textures/generated/` (hazard stripes, hull plating, cargo containers, chevrons, vents, rock, station windows, engine flare, nebula, the planet). |
| `generate_sounds.gd` | The engine hum's four loops (from `scenes/flight/EngineSynth.gd`) plus the bonk, the dialogue blip, the radio static burst, a big ship's engine rumble, whale song and a whoosh (from `scenes/common/SfxSynth.gd`), in `audio/generated/`, made from math. |
| `build_hub.gd` | The base: the bunny and Dottie models (`scenes/hub/*Visual.tscn`) and the rooms' sets (`scenes/hub/sets/`). **Re-running overwrites those**, but never the rooms' cameras, doors or people. |
| `build_world.gd` | The stations seen from space: the home base (`BaseStation.tscn`), Tidewater Cannery (`CanneryStation.tscn`) and the Gas-N-Go drive-through (`GasNGo.tscn`), in `scenes/flight/`. **Re-running overwrites them.** |
| `build_road.gd` | Everything fixed along the road to Tidewater (`scenes/flight/TidewaterRoad.tscn`): signs, landmarks, debris fields, hazards, whales, long-haul traffic, each placed by "km along the road / meters to the side / meters up". **Re-running overwrites it.** |
| `generate_world_textures.gd` | Tidewater's ocean planet and the suns' surface (`textures/generated/ocean_planet.png`, `sun_surface.png`). |
| `build_truck_stop.gd` | The truck stop's inside (`scenes/hub/sets/TruckStopSet.tscn`) and its people's models (`OwlVisual`, `BeaverVisual`, `FrogVisual`, `WalrusVisual`, `HamsterVisual`). **Re-running overwrites those**, but never the room's cameras, doors, people or things to use (`scenes/hub/TruckStop.tscn`). |
| `generate_radio_placeholders.gd` | The radio's placeholder music: a short loop per station (`audio/radio/<station>/placeholder_loop.wav`), the ambient music for when the radio's off, and the weak-signal hiss. Made from math. |
| `build_placeholder_models.gd` | The rig (`scenes/flight/ShipVisual.tscn`), its cockpit (`scenes/flight/CockpitInterior.tscn`), the traffic ships (`scenes/flight/traffic/`, except the CC0 courier) and the truck stop with its parking deck (`scenes/flight/Station.tscn`) from simple chunky shapes with PS1 materials. **Re-running overwrites those scenes**, so don't if you've edited them by hand. |

## Checkers

| File | What it does |
|---|---|
| `validate.sh` | Full health check: imports the project, loads every file with GDScript warnings treated as errors, runs the self-tests, runs the boot screen, flies on autopilot, walks the base (`smoke_hub.gd`) and plays the first mission (`smoke_mission.gd`). Fails on any error or warning. The automated runs save to a scratch file, never your real save. |
| `validate_project.gd` | Loads every script, scene and resource (or just the files you list) so Godot reports problems. |
| `strict_warnings.gd` | Used by `validate.sh`: temporarily turns GDScript warnings into errors (via a throwaway `override.cfg`). |
| `run_tests.gd` + `tests/` | A tiny self-test runner. Each `*Tests.gd` file in `tests/` holds `test_...` functions. |
| `smoke_flight.gd` | Flies on autopilot (throttle, turns, boost, cockpit view, radio, HUD hide and demo, a comm call, pause menu, back to the launch point), then flies through the truck stop's approach ring and checks the autopilot docks and you end up inside. |
| `smoke_mission.gd` | Plays the first mission from a new game: talks to Marge, takes the long haul, visits Lily's pumps, boards the rig, skips most of the road, lets the cruise autopilot fly into Tidewater's ring, gets paid at the drop-off counter and launches, then charts a course through the Gas-N-Go drive-through and checks it rolls out still moving. |
| `capture.sh` | Renders frames of the game to PNG files (plus the audio as a WAV) on a virtual screen (needs Xvfb + Mesa), for checking visuals without a monitor. |

## Commands

Run these from the project folder, with Godot available as `godot` (or set
`GODOT=/path/to/godot`):

```sh
tools/validate.sh                                    # check everything
godot --headless --path . -s tools/run_tests.gd      # just the self-tests
godot --headless --path . -s tools/validate_project.gd -- scenes/boot/Boot.gd   # check one file
godot --headless --path . -s tools/setup_input_map.gd                           # reset controls
tools/capture.sh 60 /tmp/shots                       # 2 seconds of the main scene as PNGs
tools/capture.sh 90 /tmp/shots res://scenes/flight/FlightSandbox.tscn          # the flight sandbox
RES=800x600 tools/capture.sh 60 /tmp/shots                                     # another window size
```

Why `validate_project.gd` and not Godot's own `--check-only`? Scripts that use
autoloads (`Settings`, `GameState`, ...) can't be checked with `--check-only`,
because it compiles them before the autoloads exist and reports false errors.
`validate_project.gd` loads files after startup, so those checks are reliable.

Good to know: if you edit a `.import` file by hand (outside the editor), also
delete that file's cached copy in `.godot/imported/`, or Godot won't notice the
change. The editor's Import dock does this for you.
