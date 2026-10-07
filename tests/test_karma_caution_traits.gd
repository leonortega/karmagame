extends GdUnitTestSuite

# Agent caution traits (agent-caution-traits): per-agent food/water temperament.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 60606


func _fresh() -> Dictionary:
	return KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)


func test_mk_agent_rolls_traits_in_range_when_absent() -> void:
	var a := KarmaState.mk_agent({"role": "fauna", "speciesKey": "raton"})
	assert_bool(a.has("caution_food")).is_true()
	assert_bool(a.has("caution_water")).is_true()
	assert_bool(float(a["caution_food"]) >= 0.0 and float(a["caution_food"]) <= 1.0).is_true()
	assert_bool(float(a["caution_water"]) >= 0.0 and float(a["caution_water"]) <= 1.0).is_true()


func test_mk_agent_keeps_explicit_traits() -> void:
	var a := KarmaState.mk_agent({"role": "fauna", "speciesKey": "raton", "caution_food": 0.2, "caution_water": 0.9})
	assert_float(float(a["caution_food"])).is_equal(0.2)
	assert_float(float(a["caution_water"])).is_equal(0.9)


func test_mk_predator_rolls_traits_in_range() -> void:
	var s := _fresh()
	var p := KarmaPredators.mk_predator(s, "zorro", 500.0, 500.0, 1)
	assert_bool(p.has("caution_food")).is_true()
	assert_bool(p.has("caution_water")).is_true()
	assert_bool(float(p["caution_food"]) >= 0.0 and float(p["caution_food"]) <= 1.0).is_true()
	assert_bool(float(p["caution_water"]) >= 0.0 and float(p["caution_water"]) <= 1.0).is_true()


func test_is_hungry_follows_personal_threshold() -> void:
	assert_bool(KarmaAI.is_hungry({"hambre": 80.0, "caution_food": 1.0})).is_true()
	assert_bool(KarmaAI.is_hungry({"hambre": 80.0, "caution_food": 0.0})).is_false()
	assert_bool(KarmaAI.is_hungry({"hambre": 29.0, "caution_food": 0.0})).is_true()
	assert_bool(KarmaAI.is_hungry({"hambre": 80.0})).is_true()


func _ai_raton(state: Dictionary, x: float, y: float, caution_food: float) -> Dictionary:
	var a := KarmaState.spawn_fauna(state, "raton", x, y)
	a["caution_food"] = caution_food
	a["hambre"] = 80.0
	return a


func _clear_flora(state: Dictionary) -> void:
	for list in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		state[list] = []


func test_forage_treks_when_hungry_by_trait() -> void:
	var s := _fresh()
	_clear_flora(s)
	var a := _ai_raton(s, 500.0, 500.0, 1.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 550.0, 500.0, 3))
	var x0 := float(a["x"])
	assert_bool(KarmaAI.ai_forage(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()


func test_forage_idles_when_satiated_by_trait() -> void:
	var s := _fresh()
	_clear_flora(s)
	var a := _ai_raton(s, 500.0, 500.0, 0.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 550.0, 500.0, 3))
	var x0 := float(a["x"])
	assert_bool(KarmaAI.ai_forage(s, a, 0.1)).is_false()
	assert_float(float(a["x"])).is_equal(x0)


func test_thirst_acts_below_personal_line_when_thirstier() -> void:
	var s := _fresh()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["caution_water"] = 1.0
	a["sed"] = 50.0
	a["hambre"] = 90.0
	(s["waters"] as Array).append({"x": 520.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	assert_bool(KarmaAI.ai_thirst(s, a, 0.1)).is_true()
	assert_bool(float(a["sed"]) > 50.0).is_true()


func test_thirst_ignores_above_personal_line() -> void:
	var s := _fresh()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["caution_water"] = 0.0
	a["sed"] = 50.0
	a["hambre"] = 90.0
	(s["waters"] as Array).append({"x": 520.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	assert_bool(KarmaAI.ai_thirst(s, a, 0.1)).is_false()
	assert_float(float(a["sed"])).is_equal(50.0)


func test_urgent_seek_treks_to_distant_food_at_floor() -> void:
	var s := _fresh()
	_clear_flora(s)
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["caution_food"] = 0.0
	a["hambre"] = 25.0
	a["stillT"] = 5.0
	s["insects"] = []
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 700.0, 500.0, 3))
	var x0 := float(a["x"])
	assert_bool(KarmaAI.ai_urgent_seek(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()
	assert_float(float(a.get("stillT", 5.0))).is_equal(0.0)


func test_urgent_seek_stays_put_above_floor() -> void:
	var s := _fresh()
	_clear_flora(s)
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["caution_food"] = 0.0
	a["hambre"] = 80.0
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 700.0, 500.0, 3))
	var x0 := float(a["x"])
	assert_bool(KarmaAI.ai_urgent_seek(s, a, 0.1)).is_false()
	assert_float(float(a["x"])).is_equal(x0)


func test_urgent_seek_stays_put_with_no_food() -> void:
	var s := _fresh()
	_clear_flora(s)
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["caution_food"] = 1.0
	a["hambre"] = 25.0
	s["insects"] = []
	assert_bool(KarmaAI.ai_urgent_seek(s, a, 0.1)).is_false()


func test_oruga_ladder_treks_constantly_at_floor() -> void:
	var s := _fresh()
	_clear_flora(s)
	s["agents"] = []
	var a := KarmaState.spawn_fauna(s, "oruga", 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	a["hambre"] = 25.0
	a["sed"] = 100.0
	a["stillT"] = 5.0
	(s["clumps"] as Array).append(KarmaUtils.mk_patch("leaves", 700.0, 500.0, 3))
	s["insects"] = []
	var x0 := float(a["x"])
	KarmaAI._ai_oruga(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()
	assert_float(float(a.get("stillT", 5.0))).is_equal(0.0)


func test_sapo_jev_treks_constantly_at_floor() -> void:
	var s := _fresh()
	_clear_flora(s)
	s["agents"] = []
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	a["hambre"] = 25.0
	a["sed"] = 100.0
	a["locoT"] = 0.7
	s["insects"] = [{"x": 700.0, "y": 500.0}]
	var x0 := float(a["x"])
	KarmaAISapo.step_jev(s, a, 0.1)
	assert_bool(float(a["x"]) > x0).is_true()


func test_appraise_floor_is_urgencia_even_when_calm() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": true, "hambre": 25.0}, "wander")).is_equal("Urgencia")


func test_appraise_miedo_wins_over_floor() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "pressure_near": true, "hungry": true, "hambre": 25.0}, "wander")).is_equal("Miedo")


func test_appraise_fed_stays_hambre() -> void:
	assert_str(KarmaJev.appraise_emocion({"threatened": false, "hungry": true, "hambre": 80.0}, "wander")).is_equal("Hambre")


func test_sapo_backfills_urgencia_at_floor() -> void:
	var s := _fresh()
	_clear_flora(s)
	s["agents"] = []
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	a["hambre"] = 25.0
	a["sed"] = 100.0
	s["insects"] = []
	var menu: Array = KarmaJevSapo.build_menu(s, a)
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	var idx := kinds.find("wander")
	assert_bool(idx >= 0).is_true()
	var answer := {"choice": idx, "probs": [1.0], "emocion": ""}
	KarmaJevSapo.apply_answer(s, a, menu, answer)
	assert_str(str(a.get("jev_emocion", ""))).is_equal("Urgencia")
