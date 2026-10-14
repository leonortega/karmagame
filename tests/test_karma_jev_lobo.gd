extends GdUnitTestSuite

# Lobo JEV bridge: menu legality, parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh_lobo_state() -> Dictionary:
	return KarmaState.new_run("lobo", 0.0, 0.0, 0, _rng)


func _ai_lobo(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "lobo", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func _only(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func test_schema_version_is_jev_lobo_v1() -> void:
	assert_str(KarmaJevLobo.SCHEMA_VERSION).is_equal("jev-lobo/v1")


func test_all_jev_lobos_selects_non_player_lobos_only() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	var found: Array = KarmaJevLobo.all_jev_lobos(s)
	assert_bool(found.has(a)).is_true()
	for o in found:
		assert_str(str((o as Dictionary).get("speciesKey", ""))).is_equal("lobo")
		assert_bool(str((o as Dictionary).get("brain", "")) != "PLAYER").is_true()


func test_candidate_ids_dedups() -> void:
	var menu := [{"kind": "eat"}, {"kind": "eat"}, {"kind": "wander"}]
	assert_array(KarmaJevLobo.candidate_ids(menu)).is_equal(["eat", "wander"])


func _hunter_at(state: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": "zorro", "speciesKey": "zorro", "hp": 100.0, "x": x, "y": y})
	(state["agents"] as Array).append(h)
	return h


func _hungry(a: Dictionary) -> void:
	a["caution_food"] = 1.0
	a["hambre"] = 50.0


func test_menu_always_has_wander() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = []
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("wander")).is_true()


func test_menu_eat_carrion_in_range() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	assert_bool(idx >= 0).is_true()
	assert_bool((menu[idx] as Dictionary).has("target")).is_true()


func test_menu_seek_carrion_when_hungry() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	s["carrions"] = [{"x": 700.0, "y": 500.0, "age": 0.0}]
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("seek_carrion")).is_true()


func test_menu_no_seek_carrion_when_sated() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["caution_food"] = 0.0
	a["hambre"] = 50.0
	s["carrions"] = [{"x": 700.0, "y": 500.0, "age": 0.0}]
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("seek_carrion")).is_false()


func test_menu_hunt_visible_prey() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 600.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("hunt")
	assert_bool(idx >= 0).is_true()
	assert_bool((menu[idx] as Dictionary).get("target") == prey).is_true()


func test_menu_drink_when_thirsty() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["waters"] = [{"x": 520.0, "y": 500.0, "r": 20.0}]
	a["caution_water"] = 1.0
	a["sed"] = 50.0
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("drink")).is_true()
	a["sed"] = 100.0
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("drink")).is_false()


func test_menu_strike_gated_on_hunter_and_cooldown() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("strike")).is_false()
	_hunter_at(s, 540.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("strike")).is_true()
	a["strikeCd"] = 3.0
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("strike")).is_false()


func test_menu_regurg_needs_hungry_mate() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 100.0
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("regurg")).is_false()
	var mate := KarmaState.mk_agent({"role": "company", "speciesKey": "lobo", "hp": 100.0, "hambre": 10.0, "x": 515.0, "y": 500.0})
	(s["agents"] as Array).append(mate)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("regurg")).is_true()
	(a["verbCds"] as Array)[1] = 9.0
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("regurg")).is_false()


func test_menu_alarm_needs_hunter_in_lure_range() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("alarm")).is_false()
	_hunter_at(s, 800.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("alarm")).is_true()


func test_menu_never_offers_player_only_verbs() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_hunter_at(s, 540.0, 500.0)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var kinds := _menu_kinds(KarmaJevLobo.build_menu(s, a))
	assert_bool(kinds.has("howl")).is_false()
	assert_bool(kinds.has("escort")).is_false()
	assert_bool(kinds.has("cull")).is_false()


func test_build_state_snapshot_fields() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	a["hp"] = 80.0
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var snap: Dictionary = KarmaJevLobo.build_state(s, a)
	assert_str(str(snap["schema"])).is_equal("jev-lobo/v1")
	assert_str(str(snap["species"])).is_equal("lobo")
	assert_float(float(snap["hp_frac"])).is_equal(0.5)
	assert_bool(bool(snap["hungry"])).is_true()
	assert_bool(bool(snap["carrion_near"])).is_true()
	assert_bool(bool(snap["threatened"])).is_false()


