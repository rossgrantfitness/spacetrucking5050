# tools/

Helper scripts for development. You never need these to play or edit the
game. They're mostly how Claude builds placeholder assets and checks the
project on a machine without a screen.

## Asset makers (run once; their results are committed)

| File | What it makes |
|---|---|
| `setup_input_map.gd` | The default controls in `project.godot`. Re-running resets those actions to the defaults. |
| `generate_placeholder_textures.gd` | Small textures in `textures/generated/` (the hazard stripes). |
| `generate_engine_sounds.gd` | The engine hum's four loops in `audio/generated/` (made from math by `scenes/flight/EngineSynth.gd`). |
| `build_placeholder_models.gd` | The rig (`scenes/flight/ShipVisual.tscn`) and the truck stop (`scenes/flight/Station.tscn`) from simple shapes. **Re-running overwrites those scenes**, so don't if you've edited them by hand. |

## Checkers

| File | What it does |
|---|---|
| `validate.sh` | Full health check: imports the project, loads every file with GDScript warnings treated as errors, runs the self-tests, runs the boot screen, and flies the sandbox on autopilot. Fails on any error or warning. |
| `validate_project.gd` | Loads every script, scene and resource (or just the files you list) so Godot reports problems. |
| `strict_warnings.gd` | Used by `validate.sh`: temporarily turns GDScript warnings into errors (via a throwaway `override.cfg`). |
| `run_tests.gd` + `tests/` | A tiny self-test runner. Each `*Tests.gd` file in `tests/` holds `test_...` functions. |
| `smoke_flight.gd` | Flies the flight sandbox on autopilot (throttle, turns, boost, cockpit view, pause menu, back to start) to shake out errors, then quits politely. |
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
```

Why `validate_project.gd` and not Godot's own `--check-only`? Scripts that use
autoloads (`Settings`, `GameState`, ...) can't be checked with `--check-only`,
because it compiles them before the autoloads exist and reports false errors.
`validate_project.gd` loads files after startup, so those checks are reliable.

Good to know: if you edit a `.import` file by hand (outside the editor), also
delete that file's cached copy in `.godot/imported/`, or Godot won't notice the
change. The editor's Import dock does this for you.
