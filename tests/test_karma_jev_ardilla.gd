extends GdUnitTestSuite

# Ardilla JEV bridge: menu legality (incl. carry/bury phases), parity, stale hygiene (mocked, no HTTP).

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 31337


func _fresh_ardilla_state() -> Dictionary:
	return KarmaState.new_run("ardilla", 0.0, 0.0, 0, _rng)


func _ai_ardilla(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "ardilla", x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func _clear_flora(state: Dictionary) -> void:
	for list in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		state[list] = []


func test_menu_always_has_wander() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("wander")).is_true()


func test_menu_includes_eat_when_patch_adjacent() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("eat")).is_true()


func test_menu_includes_carry_nut_near_oak() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	(s["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3))
	a["carriedNut"] = false
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("carry_nut")).is_true()
	assert_bool(_menu_kinds(menu).has("bury_nut")).is_false()


func test_menu_includes_bury_nut_when_carrying() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	a["carriedNut"] = true
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	assert_bool(_menu_kinds(menu).has("bury_nut")).is_true()


func test_ardilla_definition_schema() -> void:
	assert_str(str(KarmaJevArdilla.ardilla_definition()["schema"])).is_equal("jev-ardilla/v1")


func test_mock_choice_prefers_eat_over_carry() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	(s["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", 510.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := KarmaJevArdilla.mock_choice(menu)
	assert_str(str((menu[idx] as Dictionary)["kind"])).is_equal("eat")


func test_apply_eat_patch_heals() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	a["hp"] = 10.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	assert_int(idx).is_not_equal(-1)
	var hp0 := float(a["hp"])
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_apply_carry_picks_up_nut() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	var oak := KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3)
	(s["oaks"] as Array).append(oak)
	a["carriedNut"] = false
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("carry_nut")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool(a.get("carriedNut", false))).is_true()
	assert_int(int(oak["amount"])).is_equal(2)


func test_apply_bury_plants_and_pays() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	a["carriedNut"] = true
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("bury_nut")
	assert_int(idx).is_not_equal(-1)
	var k0 := float(a["karma"])
	var saplings0 := int(a.get("saplings", 0))
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool(a.get("carriedNut", true))).is_false()
	assert_int(int(a.get("saplings", 0))).is_equal(saplings0 + 1)
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["plantKarma"]))


func test_apply_stale_oak_falls_back_to_wander() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	var oak := KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3)
	(s["oaks"] as Array).append(oak)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	(s["oaks"] as Array).erase(oak)
	var idx := _menu_kinds(menu).find("carry_nut")
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool(a.get("carriedNut", false))).is_false()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_apply_bark_grants_pa() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	(s["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("bark")
	assert_int(idx).is_not_equal(-1)
	var pa0 := float(a["pa"])
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(a["pa"]) > pa0).is_true()


func test_apply_tailflick_saves_mates() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_near(s, 520.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("tailflick")
	assert_int(idx).is_not_equal(-1)
	var k0 := float(a["karma"])
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["tailflickKarma"]))


func test_apply_falsecache_distracts_hunter() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	var h := _hunter_near(s, 520.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("falsecache")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(h.get("restT", 0.0)) > 0.0).is_true()


func _hunter_near(state: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaPredators.mk_predator(state, "zorro", x, y, 1)
	(state["agents"] as Array).append(h)
	return h


func test_apply_stale_food_falls_back_to_wander() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var answer := {"choice": 0, "probs": [1.0], "emocion": "Hambre", "target_gone": true}
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, answer)).is_true()
	assert_str(str(a.get("jev_intent", {}).get("kind", ""))).is_equal("wander")


func _rich_ardilla(state: Dictionary, x: float, y: float) -> Dictionary:
	var a := _ai_ardilla(state, x, y)
	a["sed"] = 10.0
	(state["bushes"] as Array).append(KarmaUtils.mk_patch("berries", x + 5.0, y, 3))
	(state["waters"] as Array).append({"x": x + 5.0, "y": y, "r": 20.0, "kind": "charco"})
	return a


func test_ardilla_http_body_matches_server_contract() -> void:
	var s := _fresh_ardilla_state()
	_rich_ardilla(s, 500.0, 500.0)
	_rich_ardilla(s, 700.0, 700.0)
	var body: Dictionary = KarmaJevArdilla.build_http_body(s)
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


func test_ardilla_parse_answers_reads_server_shape() -> void:
	var s := _fresh_ardilla_state()
	var a := _rich_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var only: Dictionary = parsed["0"]
	assert_str(str((menu[int(only["choice"])] as Dictionary)["kind"])).is_equal("eat")


