# Architecture

## Goal

Build a top-down training game that teaches amateur radio operators how to conduct rabbit hunts, take bearings, and develop a fix from multiple observations.

The product should prioritize:

- Low art/content cost
- Clear instructional value
- Plausible, layered radio-direction-finding simulation
- Easy expansion from simple exercises to more advanced hunts

## Recommended engine

Use Godot 4.x for the production game.

Reasons:

- Strong 2D workflow
- Good tile-based world support
- Low licensing cost
- Simple desktop export path
- Good fit for data-driven gameplay and training UI

## Architecture principles

### 1. Training-first simulation

Do not attempt full RF realism in the first version. Build a simulation that is believable enough to teach the right habits:

- Move to multiple observation points
- Read signal direction with imperfect tools
- Distinguish strong readings from misleading ones
- Produce a fix from multiple bearings

### 2. Data-driven content

Keep maps, equipment, missions, lesson scripts, and difficulty presets in data files so scenario tuning stays cheap.

### 3. Modular game systems

Separate the instructional systems from the simulation systems. That makes it possible to expand the game from a sandbox hunt into a structured training program.

## Runtime layers

### Presentation layer

- Pixel-art top-down world
- HUD for signal, equipment state, and lesson prompts
- Map annotation tools for bearings and fixes
- Debrief overlays

### Gameplay loop layer

- Explore the map
- Take directional readings
- Record bearings
- Move to another position
- Estimate the fox location
- Submit the fix
- Review results

### Simulation layer

- Transmitter model
- Signal strength model
- Directional antenna model
- Noise and uncertainty model
- Terrain and obstruction modifiers

### Training layer

- Tutorials
- Mission goals
- Hint delivery
- Error detection
- Post-mission analysis

### Content layer

- Maps
- Scenarios
- Equipment definitions
- Lesson progression
- Difficulty settings

## Core systems

### World system

Responsibilities:

- Tile-based map or small handcrafted 2D spaces
- Terrain tags such as open ground, woods, buildings, road
- Spawn and checkpoint definitions

### Signal system

Responsibilities:

- Compute effective signal level at the player
- Apply distance falloff
- Apply directional gain/loss based on antenna aim
- Later support overload, reflection, attenuation, and terrain penalties

### Equipment system

Responsibilities:

- Represent hunt tools as reusable definitions
- Support receiver/antenna combinations
- Control reading quality and player affordances

Example equipment progression:

- Basic handheld directional receiver
- Loop antenna
- Yagi
- Attenuator
- Body-shielding mode

### Annotation and fixing system

Responsibilities:

- Save observation points
- Draw bearings on the player map
- Let the player place estimated fixes
- Support later notebook-style evidence review

### Mission system

Responsibilities:

- Scenario start state
- Mission objectives
- Pass/fail conditions
- Guided tutorial scripting

### Scoring and debrief system

Responsibilities:

- Accuracy of final fix
- Time spent
- Number and quality of observations
- Detection of common mistakes
- Debrief replay with actual transmitter reveal

## Target progression

### Phase 1: Foundational hunt trainer

- One hidden transmitter
- Static map
- Manual bearing capture
- Manual fix placement
- Simple score and debrief

### Phase 2: Field complications

- Terrain attenuation
- Urban reflections
- Receiver overload
- Ambiguous bearings

### Phase 3: Advanced scenarios

- Moving transmitters
- Timed exercises
- Competitive hunts
- Multi-fox events

## Repository direction

The repo should evolve around these top-level areas:

- `docs/` for architecture, training concepts, and design decisions
- `scenes/` for Godot scenes
- `scripts/` for gameplay systems
- `assets/` for low-cost pixel visuals and UI art
- `data/` for missions, equipment, and balance values

## First playable definition

The first playable should prove the central instructional loop:

- The player moves to different locations
- The player aims a directional tool
- The signal readout changes with distance and aim
- The player records two or more bearings
- The player places and submits a fix
- The debrief compares the estimate against the hidden transmitter
