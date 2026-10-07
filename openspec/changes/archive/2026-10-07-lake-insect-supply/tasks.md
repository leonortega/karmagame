## 1. Supply numbers

- [x] 1.1 Add failing world-sim tests: insects climb by one per respawn window and saturate at (not above) the new cap with no predation
- [x] 1.2 Set `insectMax` 6 → 10 and `insectRespawn` 20s → 12s in `KarmaData.TUNING`; keep bias, shore, wander, payoffs untouched

## 2. Verification gate

- [x] 2.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 2.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
