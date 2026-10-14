extends GdUnitTestSuite

# Oruga JEV bridge: menu legality (silk/nectar/leafroll gates, prudent+bristle
# player-only), parity, stale hygiene, stillness wander (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh_oruga_state() -> Dictionary:
	return KarmaState.new_run("oruga", 0.0, 0.0, 0, _rng)


func _ai_oruga(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "oruga", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func _only(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func _clear_flora(state: Dictionary) -> void:
	for list in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		state[list] = []


func _hunter_at(state: Dictionary, x: float, y: float, type: String = "zorro") -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": type, "speciesKey": type, "hp": 100.0, "x": x, "y": y})
	(state["agents"] as Array).append(h)
	return h


func _leaves_at(state: Dictionary, x: float, y: float) -> Dictionary:
	var p := KarmaUtils.mk_patch("leaves", x, y, 3)
	(state["clumps"] as Array).append(p)
	return p


func _water_at(state: Dictionary, x: float, y: float) -> Dictionary:
	var w := {"x": x, "y": y, "r": 20.0, "kind": "charco"}
	(state["waters"] as Array).append(w)
	return w


func _refuge_at(state: Dictionary, x: float, y: float) -> Dictionary:
	var r := {"type": "burrow-S", "maxSize": 1, "climbOnly": false, "x": x, "y": y, "dug": false}
	(state["refuges"] as Array).append(r)
	return r


func _calm_fed(state: Dictionary, a: Dictionary) -> void:
	a["caution_food"] = 1.0
	a["caution_water"] = 1.0
	a["hambre"] = 100.0
	a["sed"] = 100.0
	_only(state, a)
	_clear_flora(state)
	state["insects"] = []
	state["waters"] = []
	state["refuges"] = []


func test_menu_always_has_wander() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("wander")).is_true()


func test_menu_eat_on_contact_leaves() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("eat")).is_true()


func test_menu_seek_food_when_hungry() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 90.0
	_leaves_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("seek_food")).is_true()


func test_menu_no_seek_food_when_sated() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("seek_food")).is_false()


func test_menu_drink_when_thirsty() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["sed"] = 50.0
	_water_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("drink")).is_true()


func test_menu_no_drink_when_sated() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_water_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("drink")).is_false()


func test_menu_flee_offered_when_hunted() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_hunter_at(s, 600.0, 500.0, "saponpc")
	_refuge_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("flee")).is_true()


func test_menu_no_flee_when_safe() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_refuge_at(s, 550.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("flee")).is_false()


func test_menu_silk_offered_with_hunter_ready() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("silk")).is_true()


func test_menu_silk_absent_without_hunter() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("silk")).is_false()


func test_menu_silk_absent_on_cooldown() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	(a["verbCds"] as Array)[1] = 8.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("silk")).is_false()


func test_menu_silk_absent_when_broke() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 5.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("silk")).is_false()


func test_menu_nectar_offered_when_affordable() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	a["pa"] = 50.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("nectar")).is_true()


func test_menu_nectar_absent_when_poor() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	a["pa"] = 0.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("nectar")).is_false()


func test_menu_nectar_absent_on_cooldown() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	a["pa"] = 50.0
	(a["verbCds"] as Array)[2] = 8.0
	_hunter_at(s, 600.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("nectar")).is_false()


func test_menu_leafroll_offered_with_clump() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("leafroll")).is_true()


func test_menu_leafroll_absent_without_clump() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("leafroll")).is_false()


func test_menu_leafroll_absent_on_cooldown() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	(a["verbCds"] as Array)[3] = 8.0
	_leaves_at(s, 505.0, 500.0)
	assert_bool(_menu_kinds(KarmaJevOruga.build_menu(s, a)).has("leafroll")).is_false()


func test_menu_never_offers_prudent_or_bristle() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	a["pa"] = 50.0
	_hunter_at(s, 600.0, 500.0)
	_leaves_at(s, 505.0, 500.0)
	var kinds := _menu_kinds(KarmaJevOruga.build_menu(s, a))
	assert_bool(kinds.has("prudent")).is_false()
	assert_bool(kinds.has("bristle")).is_false()


func test_mock_choice_prefers_eat() -> void:
	var menu := [{"kind": "wander"}, {"kind": "nectar"}, {"kind": "seek_food"}, {"kind": "silk"}, {"kind": "leafroll"}, {"kind": "flee"}, {"kind": "drink"}, {"kind": "eat"}]
	assert_int(KarmaJevOruga.mock_choice(menu)).is_equal(7)


