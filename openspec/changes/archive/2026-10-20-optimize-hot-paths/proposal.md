## Why

The simulation still pays avoidable per-tick cost in distance queries, roster filtering, and repeated dictionary/list construction, while several dead wrappers and duplicate rules make the hot paths harder to maintain. This is a behavior-preserving cleanup pass so the same decisions run with less churn.

## What Changes

- Remove confirmed dead code: six unused `KarmaAI` species wrappers and the unused `sapo_definition`, `topo_definition`, and `zorro_definition` builders.
- Collapse duplicate max-HP and cooldown rules onto single helpers.
- Remove the constant `KarmaUtils.eff_age_mult()` multiplier.
- Replace comparison-only `.distance_to()` calls with squared-distance comparisons in nearest-target, collision, water, and line-of-sight helpers.
- Hoist `KarmaState.all_hunters(state)` out of the per-mate loop in `KarmaGame.wander_mates`.
- Iterate flora category keys directly instead of concatenating plant arrays on every edible-patch query.
- Cache the constant JEV view diagonal and avoid rebuilding the camera dictionary every tick.
- Consolidate duplicated verb-cast and cooldown-tick loops.
- Preserve all selection rules, tie-breaks, tuning values, save shape, JEV protocol, and public behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor and performance cleanup; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_ai.gd`, `scripts/karma_eat.gd`, `scripts/karma_game.gd`, `scripts/karma_jev.gd`, `scripts/karma_jev_sapo.gd`, `scripts/karma_jev_topo.gd`, `scripts/karma_jev_zorro.gd`, `scripts/karma_state.gd`, `scripts/karma_utils.gd`, `scripts/main.gd`.
- Systems: per-tick AI queries, collision/LOS checks, edible-patch search, cooldown handling, and camera/JEV polling.
- Verification: focused gdUnit4 tests pin nearest-target choice, collision outcome, cooldown parity, and camera state before the rewrite; the full suite must remain green.
