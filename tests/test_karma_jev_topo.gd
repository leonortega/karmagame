extends GdUnitTestSuite

# Topo JEV bridge: menu legality, parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh_topo_state() -> Dictionary:
	return KarmaState.new_run("topo", 0.0, 0.0, 0, _rng)


func _ai_topo(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "topo", x, y)
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
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("wander")).is_true()


func test_menu_tunneline_worm_absent_without_dug_refuge() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	s["refuges"] = []
	var kinds := _menu_kinds(KarmaJevTopo.build_menu(s, a))
	assert_bool(kinds.has("tunneline")).is_false()
	assert_bool(kinds.has("worm")).is_false()


func test_menu_aerate_absent_on_cooldown() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	(a["verbCds"] as Array)[0] = 8.0
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("aerate")).is_false()


func test_menu_larder_needs_insect_or_share_target() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("larder")).is_false()
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("larder")).is_true()
	s["insects"] = []
	a["larder"] = 1
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("larder")).is_true()


func test_menu_never_offers_nestdig() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": 510.0, "y": 500.0, "dug": true})
	assert_bool(_menu_kinds(KarmaJevTopo.build_menu(s, a)).has("nestdig")).is_false()


func test_mock_choice_prefers_eat_over_burrow_verbs() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevTopo.build_menu(s, a)
	var kinds := _menu_kinds(menu)
	assert_bool(kinds.has("eat")).is_true()
	var pick: Dictionary = menu[KarmaJevTopo.mock_choice(menu)]
	assert_str(str(pick["kind"])).is_equal("eat")


func test_apply_eat_eats_insect_on_contact() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevTopo.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": "Hambre"}
	assert_bool(KarmaJevTopo.apply_answer(s, a, menu, answer)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("eat")


func test_apply_stale_food_falls_back_to_wander() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var menu: Array = KarmaJevTopo.build_menu(s, a)
	s["insects"] = []
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevTopo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_unknown_kind_clamps_to_wander() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	var menu: Array = KarmaJevTopo.build_menu(s, a)
	var answer := {"choice": 999, "probs": [1.0], "emocion": ""}
	assert_bool(KarmaJevTopo.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_all_jev_topos_selects_non_player_topos_only() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	var found: Array = KarmaJevTopo.all_jev_topos(s)
	assert_bool(found.has(a)).is_true()
	for o in found:
		assert_str(str((o as Dictionary).get("speciesKey", ""))).is_equal("topo")
		assert_bool(str((o as Dictionary).get("brain", "")) != "PLAYER").is_true()


func test_http_body_matches_server_contract() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var body: Dictionary = KarmaJevTopo.build_http_body(s)
	assert_bool((body["states"] as Array).size() >= 1).is_true()
	var first: Dictionary = (body["states"] as Array)[0]
	assert_bool((first as Dictionary).has("id")).is_true()
	assert_bool((first as Dictionary).has("state")).is_true()
	assert_bool(((first["questions"] as Dictionary)["intent"] as Dictionary).has("criteria")).is_true()
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())


func test_http_body_skips_single_candidate_agents() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	s["waters"] = []
	s["refuges"] = []
	(a["verbCds"] as Array)[0] = 8.0
	var body: Dictionary = KarmaJevTopo.build_http_body_for(s, [a])
	assert_bool((body["agents"] as Array).is_empty()).is_true()


func test_step_ladder_eats_contact_insect() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	var hp0 := float(a["hp"])
	KarmaAITopo.step_ladder(s, a, 0.1)
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_step_jev_hides_before_steering() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	a["hidden"] = true
	a["hideT"] = 5.0
	_hunter_at(s, 600.0, 500.0)
	a["jev_intent"] = {"kind": "seek_food", "x": 2000.0, "y": 500.0, "ttl": 5.0}
	KarmaAITopo.step_jev(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_steer_eat_moves_and_eats_on_contact() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	a["hp"] = 10.0
	var bug := {"x": 650.0, "y": 500.0}
	(s["insects"] as Array).append(bug)
	a["jev_intent"] = {"kind": "eat", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": bug}
	var x0 := float(a["x"])
	assert_bool(KarmaAITopo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	(bug as Dictionary)["x"] = 505.0
	(bug as Dictionary)["y"] = 500.0
	(a["jev_intent"] as Dictionary)["x"] = 505.0
	var hp0 := float(a["hp"])
	assert_bool(KarmaAITopo.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_steer_wander_travels_to_poi_without_stillness() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	s["waters"] = []
	s["refuges"] = []
	a["stillT"] = 0.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	assert_bool(KarmaAITopo.steer_intent(s, a, 0.1)).is_true()
	assert_float(float(a.get("stillT", 0.0))).is_equal(0.0)


func test_jev_live_without_intent_holds_wander() -> void:
	var s := _fresh_topo_state()
	var a := _ai_topo(s, 500.0, 500.0)
	_only(s, a)
	s["insects"] = []
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAITopo.step_jev(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_pick_batch_6_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_6(true, true, true, true, true, true, "sapo")).is_equal("topo")
	assert_str(KarmaJev.pick_batch_species_6(true, true, true, true, true, true, "topo")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species_6(false, false, false, false, false, true, "zorro")).is_equal("topo")
	assert_str(KarmaJev.pick_batch_species_6(false, false, false, false, false, false, "zorro")).is_equal("")
