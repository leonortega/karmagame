extends GdUnitTestSuite

# Zorro JEV bridge: menu legality, parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh_zorro_state() -> Dictionary:
	return KarmaState.new_run("zorro", 0.0, 0.0, 0, _rng)


func _ai_zorro(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "zorro", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["pounceCd"] = 0.0
	a["strikeCd"] = 0.0
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func test_menu_always_has_wander() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("wander")).is_true()


func test_menu_excludes_pounce_on_cooldown() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["pounceCd"] = float(KarmaData.TUNING["pounceCd"])
	(state_agents(s)).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 505.0, "y": 500.0}))
	var menu: Array = KarmaJev.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("pounce")).is_false()
	assert_bool(_menu_kinds(menu).has("wander")).is_true()


func test_menu_includes_cede_cache_dendig_when_sated_and_stocked() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var kinds := _menu_kinds(menu)
	assert_bool(kinds.has("cede")).is_true()
	assert_bool(kinds.has("cache")).is_true()
	assert_bool(kinds.has("dendig")).is_true()


func test_apply_stale_carrion_falls_back_to_wander() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var wander_idx := _menu_kinds(menu).find("wander")
	var answer := {"choice": 0, "probs": [1.0], "emocion": "Hambre", "target_gone": true}
	assert_bool(KarmaJev.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_intent", {}).get("kind", ""))).is_equal("wander")
	assert_int(wander_idx).is_not_equal(-1)


func test_mock_choice_prefers_eat_over_seek() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var idx := KarmaJev.mock_choice(menu)
	assert_str(str((menu[idx] as Dictionary)["kind"])).is_equal("eat")


func test_jev_micro_moves_toward_carrion_intent() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 650.0, 500.0)
	var c: Dictionary = (s["carrions"] as Array)[0]
	a["jev_intent"] = {"kind": "seek_carrion", "x": float(c["x"]), "y": float(c["y"]), "ttl": 5.0, "target": c}
	var x0 := float(a["x"])
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_http_body_matches_server_contract() -> void:
	var s := _fresh_zorro_state()
	_ai_zorro(s, 500.0, 500.0)
	_ai_zorro(s, 700.0, 700.0)
	var body: Dictionary = KarmaJev.build_http_body(s)
	assert_bool(body.has("states")).is_true()
	assert_bool(body.has("menus")).is_true()
	assert_int((body["menus"] as Dictionary).keys().size()).is_equal((body["states"] as Array).size())
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())
	for req in body["states"] as Array:
		var crit: Dictionary = ((req as Dictionary)["questions"] as Dictionary)["intent"]
		assert_bool((crit["criteria"] as Dictionary).size() >= 2).is_true()
	var zorros := (s["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "zorro")
	assert_int((body["states"] as Array).size()).is_equal(zorros.size())
	assert_bool(zorros.size() >= 2).is_true()
	for req in body["states"] as Array:
		var keys: Array = (req as Dictionary).keys()
		keys.sort()
		assert_str(",".join(keys)).is_equal("id,questions,state")
		assert_bool(str((req as Dictionary)["id"]).strip_edges() != "").is_true()
		assert_bool(str((req as Dictionary)["state"]).strip_edges() != "").is_true()
		var questions: Dictionary = (req as Dictionary)["questions"]
		assert_str(str((questions["intent"] as Dictionary)["type"])).is_equal("choice")
		assert_bool(str((questions["intent"] as Dictionary)["instructions"]).strip_edges() != "").is_true()
		var criteria: Dictionary = (questions["intent"] as Dictionary)["criteria"]
		assert_bool(criteria.size() >= 2).is_true()
		assert_bool(criteria.size() <= 255).is_true()


func test_cache_label_hints_fullness_when_full() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hambre"] = 100.0
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	assert_bool(str(menu[_menu_kind_index(menu, "cache")]["label"]).find("full") >= 0).is_true()


func test_cache_label_plain_when_hungry_for_food() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hambre"] = 20.0
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	assert_bool(str(menu[_menu_kind_index(menu, "cache")]["label"]).find("full") < 0).is_true()


func test_candidate_ids_unique_and_nonempty() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var ids := KarmaJev.candidate_ids(KarmaJev.build_menu(s, a))
	var seen := {}
	for cid in ids:
		assert_bool(str(cid).strip_edges() != "").is_true()
		assert_bool(not seen.has(cid)).is_true()
		seen[cid] = true


func test_parse_answers_reads_server_shape() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var only: Dictionary = parsed["0"]
	assert_str(str((menu[int(only["choice"])] as Dictionary)["kind"])).is_equal("eat")


func test_parse_answers_clamps_unknown_kind_to_wander() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 1.0}, "choice": "nope", "value": "nope"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var only: Dictionary = parsed["0"]
	assert_str(str((menu[int(only["choice"])] as Dictionary)["kind"])).is_equal("wander")


func test_log_path_lives_under_user_logs() -> void:
	assert_str(KarmaJev.JEV_LOG_PATH).is_equal("user://logs/jev_zorro.log")


func test_ensure_log_ready_creates_dir_and_file() -> void:
	var tmp := "user://logs/test_tmp_probe.log"
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(tmp)
	assert_bool(KarmaJev.ensure_log_ready(tmp)).is_true()
	assert_bool(FileAccess.file_exists(tmp)).is_true()
	DirAccess.remove_absolute(tmp)


func test_error_format_mentions_code_and_body() -> void:
	var msg := KarmaJev.format_jev_error(400, "{\"error\":\"bad\"}")
	assert_bool(msg.find("400") >= 0).is_true()
	assert_bool(msg.find("bad") >= 0).is_true()


func test_should_ask_respects_stagger_and_events() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	s["time"] = 10.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	a["jev_next"] = 20.0
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()
	assert_bool(KarmaJev.should_ask(s, a, 20.0, 2000.0)).is_true()
	a["jev_intent"] = {}
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_true()


func test_decision_log_caps_and_records() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaJev.LOG_JEV_ZORRO = true
	for i in 5:
		KarmaJev.log_decision(s, {"i": i}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": "Hambre"}, true)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(5)
	assert_str(str(((s["jev_log"] as Array)[0] as Dictionary)["schema"])).is_equal(KarmaJev.SCHEMA_VERSION)
	assert_bool(str(((s["jev_log"] as Array)[0] as Dictionary)["summary"]).find("wander") >= 0).is_true()
	for i in KarmaJev.JEV_LOG_CAP + 5:
		KarmaJev.log_decision(s, {"i": i}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0]}, true)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(KarmaJev.JEV_LOG_CAP)
	KarmaJev.LOG_JEV_ZORRO = false


