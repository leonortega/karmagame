## Why

Four species (zorro, halcon, raton, ardilla) already get NanoJev-ranked macro intents while Godot keeps real-time micro steering; sapo AI is still ladder-only, so its threat verbs (toxin, burrow-in, chorus) and tongue hunting fire on fixed reflex order with no ranking. The `sapo-pest-ai` change unblocked this by making every sapo verb legally executable by AI agents.

## What Changes

- Each AI sapo gets its macro intent from one batched NanoJev `Choice` request covering all AI sapos, applying the ranked winner; GDScript builds the per-sapo candidate menu from legal moves only and NanoJev only ranks, never invents moves.
- Micro steering every physics tick (hop locomotion, contact tongue-eat, drink, hide/flee, needs/cooldowns) never waits for answers; mocked brain keeps working with the sidecar down.
- Candidate menu from: eat (insect in tongue range), seek-food (distant insect when hungry), drink-seek, flee-to-refuge, burrow-in, toxin, croak, chorus, pest (instant, now AI-castable), and always-present wander. Stale answers resolve to continued steering or wander, never a freeze.
- `emocion` labels stay flavor-only (HUD/feed), never gating execution; live decisions log under schema `jev-sapo/v1` to `user://logs/jev_sapo.log` only when the sapo log flag is on.
- Sapo batches join the Main-owned single-flight poll path with fair cross-species scheduling so no species starves another.

## Capabilities

### New Capabilities

- `ai-jev-sapo`: NanoJev-backed macro decisions for AI sapos over the same tongue-insectivore menu a human sapo plays, with micro/macro split, 1s staggered + event re-asks, 3s far-camera LOD, and per-species logging.

### Modified Capabilities

- `ai-species-behavior`: the sapo agent function splits into micro steering every physics tick plus macro intent from NanoJev ranking (same pattern as the four migrated species), using the same insect-eat, drink, and karma values as the player.
- `ai-jev-cadence`: the single-flight fairness rule (longest-waiting due species wins) and per-species poll counters extend to five species including sapo.

## Impact

- New code: `scripts/karma_jev_sapo.gd`, `scripts/karma_ai_sapo.gd`, `tests/test_karma_jev_sapo.gd` (mocked answers only, no live HTTP).
- Touched code: `scripts/karma_jev.gd` (flags + delegates), `scripts/karma_ai.gd` (dispatch), `scripts/main.gd` (poll, batch send, answer apply, flush, clear).
- No tuning numbers change; no other species' menus, specs, or log flags change.
