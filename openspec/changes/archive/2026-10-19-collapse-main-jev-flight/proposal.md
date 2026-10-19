## Why

`main.gd` repeats the same JEV request lifecycle eight times: eight sets of `_agents` / `_menus` / `_snaps` fields, eight send functions, eight apply branches, and eight clear/timeout paths. The duplication is roughly 200 lines of near-identical state and is a standing source of cross-species copy/paste bugs like the target-intent regression fixed in `fix-jev-target-intent`.

## What Changes

- Replace the eight per-species flight fields with one generic in-flight record carrying the species key, agent list, menus, snapshots, and sent time.
- Replace the eight send/apply/clear blocks with one route that dispatches by species key while preserving the existing single-flight guarantee.
- Keep fair-share scheduling, per-species cadence, telemetry counters, busy-skip accounting, timeout behavior, and apply routing exactly as they behave today.
- No spec-level, save-format, tuning, or API changes; this is a behavior-preserving refactor.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/main.gd` (flight state, send functions, apply/timeout callbacks).
- Systems: JEV request lifecycle only; AI cadence and menus are untouched.
- Prerequisite: land `fix-jev-target-intent` first so the refactor does not duplicate a known-buggy helper.
