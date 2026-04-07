# 3D Restart Options

## Goal

Restart the first-person mode from a clean slate with real elevation, traversable outdoor terrain, and a field-use can-antenna workflow.

This document replaces the old first-person plan. The current branch removes the existing 3D mode entirely so the next implementation can start clean.

## Requirements

- Outdoor terrain with visible elevation change
- Good fit for rural Washington-style terrain
- Works with the current RDF simulation instead of replacing it
- Browser preview remains desirable
- Maintainable by a small team

## Options

### 1. Godot 3 native 3D with a terrain addon

Best fit if we stay on the current runtime.

Candidate addons:
- `HTerrain` by Zylann: heightmap terrain workflow for Godot 3
  - https://github.com/Zylann/godot_heightmap_plugin
- `Qodot`: Quake/TrenchBroom map import for authored spaces and blockouts
  - https://github.com/QodotPlugin/qodot-plugin

Assessment:
- `HTerrain` is the strongest current fit for large rural outdoor terrain on this codebase.
- `Qodot` is useful for compounds, interiors, and authored checkpoints, but it is not the main answer for broad natural terrain.

### 2. Godot 4 native 3D with modern terrain addons

Best fit if we are willing to pay the migration cost.

Candidate addons:
- `Terrain3D`
  - https://github.com/TokisanGames/Terrain3D
- `godot_voxel`
  - https://github.com/Zylann/godot_voxel

Assessment:
- `Terrain3D` is attractive for large outdoor terrain and would be my leading option if we choose to upgrade the project runtime.
- `godot_voxel` is stronger when we want volumetric or destructible terrain, which is probably more than this project needs.

### 3. Qodot / BSP-authored world only

Best fit if we want deliberately designed training lanes instead of broad terrain fidelity.

Assessment:
- Strong for structured training spaces.
- Weak for the “paper map over real terrain” feel you asked for.
- Not my recommendation as the primary outdoor solution.

## Recommendation

For the current repository, the safest restart path is:

1. Stay on Godot `3.5.x` for now.
2. Rebuild first-person mode around native Godot 3D, but use `HTerrain` for the terrain layer instead of hand-built faux geometry.
3. Keep the current top-down/map-board/audio/scanner systems as the authoritative game logic.
4. Make first-person a presentation/controller layer over that shared simulation.

If we decide the product is committed to first-person outdoor fieldwork as a major pillar, then the better long-term move is:

1. Plan a separate migration branch to Godot 4.
2. Rebuild first-person terrain on `Terrain3D`.

## Proposed Restart Phases

### Phase 0: Clean reset

- Remove the current first-person code path
- Remove first-person UI and tests
- Keep the existing 2D trainer stable

### Phase 1: Terrain spike

- Integrate the chosen terrain addon
- Load a real terrain patch
- Spawn a simple first-person controller
- Prove traversal over slopes and valleys

Success criteria:
- camera height clearly changes over terrain
- movement feels natural
- terrain is visually continuous

### Phase 2: Shared simulation hookup

- Connect first-person heading to the existing DF model
- Keep DF/scanner/frequency state shared with the top-down game
- Add a simple in-view compass and reading prompt

### Phase 3: Reading workflow

- Take a reading in first person
- Push the captured LOB into the existing map-board workflow
- Debrief remains top-down/map-centric

### Phase 4: Rural training dressing

- Terrain materials
- Tree/rock scatter
- Ridgelines, valleys, and roads
- Better scale cues

## Non-goals For The Next Attempt

- Do not build another pseudo-Doom renderer
- Do not hand-author fake hills as props
- Do not fork the DF logic into a separate first-person simulation
