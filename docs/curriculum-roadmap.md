# Curriculum And Product Roadmap

## Purpose

This document turns real rabbit-hunt / fox-hunt / ARDF skills into a game curriculum and a corresponding product roadmap.

The design target is not a generic "radio minigame." It is a training game that teaches players how to:

- detect and recognize a target transmission
- take useful bearings with imperfect equipment
- move through terrain while maintaining orientation
- plot and refine fixes on a map
- make good route decisions in rural or tactical field conditions

The strongest design principle is that radio direction finding is not only a radio skill. It is a combined skill involving:

- receiver handling
- map and compass use
- terrain interpretation
- movement discipline
- uncertainty management

## Training Assumptions

The curriculum assumes a player may need to operate in:

- rural wooded terrain
- broken terrain with elevation change
- low-infrastructure environments
- tactical or field-expedient settings where GPS may be discouraged, unavailable, or intentionally withheld

Because of that, manual plotting should not be treated as optional flavor. It should be a core mechanic for at least part of the game.

## Real-World Skill Model

Based on ARRL and IARU ARDF guidance, the most important fundamentals are:

- identifying the correct signal before chasing it
- taking bearings from a known location
- using multiple bearings from multiple locations to improve the estimate
- managing receiver gain / usable signal range
- understanding peak versus null behavior depending on antenna type
- maintaining map awareness and route planning in wooded terrain
- using topographic maps, magnetic north references, and safety bearings

For this game, those fundamentals should become the spine of the curriculum.

## Curriculum Structure

The curriculum is organized into six phases. Each phase should unlock only after the player demonstrates the previous one.

### Phase 1: Signal Awareness

Goal:
- Teach the player what a target transmission sounds like and how to distinguish it from irrelevant traffic.

Player skills:
- tune to a frequency
- recognize the target conversation
- ignore obvious decoys
- understand that stronger audio does not always mean "go straight there"

Game mechanics:
- scanner use
- DF tuning
- clean training environment
- simple audio discrimination tasks

Success criteria:
- player can identify the target channel repeatedly without map work

Why it matters:
- Real hunts start with correctly identifying the signal of interest.

### Phase 2: Bearing Taking

Goal:
- Teach the player to point the DF antenna and take a usable directional line.

Player skills:
- sweep for peak or null
- stop rotating at the right moment
- understand that one bearing is not a fix
- retake a bearing if confidence is poor

Game mechanics:
- directional audio changes
- confidence feedback
- capture bearing at current location
- bearing quality grading

Success criteria:
- player can take two or three consistent bearings from separated locations

Why it matters:
- ARDF guidance emphasizes that taking good bearings is one of the most important fundamental skills.

### Phase 3: Manual Fixing On A Map

Goal:
- Teach the player to translate bearings into a probable source location.

Player skills:
- orient the map
- mark current position
- draw a bearing line
- compare line intersections
- judge when a fix is weak, wide, or misleading

Game mechanics:
- notebook or map board view
- manual line drawing
- optional protractor/compass overlay
- visible uncertainty wedges rather than perfect lines at higher difficulties

Success criteria:
- player can produce a fix with reasonable error using hand-plotted bearings

Why it matters:
- This is the core bridge between radio skill and field navigation skill.

### Phase 4: Route Choice In Rural Terrain

Goal:
- Teach the player to move intelligently rather than simply beelining between audio peaks.

Player skills:
- read terrain
- use roads, trails, streams, ridges, and clearings
- choose better observation points
- maintain awareness of present location
- use a safety bearing if disoriented

Game mechanics:
- topographic map reading
- movement cost by terrain
- better bearings from high ground / open terrain where appropriate
- larger search area

Success criteria:
- player reaches useful observation points efficiently and avoids route traps

Why it matters:
- IARU ARDF guidance is explicit that map, compass, and route-planning skills are inseparable from the hunt.

### Phase 5: Close-In Recovery

