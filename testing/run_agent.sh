#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_GODOT="$ROOT_DIR/tools/godot4/Godot_v4.5.2-stable_linux.x86_64"

if [[ -x "$LOCAL_GODOT" ]]; then
  exec "$LOCAL_GODOT" --headless --path "$ROOT_DIR" --script "res://testing/agent/agent_runner.gd" "$@"
fi

if command -v godot4 >/dev/null 2>&1; then
  exec godot4 --headless --path "$ROOT_DIR" --script "res://testing/agent/agent_runner.gd" "$@"
fi

echo "No Godot 4 runtime found. Download the local prototype runtime or install godot4." >&2
exit 1
