extends GdUnitTestSuite

# Sapo JEV bridge: menu legality, parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh_sapo_state() -> Dictionary:
	return KarmaState.new_run("sapo", 0.0, 0.0, 0, _rng)


func _ai_sapo(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "sapo", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func _only(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func _hunter_at(state: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": "zorro", "speciesKey": "zorro", "hp": 100.0, "x": x, "y": y})
	(state["agents"] as Array).append(h)
	return h


func test_menu_always_has_wander() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("wander")).is_true()


func test_menu_toxin_absent_on_cooldown() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 50.0
	(a["verbCds"] as Array)[3] = 8.0
	_hunter_at(s, 530.0, 500.0)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("toxin")).is_false()


func test_menu_chorus_absent_without_choir() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("chorus")).is_false()


func test_menu_pest_needs_insect_in_tongue() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("pest")).is_false()
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("pest")).is_true()


func test_menu_toxin_offered_when_ready() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 50.0
	_hunter_at(s, 530.0, 500.0)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("toxin")).is_true()


func test_mock_choice_prefers_eat_over_pest() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var kinds := _menu_kinds(menu)
	assert_bool(kinds.has("eat")).is_true()
	assert_bool(kinds.has("pest")).is_true()
	var pick: Dictionary = menu[KarmaJevSapo.mock_choice(menu)]
	assert_str(str(pick["kind"])).is_equal("eat")


func test_apply_eat_eats_insect_on_contact() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Hambre"}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("eat")


func test_apply_stale_insect_falls_back_to_wander() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	s["insects"] = []
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_unaffordable_toxin_burns_nothing() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 50.0
	_hunter_at(s, 530.0, 500.0)
	s["insects"] = []
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("toxin")
	a["hp"] = 5.0
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Miedo"}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_false()
	assert_float(float(a["hp"])).is_equal(5.0)
	assert_float(float((a["verbCds"] as Array)[3])).is_equal(0.0)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_pest_casts_instantly_then_wanders() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("pest")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")
	assert_float(float((a["verbCds"] as Array)[1])).is_equal(8.0)


func test_apply_burrowin_hides() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	_hunter_at(s, 600.0, 500.0)
	s["insects"] = []
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("burrowin")).is_true()
	var idx := _menu_kinds(menu).find("burrowin")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Miedo"}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_apply_chorus_pays_with_choir() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "sapo", "hp": 80.0, "x": 510.0, "y": 500.0}))
	s["insects"] = []
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("chorus")).is_true()
	var idx := _menu_kinds(menu).find("chorus")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_float(float(a["karma"])).is_equal(float(KarmaData.TUNING["chorusKarma"]) * 2.0)


func test_all_jev_sapos_selects_non_player_sapos_only() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	var found: Array = KarmaJevSapo.all_jev_sapos(s)
	assert_bool(found.has(a)).is_true()
	for o in found:
		assert_str(str((o as Dictionary).get("speciesKey", ""))).is_equal("sapo")
		assert_bool(str((o as Dictionary).get("brain", "")) != "PLAYER").is_true()


func test_http_body_matches_server_contract() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var body: Dictionary = KarmaJevSapo.build_http_body(s)
	assert_bool((body["states"] as Array).size() >= 1).is_true()
	var first: Dictionary = (body["states"] as Array)[0]
	assert_bool((first as Dictionary).has("id")).is_true()
	assert_bool((first as Dictionary).has("state")).is_true()
	assert_bool(((first["questions"] as Dictionary)["intent"] as Dictionary).has("criteria")).is_true()
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())


func test_http_body_skips_single_candidate_agents() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	s["waters"] = []
	s["refuges"] = []
	var body: Dictionary = KarmaJevSapo.build_http_body_for(s, [a])
	assert_bool((body["agents"] as Array).is_empty()).is_true()


func test_step_ladder_eats_contact_insect() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var hp0 := float(a["hp"])
	KarmaAISapo.step_ladder(s, a, 0.1)
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_step_jev_hides_before_steering() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hidden"] = true
	a["hideT"] = 5.0
	_hunter_at(s, 600.0, 500.0)
	a["jev_intent"] = {"kind": "seek_food", "x": 2000.0, "y": 500.0, "ttl": 5.0}
	KarmaAISapo.step_jev(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_menu_flee_offered_on_pressure() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	_hunter_at(s, 600.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-S", "maxSize": 1, "climbOnly": false, "x": 550.0, "y": 500.0, "dug": false})
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevSapo.build_menu(s, a)).has("flee")).is_true()


func test_state_text_reports_pressure() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(KarmaJevSapo.state_text(s, a).contains("pressure=false")).is_true()
	_hunter_at(s, 600.0, 500.0)
	assert_bool(KarmaJevSapo.state_text(s, a).contains("pressure=true")).is_true()


func test_steer_eat_moves_and_eats_on_contact() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	var bug := {"x": 650.0, "y": 500.0}
	(s["insects"] as Array).append(bug)
	a["jev_intent"] = {"kind": "eat", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": bug}
	a["locoT"] = 0.7 # hop impulse window: envelope 1 for this tick
	var x0 := float(a["x"])
	assert_bool(KarmaAISapo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	(bug as Dictionary)["x"] = 505.0
	(bug as Dictionary)["y"] = 500.0
	(a["jev_intent"] as Dictionary)["x"] = 505.0
	var hp0 := float(a["hp"])
	assert_bool(KarmaAISapo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_steer_wander_accumulates_stillness_without_travel() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	s["waters"] = []
	s["refuges"] = []
	a["stillT"] = 0.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	assert_bool(KarmaAISapo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a.get("stillT", 0.0)) > 0.0).is_true()
	assert_float(float(a["x"])).is_equal(500.0)
	assert_float(float(a["y"])).is_equal(500.0)


func test_jev_live_without_intent_holds_wander() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAISapo.step_jev(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_pick_batch_5_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_5(true, true, true, true, true, "ardilla")).is_equal("sapo")
	assert_str(KarmaJev.pick_batch_species_5(true, true, true, true, true, "sapo")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species_5(false, false, false, false, true, "zorro")).is_equal("sapo")
	assert_str(KarmaJev.pick_batch_species_5(false, false, false, false, false, "zorro")).is_equal("")


func test_appraise_pressure_over_hunger_is_miedo() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": true, "pressure_near": true}, "wander")).is_equal("Miedo")


func test_appraise_calm_hunger_stays_hambre() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": true}, "wander")).is_equal("Hambre")


func test_appraise_empty_snapshot_stays_empty() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": false}, "wander")).is_equal("")


func test_apply_backfills_miedo_under_pressure() -> void:
	var s := _fresh_sapo_state()
	var a := _ai_sapo(s, 500.0, 500.0)
	_only(s, a)
	a["hambre"] = 50.0
	_hunter_at(s, 600.0, 500.0)
	s["insects"] = []
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("wander")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevSapo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_emocion", ""))).is_equal("Miedo")
