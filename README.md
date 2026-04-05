# Rabbit Hunt Trainer

[![CI](https://github.com/leeroywking/radio_game/actions/workflows/ci.yml/badge.svg)](https://github.com/leeroywking/radio_game/actions/workflows/ci.yml)
[![Live Demo](https://img.shields.io/badge/demo-GitHub%20Pages-blue)](https://leeroywking.github.io/radio_game/)
[![Latest Release](https://img.shields.io/github/v/release/leeroywking/radio_game?display_name=release)](https://github.com/leeroywking/radio_game/releases/latest)
[![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-lightgrey)](./LICENSE)

Radio direction-finding training prototype built in Godot. The current gameplay loop teaches players to tune a DF receiver, sort target audio from decoys, capture bearings, and place a fix.

## Status

- Project stage: prototype / pre-alpha
- Primary demo: GitHub Pages HTML5 build
- Maintained areas: gameplay prototype, CI, export packaging, testing agent
- Current focus: turning the training loop into a cleaner product/repo baseline

## Links

- Live demo: https://leeroywking.github.io/radio_game/
- Latest release: https://github.com/leeroywking/radio_game/releases/latest
- Architecture notes: [docs/architecture.md](/home/ein/projects/simple_game/docs/architecture.md)
- Prototype scope: [docs/prototype.md](/home/ein/projects/simple_game/docs/prototype.md)
- Distribution notes: [docs/distribution.md](/home/ein/projects/simple_game/docs/distribution.md)

## Requirements

- Godot runtime: `3.5.3-stable` for the local prototype tooling in this repo
- Platform for local runs: Linux with `godot3` or the downloaded user-space runtime
- Browser demo: modern desktop browser with WebAssembly support

## Compatibility

| Area | Status |
| --- | --- |
| Linux desktop export | Supported |
| Windows desktop export | Supported |
| HTML5 / browser demo | Supported |
| macOS export | Not wired in this repo |
| Godot 4 production direction | Recommended target, not the current prototype runtime |

## Quickstart

Run the game:

```bash
./run_demo.sh
```

Run the headless test agent:

```bash
./testing/run_agent.sh
```

Build desktop and browser artifacts:

```bash
./scripts/build_exports.sh
```

## What The Prototype Covers

- Top-down movement on a real Washington hillshade map
- DF tuning by direct frequency entry, slider, or waterfall click
- Full-band waterfall display
- Scanner sweep, lock, and unlock behavior
- Audio discrimination between the real conversation and educational decoys
- Bearing capture and fix submission
- A startup welcome modal explaining the hunt flow

## Releases And Downloads

The repo publishes a rolling `Prototype Latest` release on successful pushes to `master` or `main`.

Release artifacts include:

- Linux desktop zip
- Windows desktop zip
- HTML5 browser zip

For local output paths and packaging details, see [docs/distribution.md](/home/ein/projects/simple_game/docs/distribution.md).

## Contributor Quickstart

- Start from a short-lived branch
- Open a PR against `master`
- Keep changes focused
- Run relevant verification before pushing

Preferred local checks:

```bash
./run_demo.sh --quit
./testing/run_agent.sh
./scripts/build_exports.sh
```

See [CONTRIBUTING.md](/home/ein/projects/simple_game/CONTRIBUTING.md) for the repo workflow.

## Roadmap

- Improve repo hardening and maintenance automation
- Refine onboarding and user-facing training flow
- Push the fake-but-useful waterfall and RF simulation toward a more realistic model
- Expand scenarios, terrain effects, and mission progression

## Audio Sources

The demo defaults to cleaner training-voice loops and then applies in-game degradation on top.

Primary clean training sources:

- `Wikipedia - Human voice (spoken by AI voice).mp3`, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Wikipedia_-_Human_voice_(spoken_by_AI_voice).mp3
- `Wikipedia - Umbriel (spoken by AI voice).mp3`, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Wikipedia_-_Umbriel_(spoken_by_AI_voice).mp3

Legacy comparison sample:

- `Ham Contest Exchange.ogg`, Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Ham_Contest_Exchange.ogg
