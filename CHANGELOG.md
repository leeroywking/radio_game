# Changelog

## Unreleased

- Added tracked `export_presets.cfg` for Linux, Windows, and HTML5 builds.
- Added `scripts/build_exports.sh` to download export templates and package release artifacts.
- Added `docs/distribution.md` describing local outputs and itch.io upload paths.
- Built release artifacts into `dist/` for desktop and browser distribution.
- Added a headless gameplay testing agent under `testing/`.
- Added an initial automated behavior report under `testing/reports/`.
- Replaced the decorative waterfall with a fake full-band waterfall showing simulated energy by frequency over time.
- Fixed the waterfall rendering path by moving it into the HUD layer and added an automated visibility test for it.

## 2026-04-05

- Created the initial Godot-based rabbit hunt trainer prototype.
- Added architecture and prototype documentation.
- Implemented a playable DF/scanner training loop.
- Added real USGS Washington hillshade map backdrop.
- Added multiple broadcasters with one designated target conversation.
- Added DF tuning by slider and direct numeric entry.
- Added scanner sweep, lock, and unlock behavior.
- Added separate DF and scanner volume controls.
- Added a placeholder waterfall element.
- Tightened DF directionality.
- Added issue tracking and handoff documentation.
- Initialized git and committed baseline `f71ed0e`.
