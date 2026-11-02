## 1. Core implementation

- [x] 1.1 Rewrite `KarmaEat.eat_patch` in `scripts/karma_eat.gd`: keep empty/dead and off-diet guards; keep mimic and toxic-shroom branches unchanged; branch leaves onto the existing sustainable path; implement one-bite whole-patch consumption for non-leaf fruits (amount=0, alive=false, heal (amount-1)*foodHp + lastFruitHp, refill hambre, PA=(amount-1)*foodPa player only, karma -15 player only, seed drop `amount` times).
- [x] 1.2 Update `KarmaData.PRED` damage bases in `scripts/karma_data.gd`: zorro 28.0 (unchanged), lobo 35.0→38.0, halcón 15.0→30.0.

## 2. Tests

- [x] 2.1 Update `tests/test_karma_systems.gd::test_sustainable_eat_pays` to the one-bite expectation (bush with 3 fruits → 50 HP, 10 PA, -15 karma, dead).
- [x] 2.2 Update (verified unchanged) `tests/test_karma_flora_pacing.gd::test_eating_empty_bush_is_refused` if its HP assertion changes (single fruit still +20, so likely unchanged; verify).
- [x] 2.3 Update (verified: JEV tests assert HP increase only; no amount-after-eat assertions) `tests/test_karma_jev_raton.gd` and `tests/test_karma_jev_ardilla.gd` eat_patch parity expectations to full-patch consumption.
- [x] 2.4 Run gdUnit4 suite (645 cases, 0 failures, 0 errors) and confirm full count, no silent suite aborts.

## 3. Verification

- [x] 3.1 Parse touched scripts (karma_eat.gd, karma_data.gd OK) with Godot `--check-only`.
- [x] 3.2 Confirm no duplicate global class_name/func collisions global class_name/func collisions.
- [x] 3.3 Run main scene smoke test (ran 5s headless, no crash).