func test_ardilla_parse_answers_passes_emocion_through() -> void:
	var s := _fresh_ardilla_state()
	var a := _rich_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat", "emocion": "Miedo"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	assert_str(str((parsed["0"] as Dictionary)["emocion"])).is_equal("Miedo")


func test_log_triple_schema_path_and_flag() -> void:
	assert_str(KarmaJev.schema_for("ardilla")).is_equal("jev-ardilla/v1")
	assert_str(KarmaJev.jev_log_path_for("ardilla")).is_equal("user://logs/jev_ardilla.log")
	assert_bool(KarmaJev.log_enabled("ardilla")).is_true()


func test_log_decision_writes_ardilla_buffer_only() -> void:
	var s := _fresh_ardilla_state()
	KarmaJev.LOG_JEV_ARDILLA = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "ardilla")
	assert_int(((s.get("jev_log_ardilla", []) as Array)).size()).is_equal(1)
	assert_str(str((((s["jev_log_ardilla"] as Array)[0] as Dictionary))["schema"])).is_equal("jev-ardilla/v1")
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log_raton", []) as Array).size()).is_equal(0)
	KarmaJev.LOG_JEV_ARDILLA = true


func test_log_decision_stores_agent_id() -> void:
	var s := _fresh_ardilla_state()
	KarmaJev.LOG_JEV_ARDILLA = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat"}, {"kind": "wander"}], {"choice": 0, "probs": [1.0], "emocion": ""}, true, "ardilla", "ardilla-7")
	assert_str(str((((s["jev_log_ardilla"] as Array)[0] as Dictionary))["agent"])).is_equal("ardilla-7")
	KarmaJev.LOG_JEV_ARDILLA = true


func test_mock_macro_never_logs() -> void:
	var s := _fresh_ardilla_state()
	var a := _rich_ardilla(s, 500.0, 500.0)
	KarmaJevArdilla.mock_macro(s, a)
	assert_int((s.get("jev_log_ardilla", []) as Array).size()).is_equal(0)
	assert_int((s.get("jev_log", []) as Array).size()).is_equal(0)


func _hunter_free(state: Dictionary, keep: Dictionary) -> void:
	state["agents"] = (state["agents"] as Array).filter(func(o): return o == keep)


func test_jev_micro_moves_toward_food_intent() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 650.0, 500.0, 3))
	var c: Dictionary = (s["bushes"] as Array)[(s["bushes"] as Array).size() - 1]
	a["jev_intent"] = {"kind": "seek_food", "x": 650.0, "y": 500.0, "ttl": 5.0, "target": c}
	var x0 := float(a["x"])
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_jev_micro_eat_resolves_locally() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["hp"] = 10.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var c: Dictionary = (s["bushes"] as Array)[(s["bushes"] as Array).size() - 1]
	a["jev_intent"] = {"kind": "eat", "x": 505.0, "y": 500.0, "ttl": 5.0, "target": c}
	var hp0 := float(a["hp"])
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_bool(float(a["hp"]) > hp0).is_true()


func test_jev_live_flag_skips_mock_and_wanders() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_carry_persists_past_intent_expiry() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["carriedNut"] = true
	a["jev_live"] = true
	a["jev_intent"] = {}
	KarmaAI._ai_ardilla(s, a, 0.0)
	assert_bool(bool(a.get("carriedNut", false))).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	assert_bool(kinds.has("bury_nut")).is_true()


func test_hungry_carrier_drops_nut() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["carriedNut"] = true
	a["hambre"] = 50.0
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_bool(bool(a.get("carriedNut", true))).is_false()


func test_wander_fallthrough_keeps_ladder_verbs() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	s["refuges"] = []
	_hunter_near(s, 600.0, 500.0)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var k0 := float(a["karma"])
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_float(float(a["karma"])).is_equal(k0 + float(KarmaData.TUNING["shoutKarma"]) + float(KarmaData.TUNING["falseCacheKarma"]))


func test_pick_batch_4_rotates_when_all_due() -> void:
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "halcon")).is_equal("raton")
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "raton")).is_equal("ardilla")
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "ardilla")).is_equal("zorro")


func test_pick_batch_4_skips_empty_species() -> void:
	assert_str(KarmaJev.pick_batch_species_4(false, false, false, true, "zorro")).is_equal("ardilla")
	assert_str(KarmaJev.pick_batch_species_4(true, false, false, false, "ardilla")).is_equal("zorro")


