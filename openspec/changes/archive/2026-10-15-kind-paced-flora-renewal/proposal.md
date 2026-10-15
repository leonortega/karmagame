## Why

Plants recover on fixed 45s/60s/75s clocks while animals age one year every 15-30s (`SEC_PER_YEAR`), so a full bush (135s) costs 6-9 animal-years and a buried oak (75s) often matures after the planter is dead. The map feels frozen and planting is not rewarded within one life.

## What Changes

- Replace single `TUNING.fruitRegrow` (45s) with a per-kind table `TUNING.fruitRegrowByKind` (berries 20s, carrots 25s, leaves 30s, mushrooms 30s, apples 35s, nuts 45s), anchored to ~1 raton-year (20s) as the base unit.
- Replace fixed `TUNING.seedlingMaturity` (75s) with derived maturity: `seedMult (2.0) x fruitRegrowByKind[kind]`; delete the independent clock so seedlings and emptied plants renew on the same per-kind velocity.
- Empty-plant revival stays one regrow tick (now per-kind); full recovery is `cap x rate`; seedlings mature bearing full load unchanged.
- Lock apple full load at 2 (spec value) to fix the code/spec drift (`FRUIT_CAP` apples 3 vs spec 2).
- Keep leaf-clumps on the same table (30s, down from 60s) instead of a separate `leafRegrow`; keep oak/nuts slow (45s) as landmarks and bark-strip recovery on the nuts rate.
- Seed every fruiting kind `floraHeadroom` (2) below its flora cap so seedlings can mature into new plants/trees during play (draws unchanged, kept prefix shrinks); `eat_patch` refuses dead/empty plants so stock never goes negative and worst-case recovery is always one cycle.
- Last-fruit player message drops "se seca para siempre" for "volverá a dar fruto".

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `flora-lifecycle`: fruit regrow clock becomes per-kind; seedling maturity becomes derived from the same per-kind rate; leaf regrow folds into the table; fresh worlds seed below cap; empty eats are refused.
- `ecosystem-2d`: initial food counts leave `floraHeadroom` headroom below cap; leaf regrow follows the per-kind table (30s).

## Impact

- `scripts/karma_data.gd` (`TUNING` shape only, no other numbers): `fruitRegrowByKind` + `seedlingMult`, retire `fruitRegrow`/`seedlingMaturity`/`leafRegrow` as independent clocks (kept as aliases only if tests need a transition).
- `scripts/karma_game.gd`: `regrow_fruit` per-kind rate lookup, `mature_seedlings` derived wait, `age_world` call sites, bark `stripT` on nuts rate.
- Tests: gdUnit4 flora regrow/seedling suites assert new per-kind timings; census demand-vs-throughput check re-validated (faster throughput only relaxes it).
