# tools/

Helper scripts for development. You never need these to play or edit the
game. They're mostly how Claude builds placeholder assets and checks the
project on a machine without a screen.

## Asset makers (run once; their results are committed)

| File | What it makes |
|---|---|
| `setup_input_map.gd` | The default controls in `project.godot`. Re-running resets those actions to the defaults. |
| `generate_placeholder_textures.gd` | Small PS1-style textures in `textures/generated/` (hazard stripes, hull plating, cargo containers, chevrons, vents, rock, station windows, engine flare, nebula, the planet). |
| `generate_sounds.gd` | The engine hum's four loops (from `scenes/flight/EngineSynth.gd`) plus the bonk, the dialogue blip, the radio static burst, a big ship's engine rumble, whale song, a whoosh, the intro's power-on chime and self-test beep, a crate thump, the cab rattle, the boost spool, the four other voice types (square, reed, gruff, chirp) and the game cues `cue_*.wav` (menus, jobs, the nav computer, money, doors; played with `Sfx.play`) (from `scenes/common/SfxSynth.gd`), in `audio/generated/`, made from math. |
| `build_hub.gd` | The base: the bunny and Dottie models (`scenes/hub/*Visual.tscn`) and the rooms' sets (`scenes/hub/sets/`). **Re-running overwrites those**, but never the rooms' cameras, doors or people. |
| `build_world.gd` | The stations seen from space: the home base (`BaseStation.tscn`), Tidewater Cannery (`CanneryStation.tscn`) and the Gas-N-Go drive-through (`GasNGo.tscn`), in `scenes/flight/`. **Re-running overwrites them.** |
| `build_cannery.gd` | Tidewater Cannery's canteen set (`scenes/hub/sets/CanneryCanteenSet.tscn`) and Gill's model (`scenes/hub/OtterVisual.tscn`). **Re-running overwrites those**, but never the room's cameras, doors, people or things to use (`scenes/hub/CanneryCanteen.tscn`). |
| `build_road.gd` | Everything fixed along the road to Tidewater (`scenes/flight/TidewaterRoad.tscn`): signs, landmarks, debris fields, hazards, whales, long-haul traffic, each placed by "km along the road / meters to the side / meters up". **Re-running overwrites it.** |
| `generate_world_textures.gd` | Tidewater's ocean planet, Glimmer's magenta gas giant and the suns' surface (`textures/generated/ocean_planet.png`, `glimmer_planet.png`, `sun_surface.png`). |
| `build_high_roller.gd` | Sal's casino seen from space (`scenes/flight/HighRollerStation.tscn`): a turning roulette wheel, a hotel tower, a giant neon sign. **Re-running overwrites it.** |
| `build_glimmer_road.gd` | Everything fixed along the road to the Glimmer System (`scenes/flight/GlimmerRoad.tscn`): signs, the border gate, neon billboards, the giant slot machine, the dice, the chapel, a chip spill, the speed trap, limos. **Re-running overwrites it.** |
| `build_casino_lounge.gd` | The casino floor's set (`scenes/hub/sets/HighRollerLoungeSet.tscn`) and Sal's model (`scenes/hub/CrocodileVisual.tscn`). **Re-running overwrites those**, but never the room's cameras, doors, people or things to use (`scenes/hub/HighRollerLounge.tscn`). |
| `build_truck_stop.gd` | The truck stop's inside (`scenes/hub/sets/TruckStopSet.tscn`) and its people's models (`OwlVisual`, `BeaverVisual`, `FrogVisual`, `WalrusVisual`, `HamsterVisual`). **Re-running overwrites those**, but never the room's cameras, doors, people or things to use (`scenes/hub/TruckStop.tscn`). |
| `generate_radio_placeholders.gd` | The radio's placeholder music: a short loop per genre (`audio/radio/placeholders/`, shared by stations of a kind: drum & bass, dubstep, synthwave, metal, rock, hip hop, talk radio, a numbers station...), the ambient music for when the radio's off, and the weak-signal hiss. Made from math. |
| `generate_pixel_font.gd` | The game's font (`fonts/pixel_font.tres`) from the HUD's pixel letters in `scenes/ui/PixelFont.gd`. Re-run it after adding letters there. |
| `route_events/import_route_events.py` | The route events list (`data/events/route_events.tres`) from your design list (`docs/ROUTE_EVENTS_LIST.md`) plus what each playable event does (written in the script). Python, not Godot: `python3 tools/route_events/import_route_events.py`. **Re-running overwrites the list**, so make inspector edits in the script too. |
| `build_player_rig.gd` | The Thumper, your one rig, from the five load models in `art/models/rig_load_0..4.glb` (`scenes/flight/RigLoadVisual.tscn`: empty deck up to piled high, one shown by how heavy the job is). Places the 4 engine "Nozzle" markers. **Re-running overwrites it.** |
| `build_traffic_models.gd` | Your traffic ships from `art/models/traffic_*.glb` (`scenes/flight/traffic/*Visual.tscn`). |
| `texture_paint.gd` | Not run by itself: the MML / MGS painter used by the two texture generators (flat dithered tones for planets, faceted rock, cratered moons). |
| `build_crew.gd` | The crew's models (`scenes/hub/crew/DottieVisual.tscn`, `MoleVisual.tscn`, `DonkeyVisual.tscn`) from your Meshy models in `assets/characters/crew_*/source.glb`: cut into parts the walk animation swings, arms dropped from the T-pose, stood on the floor. Add a character with a new entry in its CREW list. **Re-running overwrites those.** |
| `build_rig_rooms.gd` | The rig's galley, engine room and cargo bay: their sets (`scenes/hub/sets/GalleySet.tscn`, ...) every time, and their room scenes (`scenes/hub/Galley.tscn`, ...) **only if they don't exist yet**, so cameras and crew spots you move in the editor are kept. |
| `crew_data/make_crew.py` | The crew's activities, small talk, greetings and the ship events (`data/crew/crew.tres`), plus Digby's and Clem's name files, from plain lists. Python: `python3 tools/crew_data/make_crew.py`. **Re-running overwrites crew.tres**, so make edits in the script. |
| `build_placeholder_models.gd` | The rig (`scenes/flight/ShipVisual.tscn`), its cockpit (`scenes/flight/CockpitInterior.tscn`), the traffic ships (`scenes/flight/traffic/`, except the CC0 courier) and the truck stop with its parking deck (`scenes/flight/Station.tscn`) from simple chunky shapes with PS1 materials. **Re-running overwrites those scenes**, so don't if you've edited them by hand. |

