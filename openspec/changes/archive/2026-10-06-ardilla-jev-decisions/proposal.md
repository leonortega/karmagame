## Why

AI ardilla still runs a hardcoded ladder while zorro, halcon, and raton already play their full kits through NanoJev ranking over code-built legal menus. Ardilla is the next grazer conversion: its two-phase nut carrying (pick up, carry across intents, bury) is the first multi-step intent state in the migration series, and its climber trait plus no-lure alarm give the ranker genuinely new trade-offs.

## What Changes

- Give AI ardilla the same micro/macro split as the converted species: micro steering every physics tick (contact eat, forage-seek, drink, hide/flee reflexes, needs/cooldowns, never waits for API) plus macro intent from batched NanoJev `Choice` ranking over a code-built legal candidate menu (eat, seek-food, carry-nut, bury-nut, bark, falsecache, tailflick, drink-seek, flee-to-refuge, wander always present).
- Every applied ardilla intent executes through the same functions as the player (`eat_patch`, `bury_or_carry_nut`, `cast_verb_for`, drink/seek/flee resolve).
- `carriedNut` persists on the agent across intent expiry; a hungry carrier eats the nut exactly as the ladder does today.
- Ardilla reuses the per-species logging seam (own `jev-ardilla/v1` schema, own `user://logs/jev_ardilla.log`, own compile-time flag defaulting on as the migrating species); mocked decisions never log.
- Poll + apply + flush ardilla through the Main-owned batch path with an explicit per-species scheduling function (no generalized N-way picker — per the project's per-species-everything stance, each animal keeps its own scheduling path).
- Only the current species logs: starting this migration flips `LOG_JEV_RATON` off and `LOG_JEV_ARDILLA` on.

## Capabilities

### New Capabilities

- `ai-jev-ardilla`: NanoJev-backed macro decisions for AI ardilla (batch contract, climber-aware grazer menu with two-phase carry/bury, micro/macro split, cadence, per-species logging).

### Modified Capabilities

- `ai-species-behavior`: ardilla clause of `updateAgents` delegates macro intent to JEV ranking instead of the hardcoded ladder; eat/diet/karma values unchanged.

## Impact

- Affected code: `scripts/karma_jev_ardilla.gd` (new bridge), `scripts/karma_ai_ardilla.gd` (new strategy), `scripts/karma_jev.gd` + `scripts/karma_ai.gd` (facade delegates + ardilla scheduling function), `scripts/main.gd` (ardilla poll/apply/flush blocks).
- Tests: new `tests/test_karma_jev_ardilla.gd` (menu legality incl. carry/bury phases, parity, stale hygiene, log isolation) plus existing suites unchanged.
- Systems: F5 dev needs the NanoJev sidecar for ardilla intent when its flag is on; ladder remains as fallback when the flag is off. No save-format migration (logs append-only, outside saves).
