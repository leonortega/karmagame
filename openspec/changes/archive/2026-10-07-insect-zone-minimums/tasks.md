## 1. Zone minimums

- [x] 1.1 Add failing tests: zone counts split insects by ring geometry (overlap counts both); refill with short charco zone spawns in a charco ring; minimums-met falls through to the lottery/cap path; absent kinds never stall respawn
- [x] 1.2 Implement the zone-counting helper and priority refill in `age_world` (charco-short → lago-short → lottery under cap 40)
- [x] 1.3 Seed both minimums round-robin at world gen; update the existing cap-10 tests to the new ceiling

## 2. Verification gate

- [x] 2.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 2.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
