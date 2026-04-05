# Prototype Scope

## Purpose

This prototype validates the smallest useful gameplay loop for a rabbit hunt trainer.

It is not a full game. It is a proof of the key teaching interaction.

## Included concepts

- Top-down navigation
- Directional aiming with the mouse
- Multiple simultaneous broadcasters on the map
- Frequency-hopping autoscanner with manual scan trigger, lock, and unlock
- DF frequency tuning
- Optional clean-monitor playback for hearing the source without simulated degradation
- Simulated voice reception instead of a numeric strength readout
- Receiver scope feedback tied to the current audio state
- Full-band waterfall display across the scannable range
- Independent DF and scanner audio volume controls
- Per-source stereo routing controls
- Aim-quality feedback
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
- Each broadcaster can be routed to left, right, or both channels for demo and training experiments

The waterfall display is currently a fake but structured spectrogram:

- Frequency runs left-to-right across the full scan range
- Time scrolls downward
- Color intensity represents stronger simulated energy at each frequency
- Active broadcast frequencies show brighter vertical traces and pulsing energy

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
