# Native 3D First-Person Plan

## Decision

Do not use a Doom-style or raycast-style sub-engine for the rabbit-hunt first-person mode.

Use Godot's native 3D stack instead.

For this repo, that means:

- keep the existing project in Godot
- rebuild first-person mode around real 3D terrain and a 3D movement body
- keep the 2D training loop, RF/audio simulation, bearings, map board, and scoring as shared game systems

## Why

The rejected approach was not failing because Godot cannot handle vertical terrain. It was failing because the first-person mode was still architected like a lightweight pseudo-retro overlay:

- camera position was derived from a 2D point
- terrain was hinted visually instead of being the movement surface
- verticality was sampled, not traversed
- the player was never really "in" a 3D world

That makes hills and valleys look decorative instead of navigable.

## Recommended Runtime Architecture

1. Shared simulation stays in the top-level game controller
   - broadcasts
   - tuning
   - scanner state
   - DF receiver state
   - bearing capture
   - map board and scoring

2. First-person presentation becomes a native 3D subsystem
   - `Viewport`
   - terrain `MeshInstance`
   - terrain collision body
   - player `KinematicBody`
   - pitch/yaw camera rig
   - can-antenna view model

3. Position synchronization stays explicit
   - top-down mode owns the 2D map position
   - first-person mode owns the 3D body position while active
   - conversion helpers map between 2D map coordinates and 3D terrain coordinates

4. Terrain becomes authoritative for movement
   - the visible terrain mesh and the collision shape come from the same sampled height data
   - props are snapped to terrain height
   - camera height comes from the 3D body, not a manually sampled offset

## Chosen Implementation Path

Phase 1:

- native 3D player body
- mouse-look yaw/pitch
- generated terrain mesh from the WA hillshade
- terrain collision
- first-person movement over real slopes
- preserve existing DF/audio/LOB workflow

Phase 2:

- stronger terrain materials
- roads, cuts, ridge lines, and sparse landmarks
- terrain-aware path teaching

Phase 3:

- authored rural/tactical scenario maps
- cover/concealment cues
- route-choice teaching based on terrain and access

## Current Rule

Any future first-person work should extend the native 3D terrain/controller path, not reintroduce a pseudo-Doom rendering model.