func test_state_text_summarizes_snapshot() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	var text := KarmaJevLobo.state_text(s, a)
	assert_bool(text.begins_with("Lobo ")).is_true()
	assert_bool(text.contains("hambre=")).is_true()


func test_state_text_marks_urgent_at_floor_hunger() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["caution_food"] = 1.0
	a["hambre"] = 20.0
	assert_bool(KarmaJevLobo.state_text(s, a).contains("need=urgent")).is_true()


func test_state_text_marks_hunger_above_floor() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	assert_bool(KarmaJevLobo.state_text(s, a).contains("need=hunger")).is_true()


func test_state_text_marks_thirst_without_hunger() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["caution_food"] = 0.0
	a["hambre"] = 100.0
	a["caution_water"] = 1.0
	a["sed"] = 50.0
	assert_bool(KarmaJevLobo.state_text(s, a).contains("need=thirst")).is_true()


func test_state_text_marks_none_when_sated() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	var text := KarmaJevLobo.state_text(s, a)
	assert_bool(text.contains("need=none")).is_true()
	assert_bool(text.begins_with("Lobo ")).is_true()


func _red_flag_fixture() -> Array:
	var snapshot := {"hungry": true}
	var menu := [{"kind": "eat"}, {"kind": "wander"}]
	return [snapshot, menu]


func test_is_red_flag_on_hungry_eat_declined() -> void:
	var parts: Array = _red_flag_fixture()
	assert_bool(KarmaJevLobo.is_red_flag(parts[0], parts[1], {"choice": 1})).is_true()


func test_is_red_flag_off_when_sated() -> void:
	var parts: Array = _red_flag_fixture()
	(parts[0] as Dictionary)["hungry"] = false
	assert_bool(KarmaJevLobo.is_red_flag(parts[0], parts[1], {"choice": 1})).is_false()


func test_is_red_flag_off_without_eat_candidate() -> void:
	var parts: Array = _red_flag_fixture()
	assert_bool(KarmaJevLobo.is_red_flag(parts[0], [{"kind": "wander"}], {"choice": 0})).is_false()


func test_is_red_flag_off_when_eat_chosen() -> void:
	var parts: Array = _red_flag_fixture()
	assert_bool(KarmaJevLobo.is_red_flag(parts[0], parts[1], {"choice": 0})).is_false()


func _red_flag_log_call(state: Dictionary, hungry: bool, kinds: Array, choice: int) -> void:
	var menu: Array = []
	for kind in kinds:
		menu.append({"kind": str(kind)})
	KarmaJev.log_decision(state, {"t": 1.0, "hp_frac": 1.0, "hungry": hungry}, menu, {"choice": choice, "probs": [1.0], "emocion": ""}, true, "lobo")


func _red_flag_count(state: Dictionary) -> int:
	return int((state.get("jev_red_flags", {}) as Dictionary).get("lobo", 0))


func test_red_flag_match_bumps_counter() -> void:
	var s := _fresh_lobo_state()
	KarmaJev.LOG_JEV_LOBO = true
	_red_flag_log_call(s, true, ["eat", "wander"], 1)
	assert_int(_red_flag_count(s)).is_equal(1)
	_red_flag_log_call(s, true, ["eat", "wander"], 1)
	assert_int(_red_flag_count(s)).is_equal(2)
	KarmaJev.LOG_JEV_LOBO = true


func test_red_flag_non_match_leaves_counter() -> void:
	var s := _fresh_lobo_state()
	KarmaJev.LOG_JEV_LOBO = true
	_red_flag_log_call(s, false, ["eat", "wander"], 1)
	_red_flag_log_call(s, true, ["wander"], 0)
	_red_flag_log_call(s, true, ["eat", "wander"], 0)
	assert_int(_red_flag_count(s)).is_equal(0)
	KarmaJev.LOG_JEV_LOBO = true