func test_pick_batch_4_prefers_longest_waiting() -> void:
	var served := {"zorro": 10.0, "halcon": 9.0, "raton": 8.0, "ardilla": 1.0}
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "zorro", served)).is_equal("ardilla")


func test_pick_batch_4_tie_breaks_by_rotation() -> void:
	var served := {"zorro": 5.0, "halcon": 5.0, "raton": 5.0, "ardilla": 5.0}
	assert_str(KarmaJev.pick_batch_species_4(true, true, true, true, "halcon", served)).is_equal("raton")


func test_mark_served_tracks_last_served_time() -> void:
	var s := {"time": 12.5}
	KarmaJev.mark_served(s, "ardilla")
	assert_float(float((s["jev_last_served"] as Dictionary)["ardilla"])).is_equal(12.5)


func test_event_reask_suppressed_inside_backoff_window() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	_hunter_near(s, 520.0, 500.0)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var now := float(s.get("time", 0.0))
	KarmaJev.mark_asked(s, a, 1000.0)
	assert_bool(KarmaJev.should_ask(s, a, now, 1000.0)).is_false()


func test_event_reask_fires_after_backoff_window() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	_hunter_near(s, 520.0, 500.0)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var now := float(s.get("time", 0.0))
	KarmaJev.mark_asked(s, a, 1000.0)
	assert_bool(KarmaJev.should_ask(s, a, now + 1.0, 1000.0)).is_true()


func test_timer_ask_ignores_backoff_window() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 5.0}
	var now := float(s.get("time", 0.0))
	KarmaJev.mark_asked(s, a, 1000.0)
	assert_bool(KarmaJev.should_ask(s, a, now + 4.0, 1000.0)).is_true()


func test_carry_bury_labels_nudge_ranker() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	(s["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3))
	a["carriedNut"] = false
	var labels := {}
	for c in KarmaJevArdilla.build_menu(s, a):
		labels[str((c as Dictionary)["kind"])] = str((c as Dictionary)["label"])
	assert_bool(str(labels.get("carry_nut", "")).contains("(take it!)")).is_true()
	a["carriedNut"] = true
	var labels2 := {}
	for c in KarmaJevArdilla.build_menu(s, a):
		labels2[str((c as Dictionary)["kind"])] = str((c as Dictionary)["label"])
	assert_bool(str(labels2.get("bury_nut", "")).contains("(plant it!)")).is_true()


func test_threat_labels_flag_hunted() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "x": 510.0, "y": 500.0})
	_hunter_near(s, 520.0, 500.0)
	var labels := {}
	for c in KarmaJevArdilla.build_menu(s, a):
		labels[str((c as Dictionary)["kind"])] = str((c as Dictionary)["label"])
	assert_bool(str(labels.get("tailflick", "")).contains("(hunted!)")).is_true()
	assert_bool(str(labels.get("falsecache", "")).contains("(hunted!)")).is_true()
	assert_bool(str(labels.get("flee", "")).contains("(hunted!)")).is_true()


func test_falsecache_ignores_harmless_hunter() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	var h := KarmaPredators.mk_predator(s, "saponpc", 520.0, 500.0, 1)
	(s["agents"] as Array).append(h)
	assert_bool(KarmaAI.is_hunted(s, a)).is_false()
	assert_bool(_menu_kinds(KarmaJevArdilla.build_menu(s, a)).has("falsecache")).is_false()


func test_jev_hides_under_eat_intent_when_hunted() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_hunter_free(s, a)
	_hunter_near(s, 520.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "x": 510.0, "y": 500.0})
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var c: Dictionary = (s["bushes"] as Array)[(s["bushes"] as Array).size() - 1]
	a["jev_intent"] = {"kind": "eat", "x": 505.0, "y": 500.0, "ttl": 5.0, "target": c}
	KarmaAI._ai_ardilla(s, a, 0.1)
	assert_bool(bool(a.get("hidden", false))).is_true()


func test_poll_note_counts_busy_skips() -> void:
	var s := {}
	KarmaJev.poll_note(s, "busy_skip")
	KarmaJev.poll_note(s, "busy_skip")
	assert_int(int((s["jev_poll"] as Dictionary)["busy_skip"])).is_equal(2)


func test_poll_note_counts_sent_per_species() -> void:
	var s := {}
	KarmaJev.poll_note(s, "sent", "ardilla")
	KarmaJev.poll_note(s, "sent", "ardilla")
	KarmaJev.poll_note(s, "error")
	assert_int(int(((s["jev_poll"] as Dictionary)["sent"] as Dictionary)["ardilla"])).is_equal(2)
	assert_int(int((s["jev_poll"] as Dictionary)["error"])).is_equal(1)


