# Agent Instructions

## Branch Policy

- Do not work directly on `master` or `main` for normal feature work, bug fixes, or documentation changes.
- Start every task on a short-lived branch unless the user explicitly says to work directly on the default branch.
- Use clear branch names such as:
  - `feature/waterfall-real-data`
  - `bugfix/df-audio-audible`
  - `docs/branch-policy`
- Open a PR for review before merging whenever practical.
- For reviewable work, do not stop at "branch pushed". The work is only handoff-ready once there is a GitHub PR URL or a clear blocker.

## Exceptions

- Direct work on `master` or `main` is only acceptable for urgent CI repair, release unblocking, or if the user explicitly asks for it.
- If direct default-branch work is necessary, call that out in the final handoff and explain why it was an exception.

## Verification

- Before pushing, run the smallest relevant verification locally.
- Preferred checks for this repo:
  - `./testing/run_agent.sh`
  - `./run_demo.sh --quit`
- For PR work, do not treat the branch as review-ready until the current GitHub PR checks have completed successfully.
- If a stale failed check from an older head leaves the PR in a failed or unstable state, rerun or update the branch until the current head shows green checks.
- Reviewable product changes should also include a small `VERSION` bump.
- For feature, UI, or gameplay work intended for PR review, make sure the branch can produce a browser preview and include that live-build URL in the PR body.
- Use the repo's preview URL conventions:
  - default branch build: `https://leeroywking.github.io/radio_game/`
  - feature branch preview: `https://leeroywking.github.io/radio_game/previews/<branch-name>/`

## Documentation

- Update agent-facing docs when workflow expectations change.
- Keep `docs/workflow.md` and `docs/handoff.md` aligned with these instructions.

## Execution Policy

- Do not stop at a partial implementation when the task can reasonably be carried through to review-ready state.
- Continue working until one of these is true:
  - the change is ready for human review with code, local verification, a PR, and green current PR checks
  - you hit a real blocker that cannot be resolved safely without user input
- If the work touches GitHub state or automation, push the branch and open the PR instead of leaving the change only in the local workspace.
- For reviewable feature work, "ready" means the PR includes a visible live preview link when the branch changes browser-playable behavior.
- In user-facing status and final messages, always state the PR status explicitly:
  - `open` with PR number and URL, or
  - `merged` with PR number and URL
- Never assume the user will infer PR state from context such as "it’s up" or from an empty open-PR list.
- If a PR changes shipped behavior in `scripts/`, `scenes/`, `assets/`, `project.godot`, or similar product files, bump `VERSION` in the same PR unless the user explicitly says not to.
