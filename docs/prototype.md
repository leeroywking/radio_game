# Prototype Scope

## Purpose

This prototype validates the smallest useful gameplay loop for a rabbit hunt trainer.

It is not a full game. It is a proof of the key teaching interaction.

## Included concepts

- Top-down navigation
- Directional aiming with the mouse
- Multiple simultaneous broadcasters on the map
- Five distinct clean educational broadcasters plus one target conversation
- Frequency-hopping autoscanner with manual scan trigger, lock, and unlock
- DF frequency tuning
- Optional clean-monitor playback for hearing the source without simulated degradation
- Simulated voice reception instead of a numeric strength readout
- Receiver scope feedback tied to the current audio state
- Full-band waterfall display across the scannable range
- Toggleable map board overlay for a larger topographic review view
- Map-board plotting aids including a north reference ring, bearing cards, uncertainty wedges, and board-side fix placement
- Step-by-step training prompts that advance with the player’s progress
- Lensatic-style compass overlay with live heading readout
- Toggleable first-person can-antenna view rendered in-engine
- Independent DF and scanner audio volume controls
- Aim-quality feedback
- Bearing coaching with azimuth readout and keep/retake guidance
- Bearing capture from multiple positions
- Estimated fix placement
- Submission and scoring

## Deliberate simplifications

- No tilemap pipeline yet
- No art pass beyond simple shapes and colors
- No terrain attenuation
- No multipath/reflection
- No inventory or equipment swapping
- No narrative tutorial scripting

## Receiver behavior

The receiver no longer exposes a direct signal percentage. Instead it teaches by feel:

- Off-target aim gives mostly static or silence
- Better aim produces intermittent, rough voice copy
- Good aim and distance give clearer voice copy
- Very close range can overload the receiver and degrade readability again
- Clean monitor mode bypasses the added receiver noise for source auditioning

The demo now includes a simplified scanner path:

- The player manually starts a sweep
- The scanner hops through a fake VHF channel list
- If it lands on the transmitter frequency with enough signal, it locks and plays audio
- The player can unlock the scanner and resume hunting
- The DF receiver and scanner have separate volume controls
- Educational decoys now use a broader mix of clean voice clips so identifying the real conversation takes a bit more discretion

The waterfall display is currently a fake but structured spectrogram:

- Frequency runs left-to-right across the full scan range
- Time scrolls downward
- Color intensity represents stronger simulated energy at each frequency
- Active broadcast frequencies show brighter vertical traces and pulsing energy
- The waterfall is rendered on a HUD texture surface so it remains visible above the panel chrome
- Clicking the waterfall tunes the DF receiver to the selected displayed frequency
- Waterfall peaks are now driven by the live station list and player-relative signal strength, not a generic band pattern
- Capturing a bearing should no longer interrupt DF audio playback

The map board is now closer to a hand-plotting aid than a simple zoomed view:

- Bearings appear as both precise lines and broader uncertainty wedges based on quality
- A north-up reference ring gives the player a quick azimuth aid while plotting
- Captured bearings are listed as simple bearing cards with azimuth, quality, and frequency
- Captured bearings are labeled in-world and on the map board so the shot location and angle stay visually linked
- Left-clicking the board places the current estimated fix directly on the plotting surface

The first-person can-antenna slice now exists as an alternate presentation mode:

- `V` toggles first-person view
- mouse motion rotates native 3D yaw and pitch
- `WASD` moves a native 3D first-person body relative to the current heading
- the same DF simulation and bearing capture logic remain authoritative
- a small tactical inset map records player position and captured LOBs while in first person
- a compact in-view overlay shows heading, DF frequency, last reading, and the active prompt
- the first-person terrain is now a continuous generated heightfield sampled from the WA map, so walking there follows visible rises and dips instead of crossing a flat plane
- the 3D view is intentionally low-resolution and simple to preserve a retro training feel
- the overhead hunt still behaves like a fixed paper map, with the full exercise area visible at once

The prototype now includes a lightweight training flow instead of only a static welcome panel:

- The welcome modal explains the purpose of the exercise briefly
- The HUD advances through one live step at a time
- The sequence walks the player through identifying the target, taking bearings, plotting, and submitting

The stated task for the player is:

- Find the real conversation and ignore the educational content

## Controls

- `WASD` or arrow keys: move
- Mouse: aim the directional antenna
- `Space`: capture a bearing from the current position
- Left click: place or move the estimated fix
- `Enter`: submit the current fix
- `R`: reset the exercise
- `C`: toggle clean monitor
- `F`: trigger scanner sweep or rescan
- `M`: open or close the map board
- `V`: toggle first-person can-antenna view

## Local launch

- Preferred in this workspace: `./run_demo.sh`
- Direct system runtime: `godot3 --path .`

The local helper script will use the downloaded `tools/godot3/` runtime if present, otherwise it falls back to a system `godot3` binary.

## Demo success criteria

The demo is successful if a player can:

1. Move to one point and observe a weak but directional signal
2. Move to another point and capture another bearing
3. Place an estimated fox location from the intersection idea
4. Submit the fix and understand how close they were

## Follow-up build targets

- Render bearings on a dedicated notebook/minimap
- Add terrain regions that alter propagation
- Add overload behavior when close to the fox
- Add a guided tutorial mission