func test_apply_cede_grants_player_parity_karma() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var idx := _menu_kind_index(menu, "cede")
	var k0 := float(a["karma"])
	assert_bool(KarmaJev.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool((s["carrions"] as Array)[0].get("ceded", false))).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["cedeKarma"]))


func test_apply_cede_doubles_with_reparto() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	a["owned"] = {"cedePlus": true}
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	var k0 := float(a["karma"])
	KarmaJev.apply_answer(s, a, menu, {"choice": _menu_kind_index(menu, "cede"), "probs": [1.0], "emocion": ""})
	assert_float(float(a["karma"])).is_equal(k0 + 2.0 * float(KarmaData.TUNING["cedeKarma"]))


func test_apply_cede_surfaces_emocion_as_flavor() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_menu(s, a)
	KarmaJev.apply_answer(s, a, menu, {"choice": _menu_kind_index(menu, "cede"), "probs": [1.0], "emocion": "Noble"})
	var feed: Array = s["otherFeed"] as Array
	assert_bool(str(feed[feed.size() - 1]).find("[Noble]") >= 0).is_true()


func test_hunt_intent_kills_on_contact() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	var prey := KarmaState.spawn_fauna(s, "raton", 510.0, 500.0)
	var carrion_n := (s["carrions"] as Array).size()
	a["jev_intent"] = {"kind": "hunt", "x": 510.0, "y": 500.0, "ttl": 5.0, "target": prey}
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n + 1)


func test_should_ask_on_threat_with_nonflee_intent() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	(s["agents"] as Array).append(KarmaPredators.mk_predator(s, "lobo", 550.0, 500.0, 2))
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	a["jev_next"] = 9999.0
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_true()
	a["jev_intent"] = {"kind": "flee", "x": 100.0, "y": 100.0, "ttl": 5.0}
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()


func test_lod_interval_near_and_far() -> void:
	var s := _fresh_zorro_state()
	var near := _ai_zorro(s, float(s["px"]) + 10.0, float(s["py"]))
	var far := _ai_zorro(s, float(s["px"]) + 600.0, float(s["py"]))
	assert_float(KarmaJev.lod_interval(s, near, 1000.0)).is_equal(1.0)
	assert_float(KarmaJev.lod_interval(s, far, 1000.0)).is_equal(3.0)