func test_poll_note_ignores_unknown_events() -> void:
	var s := {}
	KarmaJev.poll_note(s, "bogus")
	var p := s["jev_poll"] as Dictionary
	assert_int(int(p["busy_skip"])).is_equal(0)
	assert_int(int(p["error"])).is_equal(0)
	assert_bool((p["sent"] as Dictionary).is_empty()).is_true()


func test_log_decision_stores_menu_labels() -> void:
	var s := _fresh_ardilla_state()
	KarmaJev.LOG_JEV_ARDILLA = true
	var menu := [{"kind": "eat", "label": "Eat food"}, {"kind": "wander", "label": "Wander"}]
	var answer := {"choice": 0, "probs": [1.0], "emocion": "", "intent_keys": ["choice", "value"]}
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, menu, answer, true, "ardilla")
	var entry: Dictionary = (s["jev_log_ardilla"] as Array)[0]
	assert_str(",".join(entry["labels"])).is_equal("Eat food,Wander")
	assert_str(",".join(entry["intent_keys"])).is_equal("choice,value")
	KarmaJev.LOG_JEV_ARDILLA = true


func test_parse_answers_records_intent_keys() -> void:
	var s := _fresh_ardilla_state()
	var a := _rich_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var response := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"wander": 0.7, "eat": 0.3}, "choice": "eat", "value": "eat"}}}]}
	var parsed: Dictionary = KarmaJev.parse_answers(response, {"0": menu})
	var keys: Array = (parsed["0"] as Dictionary)["intent_keys"]
	keys.sort()
	assert_str(",".join(keys)).is_equal("choice,probabilities,type,value")


func test_appraise_emocion_table() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": true, "hungry": true, "carriedNut": true}, "eat")).is_equal("Miedo")
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": true, "carriedNut": false}, "eat")).is_equal("Hambre")
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": false, "carriedNut": true}, "wander")).is_equal("Esperanza")
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": false, "carriedNut": false}, "bury_nut")).is_equal("Esperanza")
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": false, "carriedNut": false}, "wander")).is_equal("")


func test_apply_fills_empty_emocion_from_appraisal() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	KarmaJevArdilla.apply_answer(s, a, menu, answer)
	assert_str(str(a.get("jev_emocion", ""))).is_equal("Hambre")
	assert_str(str(answer.get("emocion", ""))).is_equal("Hambre")


func test_apply_keeps_ranker_emocion() -> void:
	var s := _fresh_ardilla_state()
	var a := _ai_ardilla(s, 500.0, 500.0)
	_clear_flora(s)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 505.0, 500.0, 3))
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _menu_kinds(menu).find("eat")
	KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": "Noble"})
	assert_str(str(a.get("jev_emocion", ""))).is_equal("Noble")


func test_parse_answers_marks_emocion_source() -> void:
	var s := _fresh_ardilla_state()
	var a := _rich_ardilla(s, 500.0, 500.0)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var silent := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"eat": 1.0}, "choice": "eat", "value": "eat"}}}]}
	var loud := {"states": [{"id": "0", "answers": {"intent": {"type": "choice",
		"probabilities": {"eat": 1.0}, "choice": "eat", "value": "eat", "emocion": "Miedo"}}}]}
	assert_str(str(KarmaJev.parse_answers(silent, {"0": menu})["0"]["emocion_source"])).is_equal("local")
	assert_str(str(KarmaJev.parse_answers(loud, {"0": menu})["0"]["emocion_source"])).is_equal("ranker")


func test_log_decision_copies_emocion_source() -> void:
	var s := _fresh_ardilla_state()
	KarmaJev.LOG_JEV_ARDILLA = true
	KarmaJev.log_decision(s, {"t": 1.0, "hp_frac": 1.0}, [{"kind": "eat", "label": "Eat food"}],
		{"choice": 0, "probs": [1.0], "emocion": "Hambre", "emocion_source": "local"}, true, "ardilla")
	assert_str(str(((s["jev_log_ardilla"] as Array)[0] as Dictionary)["emocion_source"])).is_equal("local")
	KarmaJev.LOG_JEV_ARDILLA = true
	assert_str(KarmaJev.pick_batch_species_4(false, true, false, false, "zorro")).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species_4(false, false, false, false, "zorro")).is_equal("")
