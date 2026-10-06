#!/usr/bin/env bash
# Headless health check for Space Truckin' 5050. Run from anywhere:
#     tools/validate.sh
# Uses the `godot` command, or set GODOT=/path/to/godot to pick a binary.
#
# It (1) imports the project, (2) loads every script, scene and resource with
# GDScript warnings promoted to errors and runs the self-tests in tools/tests/, and
# (3) runs the main scene, then flies the flight sandbox on autopilot
# (tools/smoke_flight.gd), walks around the base (tools/smoke_hub.gd),
# loads the rig with the forklift at the loading dock (tools/smoke_dock.gd),
# plays the first mission (tools/smoke_mission.gd), the trip to the casino
# in the Glimmer System (tools/smoke_glimmer.gd), a crash at boost speed
# (tools/smoke_crash.gd) and tries the cabin,
# comm replies and radio (tools/smoke_cabin.gd).
# It fails if Godot printed ANY error or warning.
set -u
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
LOG="$(mktemp)"
cleanup() { rm -f override.cfg "$LOG"; }
trap cleanup EXIT

run() {
	echo "\$ godot $*" >>"$LOG"
	timeout 300 "$GODOT" --headless --path . "$@" >>"$LOG" 2>&1
	local status=$?
	if [ "$status" -ne 0 ]; then
		echo "Godot exited with status $status: godot $*" >>"$LOG"
		echo "ERROR: non-zero exit" >>"$LOG"
	fi
}

echo "== Godot: $("$GODOT" --version)"

echo "== 1/3 Importing project"
run --import

echo "== 2/3 Loading every file (warnings count as errors) + self-tests"
rm -f override.cfg
run -s tools/strict_warnings.gd
run -s tools/validate_project.gd
run -s tools/run_tests.gd

echo "== 3/3 Running the playable scenes"
run --quit-after 600
run -s tools/smoke_flight.gd
run -s tools/smoke_hub.gd
run -s tools/smoke_dock.gd
run -s tools/smoke_mission.gd
run -s tools/smoke_cabin.gd
run -s tools/smoke_glimmer.gd
run -s tools/smoke_crash.gd
rm -f override.cfg

if grep -E "ERROR|WARNING|Parse Error" "$LOG" >/dev/null; then
	echo
	echo "!! Problems found. Full log:"
	cat "$LOG"
	exit 1
fi

grep -E "^Checked [0-9]+ file|^Self-tests finished" "$LOG"
echo "== All clear: no errors or warnings."
