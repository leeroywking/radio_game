# Handoff Notes

## Current state

This repository contains a playable Godot-based prototype for a radio direction finding training game.

The current build includes:

- A real USGS Washington hillshade map backdrop
- Multiple simultaneous broadcasters with one designated as the real target conversation
- DF receiver tuning by slider and direct numeric entry
- A manual-start autoscanner with lock and unlock behavior
- Separate DF and scanner volume controls
- A placeholder waterfall element that is visual only and not yet tied to the signal model
- A strongly directional DF audio model intended to feel closer to a narrow improvised directional antenna
- Bearing capture, fix placement, and scoring

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

## Current files to know

- `scripts/Main.gd`
  Main gameplay, audio simulation, reset logic, map loading, scanner behavior, and UI updates.

- `scenes/Main.tscn`
  Current HUD layout and all control widgets.

- `export_presets.cfg`
  Tracked export definitions for Linux, Windows, and HTML5 packaging.

- `scripts/build_exports.sh`
  Repeatable export entrypoint. Installs official Godot 3.5.3 export templates on demand and writes release artifacts into `dist/`.

- `docs/distribution.md`
  Explains the output folders and which files are intended for itch.io download uploads versus HTML5 browser uploads.

- `testing/run_agent.sh`
  Runs the headless gameplay testing agent against the real main scene.

- `testing/agent/agent_runner.gd`
  Drives gameplay actions, collects telemetry, compares against the previous run, and writes behavior reports.

- `testing/reports/latest.md`
  Current baseline behavior report from the testing agent.

- `docs/architecture.md`
  High-level product/system architecture direction.

- `docs/prototype.md`
  Prototype scope and controls.

- `docs/issue-log.md`
  Captured issue list and resolved items from recent iteration.

## Current rough edges

- The HUD still feels crowded.
- The waterfall is placeholder-only and not frequency-linked yet.
- The map is a real hillshade, but the gameplay layer on top of it is still sparse.
- The signal model is intentionally simplified and not terrain-aware yet.
- The continuity test can prove stable target audio under ideal conditions, but it still warns when it does not observe a full audio-loop wrap during the sample window.
- The waterfall now behaves like a fake full-band spectrogram with bottom frequency labels and energy peaks aligned to broadcast frequencies. It is still not fed by a real RF model or FFT.

## Recommended next steps

1. Refactor the HUD into clearer sections or multiple panels before adding more controls.
2. Convert the waterfall from decorative animation into a real full-band frequency display.
3. Add a stronger mission loop around identifying the target frequency before triangulation.
4. Introduce terrain-aware attenuation only after the current interaction loop feels stable.

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
