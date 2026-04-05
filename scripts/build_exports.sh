#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="$ROOT_DIR/tools/godot3/Godot_v3.5.3-stable_x11.64"
GODOT_VERSION="3.5.3.stable"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/templates/$GODOT_VERSION"
TEMPLATE_ARCHIVE="$ROOT_DIR/tools/export_templates/Godot_v3.5.3-stable_export_templates.tpz"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/3.5.3-stable/Godot_v3.5.3-stable_export_templates.tpz"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

download_file() {
  local url="$1"
  local output_path="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$output_path"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output_path" "$url"
    return
  fi

  echo "Missing required downloader: curl or wget" >&2
  exit 1
}

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Missing Godot runtime at $GODOT_BIN" >&2
  exit 1
fi

require_cmd unzip
require_cmd zip

mkdir -p "$ROOT_DIR/dist/staging/linux" \
  "$ROOT_DIR/dist/staging/windows" \
  "$ROOT_DIR/dist/staging/html5" \
  "$ROOT_DIR/dist/releases" \
  "$ROOT_DIR/dist/itch/downloads" \
  "$ROOT_DIR/dist/itch/html5" \
  "$ROOT_DIR/tools/export_templates"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  if [[ ! -f "$TEMPLATE_ARCHIVE" ]]; then
    echo "Downloading Godot export templates..."
    download_file "$TEMPLATE_URL" "$TEMPLATE_ARCHIVE"
  fi

  rm -rf "$TEMPLATE_DIR"
  mkdir -p "$TEMPLATE_DIR"
  unzip -oq "$TEMPLATE_ARCHIVE" -d "$TEMPLATE_DIR"

fi

if [[ -d "$TEMPLATE_DIR/templates" ]]; then
  find "$TEMPLATE_DIR/templates" -mindepth 1 -maxdepth 1 -exec mv {} "$TEMPLATE_DIR/" \;
  rmdir "$TEMPLATE_DIR/templates"
fi

rm -f \
  "$ROOT_DIR/dist/staging/linux/RabbitHuntTrainer.x86_64" \
  "$ROOT_DIR/dist/staging/linux/RabbitHuntTrainer.pck" \
  "$ROOT_DIR/dist/staging/windows/RabbitHuntTrainer.exe" \
  "$ROOT_DIR/dist/staging/windows/RabbitHuntTrainer.pck" \
  "$ROOT_DIR/dist/staging/html5/index.html" \
  "$ROOT_DIR/dist/staging/html5/index.js" \
  "$ROOT_DIR/dist/staging/html5/index.pck" \
  "$ROOT_DIR/dist/staging/html5/index.png" \
  "$ROOT_DIR/dist/staging/html5/index.wasm"

echo "Exporting Linux build..."
"$GODOT_BIN" --path "$ROOT_DIR" --export "Linux/X11" "dist/staging/linux/RabbitHuntTrainer.x86_64"

echo "Exporting Windows build..."
"$GODOT_BIN" --path "$ROOT_DIR" --export "Windows Desktop" "dist/staging/windows/RabbitHuntTrainer.exe"

echo "Exporting HTML5 build..."
"$GODOT_BIN" --path "$ROOT_DIR" --export "HTML5" "dist/staging/html5/index.html"

(
  cd "$ROOT_DIR/dist/staging/linux"
  zip -9 -q "$ROOT_DIR/dist/releases/RabbitHuntTrainer-linux-x86_64.zip" \
    RabbitHuntTrainer.x86_64 \
    RabbitHuntTrainer.pck
)

(
  cd "$ROOT_DIR/dist/staging/windows"
  zip -9 -q "$ROOT_DIR/dist/releases/RabbitHuntTrainer-windows-x86_64.zip" \
    RabbitHuntTrainer.exe \
    RabbitHuntTrainer.pck
)

(
  cd "$ROOT_DIR/dist/staging/html5"
  zip -9 -q "$ROOT_DIR/dist/releases/RabbitHuntTrainer-html5.zip" \
    index.html \
    index.js \
    index.pck \
    index.png \
    index.wasm
)

cp "$ROOT_DIR/dist/releases/RabbitHuntTrainer-linux-x86_64.zip" "$ROOT_DIR/dist/itch/downloads/"
cp "$ROOT_DIR/dist/releases/RabbitHuntTrainer-windows-x86_64.zip" "$ROOT_DIR/dist/itch/downloads/"
cp "$ROOT_DIR/dist/releases/RabbitHuntTrainer-html5.zip" "$ROOT_DIR/dist/itch/html5/"

echo "Build artifacts:"
echo "  Desktop zips: $ROOT_DIR/dist/itch/downloads"
echo "  HTML5 zip:    $ROOT_DIR/dist/itch/html5"
echo "  Unpacked web: $ROOT_DIR/dist/staging/html5"
