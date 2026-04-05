# Agent Instructions

## Branch Policy

- Do not work directly on `master` or `main` for normal feature work, bug fixes, or documentation changes.
- Start every task on a short-lived branch unless the user explicitly says to work directly on the default branch.
- Use clear branch names such as:
  - `feature/waterfall-real-data`
  - `bugfix/df-audio-audible`
  - `docs/branch-policy`
- Open a PR for review before merging whenever practical.

## Exceptions

- Direct work on `master` or `main` is only acceptable for urgent CI repair, release unblocking, or if the user explicitly asks for it.
- If direct default-branch work is necessary, call that out in the final handoff and explain why it was an exception.

## Verification

- Before pushing, run the smallest relevant verification locally.
- Preferred checks for this repo:
  - `./testing/run_agent.sh`
  - `./run_demo.sh --quit`

## Documentation

- Update agent-facing docs when workflow expectations change.
- Keep `docs/workflow.md` and `docs/handoff.md` aligned with these instructions.
