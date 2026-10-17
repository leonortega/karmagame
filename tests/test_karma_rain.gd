extends GdUnitTestSuite

# Rain cycle (water-depletion-rain): weather clock, refill, insect burst.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 909


func _fresh(species := "raton") -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func _body(level: float) -> Dictionary:
	return {"kind": "charco", "x": 500.0, "y": 500.0, "r": float(KarmaData.TUNING["charcoR"]),
		"level": level, "cap": float(KarmaData.TUNING["waterCapCharco"])}


func test_fresh_state_is_not_raining() -> void:
	var s := _fresh()
	assert_bool(bool((s["weather"] as Dictionary)["raining"])).is_false()


func test_dry_spell_flip_starts_rain_with_rolled_duration() -> void:
	var s := _fresh()
	s["weather"] = {"raining": false, "t": 0.1}
	KarmaGame.weather_tick(s, 0.2, _rng)
	var w: Dictionary = s["weather"]
	assert_bool(bool(w["raining"])).is_true()
	assert_bool(float(w["t"]) >= float(KarmaData.TUNING["rainWetMin"])).is_true()
	assert_bool(float(w["t"]) <= float(KarmaData.TUNING["rainWetMax"])).is_true()


func test_rain_ends_and_next_dry_spell_begins() -> void:
	var s := _fresh()
	s["weather"] = {"raining": true, "t": 0.1}
	KarmaGame.weather_tick(s, 0.2, _rng)
	var w: Dictionary = s["weather"]
	assert_bool(bool(w["raining"])).is_false()
	assert_bool(float(w["t"]) >= float(KarmaData.TUNING["rainDryMin"])).is_true()
	assert_bool(float(w["t"]) <= float(KarmaData.TUNING["rainDryMax"])).is_true()


func test_rain_refills_capped() -> void:
	var s := _fresh()
	s["waters"] = [_body(0.0)]
	var cap := float(KarmaData.TUNING["waterCapCharco"])
	KarmaGame.rain_refill(s, float(KarmaData.TUNING["rainFillTime"]))
	assert_float(float((s["waters"] as Array)[0]["level"])).is_equal(cap)
	KarmaGame.rain_refill(s, float(KarmaData.TUNING["rainFillTime"]))
	assert_float(float((s["waters"] as Array)[0]["level"])).is_equal(cap)


func test_short_rain_leaves_partial() -> void:
	var s := _fresh()
	s["waters"] = [_body(0.0)]
	KarmaGame.rain_refill(s, float(KarmaData.TUNING["rainFillTime"]) / 2.0)
	assert_float(float((s["waters"] as Array)[0]["level"])).is_equal(
		float(KarmaData.TUNING["waterCapCharco"]) / 2.0)


func test_rain_revives_dry_body() -> void:
	var s := _fresh("raton")
	s["waters"] = [_body(0.0)]
	s["px"] = 500.0
	s["py"] = 500.0
	assert_bool(KarmaEat.try_drink(s)).is_false()
	KarmaGame.rain_refill(s, float(KarmaData.TUNING["rainFillTime"]))
	assert_bool(KarmaEat.try_drink(s)).is_true()


func test_rain_burst_adds_insects_outside_water() -> void:
	var s := _fresh()
	s["insects"] = []
	s["waters"] = [_body(0.0)]
	s["weather"] = {"raining": false, "t": 0.1}
	KarmaGame.weather_tick(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(int(KarmaData.TUNING["rainInsectBurst"]))
	for ins in s["insects"]:
		assert_bool(KarmaUtils.inside_water(s, float(ins["x"]), float(ins["y"]))).is_false()
		if is_failure():
			return


func test_burst_capped_at_insect_max_plus_burst() -> void:
	var s := _fresh()
	s["waters"] = [_body(0.0)]
	s["insects"] = []
	var ceiling := int(KarmaData.TUNING["insectMax"]) + int(KarmaData.TUNING["rainInsectBurst"])
	for i in ceiling - 3:
		(s["insects"] as Array).append({"x": 100.0, "y": 100.0})
	s["weather"] = {"raining": false, "t": 0.1}
	KarmaGame.weather_tick(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(ceiling)


func test_population_does_not_grow_above_cap() -> void:
	var s := _fresh()
	s["waters"] = []
	s["insects"] = []
	for i in 52:
		(s["insects"] as Array).append({"x": 100.0 + float(i), "y": 100.0})
	s["insectT"] = 999.0
	KarmaGame.age_world(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(52)
