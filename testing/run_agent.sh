#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_GODOT="$ROOT_DIR/tools/godot4/Godot_v4.5.2-stable_linux.x86_64"

run_godot() {
  if [[ -x "$LOCAL_GODOT" ]]; then
    "$LOCAL_GODOT" "$@"
    return
  fi

  if command -v godot4 >/dev/null 2>&1; then
    godot4 "$@"
    return
  fi

  echo "No Godot 4 runtime found. Download the local prototype runtime or install godot4." >&2
  exit 1
}

if [[ ! -d "$ROOT_DIR/.godot/imported" ]]; then
  run_godot --headless --path "$ROOT_DIR" --import
fi

run_godot --headless --path "$ROOT_DIR" --script "res://testing/agent/agent_runner.gd" "$@"
