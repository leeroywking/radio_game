#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# renovate: datasource=github-releases depName=godotengine/godot versioning=loose
GODOT_RELEASE="4.5.2-stable"
GODOT_BIN="$ROOT_DIR/tools/godot4/Godot_v${GODOT_RELEASE}_linux.x86_64"
GODOT_VERSION="${GODOT_RELEASE/-/.}"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$GODOT_VERSION"
TEMPLATE_ARCHIVE="$ROOT_DIR/tools/export_templates/Godot_v${GODOT_RELEASE}_export_templates.tpz"
TEMPLATE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_export_templates.tpz"
TEMPLATE_SHA512="003aa33743f58fb657717f090fc872ed3975e48d08a6012201a2259970d458a63d4d8a83090585307c23455ebfa4e6e0050e1057761c34863536095e3fcfab6c"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

verify_sha512() {
  local expected_sha="$1"
  local file_path="$2"
  echo "$expected_sha  $file_path" | sha512sum --check --
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
require_cmd sha512sum

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
  verify_sha512 "$TEMPLATE_SHA512" "$TEMPLATE_ARCHIVE"

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
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Linux/X11" "dist/staging/linux/RabbitHuntTrainer.x86_64"

echo "Exporting Windows build..."
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "Windows Desktop" "dist/staging/windows/RabbitHuntTrainer.exe"

echo "Exporting HTML5 build..."
"$GODOT_BIN" --headless --path "$ROOT_DIR" --export-release "HTML5" "dist/staging/html5/index.html"

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
