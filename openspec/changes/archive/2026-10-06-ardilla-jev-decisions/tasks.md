## 1. Ardilla decision bridge (TDD)

- [x] 1.1 Add `KarmaJevArdilla` definition/menu/state builders (eat, seek-food, carry-nut, bury-nut, bark, falsecache, tailflick, drink-seek, flee-to-refuge, wander-always) with menu-legality tests
- [x] 1.2 Add ardilla `apply_answer` through player paths (`eat_patch`, `bury_or_carry_nut`, verb slots) with parity and stale-target-to-wander tests
- [x] 1.3 Add ardilla batch body (`id/state/questions/criteria`, 2+ candidates, wander fallback) and per-species log triple (`jev-ardilla/v1`, `jev_ardilla.log`, flag) with isolation tests

## 2. Ardilla micro/macro wiring and verification

- [x] 2.1 Split ardilla strategy into JEV micro (contact eat, carry/bury intents with agent-side `carriedNut`, hungry-carrier rule, forage trek, drink, hide/flee incl. climb-only, needs/cooldowns, wander social-verb fallthrough, `jev_live` wander) plus staggered 1s/3s LOD cadence and event re-ask (incl. pickup/burial) with tests
- [x] 2.2 Wire `Main` poll/apply/flush for ardilla with explicit `pick_batch_species_4` (keep `_3` untouched) and assert log isolation; flip `LOG_JEV_RATON` off / `LOG_JEV_ARDILLA` on
- [x] 2.3 Verify suite green plus F5 movement parity on the mocked ardilla path (steer/carry/bury/eat/drink/flee without sidecar) and run `ponytail-review` over the diff
