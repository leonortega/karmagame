## 1. Bridge (`karma_jev_lobo.gd`)

- [x] 1.1 Add `KarmaJevLobo` with schema/question/`USE_JEV` consts, `_set_intent`, `_verb_ready`, `all_jev_lobos`, `candidate_ids` (red: suite references the class; green: minimal stub parses)
- [x] 1.2 Implement `build_menu` legal-only gates (eat, seek-carrion, hunt, drink-seek, strike, regurg, alarm, wander-always; never howl/escort/cull) with menu-gate tests
- [x] 1.3 Implement `build_state` + `state_text` snapshot (hp_frac, hambre, sed, karma, pa, hungry, threatened, prey/carrion/water flags) with snapshot test
- [x] 1.4 Implement `mock_choice` priority order + `mock_macro` + `apply_answer` (instant verbs via `cast_verb_for`, movement verbs set intent, stale/out-of-range answers to wander, emocion appraisal fallback) with apply/parity tests
- [x] 1.5 Implement `build_batch` + `build_http_body_for` (<2-criteria skip) with batch test

## 2. Driver (`karma_ai_lobo.gd` + dispatcher)

- [x] 2.1 Add `KarmaAILobo` with `step` / `step_ladder` (verbatim current `_ai_lobo` behavior) and wire `KarmaAI._ai_lobo` to it; suite stays green, no behavior change
- [x] 2.2 Implement `step_jev` (needs, `ai_base`, `intent_tick`, thirst, urgent-seek, `steer_intent`, `jev_live` wander-hold, `mock_macro` fallback) with micro-never-waits test
- [x] 2.3 Implement `steer_intent` (eat/seek/drink branches, hunt chase with `loboChaseMult` + contact kill, strike/regurg/alarm verb fallthrough, wander-POI tail) with steering tests

## 3. Facade + scheduler (`karma_jev.gd`)

- [x] 3.1 Add `USE_JEV_LOBO`, `LOG_JEV_LOBO` (off), schema/log-path support, and lobo delegate functions; log-isolation test (mock never logs, disabled flag touches no file)
- [x] 3.2 Add `pick_batch_species_7` covering seven species with longest-wait fair-share; fairness + lone-lobo-unaffected tests

## 4. Scene wiring (`main.gd`)

- [x] 4.1 Add lobo due set to `_jev_poll` and route through the 7-species picker with `_send_lobo_batch`
- [x] 4.2 Handle lobo answers in `_on_jev_done` (apply + `log_decision` as `lobo`), include lobo in `_jev_flush_log` species list and `_clear_jev_flight`

## 5. Suite + verification gate

- [x] 5.1 Add `tests/test_karma_jev_lobo.gd` covering each spec scenario (ranked hunt parity, illegal-move-impossible, player-only exclusion, contact-kill-local, latency steering, cadence/LOD/backoff, stale hygiene, emocion flavor, log completeness/isolation)
- [x] 5.2 Run full gdUnit4 suite green, confirm no duplicate `class_name`/func collisions, and run the main scene (F5) with a live lobo to observe ranked intents and steering (NOTE: suite shows 213 cases with the same 5 pre-existing failures as before this change — `test_should_ask_on_fresh_carrion`, ardilla `test_log_triple_schema_path_and_flag`, raton `test_wander_fallthrough_keeps_social_verbs` x2 asserts, `test_edible_for_chain` — all traced to unmodified code/tests or the uncommitted topo-tree flag flip; zero new failures; lobo suite 45/45 green; live scene ran clean with only expected offline-sidecar errors)
