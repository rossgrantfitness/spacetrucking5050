#!/bin/bash
# SessionStart hook for Claude Code cloud sessions (does nothing anywhere else).
#
# Cloud containers don't come with Godot, so this downloads the exact Godot
# version the project uses, puts `godot` on the PATH, and imports the project
# once so tools/validate.sh works straight away. Safe to run repeatedly: if
# Godot is already installed it just re-links it.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GODOT_VERSION="4.7.2"  # Keep in sync with config/features in project.godot.
INSTALL_DIR="$HOME/.local/godot"
BINARY="$INSTALL_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"

if [ ! -x "$BINARY" ]; then
  echo "Installing Godot ${GODOT_VERSION}..."
  mkdir -p "$INSTALL_DIR"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 4 --retry-delay 2 -o "$tmp/godot.zip" "$URL"
  if command -v unzip > /dev/null; then
    unzip -q -o "$tmp/godot.zip" -d "$INSTALL_DIR"
  else
    python3 -m zipfile -e "$tmp/godot.zip" "$INSTALL_DIR"
  fi
  chmod +x "$BINARY"
fi

# Make `godot` available to every command in this session.
ln -sf "$BINARY" "$INSTALL_DIR/godot"
if [ -w /usr/local/bin ]; then
  ln -sf "$BINARY" /usr/local/bin/godot
fi
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Build Godot's import cache (.godot/) so scripts can be checked right away.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"
if ! timeout 300 "$BINARY" --headless --path . --import > /tmp/godot-import.log 2>&1; then
  echo "Warning: the Godot import reported problems; see /tmp/godot-import.log"
fi
echo "Godot $("$BINARY" --version) is ready (run tools/validate.sh to check the project)."
