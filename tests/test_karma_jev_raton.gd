extends GdUnitTestSuite

# Raton JEV bridge: menu legality, parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 777


func _fresh_raton_state() -> Dictionary:
	return KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)


func _ai_raton(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "raton", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func test_menu_always_has_wander() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("wander")).is_true()


func test_menu_includes_eat_when_patch_adjacent() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("eat")).is_true()


func test_mock_choice_prefers_eat_over_seek() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := KarmaJevRaton.mock_choice(menu)
	assert_str(str((menu[idx] as Dictionary)["kind"])).is_equal("eat")


func test_apply_stale_food_falls_back_to_wander() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var answer := {"choice": 0, "probs": [1.0], "emocion": "Hambre", "target_gone": true}
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_intent", {}).get("kind", ""))).is_equal("wander")


func test_apply_eat_patch_heals() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	a["hp"] = 10.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	assert_int(idx).is_not_equal(-1)
	var hp0 := float(a["hp"])
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func _rich_raton(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := _ai_raton(state, x, y)
	a["sed"] = 10.0
	(state["bushes"] as Array).append(KarmaUtils.mk_patch("berries", x + 5.0, y, 3))
	(state["waters"] as Array).append({"x": x + 5.0, "y": y, "r": 20.0, "kind": "charco"})
	return a


func test_raton_definition_schema() -> void:
	assert_str(str(KarmaJevRaton.raton_definition()["schema"])).is_equal("jev-raton/v1")


func test_raton_http_body_matches_server_contract() -> void:
	var s := _fresh_raton_state()
	_rich_raton(s, 500.0, 500.0)
	_rich_raton(s, 700.0, 700.0)
	var body: Dictionary = KarmaJevRaton.build_http_body(s)
	assert_bool(body.has("states")).is_true()
	assert_bool(body.has("menus")).is_true()
	assert_int((body["menus"] as Dictionary).keys().size()).is_equal((body["states"] as Array).size())
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())
	assert_bool((body["states"] as Array).size() >= 2).is_true()
	for req in body["states"] as Array:
		var keys: Array = (req as Dictionary).keys()
		keys.sort()
		assert_str(",".join(keys)).is_equal("id,questions,state")
		var questions: Dictionary = (req as Dictionary)["questions"]
		assert_str(str((questions["intent"] as Dictionary)["type"])).is_equal("choice")
		assert_bool(((questions["intent"] as Dictionary)["criteria"] as Dictionary).size() >= 2).is_true()


func test_raton_parse_answers_reads_server_shape() -> void:
	var s := _fresh_raton_state()
	var a := _rich_raton(s, 500.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var only: Dictionary = parsed["0"]
	assert_str(str((menu[int(only["choice"])] as Dictionary)["kind"])).is_equal("eat")


func test_log_triple_schema_path_and_flag() -> void:
	assert_str(KarmaJev.schema_for("raton")).is_equal("jev-raton/v1")
	assert_str(KarmaJev.jev_log_path_for("raton")).is_equal("user://logs/jev_raton.log")
	assert_bool(KarmaJev.log_enabled("raton")).is_false()


func test_log_decision_writes_raton_buffer_only() -> void:
	var s := _fresh_raton_state()
	KarmaJev.LOG_JEV_RATON = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "raton")
	assert_int(((s.get("jev_log_raton", []) as Array)).size()).is_equal(1)
	assert_str(str((((s["jev_log_raton"] as Array)[0] as Dictionary))["schema"])).is_equal("jev-raton/v1")
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log_halcon", []) as Array).size()).is_equal(0)
	KarmaJev.LOG_JEV_RATON = false


