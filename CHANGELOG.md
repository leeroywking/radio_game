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
- Added click-to-tune behavior on the waterfall and fed the waterfall from live station data with automated tests for tuning and station-aligned energy.
- Fixed DF audio dropping during bearing capture and added an automated bearing-capture audio continuity test.
- Refreshed the automated test baseline and rebuilt Linux, Windows, and HTML5 distribution artifacts.
- Added GitHub Actions CI to run the headless test agent and export builds on push and pull request.
- Updated GitHub Actions CI to publish a rolling `prototype-latest` release with the latest build artifacts on pushes to `master` or `main`.
- Changed the rolling `prototype-latest` publication from a prerelease to a normal release so it becomes the visible latest GitHub release after each successful push.
- Added automatic GitHub Pages deployment for the HTML5 build and linked the live demo in the README.
- Fixed a DF receiver audio regression by making the DF player restart if playback stops on the active tuned source and by boosting the target conversation source gain.
- Added automated DF audibility and DF restart regression cases to the headless testing agent.
- Added a startup welcome modal that explains the mission and controls before the hunt begins.
- Added a regression test that verifies the welcome modal appears on startup and can be dismissed.
- Added `docs/curriculum-roadmap.md` to align real rabbit-hunt / ARDF skills with a staged game curriculum and roadmap, including rural navigation and manual map-plotting requirements.

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
