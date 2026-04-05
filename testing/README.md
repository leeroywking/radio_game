# Testing Agent

This folder contains a headless gameplay testing agent for the prototype.

Run it with:

```bash
./testing/run_agent.sh
```

The agent instantiates the real main scene, drives core game actions through test hooks, and writes reports to:

- `testing/reports/latest.json`
- `testing/reports/latest.md`
- `testing/reports/previous.json`

Current coverage:

- Reset behavior changes broadcast layout and target frequency
- DF numeric entry updates tuning state
- Scanner can lock onto a broadcast
- Bearing capture and fix submission still work
- Target-audio continuity under ideal conditions, with and without clean monitor

The continuity case is intended to catch regressions where target audio drops out or slips off the target broadcast while it should remain stable.
