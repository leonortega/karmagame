## Why

AI halcon uses a hardcoded ladder (`_ai_halcon`) while AI zorro already plays its full 5-verb kit through NanoJev ranking. Halcon is the next conversion because it shares the carnivore diet (carrion + mates) and hunt verbs closest to zorro, and its dive/land/grounded cycle needs decision data. At the same time the single `jev_zorro.log` blocks multi-species debugging: lobo/halcon entries would mix with zorro noise and pollute training data.

## What Changes

- Generalize JEV decision logging to one file per species (`user://logs/jev_<species>.log`), gated by compile-time per-species log flags; disabled species drop entries at `log_decision` (no memory growth, no file touch).
- Generalize JEV schema to one per animal (`jev-<species>/v1`), starting with `jev-zorro/v1` (kept) plus `jev-halcon/v1`.
- Give AI halcon the same micro/macro split as zorro: micro steering every physics tick (dive-kill, drink, grounded/land cycle, needs/cooldowns, never waits for API) plus macro intent from batched NanoJev `Choice` ranking over a code-built legal candidate menu (dive/hunt, eat-carrion, seek-carrion, courtesy-share, scare, bone-drop, thermal, drink-seek, flee/hide, wander always present).
- Poll + apply + flush halcon through the same Main-owned single-batch path, writing only to `jev_halcon.log` when its flag is on.
- Mock halcon decisions never log; only live NanoJev answers append entries (same rule now stated explicitly for zorro).
- Halcon thermal is only offered when affordable (`pa >= costPa`, mirroring the zorro dendig HP check); unaffordable picks fall back to wander and log `applied=false` so training data stays honest.
- Costly halcon verbs carry their cost in the criteria label (thermal shows its PA cost) so the ranker can weigh affordability alongside the numeric `pa` already in the state snapshot.
- Hunger is appetite-based for every animal: `hungry` is true whenever `hambre < 100`, so food-seeking outranks secondary behaviors at any deficit instead of only near starvation.
- Thirst emergency for every animal: a thirsty animal with no water inside scout range treks to the nearest water at any distance instead of giving up.
- Hungry halcon sees food urgency: the eat criteria label carries a hunger hint below `regenHambre` so the ranker can weigh need, mirroring the cache-fullness hint.

## Capabilities

### New Capabilities

- `ai-jev-halcon`: NanoJev-backed macro decisions for AI halcon (batch contract, candidate menu, micro/macro split, cadence, per-species logging).

### Modified Capabilities

- `ai-jev-zorro`: decision logging becomes per-species (own file, own compile-time flag, own `jev-zorro/v1` schema); mock decisions explicitly never log.
- `ai-species-behavior`: halcon clause of `updateAgents` delegates macro intent to JEV ranking instead of the hardcoded ladder; kill/carrion/karma values unchanged.

## Impact

- Affected code: `scripts/karma_jev.gd` (species-keyed schema/path/flags, halcon menu/state/batch/apply), `scripts/karma_ai.gd` (`_ai_halcon` split into `_ai_halcon_jev` + steer + ladder fallback), `scripts/main.gd` (per-species poll/flush counters).
- Tests: `tests/test_karma_jev.gd` (halcon menu legality/parity/hygiene, per-species log isolation) plus existing zorro tests updated for species-keyed logging.
- Systems: F5 dev requires the NanoJev sidecar for halcon intent when its flag is on; zorro behavior unchanged when its flag is on. No save-format migration (logs are append-only files outside saves).
