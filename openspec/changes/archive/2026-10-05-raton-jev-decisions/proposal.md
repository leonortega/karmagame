## Why

AI raton still runs a hardcoded ladder (`_ai_raton`: contact eat, forage, groom/share verbs, wander) while zorro and halcon already play their full kits through NanoJev ranking over code-built legal menus. Raton is the first grazer conversion and the template for the remaining five species: same micro/macro split, same single-batch path, same per-species logging — with a grazer-shaped menu (edible patches, drink-seek, flee/hide, wander) instead of carrion/hunt verbs.

## What Changes

- Give AI raton the same micro/macro split as zorro/halcon: micro steering every physics tick (contact eat, forage-seek, drink, hide/flee reflexes, needs/cooldowns, never waits for API) plus macro intent from batched NanoJev `Choice` ranking over a code-built legal candidate menu (eat, seek-food, drink-seek, flee-to-refuge, wander always present).
- Every applied raton intent executes through the same functions as the player (`eat_patch`, `ai_drink`/`drink_water`, `move_toward`, `cast_verb_for` for groom/share paths).
- Raton reuses the per-species logging seam (own `jev-raton/v1` schema, own `user://logs/jev_raton.log`, own compile-time flag); mocked decisions never log.
- Poll + apply + flush raton through the existing Main-owned batch path with fair cross-species scheduling (no species starves another).
- Groom/share social verbs keep working during JEV mode (wander intent falls through to the existing social-verb path when not hungry), so no karma behavior is lost in conversion.

## Capabilities

### New Capabilities

- `ai-jev-raton`: NanoJev-backed macro decisions for AI raton (batch contract, grazer candidate menu, micro/macro split, cadence, per-species logging).

### Modified Capabilities

- `ai-species-behavior`: raton clause of `updateAgents` delegates macro intent to JEV ranking instead of the hardcoded ladder; eat/diet/karma values unchanged.

## Impact

- Affected code: `scripts/karma_jev_raton.gd` (new bridge), `scripts/karma_ai_raton.gd` (new strategy), `scripts/karma_jev.gd` + `scripts/karma_ai.gd` (facade delegates), `scripts/main.gd` (raton poll/apply/flush alongside zorro/halcon).
- Tests: new `tests/test_karma_jev_raton.gd` (menu legality/parity/hygiene) plus existing zorro/halcon suites unchanged.
- Systems: F5 dev needs the NanoJev sidecar for raton intent when its flag is on; ladder remains as fallback when the flag is off. No save-format migration (logs append-only, outside saves).
