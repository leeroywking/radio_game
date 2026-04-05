# Rabbit Hunt Trainer

This repository contains the architecture notes and a first playable prototype for a radio direction finding training game.

The current prototype demonstrates the core learning loop:

- Move around a top-down map
- Tune a directional receiver to one of several live broadcasts
- Trigger an autoscanner that sweeps for active audio and locks onto a transmission
- Interpret a receiver scope, waterfall display, and simulated voice reception
- Separate the real conversation from educational decoys
- Route each broadcast to the left channel, right channel, or both
- Capture bearings from multiple positions
- Place an estimated fix and submit it for scoring

See [docs/architecture.md](/home/ein/projects/simple_game/docs/architecture.md) for the long-term architecture and [docs/prototype.md](/home/ein/projects/simple_game/docs/prototype.md) for the current demo scope.

## Engine choice

The recommended production engine is Godot 4.x because it is a strong fit for low-budget 2D pixel-art simulation work.

The local runnable prototype in this repository targets Godot 3.5-compatible scene/script formats so it can be executed in this environment if `godot3` is installed.

## Running the prototype

From the repository root:

```bash
godot3 --path .
```

If you used the local user-space runtime download during setup, you can also run:

```bash
./run_demo.sh
```

Controls are documented in the in-game HUD and in [docs/prototype.md](/home/ein/projects/simple_game/docs/prototype.md).

## Automated testing

The repository now includes a headless gameplay testing agent:

```bash
./testing/run_agent.sh
```

It exercises the real main scene, writes reports into `testing/reports/`, and compares the latest run with the previous one.

See [testing/README.md](/home/ein/projects/simple_game/testing/README.md) for coverage and report files.

GitHub Actions CI is configured in [.github/workflows/ci.yml](/home/ein/projects/simple_game/.github/workflows/ci.yml) to run the headless test agent and export builds on push and pull request.

## Building distributables

The repository now includes a repeatable export pipeline for desktop and browser builds:

```bash
./scripts/build_exports.sh
```

This produces:

- Linux desktop export
- Windows desktop export
- HTML5 browser export
- itch.io-ready upload zips under `dist/itch/`

See [docs/distribution.md](/home/ein/projects/simple_game/docs/distribution.md) for the output layout and upload guidance.

## Audio source

The demo now defaults to clean training-voice loops derived from clearer spoken-audio sources, then applies in-game degradation on top. The user can switch between clean training sources and a legacy radio sample in the HUD.

Primary source files used for the clean training presets:

- `Wikipedia - Human voice (spoken by AI voice).mp3`, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Wikipedia_-_Human_voice_(spoken_by_AI_voice).mp3
- `Wikipedia - Umbriel (spoken by AI voice).mp3`, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Wikipedia_-_Umbriel_(spoken_by_AI_voice).mp3

Legacy radio sample kept for comparison:

- `Ham Contest Exchange.ogg`, described as a typical ham radio contest exchange by Meisam, licensed CC0 1.0
- Source page: https://commons.wikimedia.org/wiki/File:Ham_Contest_Exchange.ogg

The repository keeps downloaded source files plus locally converted WAV clips for runtime playback.
