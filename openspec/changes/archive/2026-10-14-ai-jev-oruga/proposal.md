## Why

Oruga is the last species still running inline ladder AI (`KarmaAI._ai_oruga`) while all seven other species use NanoJev macro ranking + per-tick micro steering. Migrating oruga to the same pattern closes the migration, and enabling the JEV log only for oruga gives a focused observation window to tune its behaviour from real ranked decisions.

## What Changes

- New `KarmaJevOruga` bridge (menu / state / mock / apply / batch / HTTP body) following the sapo/topo template (Option B: GDScript builds legal menu, sidecar only ranks).
- New `KarmaAIOruga` strategy (`step_ladder` / `step_jev` / `steer_intent`) with micro steering every physics tick that never waits for answers.
- Oruga candidate menu (option A, menu-complete): `eat` (leaves contact), `seek_food` (distant leaves when hungry), `drink`, `flee` (hunted), `silk` (slot 2, hunter in range), `nectar` (slot 3, hunter in range, HP/PA affordable), `leafroll` (slot 4, clump in range), `wander` (always present). `prudent` (slot 1) is not offered separately because `eat_patch` already pays `prudentKarma` automatically; `bristle` (slot 5) stays player-only (no agent-side reversal exists in `strike_agents`).
- Stillness-preserving wander tail (sapo pattern): wander accumulates `stillT` instead of `wander_poi` travel, keeping `curled_agent` defense and `ai-species-behavior` exemption intact.
- Batch path: oruga joins Main single-flight scheduling with fair rotation (`pick_batch_species_8`); LOD 1s near / 3s far; event re-asks via `should_ask`.
- Logging: `LOG_JEV_ORUGA = true`, all other `LOG_JEV_* = false`; live decisions log under `jev-oruga/v1` to `user://logs/jev_oruga.log`; mocked decisions never log.

## Capabilities

### New Capabilities

- `ai-jev-oruga`: NanoJev-backed macro decisions for AI orugas (menu, steering, cadence, logging).

### Modified Capabilities

- `ai-species-behavior`: oruga moves from the inline ladder list to the JEV micro+macro split (same player-parity functions, hunger gating, hide/flee, stillness exemption retained).

## Impact

- Touched systems: `scripts/karma_ai.gd` (delegate), `scripts/karma_jev.gd` (facade flags + delegates + `pick_batch_species_8`), `scripts/main.gd` (oruga due/send/done/flush/clear), new `scripts/karma_ai_oruga.gd` + `scripts/karma_jev_oruga.gd`, new `tests/test_karma_jev_oruga.gd`.
- No player verb changes; no tuning-number changes; no new predator combat logic (bristle reversal explicitly out of scope, candidate for a follow-up change driven by the oruga logs).
- Log output: only `jev_oruga.log` (+ existing `jev_poll.json` census) grows during the observation window.