func test_red_flag_disabled_counts_nothing() -> void:
	var s := _fresh_lobo_state()
	KarmaJev.LOG_JEV_LOBO = false
	_red_flag_log_call(s, true, ["eat", "wander"], 1)
	assert_bool(s.has("jev_red_flags")).is_false()
	KarmaJev.LOG_JEV_LOBO = true


func test_red_flag_mock_path_counts_nothing() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	KarmaJev.LOG_JEV_LOBO = true
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	assert_bool(KarmaJevLobo.mock_macro(s, a)).is_true()
	assert_bool(s.has("jev_red_flags")).is_false()
	KarmaJev.LOG_JEV_LOBO = true


func test_mock_choice_prefers_eat() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var pick: Dictionary = menu[KarmaJevLobo.mock_choice(menu)]
	assert_str(str(pick["kind"])).is_equal("eat")


func test_mock_macro_sets_intent() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	assert_bool(KarmaJevLobo.mock_macro(s, a)).is_true()
	assert_bool((a.get("jev_intent", {}) as Dictionary).has("kind")).is_true()


func test_apply_eat_carrion_on_contact() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Hambre"}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_int((s["carrions"] as Array).size()).is_equal(0)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("eat")


func test_apply_hunt_sets_pursuit_intent() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 600.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("hunt")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Hambre"}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("hunt")
	assert_bool((s["agents"] as Array).has(prey)).is_true()


func test_apply_strike_executes_verb() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hunter_at(s, 540.0, 500.0)
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("strike")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Miedo"}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_bool(float(a.get("strikeCd", 0.0)) > 0.0).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_regurg_feeds_mate() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 100.0
	var mate := KarmaState.mk_agent({"role": "company", "speciesKey": "lobo", "hp": 100.0, "hambre": 10.0, "x": 515.0, "y": 500.0})
	(s["agents"] as Array).append(mate)
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("regurg")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_float(float(mate.get("hambre", 0.0))).is_equal(18.0)
	assert_float(float(a.get("hp", 0.0))).is_equal(92.0)


func test_apply_stale_carrion_falls_back_to_wander() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	s["carrions"] = []
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_unknown_kind_clamps_to_wander() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = []
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var answer := {"choice": 999, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_empty_emocion_appraised_locally() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_emocion", ""))).is_equal("Hambre")


func test_http_body_matches_server_contract() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var body: Dictionary = KarmaJevLobo.build_http_body(s)
	assert_bool((body["states"] as Array).size() >= 1).is_true()
	var first: Dictionary = (body["states"] as Array)[0]
	assert_bool((first as Dictionary).has("id")).is_true()
	assert_bool((first as Dictionary).has("state")).is_true()
	assert_bool(((first["questions"] as Dictionary)["intent"] as Dictionary).has("criteria")).is_true()
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())


func test_http_body_skips_single_candidate_agents() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = []
	s["waters"] = []
	s["refuges"] = []
	var body: Dictionary = KarmaJevLobo.build_http_body_for(s, [a])
	assert_bool((body["agents"] as Array).is_empty()).is_true()


func test_http_body_states_carry_need_token() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var body: Dictionary = KarmaJevLobo.build_http_body(s)
	assert_bool((body["states"] as Array).size() >= 1).is_true()
	for st in body["states"]:
		assert_bool(str((st as Dictionary)["state"]).contains("need=hunger")).is_true()


func _sated(a: Dictionary) -> void:
	a["caution_food"] = 0.0
	a["hambre"] = 50.0
	a["caution_water"] = 0.0
	a["sed"] = 100.0


func test_step_ladder_eats_contact_carrion() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	a["hp"] = 10.0
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var hp0 := float(a["hp"])
	KarmaAILobo.step_ladder(s, a, 0.1)
	assert_int((s["carrions"] as Array).size()).is_equal(0)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_step_ladder_hunts_prey_on_contact() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 515.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	var carrion0 := (s["carrions"] as Array).size()
	KarmaAILobo.step_ladder(s, a, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion0 + 1)


