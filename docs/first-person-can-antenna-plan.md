# First-Person Can-Antenna Mode Plan

## Goal

Add a first-person direction-finding mode that teaches the player to:

- sweep with a can antenna
- read a lensatic compass heading while aimed
- capture a line of bearing from first person
- see that bearing recorded against map position

This should extend the current trainer instead of replacing it.

## Rendering Approach

Do not bolt on a separate Doom engine.

Use a Godot-native first-person module rendered through a low-resolution 3D `Viewport` and displayed inside the current 2D scene. That gives the right retro feel while preserving:

- the existing RF / DF simulation
- the current audio model
- bearing capture logic
- scanner logic
- testing hooks
- map-board plotting

This keeps one game state, one set of broadcasts, and one source of truth for bearings.

## Why This Architecture

The current codebase is a 2D Godot 3 project with gameplay, UI, audio, and test hooks centered in `scripts/Main.gd`.

The cleanest way to add first-person is:

1. Keep the existing simulation authoritative.
2. Add a first-person presentation layer on top of it.
3. Translate player position and heading into a lightweight 3D scene.
4. Reuse the same bearing capture and compass math.

That avoids splitting the project into:

- a top-down mode with one set of mechanics
- a second standalone FPS prototype with duplicated logic

## Recommended Structure

### 1. Shared Simulation Layer

Keep these systems shared:

- player world position
- heading / aim vector
- DF tuning
- scanner state
- broadcast positions and frequencies
- bearing capture data
- score / submission logic

This already exists and should stay authoritative.

### 2. First-Person Presentation Layer

Add a new first-person module that contains:

- low-resolution 3D viewport
- first-person camera
- simple outdoor geometry
- can-antenna view model
- first-person HUD overlays

This layer should never own core hunt logic.

### 3. Reading Layer

Add a focused "reading" UI for first-person work:

- current compass heading
- current DF frequency
- current target/decoy status text
- recent reading list
- small tactical map inset with captured lines of bearing

This becomes the bridge between first-person aiming and map-based fixing.

## Input Model

### Top-Down Mode

Keep existing controls.

### First-Person Mode

Add:

- `V`: toggle first-person view
- mouse X: rotate heading
- `Space`: capture reading / bearing

For the first slice, mouse look only needs yaw. Pitch is unnecessary.

## Data Flow

1. Player moves in shared 2D world coordinates.
2. First-person heading produces the same 2D aim vector used by DF logic.
3. DF logic computes voice/noise/quality exactly as it does now.
4. Bearing capture stores:
   - origin
   - direction
   - azimuth
   - quality
   - frequency
5. First-person inset map renders those stored bearings.
6. Existing map board remains available for larger plotting.

## Phase Breakdown

### Phase 0: Planning And Seams

Deliverables:

- architecture doc
- input plan
- rendering approach decision

### Phase 1: First-Person Vertical Slice

Deliverables:

- toggleable first-person mode
- low-res 3D viewport
- synced camera position and heading
- can-antenna first-person model
- live lensatic heading readout

Success condition:

- player can walk and aim in first person while hearing the same DF behavior as top-down

### Phase 2: Bearing Reading Workflow

Deliverables:

- capture readings from first person
- small tactical map inset
- map origin marker and stored LOB lines
- reading labels with azimuth and shot order

Success condition:

- player can take multiple first-person readings and see them accumulate spatially

### Phase 3: Training Flow

Deliverables:

- focused prompts for:
  - sweep
  - settle
  - read compass
  - capture
  - move
  - capture again
- less text, more stateful coaching

Success condition:

- the mode teaches one action at a time instead of dumping instructions

### Phase 4: Rural / Tactical Upgrade

Deliverables:

- stronger terrain dressing
- observation points
- roads/trails/clearings
- reduced UI assist
- better close-in search behavior

Success condition:

- first-person DF feels like fieldwork instead of a camera gimmick

### Phase 5: Full Integration

Deliverables:

- first-person and top-down share the same map-board workflow
- submit/debrief supports readings captured in either mode
- testing covers mode switching and reading capture

Success condition:

- first-person is a real part of the game loop, not a side demo

## Integration Points In Current Code

### `scripts/Main.gd`

Primary integration file for first slice:

- mode toggle state
- first-person heading state
- aim-vector switching
- first-person viewport setup
- tactical inset rendering
- testing snapshot additions

### `scenes/Main.tscn`

Needs HUD additions for:

- first-person viewport display
- mode label
- tactical inset map

### `project.godot`

Needs one new action:

- `toggle_first_person`

### `testing/agent/agent_runner.gd`

Add first-person regression coverage for:

- mode toggle
- heading readout
- first-person bearing capture state

## Asset Strategy

Do not wait on custom art.

Use simple generated meshes first:

- box terrain
- cylinders / boxes for props
- cylinder-based can antenna model

This is enough to prove interaction before committing to a visual pass.

## Risks

### 1. Forked Logic

If first-person starts owning separate DF logic, the project will become harder to maintain immediately.

Mitigation:

- keep shared simulation authoritative

### 2. UI Clutter

The current HUD is already dense.

Mitigation:

- first-person should use its own compact overlays rather than expanding the left panel further

### 3. Godot 3 Complexity

Adding 3D to a 2D scene increases setup cost.

Mitigation:

- keep the 3D scene minimal
- render it through a viewport instead of restructuring the entire project into 3D

## First Implementation Target

The first coding slice should deliver:

- `V` toggles first-person mode
- camera heading drives DF aim
- simple can antenna visible in first person
- lensatic readout stays live
- `Space` in first person records a bearing
- small inset map shows player position plus captured LOBs

That is the minimum feature set that proves this mode is worth continuing.
