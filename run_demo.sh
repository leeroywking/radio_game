#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GODOT="$ROOT_DIR/tools/godot3/Godot_v3.5.3-stable_x11.64"

if [[ -x "$LOCAL_GODOT" ]]; then
  exec "$LOCAL_GODOT" --path "$ROOT_DIR" "$@"
fi

if command -v godot3 >/dev/null 2>&1; then
  exec godot3 --path "$ROOT_DIR" "$@"
fi

echo "No Godot runtime found. Download the local prototype runtime or install godot3." >&2
exit 1
