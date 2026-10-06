## 1. Raton decision bridge (TDD)

- [x] 1.1 Add `KarmaJevRaton` definition/menu/state builders (eat, seek-food, drink-seek, flee-to-refuge, wander-always) with menu-legality tests
- [x] 1.2 Add raton `apply_answer` through player paths (`eat_patch`, drink/seek, flee resolve) with parity and stale-target-to-wander tests
- [x] 1.3 Add raton batch body (`id/state/questions/criteria`, 2+ candidates, wander fallback) and per-species log triple (`jev-raton/v1`, `jev_raton.log`, flag) with isolation tests

## 2. Raton micro/macro wiring and verification

- [x] 2.1 Split raton strategy into JEV micro (contact eat, forage trek, drink, hide/flee, needs/cooldowns, wander social-verb fallthrough, `jev_live` wander) plus staggered 1s/3s LOD cadence and event re-ask with tests
- [x] 2.2 Wire `Main` poll/apply/flush for raton alongside zorro/halcon with fair scheduling and assert log isolation (raton entries only in `jev_raton.log`)
- [x] 2.3 Verify suite green plus F5 movement parity on the mocked raton path (steer/seek/eat/drink/flee without sidecar) and run `ponytail-review` over the diff

## 3. Raton verb candidates (log-sparsity fix)

- [x] 3.1 Add groom candidate (mate in `groomRange`) with steer-to-mate micro reusing the 3s timer, no instant karma, with tests
- [x] 3.2 Add alarm-call candidate (hunter in lure range, shout ready) applying through slot-1 verb parity, with tests
- [x] 3.3 Add seed-cache candidate (spare-fruit flora in range) applying through slot-2 verb parity, with tests
- [x] 3.4 Update mock order, re-verify suite green + live log volume, run `ponytail-review`