func test_should_ask_on_fresh_carrion() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	s["time"] = 10.0
	KarmaJev.mark_asked(s, a, 2000.0)
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()
	KarmaEat.add_carrion(s, 600.0, 500.0)
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_true()


func test_cached_carrion_pays_pa_on_fresh_eat() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["stash"] = 1
	a["pa"] = 0.0
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var c: Dictionary = (s["carrions"] as Array)[0]
	assert_bool(KarmaEat.eat_carrion(s, c, a)).is_true()
	assert_int(int(a.get("stash", -1))).is_equal(0)
	assert_float(float(a["pa"])).is_equal(float(KarmaData.TUNING["pouncePa"]))


func test_live_flag_skips_mock_and_wanders() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func state_agents(state: Dictionary) -> Array:
	return state["agents"] as Array


func _menu_kind_index(menu: Array, kind: String) -> int:
	for i in menu.size():
		if str((menu[i] as Dictionary)["kind"]) == kind:
			return i
	return -1


func test_schema_for_species() -> void:
	assert_str(KarmaJev.schema_for("zorro")).is_equal("jev-zorro/v1")
	assert_str(KarmaJev.schema_for("halcon")).is_equal("jev-halcon/v1")


func test_log_path_for_species() -> void:
	assert_str(KarmaJev.jev_log_path_for("zorro")).is_equal("user://logs/jev_zorro.log")
	assert_str(KarmaJev.jev_log_path_for("halcon")).is_equal("user://logs/jev_halcon.log")


func test_log_flags_default_on() -> void:
	assert_bool(KarmaJev.log_enabled("zorro")).is_false()
	assert_bool(KarmaJev.log_enabled("halcon")).is_false()
	assert_bool(KarmaJev.log_enabled("raton")).is_false()
	assert_bool(KarmaJev.log_enabled("ardilla")).is_true()


func test_log_decision_writes_per_species_buffer() -> void:
	var s := _fresh_zorro_state()
	KarmaJev.LOG_JEV_HALCON = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "halcon")
	assert_int(((s.get("jev_log_halcon", []) as Array)).size()).is_equal(1)
	assert_str(str((((s["jev_log_halcon"] as Array)[0] as Dictionary))["schema"])).is_equal("jev-halcon/v1")
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	KarmaJev.LOG_JEV_HALCON = false


func test_log_decision_zorro_keeps_legacy_alias() -> void:
	var s := _fresh_zorro_state()
	KarmaJev.LOG_JEV_ZORRO = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "zorro")
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(1)
	assert_int(((s.get("jev_log_zorro", []) as Array)).size()).is_equal(1)
	KarmaJev.LOG_JEV_ZORRO = false


func test_mock_macro_never_logs() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	KarmaJev.mock_macro(s, a)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log_halcon", []) as Array).size()).is_equal(0)


func _fresh_halcon_state() -> Dictionary:
	return KarmaState.new_run("halcon", 0.0, 0.0, 0, _rng)


func _ai_halcon(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "halcon", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["strikeCd"] = 0.0
	a["grounded"] = false
	a["landT"] = 0.0
	return a


func test_halcon_definition_schema() -> void:
	assert_str(str(KarmaJev.halcon_definition()["schema"])).is_equal("jev-halcon/v1")


func test_halcon_menu_always_has_wander() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	assert_bool(_menu_kinds(KarmaJev.build_halcon_menu(s, a)).has("wander")).is_true()


func test_is_hungry_flags_any_deficit() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["hambre"] = 100.0
	assert_bool(KarmaAI.is_hungry(a)).is_false()
	a["hambre"] = 99.9
	assert_bool(KarmaAI.is_hungry(a)).is_true()


func test_halcon_menu_excludes_thermal_without_pa() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["pa"] = 0.0
	assert_bool(_menu_kinds(KarmaJev.build_halcon_menu(s, a)).has("thermal")).is_false()


func test_halcon_menu_includes_thermal_when_affordable() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["pa"] = 100.0
	assert_bool(_menu_kinds(KarmaJev.build_halcon_menu(s, a)).has("thermal")).is_true()


func test_halcon_thermal_label_shows_pa_cost() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["pa"] = 100.0
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var label := str(menu[_menu_kind_index(menu, "thermal")]["label"])
	assert_bool(label.find(str(int(float((KarmaData.VERB_DEFS["halcon"] as Array)[1]["costPa"])))) >= 0).is_true()


func test_halcon_menu_excludes_dive_without_prey() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	assert_bool(_menu_kinds(KarmaJev.build_halcon_menu(s, a)).has("dive")).is_false()


func test_halcon_menu_includes_courtesy_scare_bone_when_ready() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["grounded"] = true
	KarmaEat.add_carrion(s, 505.0, 500.0)
	(state_agents(s)).append(KarmaState.mk_agent({"role": "fauna", "speciesKey": "raton", "hp": 100.0, "x": 520.0, "y": 500.0}))
	var kinds := _menu_kinds(KarmaJev.build_halcon_menu(s, a))
	assert_bool(kinds.has("eat")).is_true()
	assert_bool(kinds.has("courtesy")).is_true()
	assert_bool(kinds.has("scare")).is_true()
	assert_bool(kinds.has("bone")).is_true()


func test_halcon_state_carries_grounded() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["grounded"] = true
	a["landT"] = 0.5
	var snap := KarmaJev.build_halcon_state(s, a)
	assert_str(str(snap["species"])).is_equal("halcon")
	assert_bool(bool(snap["grounded"])).is_true()
	assert_float(float(snap["landT"])).is_equal(0.5)


func _halcon_kind_index(menu: Array, kind: String) -> int:
	for i in menu.size():
		if str((menu[i] as Dictionary)["kind"]) == kind:
			return i
	return -1


func test_halcon_apply_courtesy_grants_player_parity_karma() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["grounded"] = true
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var idx := _halcon_kind_index(menu, "courtesy")
	var k0 := float(a["karma"])
	assert_bool(KarmaJev.apply_halcon_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool((s["carrions"] as Array)[0].get("ceded", false))).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["cedeKarma"]))


