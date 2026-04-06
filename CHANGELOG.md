# Changelog

## Unreleased

- Added `VERSION` as the source of truth for shipped release versions.
- Changed GitHub release automation to publish versioned releases only when `VERSION` changes on `master` or `main`.
- Added CI enforcement so product-facing PRs must bump `VERSION`.
- Bumped project version to `0.4.2` for the native 3D first-person replacement pass.
- Added `docs/native-3d-first-person-plan.md` documenting the decision to use Godot native 3D terrain/controller architecture instead of a Doom-style sub-engine.
- Replaced the old first-person camera shim with a native 3D player-body path over generated terrain.
- Added terrain-mesh and elevation-response regression coverage for the first-person mode.
- Added `docs/first-person-can-antenna-plan.md` describing the first-person DF architecture, phases, and integration plan.
- Added a first vertical slice of a first-person can-antenna mode using a low-resolution 3D viewport inside the existing 2D game.
- Added a first-person heading model, simple can-antenna view model, and tactical inset map that shows captured lines of bearing.
- Added in-view first-person reading overlays for heading, DF frequency, last reading, and step prompt text.
- Added regression cases covering first-person mode toggle behavior and first-person reading capture.
- Changed first-person controls to Doom-style movement, with `WASD` moving relative to heading instead of map axes.
- Restored the top-down hunt view to a fixed paper-map presentation so the whole mission area stays visible at once.
- Added broader terrain cues to the first-person view using the Washington hillshade as a source for hills, ridges, and valleys.
- Restored practical broadcaster spacing and audio range after the oversized-world experiment made the band too sparse from the player start.
- Added a regression case that requires all broadcasters to remain on the visible paper map after reset.
- Fixed DF/scanner shared-broadcast playback so both receivers stay sample-aligned on the same conversation.
- Added a deterministic regression test for DF/scanner shared-broadcast sync.
- Added tracked `export_presets.cfg` for Linux, Windows, and HTML5 builds.
- Added `scripts/build_exports.sh` to download export templates and package release artifacts.
- Added `docs/distribution.md` describing local outputs and itch.io upload paths.
- Built release artifacts into `dist/` for desktop and browser distribution.
- Added a headless gameplay testing agent under `testing/`.
- Added an initial automated behavior report under `testing/reports/`.
- Replaced the decorative waterfall with a fake full-band waterfall showing simulated energy by frequency over time.
- Fixed the waterfall rendering path by moving it into the HUD layer and added an automated visibility test for it.
- Added click-to-tune behavior on the waterfall and fed the waterfall from live station data with automated tests for tuning and station-aligned energy.
- Fixed DF audio dropping during bearing capture and added an automated bearing-capture audio continuity test.
- Refreshed the automated test baseline and rebuilt Linux, Windows, and HTML5 distribution artifacts.
- Added GitHub Actions CI to run the headless test agent and export builds on push and pull request.
- Updated GitHub Actions CI to publish a rolling `prototype-latest` release with the latest build artifacts on pushes to `master` or `main`.
- Changed the rolling `prototype-latest` publication from a prerelease to a normal release so it becomes the visible latest GitHub release after each successful push.
- Added automatic GitHub Pages deployment for the HTML5 build and linked the live demo in the README.
- Added branch-preview publication to GitHub Pages so feature branches can expose browser-playable builds before merge.
- Fixed a DF receiver audio regression by making the DF player restart if playback stops on the active tuned source and by boosting the target conversation source gain.
- Added automated DF audibility and DF restart regression cases to the headless testing agent.
- Added a startup welcome modal that explains the mission and controls before the hunt begins.
- Added a regression test that verifies the welcome modal appears on startup and can be dismissed.
- Expanded the educational side of the band from three similar clips to five distinct clean training clips, including imported MP3 voice sources.
- Added a regression case that verifies educational-audio variety and that one of the new clean educational stations is actually audible through the DF path.
- Added `docs/curriculum-roadmap.md` to align real rabbit-hunt / ARDF skills with a staged game curriculum and roadmap, including rural navigation and manual map-plotting requirements.
- Added a first-pass map board overlay so players can open a larger topo view while hunting and compare bearings against a dedicated board.
- Upgraded the map board with manual plotting support: north reference ring, bearing cards, uncertainty wedges, and fix placement directly on the board.
- Added a regression case that verifies the map board plotting aids appear and that a fix can be placed from the board view.
- Bearing capture now stores azimuth and coaching text so the prototype can tell the player whether to keep or retake a line.
- Added a regression case that verifies bearing capture feedback includes azimuth and instructional guidance.
- Added step-by-step training prompts that advance from signal identification through bearing capture and fix submission.
- Added a visible lensatic-style compass overlay that always shows the current DF heading.
- Improved bearing plotting visuals so each shot is labeled on both the map and map board with its azimuth.
- Added regression coverage for training-step progression, compass heading, and bearing-visual labeling.

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
