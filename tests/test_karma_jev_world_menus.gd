extends GdUnitTestSuite

# meaningful-world-verbs 6.3: JEV menus offer the reworked verbs legally,
# ranked picks apply through the player functions with wander fallback.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 31337


func _fresh(species: String) -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func _kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


func _agent(s: Dictionary, species: String, x := 500.0, y := 500.0) -> Dictionary:
	var a := KarmaState.spawn_fauna(s, species, x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["karma"] = 0.0
	a["pa"] = 20.0
	a["hp"] = 80.0
	return a


func _mate(s: Dictionary, species: String, x: float, y: float) -> void:
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": species, "hp": 100.0, "hambre": 80.0, "x": x, "y": y}))


func _hunter(s: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": "zorro", "speciesKey": "zorro", "hp": 100.0, "x": x, "y": y})
	(s["agents"] as Array).append(h)
	return h


func test_raton_scout_offered_with_mate_near() -> void:
	var s := _fresh("raton")
	var a := _agent(s, "raton")
	_mate(s, "raton", 510.0, 500.0)
	assert_bool(_kinds(KarmaJevRaton.build_menu(s, a)).has("scout")).is_true()


func test_raton_scout_absent_on_cooldown() -> void:
	var s := _fresh("raton")
	var a := _agent(s, "raton")
	_mate(s, "raton", 510.0, 500.0)
	(a["verbCds"] as Array)[3] = 25.0
	assert_bool(_kinds(KarmaJevRaton.build_menu(s, a)).has("scout")).is_false()


func test_raton_scout_apply_drops_post_then_wanders() -> void:
	var s := _fresh("raton")
	var a := _agent(s, "raton")
	_mate(s, "raton", 510.0, 500.0)
	var menu: Array = KarmaJevRaton.build_menu(s, a)
	var idx := _kinds(menu).find("scout")
	assert_int(idx).is_not_equal(-1)
	var n0 := (s["refuges"] as Array).size()
	assert_bool(KarmaJevRaton.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool((s["refuges"] as Array).size() > n0).is_true()
	assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))).is_equal("wander")


func test_ardilla_groom_offered_with_mate_near() -> void:
	var s := _fresh("ardilla")
	var a := _agent(s, "ardilla")
	_mate(s, "ardilla", 510.0, 500.0)
	assert_bool(_kinds(KarmaJevArdilla.build_menu(s, a)).has("groom")).is_true()


func test_ardilla_groom_apply_cleanses_through_verb() -> void:
	var s := _fresh("ardilla")
	var a := _agent(s, "ardilla")
	var m := KarmaState.mk_agent({"role": "company", "speciesKey": "ardilla", "hp": 40.0, "hambre": 50.0, "x": 510.0, "y": 500.0, "mimicEaten": true})
	(s["agents"] as Array).append(m)
	var menu: Array = KarmaJevArdilla.build_menu(s, a)
	var idx := _kinds(menu).find("groom")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevArdilla.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(bool(m.get("mimicEaten", true))).is_false()


func test_lobo_escort_offered_for_threatened_mate() -> void:
	var s := _fresh("lobo")
	var a := _agent(s, "lobo")
	_mate(s, "lobo", 540.0, 500.0)
	_hunter(s, 550.0, 500.0)
	assert_bool(_kinds(KarmaJevLobo.build_menu(s, a)).has("escort")).is_true()


func test_lobo_escort_absent_without_threat() -> void:
	var s := _fresh("lobo")
	var a := _agent(s, "lobo")
	_mate(s, "lobo", 540.0, 500.0)
	assert_bool(_kinds(KarmaJevLobo.build_menu(s, a)).has("escort")).is_false()


func test_oruga_bristle_offered_with_hunter_close() -> void:
	var s := _fresh("oruga")
	var a := _agent(s, "oruga")
	_hunter(s, 530.0, 500.0)
	assert_bool(_kinds(KarmaJevOruga.build_menu(s, a)).has("bristle")).is_true()


func test_oruga_bristle_apply_stings_through_verb() -> void:
	var s := _fresh("oruga")
	var a := _agent(s, "oruga")
	var h := _hunter(s, 530.0, 500.0)
	var menu: Array = KarmaJevOruga.build_menu(s, a)
	var idx := _kinds(menu).find("bristle")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevOruga.apply_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool(float(h.get("restT", 0.0)) > 0.0).is_true()


func test_halcon_thermal_apply_projects_shadow_through_verb() -> void:
	var s := _fresh("halcon")
	var a := _agent(s, "halcon")
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "fauna", "speciesKey": "raton", "hp": 100.0, "x": 560.0, "y": 500.0}))
	var menu: Array = KarmaJevHalcon.build_halcon_menu(s, a)
	var idx := _kinds(menu).find("thermal")
	assert_int(idx).is_not_equal(-1)
	assert_bool(KarmaJevHalcon.apply_halcon_answer(s, a, menu, {"choice": idx, "probs": [1.0], "emocion": ""})).is_true()
	assert_bool((s["refuges"] as Array).any(func(r): return str(r.get("type", "")) == "shadow-disc")).is_true()