func test_halcon_apply_stale_carrion_falls_back_to_wander() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var answer := {"choice": 0, "probs": [1.0], "emocion": "Hambre", "target_gone": true}
	assert_bool(KarmaJev.apply_halcon_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_intent", {}).get("kind", ""))).is_equal("wander")


func test_halcon_apply_thermal_without_pa_logs_not_applied() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["pa"] = 100.0
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var idx := _menu_kind_index(menu, "thermal")
	a["pa"] = 0.0
	assert_bool(KarmaJev.apply_halcon_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_false()
	assert_str(str(a.get("jev_intent", {}).get("kind", ""))).is_equal("wander")


func test_halcon_mock_macro_never_logs() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	KarmaJev.mock_halcon_macro(s, a)
	assert_int((s.get("jev_log_halcon", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)


func test_halcon_http_body_matches_server_contract() -> void:
	var s := _fresh_halcon_state()
	_ai_halcon(s, 500.0, 500.0)
	_ai_halcon(s, 700.0, 700.0)
	var body: Dictionary = KarmaJev.build_halcon_http_body(s)
	assert_bool(body.has("states")).is_true()
	assert_bool(body.has("menus")).is_true()
	assert_int((body["menus"] as Dictionary).keys().size()).is_equal((body["states"] as Array).size())
	assert_int((body["agents"] as Array).size()).is_equal((body["states"] as Array).size())
	var halcons := (s["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "halcon")
	assert_bool(halcons.size() >= 2).is_true()
	for req in body["states"] as Array:
		var keys: Array = (req as Dictionary).keys()
		keys.sort()
		assert_str(",".join(keys)).is_equal("id,questions,state")
		var questions: Dictionary = (req as Dictionary)["questions"]
		assert_str(str((questions["intent"] as Dictionary)["type"])).is_equal("choice")
		assert_bool(((questions["intent"] as Dictionary)["criteria"] as Dictionary).size() >= 2).is_true()


func test_halcon_parse_answers_reads_server_shape() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var only: Dictionary = parsed["0"]
	assert_str(str((menu[int(only["choice"])] as Dictionary)["kind"])).is_equal("eat")


func test_jev_halcon_micro_moves_toward_carrion_intent() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	KarmaEat.add_carrion(s, 650.0, 500.0)
	var c: Dictionary = (s["carrions"] as Array)[0]
	a["jev_intent"] = {"kind": "seek_carrion", "x": float(c["x"]), "y": float(c["y"]), "ttl": 5.0, "target": c}
	var x0 := float(a["x"])
	KarmaAI._ai_halcon(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_jev_halcon_dive_intent_kills_and_grounds_on_contact() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	var prey := KarmaState.spawn_fauna(s, "raton", 510.0, 500.0)
	var carrion_n := (s["carrions"] as Array).size()
	a["jev_intent"] = {"kind": "dive", "x": 510.0, "y": 500.0, "ttl": 5.0, "target": prey}
	KarmaAI._ai_halcon(s, a, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n + 1)
	assert_bool(bool(a.get("grounded", false))).is_true()


func test_jev_halcon_live_flag_skips_mock_and_wanders() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAI._ai_halcon(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_log_isolation_flag_off_drops() -> void:
	var s := _fresh_zorro_state()
	assert_bool(KarmaJev.log_enabled("zorro")).is_false()
	assert_bool(KarmaJev.log_enabled("halcon")).is_false()
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0]}, true, "zorro")
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log_zorro", []) as Array).size()).is_equal(0)
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0]}, true, "halcon")
	assert_int(((s.get("jev_log_halcon", []) as Array)).size()).is_equal(0)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0]}, true, "raton")
	assert_int(((s.get("jev_log_raton", []) as Array)).size()).is_equal(0)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "wander"}], {"choice": 0, "probs": [1.0]}, true, "ardilla")
	assert_int(((s.get("jev_log_ardilla", []) as Array)).size()).is_equal(1)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)


