## Context

See proposal.md Why. Current state: `KarmaGame.regrow_fruit(list, cap, dt, rate)` defaults every kind to `TUNING.fruitRegrow` 45s except clumps on `TUNING.leafRegrow` 60s; `mature_seedlings` waits fixed `TUNING.seedlingMaturity` 75s; `FRUIT_CAP` in code says apples 3 while the spec says 2; bark sets `stripT = fruitRegrow`. Numbers live in `KarmaData.TUNING` per repo rule, no magic numbers elsewhere.

## Goals / Non-Goals

**Goals:**
- One per-kind velocity drives empty revival, incremental regrow, seedling maturity, and bark-strip recovery.
- Base unit reads as ~1 raton-year (20s); oaks stay slow landmarks.

**Non-Goals:**
- No hunger/SEC_PER_YEAR dynamic scaling (fixed table, not a live function of possessed species).
- No changes to `seedSproutChance`, `seedlingMax`, flora caps, karma payoffs, mimic/toxic rules, or rendering.

## Decisions

- **Table over formula:** `fruitRegrowByKind = {berries 20, carrots 25, leaves 30, mushrooms 30, apples 35, nuts 45}`. Why: per-kind flavor the request names ("depending the fruit and the plant") with one glanceable table; alternative live scaling by `hungerMult`/`SEC_PER_YEAR` was rejected as harder to test and explain, and it would swing census balance per-life.
- **`seedlingMult 2.0` derived maturity:** `maturity[kind] = 2.0 x rate[kind]` (berries 40s, oak 90s). Why 2x: seeds beat in-place full recovery (cap x rate) so spreading is rewarded within one life, but stay slow enough that caps remain the throttle; 1x floods the map, cap-based makes planting pointless.
- **Leaves fold into the table (30s):** removes `leafRegrow` as a second clock; oruga feeder surplus only grows, which the census check already requires to fit.
- **Apples lock at 2:** spec wins over `FRUIT_CAP` drift; full-recovery cost becomes 70s, matching the "productive" scenario.
- **Bark `stripT` rides the nuts rate:** stripped oak is an emptied plant by another name; no fourth clock.

## Risks / Trade-offs

- [Risk] Faster berries (20s vs 45s) doubles fruit throughput; AI grazers may never go hungry, softening predator pressure → Mitigation: caps and `seedlingMax` unchanged; re-run census demand-vs-throughput validation (it only relaxes, never tightens).
- [Risk] Callers still pass raw `fruitRegrow`/`leafRegrow`/`seedlingMaturity` → Mitigation: single lookup helper `regrow_rate_for(kind)`; old keys removed, tests updated to the table.
- [Risk] Save/compat: `regrowT`/`age` counters are unitless seconds, so no migration; only rates change.

## Migration Plan

TUNING-only shape change plus call-site lookups; no save migration. Rollback = restore the three old scalars. No deployment steps (local Godot project).
