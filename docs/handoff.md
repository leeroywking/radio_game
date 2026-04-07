# Handoff Notes

## Current state

This repository contains a playable Godot-based prototype for a radio direction finding training game.

The current build includes:

- A Godot 4 first-person terrain view generated from the USGS Washington hillshade
- Terrain reconstruction is now driven by a profile-based image importer rather than only scene-local math
- Terrain now uses a built-in mesh-and-collision backend instead of a native addon, so the browser preview can run without GDExtension support
- First-person movement now derives from the actual camera basis, so forward/back behavior and DF heading stay aligned
- Tree scatter across the terrain view
- Multiple simultaneous broadcasters with one designated as the real target conversation
- Five distinct clean educational broadcasters now sit on the band before the target conversation is found
- DF receiver tuning by slider and direct numeric entry
- Click-to-tune frequency selection from the waterfall
- A map board overlay that can be toggled during the hunt for a larger topo view
- Manual plotting aids on the map board: bearing cards, uncertainty wedges, north reference ring, and board-side fix placement
- A manual-start autoscanner with lock and unlock behavior
- Separate DF and scanner volume controls
- A visible full-band waterfall rendered in the HUD
- Waterfall energy driven by the live station list and player-relative strength
- A strongly directional DF audio model intended to feel closer to a narrow improvised directional antenna
- Step-by-step training prompts that update as the player progresses through identify, capture, plot, and submit
- A visible lensatic-style compass overlay that continuously shows the current DF heading
- The overhead hunt remains a fixed paper-map view, with the full mission area visible at once
- A short DF-audio hold during bearing capture so `Space` does not cut playback
- DF and scanner playback stay time-aligned when both receivers are monitoring the same broadcast
- Bearing capture now records azimuth and coaching text so players get explicit keep/retake guidance
- Bearing shots are labeled directly on the map and map board so each line of bearing is tied to a shot location and angle
- Bearing capture, fix placement, and scoring
- A Godot 4-native first-person mode is now the active migration slice
- A headless gameplay testing agent with comparison against the previous run

## Key learnings

1. Avoid adding visual features by reshaping too many systems at once.
   The failed waterfall/routing pass broke working behavior because it mixed UI changes, audio routing changes, and signal-display changes in one step.

2. This local runtime cannot reliably preload imported assets the way a normal editor workflow would.
   Audio and map image loading should prefer explicit runtime load paths instead of assuming import metadata exists.

3. The left HUD column is space-constrained.
   Small layout tweaks help, but if more controls are added the next real solution should be a structural change such as tabs, collapsible sections, or moving part of the UI to the right side.

4. Reset behavior matters.
   Users noticed repeated layouts quickly. Broadcast locations now regenerate on reset, and the target frequency also randomizes.

5. Player-facing text should stay instructional, not diagnostic.
   Debug-heavy status output was replaced with simpler mission/status copy after user feedback.

6. Branch-first workflow should be treated as standard operating procedure.
   Future agents should start work on a short-lived branch and avoid direct `master` or `main` edits unless the user explicitly requests it or CI/release recovery requires it.

7. Educational content should not sound too uniform.
   The original three clean training clips became recognizable too quickly, so the prototype now mixes in additional clean imported voice sources to make decoys less obvious.

8. PR state needs to be explicit in handoffs.
   Saying that work is "up" is not enough. Future agents should state whether the PR is open or already merged, with the PR number and URL.

9. "Review-ready" includes green current PR checks.
   Local verification is not enough on its own. Before handoff, the current PR head should show successful GitHub checks, or the agent should continue until that is true or report the concrete blocker.

10. The first-person path needed a clean break from the earlier pseudo-3D attempts.
   The active migration now uses a Godot 4-native script plus a built-in terrain mesh runtime instead of extending the removed path.

11. Browser previews cannot depend on stock-web-incompatible native addons.
   The original Terrain3D-based branch could pass local desktop tests and still fail in GitHub Pages because the stock Godot web template does not ship the needed native extension support. The active branch now avoids that class of failure by using built-in terrain rendering and by validating the exported `index.html` for stray extension references.

12. First-person controls need to be verified behaviorally, not assumed from yaw math.
   The manual trig-based movement path could feel reversed even when the DF compass looked plausible. The active branch now derives movement from the camera basis and has a regression case that checks forward motion against the current heading.

13. Terrain generation needs a reusable import layer.
   The built-in terrain backend is now fed by `TerrainImportModel`, which separates source-image interpretation from the scene script and gives us a path to support future contour maps as inputs instead of only the current hillshade.

14. Terrain world scale needs explicit kilometer semantics.
   The active branch now treats the imported play area as a `32 x 24 km` paper map with `1 km` grid squares, which keeps traversal and map plotting from feeling like a tiny sandbox.

## Current files to know

