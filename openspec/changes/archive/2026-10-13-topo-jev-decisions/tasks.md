## 1. Bridge (`karma_jev_topo.gd`)

- [x] 1.1 Add failing gdUnit4 tests: menu always has wander; menu holds legal-only candidates (tunneline/worm absent without dug refuge near, aerate absent on cooldown, larder only with storable insect or sharing target, nestdig never present)
- [x] 1.2 Implement `topo_definition`, `build_menu`, `build_state`, `state_text` with generic names and hybrid insect/patch diet (insect-first contact order, same as `ai_grazer_eat`)
- [x] 1.3 Add failing tests: `mock_choice` prefers eat over burrow verbs (eat > drink > flee > alarm > worm > aerate > tunneline > larder > seek_food > wander); `apply_answer` eats on contact, resolves stale/missing food and gone refuges to wander, re-validates larder share targets without mutating state
- [x] 1.4 Implement `mock_choice`, `mock_macro`, `apply_answer` (aerate/tunneline/worm/larder via `cast_verb_for` slots 1-4, alarm via shout path, emocion backfill via `appraise_emocion`)
- [x] 1.5 Add failing tests: `build_http_body_for` matches the server contract (criteria from menu, skips single-candidate agents); `all_jev_topos` selects non-player topos only
- [x] 1.6 Implement `all_jev_topos`, `candidate_ids`, `build_batch`, `build_http_body`, `build_http_body_for`

## 2. Strategy (`karma_ai_topo.gd` + dispatch)

- [x] 2.1 Add failing tests: `step` follows the flag (ladder when off); `step_jev` keeps hide/thirst reflexes ahead of intent steering
- [x] 2.2 Implement `step`, `step_ladder` (current `_ai_topo` behavior, unchanged), `step_jev`
- [x] 2.3 Add failing tests: `steer_intent` moves toward eat/seek/drink/flee targets, eats contact food, POI-travels on wander (never accumulates stillness); `jev_live` without intent falls back to wander instead of mocking
- [x] 2.4 Implement `steer_intent` with the ardilla-pattern POI-travel wander tail
- [x] 2.5 Dispatch `_ai_topo` to the Strategy in `karma_ai.gd`

## 3. Facade + Main wiring

- [x] 3.1 Add `USE_JEV_TOPO`, `LOG_JEV_TOPO`, and topo delegates in `scripts/karma_jev.gd` (log path/schema helpers already generic)
- [x] 3.2 Wire `main.gd`: topo due-list in `_jev_poll`, `_send_topo_batch`, `_on_jev_done` topo branch, flush entry, flight vars + clear, `_jev_flushed` topo key
- [x] 3.3 Extend fair scheduling to six species (least-recently-served rule unchanged, `pick_batch_species_5` → 6-way) with topo `sent` poll counters; add failing test for longest-waiting-wins with topo due

## 4. Verification gate

- [x] 4.1 New `test_karma_jev_topo.gd` green standalone (mocked answers only); no new failures vs the stashed baseline in any other suite
- [x] 4.2 Touched scripts parse with no duplicate `class_name`/`func` collisions
- [x] 4.3 Run `ponytail-review` over the diff; fix or explicitly defer each finding
