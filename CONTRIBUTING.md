# Contributing

## Workflow

- Start work from a short-lived branch.
- Open a pull request against `master`.
- Keep changes focused on one concern.
- Run the smallest relevant local verification before pushing.

Preferred verification commands:

```bash
./run_demo.sh --quit
./testing/run_agent.sh
./scripts/build_exports.sh
```

## Change Scope

- Avoid mixing unrelated UI, signal-model, CI, and repo-maintenance changes in one PR.
- Update documentation when behavior or workflow changes.
- Do not commit generated runtime noise unless the file is intentionally tracked.

## Review Notes

PR descriptions should include:

- what changed
- why it changed
- how it was verified
- any known caveats

## Assets And External Sources

- Prefer assets with clear reuse terms.
- Document source/provenance for newly added third-party assets or downloads.