func test_candidate_ids_dedups() -> void:
	var menu := [{"kind": "eat"}, {"kind": "eat"}, {"kind": "wander"}]
	var ids := KarmaJevOruga.candidate_ids(menu)
	assert_int(ids.size()).is_equal(2)
	assert_bool(ids.has("eat")).is_true()
	assert_bool(ids.has("wander")).is_true()


func _label_of(menu: Array, kind: String) -> String:
	return str((menu[_menu_kinds(menu).find(kind)] as Dictionary)["label"])


func test_eat_label_plain_when_sated() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 100.0
	_leaves_at(s, 505.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(_label_of(menu, "eat").find("hungry") < 0).is_true()


func test_eat_label_hints_hunger_at_floor() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 10.0
	_leaves_at(s, 505.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(_label_of(menu, "eat").find("hungry") >= 0).is_true()


func test_drink_label_plain_above_floor() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["sed"] = 50.0
	_water_at(s, 550.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(_label_of(menu, "drink").find("thirsty") < 0).is_true()


func test_drink_label_hints_thirst_at_floor() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["sed"] = 10.0
	_water_at(s, 550.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(_label_of(menu, "drink").find("thirsty") >= 0).is_true()


func test_seek_food_label_hints_hunger_at_floor() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 10.0
	_leaves_at(s, 550.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(_label_of(menu, "seek_food").find("hungry") >= 0).is_true()


func test_mock_macro_sets_intent_and_never_logs() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	assert_bool(KarmaJevOruga.mock_macro(s, a)).is_true()
	assert_bool((a.get("jev_intent", {}) as Dictionary).is_empty()).is_false()
	assert_bool(s.has("jev_log_oruga")).is_false()


func test_apply_eat_eats_contact_leaves() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var patch := _leaves_at(s, 505.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var karma0 := float(a.get("karma", 0.0))
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_int(int(patch.get("amount", 0))).is_equal(2)
	assert_bool(float(a.get("karma", 0.0)) > karma0).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("eat")


func test_apply_stale_patch_falls_back_to_wander() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var patch := _leaves_at(s, 505.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	(s["clumps"] as Array).erase(patch)
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": _menu_kinds(menu).find("eat"), "probs": [1.0], "emocion": ""})).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_unaffordable_nectar_burns_nothing() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	a["pa"] = 50.0
	_hunter_at(s, 600.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	var idx := _menu_kinds(menu).find("nectar")
	a["pa"] = 0.0
	var hp0 := float(a.get("hp", 0.0))
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")
	assert_float(float(a.get("hp", 0.0))).is_equal(hp0)
	assert_float(float((a["verbCds"] as Array)[2])).is_equal(0.0)


func test_apply_silk_casts_instantly_then_wanders() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 60.0
	_hunter_at(s, 600.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	var x0 := float(a["x"])
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": _menu_kinds(menu).find("silk"), "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(a["x"]) < x0).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_leafroll_casts_then_wanders() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	var before := (s["refuges"] as Array).size()
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": _menu_kinds(menu).find("leafroll"), "probs": [1.0], "emocion": ""})).is_true()
	assert_int((s["refuges"] as Array).size()).is_equal(before + 1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_unknown_kind_clamps_to_wander() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": 99, "probs": [1.0], "emocion": ""})).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_schema_version_is_jev_oruga_v1() -> void:
	assert_str(str(KarmaJevOruga.oruga_definition()["schema"])).is_equal("jev-oruga/v1")


func test_all_jev_orugas_selects_non_player_orugas_only() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_only(s, a)
	var player := {"speciesKey": "oruga", "brain": "PLAYER", "x": 0.0, "y": 0.0}
	(s["agents"] as Array).append(player)
	var raton := KarmaState.spawn_fauna(s, "raton", 100.0, 100.0)
	var got := KarmaJevOruga.all_jev_orugas(s)
	assert_bool(got.has(a)).is_true()
	assert_bool(got.has(player)).is_false()
	assert_bool(got.has(raton)).is_false()


func test_build_state_snapshot_fields() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var snap: Dictionary = KarmaJevOruga.build_state(s, a)
	assert_str(str(snap.get("species", ""))).is_equal("oruga")
	assert_str(str(snap.get("schema", ""))).is_equal("jev-oruga/v1")
	assert_bool(snap.has("hungry")).is_true()
	assert_bool(snap.has("threatened")).is_true()
	assert_bool(snap.has("food_near")).is_true()
	assert_bool(snap.has("water_near")).is_true()
	assert_bool(snap.has("clump_near")).is_true()
	assert_bool(snap.has("pressure_near")).is_true()


func test_state_text_reports_pressure_and_food() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	assert_bool(KarmaJevOruga.state_text(s, a).contains("pressure=false")).is_true()
	_hunter_at(s, 600.0, 500.0)
	assert_bool(KarmaJevOruga.state_text(s, a).contains("pressure=true")).is_true()


func test_http_body_matches_server_contract() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 90.0
	_leaves_at(s, 550.0, 500.0)
	_water_at(s, 560.0, 500.0)
	var body: Dictionary = KarmaJevOruga.build_http_body(s)
	assert_bool(((body["states"] as Array)).size() >= 1).is_true()
	var first := (body["states"] as Array)[0] as Dictionary
	assert_bool((first as Dictionary).has("id")).is_true()
	assert_bool((first as Dictionary).has("state")).is_true()
	assert_bool(((first["questions"] as Dictionary)["intent"] as Dictionary).has("criteria")).is_true()
	assert_bool((body["menus"] as Dictionary).has("0")).is_true()
	assert_bool((body["agents"] as Array).has(a)).is_true()


func test_http_body_skips_single_candidate_agents() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var body: Dictionary = KarmaJevOruga.build_http_body(s)
	assert_bool((body["states"] as Array).is_empty()).is_true()


func test_step_ladder_eats_contact_leaves() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 40.0
	_leaves_at(s, 505.0, 500.0)
	var hp0 := float(a["hp"])
	KarmaAIOruga.step_ladder(s, a, 0.1)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_step_ladder_seeks_distant_leaves_when_starving() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 10.0
	_leaves_at(s, 550.0, 500.0)
	var x0 := float(a["x"])
	KarmaAIOruga.step_ladder(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_step_ladder_hides_when_hunted() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_hunter_at(s, 600.0, 500.0, "saponpc")
	_refuge_at(s, 520.0, 500.0)
	KarmaAIOruga.step_ladder(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_step_jev_holds_hidden() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hidden"] = true
	a["hideT"] = 5.0
	_hunter_at(s, 600.0, 500.0)
	a["jev_intent"] = {"kind": "seek_food", "x": 2000.0, "y": 500.0, "ttl": 5.0}
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_step_jev_hides_when_hunted() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_hunter_at(s, 600.0, 500.0, "saponpc")
	_refuge_at(s, 520.0, 500.0)
	a["jev_intent"] = {"kind": "seek_food", "x": 2000.0, "y": 500.0, "ttl": 5.0}
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_step_jev_drinks_before_steering() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["sed"] = 0.0
	_water_at(s, 505.0, 500.0)
	a["jev_intent"] = {"kind": "seek_food", "x": 2000.0, "y": 500.0, "ttl": 5.0}
	var sed0 := float(a.get("sed", 0.0))
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_bool(float(a.get("sed", 0.0)) > sed0).is_true()


func test_step_jev_urgent_seek_runs_before_steering() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hambre"] = 10.0
	_leaves_at(s, 550.0, 500.0)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var x0 := float(a["x"])
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_jev_live_without_intent_holds_wander() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["jev_live"] = true
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_step_jev_falls_back_to_mock() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	KarmaAIOruga.step_jev(s, a, 0.1)
	assert_bool((a.get("jev_intent", {}) as Dictionary).is_empty()).is_false()


func test_steer_eat_moves_and_eats_on_contact() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["hp"] = 40.0
	var patch := _leaves_at(s, 650.0, 500.0)
	a["jev_intent"] = {"kind": "eat", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": patch}
	var x0 := float(a["x"])
	assert_bool(KarmaAIOruga.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	(patch as Dictionary)["x"] = 505.0
	(patch as Dictionary)["y"] = 500.0
	(a["jev_intent"] as Dictionary)["x"] = 505.0
	var hp0 := float(a["hp"])
	assert_bool(KarmaAIOruga.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_steer_drink_moves_toward_water() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["jev_intent"] = {"kind": "drink", "x": 650.0, "y": 500.0, "ttl": 5.0}
	var x0 := float(a["x"])
	assert_bool(KarmaAIOruga.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()


func test_steer_flee_moves_toward_refuge() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	var refuge := _refuge_at(s, 650.0, 500.0)
	a["jev_intent"] = {"kind": "flee", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": refuge}
	var x0 := float(a["x"])
	assert_bool(KarmaAIOruga.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()


func test_steer_wander_accumulates_stillness_without_travel() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	a["stillT"] = 0.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	assert_bool(KarmaAIOruga.steer_intent(s, a, 0.1)).is_true()
	assert_bool(float(a.get("stillT", 0.0)) > 0.0).is_true()
	assert_float(float(a["x"])).is_equal(500.0)
	assert_float(float(a["y"])).is_equal(500.0)


func test_facade_oruga_delegates() -> void:
	var s := _fresh_oruga_state()
	var a := _ai_oruga(s, 500.0, 500.0)
	_calm_fed(s, a)
	_leaves_at(s, 505.0, 500.0)
	assert_bool(_menu_kinds(KarmaJev.build_oruga_menu(s, a)).has("eat")).is_true()
	assert_bool(KarmaJev.all_jev_orugas(s).has(a)).is_true()
	assert_str(str(KarmaJev.oruga_definition()["schema"])).is_equal("jev-oruga/v1")
	assert_str(KarmaJev.oruga_state_text(s, a)).is_equal(KarmaJevOruga.state_text(s, a))
	assert_int(KarmaJev.oruga_mock_choice([{"kind": "wander"}, {"kind": "eat"}])).is_equal(1)


func test_pick_batch_8_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_8(true, true, true, true, true, true, true, true, "lobo")).is_equal("oruga")
	assert_str(KarmaJev.pick_batch_species_8(true, true, true, true, true, true, true, true, "oruga")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species_8(false, false, false, false, false, false, false, true, "zorro")).is_equal("oruga")
	assert_str(KarmaJev.pick_batch_species_8(false, false, false, false, false, false, false, false, "zorro")).is_equal("")


func test_pick_batch_8_prefers_longest_waiting() -> void:
	var served := {"zorro": 10.0, "oruga": 5.0}
	assert_str(KarmaJev.pick_batch_species_8(true, false, false, false, false, false, false, true, "zorro", served)).is_equal("oruga")


func test_log_triple_schema_path_and_flag() -> void:
	KarmaJev.LOG_JEV_ORUGA = true
	assert_bool(KarmaJev.log_enabled("oruga")).is_true()
	assert_str(KarmaJev.schema_for("oruga")).is_equal("jev-oruga/v1")
	assert_str(KarmaJev.jev_log_path_for("oruga")).is_equal("user://logs/jev_oruga.log")
	KarmaJev.LOG_JEV_ORUGA = false


func test_enabled_log_records_schema() -> void:
	var s := _fresh_oruga_state()
	KarmaJev.LOG_JEV_ORUGA = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "oruga")
	assert_int(((s.get("jev_log_oruga", []) as Array)).size()).is_equal(1)
	assert_str(str((((s["jev_log_oruga"] as Array)[0] as Dictionary))["schema"])).is_equal("jev-oruga/v1")
	KarmaJev.LOG_JEV_ORUGA = false


func test_other_species_stay_silent() -> void:
	var s := _fresh_oruga_state()
	KarmaJev.LOG_JEV_ZORRO = false
	KarmaJev.LOG_JEV_HALCON = false
	KarmaJev.LOG_JEV_RATON = false
	KarmaJev.LOG_JEV_ARDILLA = false
	KarmaJev.LOG_JEV_SAPO = false
	KarmaJev.LOG_JEV_TOPO = false
	KarmaJev.LOG_JEV_LOBO = false
	KarmaJev.LOG_JEV_ORUGA = true
	for species in ["zorro", "halcon", "raton", "ardilla", "sapo", "topo", "lobo"]:
		KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, species)
		assert_bool(s.has(KarmaJev.log_key_for(species))).is_false()
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "oruga")
	assert_int(((s.get("jev_log_oruga", []) as Array)).size()).is_equal(1)
	KarmaJev.LOG_JEV_ZORRO = false
	KarmaJev.LOG_JEV_HALCON = false
	KarmaJev.LOG_JEV_RATON = false
	KarmaJev.LOG_JEV_ARDILLA = false
	KarmaJev.LOG_JEV_SAPO = false
	KarmaJev.LOG_JEV_TOPO = false
	KarmaJev.LOG_JEV_LOBO = false
	KarmaJev.LOG_JEV_ORUGA = false