Goal:
- Teach the player that final approach behavior differs from long-range fixing.

Player skills:
- stop over-trusting triangulation near the source
- reduce gain / attenuate
- work through overload or confusing near-field behavior
- search carefully once the probable area is small

Game mechanics:
- overload state
- attenuator or sniffer tool
- "last 100 meters" mode
- tighter local search gameplay

Success criteria:
- player can transition from large-area fixing to close-in recovery without becoming less effective near the fox

Why it matters:
- Practical fox-hunt material consistently notes that close-in behavior is different and that early triangulation habits stop being enough.

### Phase 6: Tactical Field Exercise

Goal:
- Combine radio finding, manual map work, and disciplined movement under constraints.

Player skills:
- minimize exposure or route signature
- use rally points or observation points
- operate without GPS
- keep a paper-style map solution current
- discriminate real traffic from misleading educational or decoy transmissions

Game mechanics:
- limited UI assist
- manual plotting encouraged or required
- time pressure
- communications discipline objectives
- optional "do not cross" or "stay concealed" constraints

Success criteria:
- player can locate the target while meeting scenario constraints, not merely by shortest path

Why it matters:
- This is where the game becomes useful beyond hobby instruction and moves into fieldcraft-oriented training.

## Recommended Course Sequence

Use the curriculum in three tracks rather than one flat ladder.

### Track A: Intro DF

Audience:
- new radio users
- casual players
- first-time trainees

Modules:
- Signal Awareness
- Bearing Taking
- Intro Manual Fixing

Output:
- player can hunt a simple transmitter on a small map

### Track B: Rural Search

Audience:
- volunteer search / event support learners
- hams wanting realistic field hunts

Modules:
- Bearing Taking
- Manual Fixing
- Route Choice In Rural Terrain
- Close-In Recovery

Output:
- player can work a larger search box using terrain and hand-plotted fixes

### Track C: Tactical Fieldcraft

Audience:
- users who want austere, map-driven, low-assist scenarios

Modules:
- Signal Awareness under ambiguity
- Manual Fixing under uncertainty
- Route Choice under constraints
- Tactical Field Exercise

Output:
- player can locate the correct emitter while managing concealment, movement constraints, and imperfect information

## Core Game Systems Needed To Support The Curriculum

These are the systems the product needs if it is going to teach the above skills credibly.

### 1. Receiver Training System

Needed for:
- tuning
- scanner use
- gain / attenuation
- peak/null interpretation
- audio discrimination

Minimum feature set:
- target and decoy channels
- audio clarity/noise model
- lockable scanner
- DF tuning controls

### 2. Bearing And Confidence System

Needed for:
- taking bearings
- grading measurement quality
- teaching good observation positions

Minimum feature set:
- capture bearing
- bearing confidence
- uncertainty width
- history of prior lines

### 3. Manual Map Board

Needed for:
- hand plotting
- map orientation
- route planning
- deliberate fixing

Minimum feature set:
- topographic map
- player position marking
- bearing drawing
- erase / annotate
- optional ruler / protractor overlay

This should eventually become more important than the HUD.

### 4. Terrain And Movement System

Needed for:
- rural realism
- route-choice teaching
- tactical movement constraints

Minimum feature set:
- topographic maps
- terrain traversal cost
- roads / trails / streams / ridges
- search-area boundaries
- safety bearing mechanic

### 5. Scenario Authoring System

Needed for:
- curriculum progression
- instructor-designed exercises
- replayability

Minimum feature set:
- mission objective
- target identity
- decoy mix
- terrain set
- allowed tools
- grading rules

### 6. Debrief And Instruction System

Needed for:
- actual training value

Minimum feature set:
- show player route
- show bearing set
- show ideal observation points
- explain error sources
- identify premature or bad bearings

## Roadmap

This roadmap is aligned to the curriculum instead of generic feature buckets.

## Milestone 1: Stronger First-Lesson Prototype

