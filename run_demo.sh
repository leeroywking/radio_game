#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# renovate: datasource=github-releases depName=godotengine/godot versioning=loose
GODOT_RELEASE="4.5.2-stable"
LOCAL_GODOT="$ROOT_DIR/tools/godot4/Godot_v${GODOT_RELEASE}_linux.x86_64"

if [[ -x "$LOCAL_GODOT" ]]; then
  exec "$LOCAL_GODOT" --path "$ROOT_DIR" "$@"
fi

if command -v godot4 >/dev/null 2>&1; then
  exec godot4 --path "$ROOT_DIR" "$@"
fi

echo "No Godot 4 runtime found. Download the local prototype runtime or install godot4." >&2
exit 1
