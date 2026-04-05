# Workflow Notes

## Branching

For future work, use short-lived branches from the current baseline by default.

Suggested pattern:

- `main` or `master` stays runnable and should not be used for day-to-day implementation work
- Feature branches use names like:
  - `feature/waterfall-real-data`
  - `feature/hud-reflow`
  - `fix/reset-randomization`

Required policy:

- Start new work on a branch unless the user explicitly asks for direct default-branch changes.
- Open a PR before merging whenever practical.
- Treat direct `master` or `main` commits as exceptions for urgent CI or release repair only.

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

## Release flow

- Pushes to `master` or `main` trigger GitHub Actions CI.
- CI runs the headless gameplay tests and export build.
- If CI succeeds on `master` or `main`, GitHub updates the rolling release tagged `prototype-latest` with the latest Linux, Windows, and HTML5 artifacts.
- The same successful push also deploys the HTML5 build to GitHub Pages.

## Current baseline

- Commit: `f71ed0e`
- Meaning: first stable prototype baseline with docs and git tracking