func test_step_ladder_strikes_adjacent_hunter() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	_hunter_at(s, 540.0, 500.0)
	KarmaAILobo.step_ladder(s, a, 0.1)
	assert_bool(float(a.get("strikeCd", 0.0)) > 0.0).is_true()


func test_jev_live_without_intent_holds_wander() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = []
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAILobo.step_jev(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_step_jev_steers_while_answer_pending() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	s["carrions"] = [{"x": 700.0, "y": 500.0, "age": 0.0}]
	a["jev_live"] = true
	a["jev_intent"] = {"kind": "seek_carrion", "x": 700.0, "y": 500.0, "ttl": 5.0, "target": (s["carrions"] as Array)[0]}
	var x0 := float(a["x"])
	KarmaAILobo.step_jev(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_step_jev_falls_back_to_mock() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	a["jev_live"] = false
	a["jev_intent"] = {}
	KarmaAILobo.step_jev(s, a, 0.1)
	assert_bool((a.get("jev_intent", {}) as Dictionary).has("kind")).is_true()


func test_steer_hunt_chases_prey() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 650.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	a["jev_intent"] = {"kind": "hunt", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": prey}
	var x0 := float(a["x"])
	assert_bool(KarmaAILobo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	assert_bool((s["agents"] as Array).has(prey)).is_true()


func test_steer_hunt_kills_on_contact() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 510.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	a["jev_intent"] = {"kind": "hunt", "x": 510.0, "y": 500.0, "ttl": 5.0, "target": prey}
	var carrion0 := (s["carrions"] as Array).size()
	assert_bool(KarmaAILobo.steer_intent(s, a, 0.1)).is_true()
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion0 + 1)


func test_steer_eat_moves_and_eats_on_contact() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	var meal := {"x": 650.0, "y": 500.0, "age": 0.0}
	(s["carrions"] as Array).append(meal)
	a["jev_intent"] = {"kind": "eat", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": meal}
	var x0 := float(a["x"])
	assert_bool(KarmaAILobo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	(meal as Dictionary)["x"] = 505.0
	(a["jev_intent"] as Dictionary)["x"] = 505.0
	var hp0 := float(a["hp"])
	assert_bool(KarmaAILobo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_steer_wander_falls_through_to_hunt() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_sated(a)
	var prey := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "hp": 100.0, "x": 650.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var x0 := float(a["x"])
	assert_bool(KarmaAILobo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()


func test_facade_lobo_delegates() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	assert_bool(KarmaJev.build_lobo_menu(s, a).size() >= 2).is_true()
	assert_bool(KarmaJev.all_jev_lobos(s).has(a)).is_true()
	assert_str(str(KarmaJev.lobo_definition()["schema"])).is_equal("jev-lobo/v1")


func test_log_triple_schema_path_and_flag() -> void:
	assert_bool(KarmaJev.log_enabled("lobo")).is_true()
	assert_str(KarmaJev.schema_for("lobo")).is_equal("jev-lobo/v1")
	assert_str(KarmaJev.jev_log_path_for("lobo")).is_equal("user://logs/jev_lobo.log")


func test_disabled_log_buffers_nothing() -> void:
	var s := _fresh_lobo_state()
	KarmaJev.LOG_JEV_LOBO = false
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "lobo")
	assert_bool(s.has("jev_log_lobo")).is_false()


func test_enabled_log_records_schema() -> void:
	var s := _fresh_lobo_state()
	KarmaJev.LOG_JEV_LOBO = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "lobo")
	assert_int(((s.get("jev_log_lobo", []) as Array)).size()).is_equal(1)
	assert_str(str((((s["jev_log_lobo"] as Array)[0] as Dictionary))["schema"])).is_equal("jev-lobo/v1")
	KarmaJev.LOG_JEV_LOBO = false


func test_pick_batch_7_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_7(true, true, true, true, true, true, true, "topo")).is_equal("lobo")
	assert_str(KarmaJev.pick_batch_species_7(true, true, true, true, true, true, true, "lobo")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species_7(false, false, false, false, false, false, true, "zorro")).is_equal("lobo")
	assert_str(KarmaJev.pick_batch_species_7(false, false, false, false, false, false, false, "zorro")).is_equal("")


func test_pick_batch_7_prefers_longest_waiting() -> void:
	var served := {"zorro": 10.0, "lobo": 5.0}
	assert_str(KarmaJev.pick_batch_species_7(true, false, false, false, false, false, true, "zorro", served)).is_equal("lobo")


func test_apply_target_gone_falls_back_to_wander() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var answer := {"choice": 0, "probs": [1.0], "emocion": "", "target_gone": true}
	assert_bool(KarmaJevLobo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_mock_macro_never_logs() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	KarmaJev.LOG_JEV_LOBO = true
	s["carrions"] = [{"x": 520.0, "y": 500.0, "age": 0.0}]
	assert_bool(KarmaJevLobo.mock_macro(s, a)).is_true()
	assert_bool(s.has("jev_log_lobo")).is_false()
	KarmaJev.LOG_JEV_LOBO = false


func test_lobo_should_ask_respects_stagger() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	s["time"] = 10.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	KarmaJev.mark_asked(s, a, 2000.0)
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()


func test_probe_t408_hungry_seek_offered_despite_water() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	a["caution_water"] = 1.0
	a["sed"] = 60.0
	s["waters"] = [{"x": 520.0, "y": 500.0, "r": 20.0}]
	s["carrions"] = [{"x": 700.0, "y": 500.0, "age": 0.0}]
	var kinds := _menu_kinds(KarmaJevLobo.build_menu(s, a))
	assert_bool(kinds.has("seek_carrion")).is_true()


func _fauna_lobos(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(o): return str(o.get("speciesKey", "")) == "lobo" and str(o.get("role", "")) == "fauna")


func test_pack_floor_lobo_is_two() -> void:
	assert_int(int((KarmaData.POP["faunaFloor"] as Dictionary)["lobo"])).is_equal(2)


func test_fresh_run_seeds_two_fauna_lobos() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_int(_fauna_lobos(s).size()).is_equal(2)


func test_respawn_tops_up_lobos_to_two() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	for o in _fauna_lobos(s):
		(s["agents"] as Array).erase(o)
	KarmaState.respawn_missing(s, _rng)
	assert_int(_fauna_lobos(s).size()).is_equal(1)
	KarmaState.respawn_missing(s, _rng)
	assert_int(_fauna_lobos(s).size()).is_equal(2)
	KarmaState.respawn_missing(s, _rng)
	assert_int(_fauna_lobos(s).size()).is_equal(2)


func test_regurg_feeds_hungry_fauna_packmate() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 100.0
	var mate := KarmaState.spawn_fauna(s, "lobo", 515.0, 500.0)
	mate["hambre"] = 10.0
	var karma0 := float(a.get("karma", 0.0))
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_float(float(mate.get("hambre", 0.0))).is_equal(18.0)
	assert_float(float(a.get("hp", 0.0))).is_equal(92.0)
	assert_bool(float(a.get("karma", 0.0)) > karma0).is_true()


func test_regurg_never_feeds_self() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 100.0
	a["hambre"] = 10.0
	a["caution_food"] = 1.0
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_false()
	assert_float(float(a.get("hp", 0.0))).is_equal(100.0)


func test_menu_regurg_offers_fauna_packmate() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 100.0
	var mate := KarmaState.spawn_fauna(s, "lobo", 515.0, 500.0)
	mate["hambre"] = 10.0
	var menu: Array = KarmaJevLobo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("regurg")
	assert_bool(idx >= 0).is_true()
	assert_bool((menu[idx] as Dictionary).get("target") == mate).is_true()


func test_menu_seek_reaches_wander_range_when_hungry() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	_hungry(a)
	s["carrions"] = [{"x": 900.0, "y": 500.0, "age": 0.0}]
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("seek_carrion")).is_true()


func test_menu_no_distant_seek_when_sated() -> void:
	var s := _fresh_lobo_state()
	var a := _ai_lobo(s, 500.0, 500.0)
	_only(s, a)
	a["caution_food"] = 0.0
	a["hambre"] = 50.0
	s["carrions"] = [{"x": 900.0, "y": 500.0, "age": 0.0}]
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(s, a)).has("seek_carrion")).is_false()
