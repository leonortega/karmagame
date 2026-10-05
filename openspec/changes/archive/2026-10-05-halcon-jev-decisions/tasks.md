## 1. Per-species logging seam

- [x] 1.1 Add `SCHEMA_FOR(species)`, `JEV_LOG_PATH_FOR(species)`, `LOG_JEV_ZORRO` / `LOG_JEV_HALCON` flags and migrate zorro calls to the species-keyed forms with identical zorro output
- [x] 1.2 Gate `log_decision` on species flag with per-species `state["jev_log_<species>"]` buffers at cap 200; assert disabled species buffers nothing and mock applies log nothing
- [x] 1.3 Split `Main` flush to per-species `_jev_flushed_<species>` counters looping only enabled species with independent `ensure_log_ready` per file

## 2. Halcon decision bridge

- [x] 2.1 Implement halcon definition/menu/state builders (dive/hunt, eat/seek-carrion, courtesy, scare, bone, thermal, drink, flee, wander-always) with menu-legality tests
- [x] 2.2 Implement halcon `apply_answer` through player paths (`eat_carrion`, `cast_verb_for`, dive/hunt resolve, grounded/landT) with parity and stale-target-to-wander tests
- [x] 2.3 Implement halcon batch body (`id/state/questions/criteria` 2+ candidates, wander fallback) and answer parsing with contract tests

## 3. Halcon micro/macro wiring and verification

- [x] 3.1 Split `_ai_halcon` into `_ai_halcon_jev` micro (dive-kill at 60px, grounded eat/unground, drink, needs/cooldowns, `jev_live` wander) plus staggered 1s/3s LOD cadence and event re-ask with tests
- [x] 3.2 Wire `Main` poll/apply/flush for halcon alongside zorro and assert log isolation (halcon entries only in `jev_halcon.log`, zorro file untouched when its flag is off)
- [x] 3.3 Verify suite green plus F5 movement parity on the mocked halcon path (steer/hunt/eat/land/drink without sidecar)

## 4. Thermal affordability fixes (from live `jev_halcon.log` review)

- [x] 4.1 Gate thermal menu entry on `pa >= costPa` so unaffordable thermal is impossible by construction
- [x] 4.2 Return `applied=false` from the thermal apply-time PA fallback so the log records what executed
- [x] 4.3 Show thermal PA cost in its criteria label so the ranker can weigh affordability

## 5. Appetite-based hunger (applies to every animal)

- [x] 5.1 Redefine `is_hungry` as `hambre < 100` so any food deficit outranks secondary behaviors, with suite green and no new fallout

## 7. Thirst emergency (applies to every animal)

- [x] 7.1 Fall back to the nearest water at any distance in `ai_seek_water` when nothing is inside scout range, with suite green

## 8. Eat urgency hint (halcon)

- [x] 8.1 Show a hunger hint in the eat criteria label when `hambre < regenHambre`, plain label otherwise, with suite green

## 6. Halcon poll starvation (live symptom: zorro calls fine, zero halcon batches)

- [x] 6.1 Hunger re-ask is edge-triggered (`jev_was_hungry` recorded in `mark_asked`) so steady hunger no longer bypasses the stagger timer every frame
- [x] 6.2 Species batches round-robin via testable `pick_batch_species` so same-frame contention alternates instead of zorro-first always winning