func test_halcon_eat_label_plain_when_sated() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["hambre"] = 100.0
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var label := str(menu[_menu_kind_index(menu, "eat")]["label"])
	assert_bool(label.find("hungry") < 0).is_true()


func test_halcon_eat_label_hints_hunger_when_needy() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	a["hambre"] = 10.0
	KarmaEat.add_carrion(s, 505.0, 500.0)
	var menu: Array = KarmaJev.build_halcon_menu(s, a)
	var label := str(menu[_menu_kind_index(menu, "eat")]["label"])
	assert_bool(label.find("hungry") >= 0).is_true()


func test_hunger_event_fires_once_on_edge() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	s["time"] = 10.0
	KarmaJev.mark_asked(s, a, 2000.0)
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()
	a["hambre"] = 90.0
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_true()
	KarmaJev.mark_asked(s, a, 2000.0)
	assert_bool(KarmaJev.should_ask(s, a, 10.0, 2000.0)).is_false()


func test_pick_batch_species_alternates_when_both_due() -> void:
	assert_str(KarmaJev.pick_batch_species(true, true, "halcon")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species(true, true, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species(true, false, "halcon")).is_equal("zorro")
	assert_str(KarmaJev.pick_batch_species(false, true, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species(false, false, "zorro")).is_equal("")


func _strip_to(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func test_zorro_wander_fallthrough_cedes_when_sated() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	_strip_to(s, a)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	a["hp"] = float(KarmaData.SPECIES["zorro"]["maxHp"])
	a["satedT"] = 5.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var k0 := float(a["karma"])
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_int((s["carrions"] as Array).size()).is_equal(1)
	assert_bool(bool((s["carrions"] as Array)[0].get("ceded", false))).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["cedeKarma"]))


func test_zorro_wander_fallthrough_hunts_opportunistically() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	_strip_to(s, a)
	var prey := KarmaState.spawn_fauna(s, "raton", 510.0, 500.0)
	a["hambre"] = 50.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var carrion_n := (s["carrions"] as Array).size()
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n + 1)


func test_zorro_wander_fallthrough_eats_contact_carrion() -> void:
	var s := _fresh_zorro_state()
	var a := _ai_zorro(s, 500.0, 500.0)
	_strip_to(s, a)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	a["hp"] = 50.0
	a["hambre"] = 100.0
	a["satedT"] = 0.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var hp0 := float(a["hp"])
	KarmaAI._ai_zorro(s, a, 0.1)
	assert_bool(float(a["hp"]) > hp0).is_true()
	assert_int((s["carrions"] as Array).size()).is_equal(0)


func test_halcon_wander_fallthrough_hunts_opportunistically() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	_strip_to(s, a)
	var prey := KarmaState.spawn_fauna(s, "raton", 510.0, 500.0)
	var carrion_n := (s["carrions"] as Array).size()
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	KarmaAI._ai_halcon(s, a, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n + 1)
	assert_bool(bool(a.get("grounded", false))).is_true()


func test_halcon_wander_fallthrough_lands_on_carrion() -> void:
	var s := _fresh_halcon_state()
	var a := _ai_halcon(s, 500.0, 500.0)
	_strip_to(s, a)
	KarmaEat.add_carrion(s, 505.0, 500.0)
	a["grounded"] = false
	a["landT"] = 0.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	KarmaAI._ai_halcon(s, a, 0.1)
	assert_bool(bool(a.get("grounded", false))).is_true()
	assert_float(float(a.get("landT", 0.0))).is_equal(float(KarmaData.TUNING["landTime"]))
	assert_int((s["carrions"] as Array).size()).is_equal(1)
