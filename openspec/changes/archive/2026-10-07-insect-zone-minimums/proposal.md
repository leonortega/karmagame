## Why

Bias alone cannot promise insects: a probability still rolls empty, and the global cap (10) sits far below what "a lot more insects around water" means. The user wants guaranteed minimums — at least 10 insects around charcos and at least 20 around lagos at all times.

## What Changes

- Zone minimums with priority refill: each respawn tick first tops up charco zones below 10 (spawn in a charco ring), then lago zones below 20 (spawn in a lago ring), and only then runs the existing bias lottery while the total stays below cap.
- Global cap `insectMax` 10 → 40 (minimums total 30 plus headroom for uniform stragglers); cadence, wander, payoffs, and never-inside-water unchanged.
- World generation seeds the minimums directly (10 across charcos, 20 across lagos, round-robin); maps lacking a water kind skip that kind's minimum.
- A zone counts insects within its ring geometry (charco `r×4`, lago `r+lakeShore`); an insect inside both counts for both.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `vitals-water`: the insect-density requirement gains zone minimums, priority refill order, the higher cap, and seeded minimums.

## Impact

- Affected code: `KarmaGame.age_world` respawn branch, world-gen insect seeding (`KarmaState`), `insectMax` in `TUNING`, one zone-counting helper.
- Tests: zone counting, priority refill (below-minimum spawns in-zone; minimums-met falls through to lottery/cap), absence skips, seeded totals. Existing cap-10 tests update to the new cap.
- No diet, economy, JEV, or HUD changes; topo shares the abundance through the same supply (intended).
