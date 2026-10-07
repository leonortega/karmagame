## Why

Three live runs show sapos never perceiving insects while lake-biased supply exists: insects ring the two lagos, sapos roam (and drink at charcos) elsewhere. Counts are not the bottleneck (worlds seed ~24, cap 10); placement is. Charcos — the water sapos actually visit — have no insect affinity at all.

## What Changes

- Insect spawns cluster around all water: lago shore ring as today (probability `lakeInsectBias` 0.6, ring `r+8..r+lakeShore`), else charco shore ring (probability `charcoInsectBias` 0.7 of the remainder, ring `r+8..r×4`, radius-relative so puddles get tight rings), else uniform dry scatter as today.
- Caps, cadence, wander, payoffs, and the never-inside-water rule are untouched.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `vitals-water`: the insect-density requirement covers charco shore rings alongside lago rings with the stated probabilities and geometry.

## Impact

- Affected code: `KarmaGame.spawn_insect_pt` branching + one `TUNING` key (`charcoInsectBias`); `KarmaData.TUNING` gains that key only.
- Tests: ring-placement distribution tests (new branch RED on old code), lago-path guard, never-inside-water guard.
- No diet, economy, cadence, JEV, or HUD changes.
