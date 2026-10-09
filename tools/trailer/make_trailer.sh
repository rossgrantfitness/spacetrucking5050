#!/usr/bin/env bash
# Makes the 30-second trailer (trailer/space_truckin_5050_trailer.mp4) from
# the real game: films three parts with Godot's Movie Maker (space, on foot,
# title cards), then tools/trailer/assemble.py cuts them to the music's beat.
#
# Needs: Godot (the `godot` command, or GODOT=/path/to/godot), ffmpeg and
# Python 3. On a machine without a screen (like the cloud), it runs Godot
# under xvfb-run. Filming takes several minutes: Movie Maker renders every
# frame properly, slower than real time.
#     tools/trailer/make_trailer.sh
set -eu
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-godot}"
WORK="$(mktemp -d)"
mkdir -p trailer
RUN=()
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null; then
	RUN=(xvfb-run -a -s "-screen 0 1280x720x24")
fi
for part in cards rooms flight; do
	echo "== Filming: $part"
	"${RUN[@]}" "$GODOT" --path . --resolution 1280x720 --write-movie "$WORK/$part.avi" --fixed-fps 30 \
		-s tools/trailer/make_trailer.gd -- "part=$part" >"$WORK/$part.log" 2>&1
	grep "^CUT" "$WORK/$part.log"
done
echo "== Cutting to the beat"
python3 tools/trailer/assemble.py "$WORK" trailer/space_truckin_5050_trailer.mp4
rm -rf "$WORK"