Goal:
- make the current demo genuinely usable as Phase 1 and early Phase 2 training

Deliver:
- cleaner educational/decoy voice variety
- stable DF audio behavior
- clear scanner language
- improved onboarding
- stronger waterfall-as-supporting-tool presentation

Status:
- mostly in progress already through current prototype branches

Exit criteria:
- players can reliably identify the target and take their first useful bearings

## Milestone 2: Manual Map Work MVP

Goal:
- introduce true instructional fixing

Deliver:
- dedicated map board / notebook screen
- player position marking
- hand-drawn bearings
- basic intersection/fix workflow
- simple debrief showing actual transmitter position versus drawn fix

This is the most important next product milestone.

Exit criteria:
- curriculum phases 1 to 3 are genuinely teachable

## Milestone 3: Rural Terrain Navigation

Goal:
- make route choice and terrain interpretation part of the game

Deliver:
- larger topographic play spaces
- route cost by terrain
- roads and trails as real navigation choices
- high-ground / visibility style observation-point advantages where appropriate
- safety-bearing mechanic

Exit criteria:
- curriculum phase 4 is teachable on a larger search area

## Milestone 4: Close-In Recovery Toolkit

Goal:
- teach players not to fail once they are near the source

Deliver:
- overload / saturation behaviors
- attenuator or close-in sniffer mode
- tighter local search mechanics
- debrief of close-range mistakes

Exit criteria:
- player can complete a full hunt from first signal to final recovery

## Milestone 5: Tactical Scenarios

Goal:
- support austere and fieldcraft-heavy play

Deliver:
- limited-assist mode
- optional no-GPS or no-auto-position mode
- stricter manual plotting
- movement constraints and route penalties
- hidden decoys / misleading but plausible traffic
- mission-specific rules such as observation points, exposure limits, or checkpoint reporting

Exit criteria:
- curriculum phase 6 is teachable without the game feeling like an arcade abstraction

## Milestone 6: Instructor And Replay Layer

Goal:
- make the game useful for repeated training, not one-off novelty

Deliver:
- scenario editor or scenario schema expansion
- lesson plans
- after-action review
- difficulty presets
- curriculum bundles by learner type

Exit criteria:
- the game supports structured training programs instead of isolated demo levels

## Recommended Priority Order

If budget is constrained, build in this order:

1. Manual map board
2. Debrief and grading
3. Rural terrain route choice
4. Close-in recovery tools
5. Tactical constraints
6. Scenario authoring expansion

That order preserves the training value.

If the game ships with better audio, a better waterfall, and prettier maps but no manual fixing workflow, it will still miss the most important instructional layer.

## Content Design Guidance

To support this curriculum, scenario content should be built in tiers.

### Beginner scenarios

- small map
- one real target
- obvious decoys
- strong signal windows
- map assistance on

### Intermediate rural scenarios

- larger topo map
- multiple plausible decoys
- route tradeoffs
- fewer UI aids
- manual line plotting encouraged

### Advanced tactical scenarios

- constrained movement
- austere UI
- ambiguous traffic
- deliberate need for terrain use
- manual map work required

## Product Recommendation

The product should be framed as:

`A radio direction-finding training game with map-and-compass problem solving`

not:

`A radio scanner simulator`

That framing is more accurate to real rabbit hunting and it points development toward the right mechanics.

## Sources

- ARRL, Direction Finding: https://www.arrl.org/direction-finding
- ARRL, Rapid RDFing: https://www.arrl.org/rapid-rdfing
- IARU Region 1, What is ARDF?: https://www.iaru-r1.org/about-us/committees-and-working-groups/ardf/what-is-ardf/
- IARU Region 2, Getting Started in ARDF, Bearings: https://www.ardf-r2.org/wb6byu/getting_started_bearings.shtml
- IARU Region 2, Getting Started in ARDF, Map Skills: https://www.ardf-r2.org/wb6byu/getting_started_map_skills.shtml
