## 1. Tuning table (TDD)

- [x] 1.1 Add failing gdUnit4 test asserting `TUNING.fruitRegrowByKind` per-kind rates and `TUNING.seedlingMult` 2.0, then green it in `scripts/karma_data.gd` (retire `fruitRegrow`/`seedlingMaturity`/`leafRegrow` as independent clocks).
- [x] 1.2 Add failing test locking apple full load at 2 (`FRUIT_CAP` apples 2 to match spec), then green it.

## 2. Per-kind regrow

- [x] 2.1 Add failing test: berry bush 1 below cap regrows in 20s while oak regrows nothing, then green via per-kind lookup in `regrow_fruit`/`age_world`.
- [x] 2.2 Add failing test: stripped berry bush revives with 1 fruit after 20s and leaf-clump regrows in 30s, then green on the same table path.

## 3. Unified seedling + strip renewal

- [x] 3.1 Add failing test: berry seedling matures to a 3-fruit bush in 40s (2.0 x 20s) and apple seedling to 2 apples in 70s, then green in `mature_seedlings` via derived wait.
- [x] 3.2 Add failing test: buried oak-tree seedling matures to a 3-nut young oak in 90s and bark `stripT` recovers on the nuts 45s rate, then green.
- [x] 3.3 Retire `fruitRegrow`/`seedlingMaturity`/`leafRegrow` scalars; update existing flora regrow/seedling tests pinned to 45s/60s/75s to the per-kind timings; suite stays green.

## 4. Balance + verification gate

- [x] 4.1 Re-validate census demand-vs-throughput (leaf/fruit/insect) at the faster throughput and note the outcome in the change.
- [x] 4.2 Run touched-script parse + full gdUnit4 suite green + main scene boots from F5 with no duplicate `class_name` collisions.

## 5. Everything grows: seed headroom + honest last-fruit text

- [x] 5.1 Add failing test: a fresh world seeds every fruiting kind below its flora cap (`floraHeadroom` headroom), then green in `seed_food`.
- [x] 5.2 Add failing test: a berry seedling matures into a new bush in a freshly seeded world (cap-stall repro), then green via the 5.1 headroom.
- [x] 5.3 Add failing test: player last-fruit message no longer says "para siempre", then green in `eat_last_fruit`.
- [x] 5.4 Add failing test: eating an empty/dead plant is refused (no negative stock, no repeat heal/karma), then green with a guard in `eat_patch`.

## Validation notes (4.1 outcome)

Faster regrow only raises supply, so every census demand-vs-throughput
check relaxes: leaves 16 clumps x 1/30s = ~32/min vs ~8/min oruga
demand (was ~16/min at 60s, still fit); berries 28 bushes x 1/20s;
insect cadence untouched. Census suite green in the full run
(`test_oruga_baseline_holds_feeder_surplus`, insect-gate and
prey:hunter tests all PASSED).
