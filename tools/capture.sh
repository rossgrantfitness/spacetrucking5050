#!/usr/bin/env bash
# Renders the game to PNG frames on a virtual screen, so visuals can be
# checked on a machine with no monitor (like a cloud container). It uses
# Godot's Movie Maker mode, Xvfb (a fake screen) and Mesa (software OpenGL).
#
#   tools/capture.sh [frames] [out_dir] [extra godot args...]
#
# Examples:
#   tools/capture.sh 60 /tmp/shots                     # the main scene
#   tools/capture.sh 90 /tmp/shots res://scenes/boot/Boot.tscn
#
# Frames are recorded at a fixed 30 FPS, so 90 frames = 3 seconds of game time.
# Set RES to pick the window size (default 1280x720), e.g.
#   RES=800x600 tools/capture.sh 60 /tmp/shots     or     RES=3840x2160 ...
set -eu
cd "$(dirname "$0")/.."

FRAMES="60"
OUT="/tmp/godot_capture"
if [ $# -gt 0 ]; then FRAMES="$1"; shift; fi
if [ $# -gt 0 ]; then OUT="$1"; shift; fi
mkdir -p "$OUT"

RES="${RES:-1280x720}"
xvfb-run -a -s "-screen 0 3840x2160x24" "${GODOT:-godot}" --path . \
	--resolution "$RES" --write-movie "$OUT/frame.png" --fixed-fps 30 \
	--quit-after "$FRAMES" "$@"
echo "Frames written to $OUT"
