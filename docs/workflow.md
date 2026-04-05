# Workflow Notes

## Branching

For future work, prefer short-lived branches from the current baseline.

Suggested pattern:

- `main` or `master` stays runnable
- Feature branches use names like:
  - `feature/waterfall-real-data`
  - `feature/hud-reflow`
  - `fix/reset-randomization`

## Commit style

Prefer small commits with one main concern each.

Examples:

- `Fix reset randomization for target frequency`
- `Add direct numeric entry for DF tuning`
- `Reflow HUD to reduce overlap`

## Safety rules

- Keep the project runnable after each commit.
- Smoke-test with:

```bash
./run_demo.sh --quit
timeout 3 ./run_demo.sh
```

- Avoid mixing UI redesign, signal-model changes, and asset-pipeline changes in one commit.
- When adding visuals, prefer incremental changes over rewrites.

## Current baseline

- Commit: `f71ed0e`
- Meaning: first stable prototype baseline with docs and git tracking
