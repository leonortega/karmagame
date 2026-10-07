## 1. Bridge (`karma_jev_sapo.gd`)

- [x] 1.1 Add failing gdUnit4 tests: menu always has wander; menu holds legal-only candidates (toxin absent on cooldown, chorus absent without choir, pest only with insect in tongue range)
- [x] 1.2 Implement `sapo_definition`, `build_menu`, `build_state`, `state_text` with generic names and `tonguePlus` reach
- [x] 1.3 Add failing tests: `mock_choice` prefers eat over pest; `apply_answer` eats on contact, resolves stale/missing insects to wander, rejects unaffordable toxin without burning cooldown
- [x] 1.4 Implement `mock_choice`, `mock_macro`, `apply_answer` (pest instant-cast with wander-after, emocion backfill via `appraise_emocion`)
- [x] 1.5 Add failing tests: `build_http_body_for` matches the server contract (criteria from menu, skips single-candidate agents); `all_jev_sapos` selects non-player sapos only
- [x] 1.6 Implement `all_jev_sapos`, `candidate_ids`, `build_batch`, `build_http_body`, `build_http_body_for`

## 2. Strategy (`karma_ai_sapo.gd` + dispatch)

- [x] 2.1 Add failing tests: `step` follows the flag (ladder when off); `step_jev` keeps hide/thirst reflexes ahead of intent steering
- [x] 2.2 Implement `step`, `step_ladder` (current `_ai_sapo` behavior, unchanged), `step_jev`
- [x] 2.3 Add failing tests: `steer_intent` moves toward eat/seek/drink/flee targets, eats insects on contact, and accumulates `stillT` (never POI-travels) on wander; `jev_live` without intent falls back to wander instead of mocking
- [x] 2.4 Implement `steer_intent` with the stillness-preserving wander tail
- [x] 2.5 Dispatch `_ai_sapo` to the Strategy in `karma_ai.gd`

## 3. Facade + Main wiring

- [x] 3.1 Add `USE_JEV_SAPO`, `LOG_JEV_SAPO`, and sapo delegates in `scripts/karma_jev.gd` (log path/schema helpers already generic)
- [x] 3.2 Wire `main.gd`: sapo due-list in `_jev_poll`, `_send_sapo_batch`, `_on_jev_done` sapo branch, flush entry, flight vars + clear, `_jev_flushed` sapo key
- [x] 3.3 Extend fair scheduling to five species (least-recently-served rule unchanged) with sapo `sent` poll counters; add failing test for longest-waiting-wins with sapo due

## 4. Verification gate

- [x] 4.1 New `test_karma_jev_sapo.gd` green standalone (mocked answers only); no new failures vs the stashed baseline in any other suite
- [x] 4.2 Touched scripts parse with no duplicate `class_name`/`func` collisions
- [x] 4.3 Run `ponytail-review` over the diff; fix or explicitly defer each finding
