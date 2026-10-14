## Why

Five species (zorro, halcon, raton, ardilla, sapo) already get NanoJev-ranked macro intents while Godot keeps real-time micro steering; topo AI is still ladder-only, so its burrow verbs (aerate, tunneline, worm, larder) and hybrid insect/carrot foraging fire on fixed reflex order with no ranking. Topo is the last T1 grazer without JEV.

## What Changes

- Each AI topo gets its macro intent from one batched NanoJev `Choice` request covering all AI topos, applying the ranked winner; GDScript builds the per-topo candidate menu from legal moves only and NanoJev only ranks, never invents moves.
- Micro steering every physics tick (tunnel locomotion, contact eat, drink, hide/flee, needs/cooldowns) never waits for answers; mocked brain keeps working with the sidecar down.
- Candidate menu from: eat (insect or edible patch in eat range), seek-food (distant insect/patch when hungry), drink-seek, flee-to-refuge, aerate (slot 1), tunneline (slot 2, dug refuge near), worm (slot 3, dug refuge near + hungry), larder (slot 4), alarm (hunter in lure range, shout ready), and always-present wander. `nestdig` (slot 5) is excluded: it is player-only today (`_verb_nestdig` returns false for agents), so the ranker is never offered a move the AI cannot legally execute. Stale answers resolve to continued steering or wander, never a freeze.
- Wander tail follows the ardilla pattern (POI-travel via `wander_poi`, else jitter), preserving current topo feel — not sapo stillness.
- `emocion` labels stay flavor-only (HUD/feed), never gating execution; live decisions log under schema `jev-topo/v1` to `user://logs/jev_topo.log` only when the topo log flag is on.
- Topo batches join the Main-owned single-flight poll path with fair cross-species scheduling so no species starves another (5-way picker becomes 6-way).

## Capabilities

### New Capabilities

- `ai-jev-topo`: NanoJev-backed macro decisions for AI topos over the same burrower menu a human topo plays, with micro/macro split, 1s staggered + event re-asks, 3s far-camera LOD, and per-species logging.

### Modified Capabilities

- `ai-species-behavior`: the topo agent function splits into micro steering every physics tick plus macro intent from NanoJev ranking (same pattern as the five migrated species), using the same insect/patch-eat, drink, and karma values as the player.
- `ai-jev-cadence`: the single-flight fairness rule (longest-waiting due species wins) and per-species poll counters extend to six species including topo.

## Impact

- New code: `scripts/karma_jev_topo.gd`, `scripts/karma_ai_topo.gd` (extracted from inline `_ai_topo` in `karma_ai.gd`), `tests/test_karma_jev_topo.gd` (mocked answers only, no live HTTP).
- Touched code: `scripts/karma_jev.gd` (USE_JEV_TOPO + LOG_JEV_TOPO + delegates), `scripts/karma_ai.gd` (dispatch to `KarmaAITopo`), `scripts/main.gd` (poll, batch send, answer apply, flush, clear, 6-way picker).
- No tuning numbers change; no verb legality change (`nestdig` stays player-only); no other species' menus, specs, or log flags change.