func test_mock_macro_never_logs() -> void:
	var s := _fresh_raton_state()
	var a := _rich_raton(s, 500.0, 500.0)
	KarmaJevRaton.mock_macro(s, a)
	assert_int((s.get("jev_log_raton", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)


func test_pick_batch_3_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_3(true, true, true, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species_3(true, true, true, "halcon")).is_equal("raton")
	assert_str(KarmaJev.pick_batch_species_3(true, true, true, "raton")).is_equal("zorro")


func test_pick_batch_3_skips_empty_species() -> void:
	assert_str(KarmaJev.pick_batch_species_3(false, false, true, "zorro")).is_equal("raton")
	assert_str(KarmaJev.pick_batch_species_3(true, false, false, "raton")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species_3(false, true, false, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species_3(false, false, false, "zorro")).is_equal("")


func _hunter_free(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func test_jev_micro_moves_toward_food_intent() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 650.0, 500.0, 3))
	var c: Dictionary = (s["bushes"] as Array)[(s["bushes"] as Array).size() - 1]
	a["jev_intent"] = {"kind": "seek_food", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": c}
	var x0 := float(a["x"])
	KarmaAI._ai_raton(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_jev_micro_eat_resolves_locally() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["hp"] = 10.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var c: Dictionary = (s["bushes"] as Array)[(s["bushes"] as Array).size() - 1]
	a["jev_intent"] = {"kind": "eat", "x": 505.0, "y": 500.0, "ttl": 5.0, "target": c}
	var hp0 := float(a["hp"])
	KarmaAI._ai_raton(s, a, 0.1)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_jev_live_flag_skips_mock_and_wanders() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAI._ai_raton(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_wander_fallthrough_keeps_social_verbs() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 510.0, "y": 500.0}))
	a["hambre"] = 100.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 30.0}
	for i in 40:
		KarmaAI._ai_raton(s, a, 0.1)
	assert_float(float(a["karma"])).is_equal(float(KarmaData.TUNING["groomKarma"]))
	assert_bool(float(a.get("groomCd", 0.0)) > 0.0).is_true()


func _mate_near(state: Dictionary, x: float, y: float) -> void:
	(state["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": x, "y": y}))


func _clear_flora(state: Dictionary) -> void:
	for list in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		state[list] = []


func test_menu_includes_groom_near_mate() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	_mate_near(s, 510.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("groom")).is_true()


func test_menu_excludes_groom_when_alone() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("groom")).is_false()


func test_apply_groom_sets_stay_intent() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	_mate_near(s, 510.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := _menu_kinds(menu).find("groom")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("groom")
	assert_float(float(a.get("karma", 0.0))).is_equal(0.0)


func test_groom_intent_pays_timer_not_instant() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_free(s, a)
	_mate_near(s, 510.0, 500.0)
	a["hambre"] = 100.0
	a["jev_intent"] = {"kind": "groom", "x": 510.0, "y": 500.0, "ttl": 30.0, "target": (s["agents"] as Array)[(s["agents"] as Array).size() - 1]}
	for i in 40:
		KarmaAI._ai_raton(s, a, 0.1)
	assert_float(float(a["karma"])).is_equal(float(KarmaData.TUNING["groomKarma"]))


func _hunter_near(state: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaPredators.mk_predator(state, "zorro", x, y, 1)
	(state["agents"] as Array).append(h)
	return h


func test_menu_includes_alarm_when_hunter_near() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_near(s, 520.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("alarm")).is_true()


func test_menu_excludes_alarm_on_cooldown() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_near(s, 520.0, 500.0)
	a["shoutCd"] = float(KarmaData.TUNING["shoutCooldown"])
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("alarm")).is_false()


func test_apply_alarm_grants_shout_parity() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_hunter_near(s, 520.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := _menu_kinds(menu).find("alarm")
	assert_int(idx).is_not_equal(-1)
	var k0 := float(a["karma"])
	var pa0 := float(a["pa"])
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["shoutKarma"]))
	assert_float(float(a["pa"])).is_equal(pa0 + float(KarmaData.TUNING["shoutPa"]))
	assert_bool(float(a.get("shoutCd", 0.0)) > 0.0).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_alarm_stale_hunter_falls_back_to_wander() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	var h := _hunter_near(s, 520.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	(s["agents"] as Array).erase(h)
	var idx := _menu_kinds(menu).find("alarm")
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_menu_includes_seedcache_by_rich_flora() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_clear_flora(s)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("seedcache")).is_true()


func test_menu_excludes_seedcache_when_flora_poor() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_clear_flora(s)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 1))
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("seedcache")).is_false()


func test_apply_seedcache_grants_verb_parity() -> void:
	var s := _fresh_raton_state()
	var a := _ai_raton(s, 500.0, 500.0)
	_clear_flora(s)
	var patch := KarmaUtils.mk_patch("berries", 505.0, 500.0, 3)
	(s["bushes"] as Array).append(patch)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := _menu_kinds(menu).find("seedcache")
	assert_int(idx).is_not_equal(-1)
	var k0 := float(a["karma"])
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["seedCacheKarma"]))
	assert_int(int(patch["amount"])).is_equal(2)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")
