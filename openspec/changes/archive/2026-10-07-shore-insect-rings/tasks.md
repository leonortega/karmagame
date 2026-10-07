## 1. Charco rings

- [x] 1.1 Add failing distribution tests: charco-only world puts most spawns in charco rings (RED on old uniform code); lago-path guard keeps the lago ring; no spawn ever lands inside water
- [x] 1.2 Branch `spawn_insect_pt` (lago → charco ring → uniform) plus `charcoInsectBias` in `TUNING`; initial seeding and respawn callers untouched

## 2. Verification gate

- [x] 2.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 2.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
