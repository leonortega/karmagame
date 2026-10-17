extends GdUnitTestSuite

# Finite water (water-depletion-rain): sip costs, depletion, dry gating.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 555


func _fresh(species := "raton") -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func _charco(level := -1.0) -> Dictionary:
	var cap := float(KarmaData.TUNING["waterCapCharco"])
	return {"kind": "charco", "x": 500.0, "y": 500.0, "r": float(KarmaData.TUNING["charcoR"]),
		"level": cap if level < 0.0 else level, "cap": cap}


func _drain(s: Dictionary, for_agent: Variant) -> int:
	var w: Dictionary = (s["waters"] as Array)[0]
	var n := 0
	while float(w["level"]) > 0.0 and n < 10000:
		KarmaEat.drink_water(s, w, for_agent)
		n += 1
	return n


func test_sip_table_covers_every_species() -> void:
	for key in KarmaData.SPECIES:
		assert_bool(KarmaData.water_sip_cost_for(str(key)) > 0.0).is_true()
		if is_failure():
			return


func test_bodies_seed_full_with_proportional_capacity() -> void:
	var s := _fresh()
	var charcos: Array = (s["waters"] as Array).filter(func(w): return str(w["kind"]) == "charco")
	var lagos: Array = (s["waters"] as Array).filter(func(w): return str(w["kind"]) == "lago")
	assert_bool(charcos.size() > 0 and lagos.size() > 0).is_true()
	if is_failure():
		return
	for w in s["waters"]:
		assert_float(float(w["level"])).is_equal(float(w["cap"]))
		assert_bool(float(w["cap"]) > 0.0).is_true()
	var ccap := float((charcos[0] as Dictionary)["cap"])
	var lcap := float((lagos[0] as Dictionary)["cap"])
	assert_bool(lcap > ccap).is_true()
	var ratio := float(KarmaData.TUNING["lagoR"]) / float(KarmaData.TUNING["charcoR"])
	assert_bool(abs(lcap - ccap * ratio * ratio) < 0.01).is_true()


func test_reincarnation_keeps_water_level() -> void:
	var s := _fresh()
	(s["waters"] as Array)[0]["level"] = 7.0
	s["dead"] = true
	s["pendingNext"] = "sapo"
	var n := KarmaState.reincarnate(s, _rng)
	assert_float(float((n["waters"] as Array)[0]["level"])).is_equal(7.0)


func test_drink_lowers_level_by_cost() -> void:
	var s := _fresh("raton")
	s["waters"] = [_charco()]
	assert_bool(KarmaEat.drink_water(s, (s["waters"] as Array)[0], null)).is_true()
	assert_float(float((s["waters"] as Array)[0]["level"])).is_equal(
		float(KarmaData.TUNING["waterCapCharco"]) - KarmaData.water_sip_cost_for("raton"))


func test_costlier_drinker_empties_faster() -> void:
	var cheap := _fresh("oruga")
	cheap["waters"] = [_charco()]
	var dear := _fresh("lobo")
	dear["waters"] = [_charco()]
	var n_cheap := _drain(cheap, null)
	var n_dear := _drain(dear, null)
	assert_int(n_cheap).is_equal(40)
	assert_int(n_dear).is_equal(10)


func test_last_drop_still_heals_then_dry() -> void:
	var s := _fresh("raton")
	s["waters"] = [_charco(0.3)]
	s["sed"] = 10.0
	s["hp"] = 10.0
	assert_bool(KarmaEat.drink_water(s, (s["waters"] as Array)[0], null)).is_true()
	assert_float(s["sed"]).is_equal(45.0)
	assert_float(s["hp"]).is_equal(15.0)
	assert_float(float((s["waters"] as Array)[0]["level"])).is_equal(0.0)


func test_level_never_goes_negative() -> void:
	var s := _fresh("lobo")
	s["waters"] = [_charco(0.3)]
	KarmaEat.drink_water(s, (s["waters"] as Array)[0], null)
	assert_bool(float((s["waters"] as Array)[0]["level"]) >= 0.0).is_true()


func test_nearest_water_skips_dry() -> void:
	var s := _fresh()
	var dry := _charco(0.0)
	var wet := _charco(0.0)
	wet["x"] = 900.0
	wet["level"] = float(KarmaData.TUNING["waterCapCharco"])
	s["waters"] = [dry, wet]
	var hit: Variant = KarmaUtils.nearest_water_for(s, 500.0, 500.0, 1e9)
	assert_bool(hit == wet).is_true()
	wet["level"] = 0.0
	assert_bool(KarmaUtils.nearest_water_for(s, 500.0, 500.0, 1e9) == null).is_true()


func test_player_cannot_drink_dry_only() -> void:
	var s := _fresh("raton")
	s["waters"] = [_charco(0.0)]
	s["sed"] = 10.0
	s["hp"] = 10.0
	assert_bool(KarmaEat.try_drink(s)).is_false()
	assert_float(s["sed"]).is_equal(10.0)
	assert_float(s["hp"]).is_equal(10.0)


func test_ai_seek_water_skips_dry() -> void:
	var s := _fresh()
	var dry := _charco(0.0)
	var wet := _charco(0.0)
	wet["x"] = 900.0
	wet["level"] = float(KarmaData.TUNING["waterCapCharco"])
	s["waters"] = [dry, wet]
	var a := {"speciesKey": "raton", "x": 500.0, "y": 500.0, "sed": 0.0}
	var start := Vector2(float(a["x"]), float(a["y"]))
	assert_bool(KarmaAI.ai_seek_water(s, a, 0.1)).is_true()
	var dist_wet := Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(float(wet["x"]), float(wet["y"])))
	assert_bool(dist_wet < start.distance_to(Vector2(float(wet["x"]), float(wet["y"])))).is_true()
	wet["level"] = 0.0
	assert_bool(KarmaAI.ai_seek_water(s, a, 0.1)).is_false()