## Checkers

| File | What it does |
|---|---|
| `validate.sh` | Full health check: imports the project, loads every file with GDScript warnings treated as errors, runs the self-tests, runs the boot screen, flies on autopilot, walks the rig and talks to the crew (`smoke_hub.gd`), plays the first mission (`smoke_mission.gd`), tries the cabin (`smoke_cabin.gd`) and makes the trip to Sal's casino (`smoke_glimmer.gd`). Fails on any error or warning. The automated runs save to a scratch file, never your real save. |
| `validate_project.gd` | Loads every script, scene and resource (or just the files you list) so Godot reports problems. |
| `strict_warnings.gd` | Used by `validate.sh`: temporarily turns GDScript warnings into errors (via a throwaway `override.cfg`). |
| `run_tests.gd` + `tests/` | A tiny self-test runner. Each `*Tests.gd` file in `tests/` holds `test_...` functions. |
| `smoke_flight.gd` | Flies on autopilot (throttle, turns, boost, cockpit view, radio, HUD hide and demo, a comm call, pause menu, back to the launch point), then flies through the truck stop's approach ring and checks the autopilot docks and you end up inside. |
| `smoke_mission.gd` | Plays the first mission from a new game: talks to Marge, takes the long haul, visits Lily's pumps, boards the rig, skips most of the road, lets the cruise autopilot fly into Tidewater's ring, climbs out in the canteen and gets paid, boards again, then charts a course through the Gas-N-Go drive-through and checks it rolls out still moving. |
| `smoke_cabin.gd` | Charts a course, takes a comm call and replies, flips through every radio station (with DJ reactions), walks into the rig's cabin and the galley, checks the apartment's live window, naps, wakes up and gets back in the seat, checking each step. |
| `capture.sh` | Renders frames of the game to PNG files (plus the audio as a WAV) on a virtual screen (needs Xvfb + Mesa), for checking visuals without a monitor. |

## Commands

Run these from the project folder, with Godot available as `godot` (or set
`GODOT=/path/to/godot`):

```sh
tools/validate.sh                                    # check everything
godot --headless --path . -s tools/run_tests.gd      # just the self-tests
godot --headless --path . -s tools/validate_project.gd -- scenes/boot/Boot.gd   # check one file
godot --headless --path . -s tools/setup_input_map.gd                           # reset controls
godot --headless --path . -s tools/paint_textures.gd      # repaint the hand-painted textures
godot --headless --path . -s tools/build_bunny.gd         # rebuild the bunny from her 3D model
godot --headless --path . -s tools/build_crew.gd          # rebuild the crew from their 3D models
godot --headless --path . -s tools/build_player_rig.gd     # rebuild the Thumper from its five load models
godot --headless --path . -s tools/generate_sounds.gd     # remake the sounds (engine, voices, menu and game cues)
godot --headless --path . -s tools/build_rig_rooms.gd     # rebuild the galley, engine room and cargo bay
python3 tools/crew_data/make_crew.py                      # rewrite the crew's lines and ship events
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
