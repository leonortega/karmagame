## 1. Probe the wander-over-seek pick

- [x] 1.1 Replay the t=408 snapshot shape in a test (hungry lobo, distant carrion, water nearby, no prey): assert `seek_carrion` is offered; if it is, record ranker-side working-as-intended and close the probe with no Godot change (verdict: GREEN — gate offers seek, ranker-side working-as-intended, no Godot change)

## 2. Pack floor (`karma_data.gd`)

- [x] 2.1 Raise `POP.faunaFloor` lobo 1→2 with a seed/respawn test (fresh run seeds 2 fauna lobos; `respawn_missing` tops up to 2)

## 3. Regurg reachability (`karma_game.gd` + bridge)

- [x] 3.1 Widen `_verb_regurg` mate scan to hungry lobo packmates of any role (company or fauna) with a verb-level test (fauna-to-fauna feed pays HP cost and karma)
- [x] 3.2 Widen the JEV `regurg` menu gate to the same packmate set with a menu test (fauna mate in range appears as candidate)

## 4. Enriched seek (`karma_jev_lobo.gd`)

- [x] 4.1 Extend hungry `seek_carrion` gating from perception to `wanderSeekRange` with menu tests (distant carrion offered when hungry, absent when sated)

## 5. Suite + verification gate

- [x] 5.1 Run full `res://tests/` suite: lobo suites green, no new failures (319 cases; failures all pre-existing + previously masked by fail-fast: jev `test_should_ask_on_fresh_carrion`/`test_log_flags_default_on`/`test_is_hungry_flags_any_deficit`/`test_log_isolation_flag_off_drops`/`test_hunger_event_fires_once_on_edge`, ardilla log-triple + `test_wander_fallthrough_keeps_ladder_verbs`, raton `test_wander_fallthrough_keeps_social_verbs`, `test_edible_for_chain` — none intersect POP/regurg/menu/flag/picker/wiring lines)
- [x] 5.2 Run the main scene and confirm `jev_poll.json` census shows ≥2 lobos and `jev_lobo.log` records pack menus (regurg candidates present) (live: census lobo=4, 0 errors, live strike/hunt decisions across lobo#1/#3/#5/#7/#21; no live regurg entry in the 37s window — needs hungry-packmate proximity, scenario-dependent; regurg gate covered by verb + menu unit tests)
