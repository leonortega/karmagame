## 1. Zorro definition freeze

- [x] 1.1 Compile zorro definition table from KarmaData (SPECIES/DIET/VERB_DEFS/PRED/TUNING/SHOP/LOCO) with all values and ranges
- [x] 1.2 Version the macro state/menu JSON schema string (v1) used for batch, answers, and logs

## 2. Pure menu and state builders (mocked, tested)

- [x] 2.1 Implement legal candidate menu builder per zorro (pounce/hunt/eat/seek/cede/cache/dendig/strike/drink/flee/wander with cd/range/diet/HP checks, wander always present)
- [x] 2.2 Implement per-zorro state snapshot builder (self + perception: prey/carrion/water/lobo/refuge + need flags)
- [x] 2.3 Implement answer applier through player code paths (eat_carrion/cede/cast_verb_for/pounce resolve) with stale-answer to prior-intent/wander hygiene
- [x] 2.4 Add gdUnit4 tests for builders/applier with mocked answers (illegal-move-impossible, parity-of-effects, stale hygiene, wander-always-present)

## 3. Micro/macro split with mocked macro

- [x] 3.1 Split `_ai_zorro` into micro steering (move/kill/drink/flee/ticks every physics frame) plus macro intent object with TTL
- [x] 3.2 Wire Main-owned mocked macro source behind a revert flag (ladder vs JEV path) with other 7 species untouched
- [x] 3.3 Verify suite green plus F5 movement parity on mocked path (zorros steer/hunt/eat/cede without service)

## 4. Live local bridge, cadence, logging

- [x] 4.1 Add Main-owned async batch client for `POST 127.0.0.1:8765/api/evaluate` (one call per window, request IDs, timeout hygiene to prior-intent)
- [x] 4.2 Implement staggered 1s timer plus event re-ask (lobo-enter, hunger threshold, carrion-enter, kill, intent reached/expired) with data-LOD 3s far from camera
- [x] 4.3 Surface `emocion` to HUD/feed as text-only flavor alongside existing karma feed entry
- [x] 4.4 Append decision logs (schema v1 snapshot, menu, choice + probs, outcome) from day one
- [x] 4.5 Flush decision log to `user://jev_zorro.log` as JSONL from Main (0.5s cadence, covers mock + live)

## 5. Verification and review gate

- [x] 5.1 Run full gdUnit4 suite green with no live HTTP in tests, touched scripts parse, no duplicate class/func collisions
- [ ] 5.2 Manual F5 with sidecar: zorro batch intent visibly covers cede/cache/dendig/strike alongside hunt/eat across several minutes
- [x] 5.3 Ponytail-review pass over the diff; fix or explicitly defer each finding