- `scripts/Main4.gd`
  Active Godot 4 gameplay script. Owns first-person terrain setup, shared DF/scanner simulation, waterfall rendering, and map-board plotting.

- `scripts/TerrainImportModel.gd`
  Profile-driven image terrain importer. The current WA demo uses its `hillshade_reconstruction` mode, and the script also contains the first-pass contour import mode for future map inputs.

- `scenes/Main.tscn`
  Current HUD layout and all control widgets.

- `export_presets.cfg`
  Tracked export definitions for Linux, Windows, and HTML5 packaging.

- `scripts/build_exports.sh`
  Repeatable export entrypoint. It now targets Godot 4.5.2 export templates, writes release artifacts into `dist/`, and fails if the web bundle still references native extension libraries.

- `docs/distribution.md`
  Explains the output folders and which files are intended for itch.io download uploads versus HTML5 browser uploads.

- `testing/run_agent.sh`
  Runs the headless gameplay testing agent against the real main scene. It also performs a clean import bootstrap on fresh clones where `.godot/imported` does not exist yet.

- `testing/agent/agent_runner.gd`
  Drives gameplay actions, collects telemetry, compares against the previous run, and writes behavior reports.

- `testing/reports/latest.md`
  Current local behavior report from the testing agent. Runtime reports in `testing/reports/` are intentionally untracked and regenerated by local/CI runs.

- DF audio regression coverage
  The headless testing agent now asserts that the DF path is actually audible on the target broadcast and that the DF player self-recovers if playback stops while the tuned broadcast remains unchanged.

- Shared-broadcast sync coverage
  The headless testing agent also forces both receiver paths onto the same broadcast and verifies they remain time-aligned.

- Training-and-visual guidance coverage
  The headless testing agent now checks tutorial-step progression, live compass heading, and labeled bearing-visual summaries.

- First-person control coverage
  The headless testing agent now also verifies that stepping forward at the default heading actually advances the player in the camera-facing direction.

- Terrain import coverage
  The headless testing agent now verifies that the active terrain build came from the named `wa_hillshade_demo` import profile.

- `docs/3d-restart-options.md`
  Historical framework survey from before the current built-in Godot 4 terrain migration landed.

- `.github/workflows/ci.yml`
  GitHub Actions pipeline that downloads the Godot runtime, runs the headless gameplay tests, builds export artifacts, publishes versioned releases when `VERSION` changes, and publishes branch previews plus the default HTML5 build to GitHub Pages.

- `docs/architecture.md`
  High-level product/system architecture direction.

- `docs/prototype.md`
  Prototype scope and controls.

- `docs/curriculum-roadmap.md`
  Curriculum and milestone planning doc that maps real RDF / ARDF skills to future product phases, especially manual fixing and rural field scenarios.

- `docs/issue-log.md`
  Captured issue list and resolved items from recent iteration.

## Current rough edges

- The HUD still feels crowded.
- The map is a real hillshade, but the gameplay layer on top of it is still sparse.
- The signal model is intentionally simplified and not terrain-aware yet.
- The continuity test can prove stable target audio under ideal conditions, but it still warns when it does not observe a full audio-loop wrap during the sample window.
- The waterfall now renders inside the HUD as a texture-backed display. This mattered because the old `Node2D` drawing path sat behind the opaque panel and could be effectively invisible even when waterfall data existed.
- Clicking inside the waterfall now tunes the DF frequency. The display energy is also derived from the live `broadcasts` list and distance-based station strength, so it tracks the current scenario instead of a generic fake band texture.
- Bearing capture now applies a short DF-audio hold so pressing `Space` does not cause a momentary audio drop if the receiver would otherwise flicker off the station during capture.
- The map board is still not a full notebook workflow, but it is no longer just a zoomed view. It now supports direct fix placement on the board and shows bearings with azimuth notes and uncertainty wedges.
- Reset now also resets DF tuning so a new run starts from a clean teaching state instead of inheriting the prior frequency.
- Terrain is present and testable now, but the terrain shading/prop pass is still simple and the current 3D scene still needs aesthetic iteration.

## Recommended next steps

1. Validate the rebuilt GitHub Pages preview after the built-in terrain branch is pushed.
2. Refactor the HUD into clearer sections or multiple panels before adding more controls.
3. Evolve the current fake-but-live waterfall into a truer receiver-band model or FFT-driven display.
4. Add terrain-aware attenuation only after the first-person traversal loop feels stable.
5. Improve terrain art direction with better materials, rocks, and ridge/valley readability now that the runtime path is stable.

## Running the prototype

From the repository root:

```bash
./run_demo.sh
```

Smoke tests used during development:

```bash
./run_demo.sh --quit
timeout 3 ./run_demo.sh
```

Build packaging command:

```bash
./scripts/build_exports.sh
```

Automated testing command:

```bash
./testing/run_agent.sh
```
