# tools/

Helper scripts for development. You never need these to play or edit the
game. They're mostly how Claude checks the project on a machine without a
screen.

| File | What it does |
|---|---|
| `setup_input_map.gd` | Writes the default controls into `project.godot`. Re-running it resets those actions to the defaults. |
| `validate.sh` | Full health check: imports the project, loads every file with GDScript warnings treated as errors, runs the self-tests, then runs the main scene. Fails on any error or warning. |
| `validate_project.gd` | Loads every script, scene and resource (or just the files you list) so Godot reports problems. |
| `strict_warnings.gd` | Used by `validate.sh`: temporarily turns GDScript warnings into errors (via a throwaway `override.cfg`). |
| `run_tests.gd` + `tests/` | A tiny self-test runner. Each `*Tests.gd` file in `tests/` holds `test_...` functions. |
| `capture.sh` | Renders frames of the game to PNG files on a virtual screen (needs Xvfb + Mesa), for checking visuals without a monitor. |

## Commands

Run these from the project folder, with Godot available as `godot` (or set
`GODOT=/path/to/godot`):

```sh
tools/validate.sh                                    # check everything
godot --headless --path . -s tools/run_tests.gd      # just the self-tests
godot --headless --path . -s tools/validate_project.gd -- scenes/boot/Boot.gd   # check one file
godot --headless --path . -s tools/setup_input_map.gd                           # reset controls
tools/capture.sh 60 /tmp/shots                       # 2 seconds of the main scene as PNGs
```

Why `validate_project.gd` and not Godot's own `--check-only`? Scripts that use
autoloads (`Settings`, `GameState`, ...) can't be checked with `--check-only`,
because it compiles them before the autoloads exist and reports false errors.
`validate_project.gd` loads files after startup, so those checks are reliable.
