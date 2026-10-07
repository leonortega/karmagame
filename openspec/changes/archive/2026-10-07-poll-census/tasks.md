## 1. Census helper

- [x] 1.1 Add failing unit tests: `KarmaJev.census` counts insects, carrions, and per-species agents; empty lists count 0
- [x] 1.2 Implement the pure helper in `scripts/karma_jev.gd`
- [x] 1.3 Merge the snapshot into the `jev_poll.json` flush line in `scripts/main.gd`

## 2. Verification gate

- [x] 2.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 2.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
