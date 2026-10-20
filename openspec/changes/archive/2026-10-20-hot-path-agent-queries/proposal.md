## Why

Per-physics-tick paths allocate disposable arrays and re-scan the full agent list: `is_hunted` filters all agents on every call, `stalk_victims` is rebuilt inside each predator pass, and `_jev_poll` re-scans every species every tick even when a batch is already in flight. On a full map this is avoidable churn in the hottest code.

## What Changes

- Replace hot-path `.filter()` allocations with direct loops that preserve the same predicate and iteration order.
- Reuse the predator victim list and role buckets within a tick instead of rebuilding them per predator and per query.
- Make `_jev_poll` cheap while a request is in flight and avoid recomputing work that cannot change until the batch resolves.
- Keep every query result, cadence, fear/hide range, and selection rule identical.
- No spec-level, save-format, tuning, or API changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_ai.gd`, `scripts/karma_predators.gd`, `scripts/karma_game.gd`, `scripts/karma_state.gd`, `scripts/main.gd`.
- Systems: per-tick AI query cost and JEV poll scheduling; observable game behavior must not change.
- Verification: characterization tests pin query outcomes before the loop rewrite, then the full suite must stay green.
