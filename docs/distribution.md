# Distribution Notes

## Build targets

This repository now supports three export targets from the current Godot 3.5 prototype:

- Linux desktop
- Windows desktop
- HTML5 browser build

The repeatable export script is:

```bash
./scripts/build_exports.sh
```

## Output layout

The build script writes files into `dist/`:

- `dist/staging/linux/`
- `dist/staging/windows/`
- `dist/staging/html5/`
- `dist/releases/`
- `dist/itch/downloads/`
- `dist/itch/html5/`

Use these folders as follows:

- `dist/staging/linux/`: unpacked local Linux build
- `dist/staging/windows/`: unpacked Windows build
- `dist/staging/html5/`: unpacked browser build for local testing or static hosting
- `dist/releases/`: zipped release artifacts
- `dist/itch/downloads/`: desktop zips ready to upload as downloadable files on itch.io
- `dist/itch/html5/`: browser zip ready to upload as an itch.io HTML game

## itch.io

Recommended packaging flow:

1. Upload `dist/itch/downloads/RabbitHuntTrainer-linux-x86_64.zip` as a downloadable Linux build.
2. Upload `dist/itch/downloads/RabbitHuntTrainer-windows-x86_64.zip` as a downloadable Windows build.
3. Upload `dist/itch/html5/RabbitHuntTrainer-html5.zip` to an itch.io project configured as an HTML game.

## Local browser testing

The HTML5 build should be served over HTTP, not opened directly with `file://`.

Example:

```bash
cd dist/staging/html5
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Notes

- Export templates are installed on demand into the user Godot template directory.
- The project uses `all_resources` export filtering so runtime-loaded map and audio assets are included in exported builds.
