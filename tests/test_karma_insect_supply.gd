extends GdUnitTestSuite

# Lake insect supply (lake-insect-supply): respawn cadence and global cap.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 777


func _fresh() -> Dictionary:
	return KarmaState.new_run("sapo", 0.0, 0.0, 0, _rng)


func _bug(x: float, y: float) -> Dictionary:
	return {"x": x, "y": y}


func _ring_hits(state: Dictionary, pts: Array, inner: float, outer: float) -> int:
	var n := 0
	for p in pts:
		for w in state["waters"] as Array:
			var d := Vector2(float((p as Dictionary)["x"]), float((p as Dictionary)["y"])).distance_to(Vector2(float(w["x"]), float(w["y"])))
			if d >= inner - 1.0 and d <= outer + 1.0:
				n += 1
				break
	return n


func _spawn_many(state: Dictionary, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var pts: Array = []
	for i in n:
		pts.append(KarmaGame.spawn_insect_pt(state, rng))
	return pts


func test_charco_rims_catch_most_spawns() -> void:
	var s := _fresh()
	s["waters"] = [{"x": 1600.0, "y": 1200.0, "r": 20.0, "kind": "charco"}]
	var pts := _spawn_many(s, 40)
	assert_bool(_ring_hits(s, pts, 28.0, 80.0) >= 5).is_true()


func test_lago_ring_still_catches_spawns() -> void:
	var s := _fresh()
	s["waters"] = [{"x": 1600.0, "y": 1200.0, "r": 95.0, "kind": "lago"}]
	var pts := _spawn_many(s, 40)
	assert_bool(_ring_hits(s, pts, 103.0, 215.0) >= 5).is_true()


func test_spawns_never_land_inside_water() -> void:
	var s := _fresh()
	s["waters"] = [
		{"x": 800.0, "y": 600.0, "r": 95.0, "kind": "lago"},
		{"x": 2000.0, "y": 1800.0, "r": 20.0, "kind": "charco"},
		{"x": 2400.0, "y": 600.0, "r": 20.0, "kind": "charco"},
	]
	var pts := _spawn_many(s, 30)
	for p in pts:
		for w in s["waters"] as Array:
			var d := Vector2(float((p as Dictionary)["x"]), float((p as Dictionary)["y"])).distance_to(Vector2(float(w["x"]), float(w["y"])))
			assert_bool(d >= float(w["r"])).is_true()
			if is_failure():
				return


func test_zone_counts_split_by_rings() -> void:
	var s := _fresh()
	s["waters"] = [
		{"x": 800.0, "y": 600.0, "r": 95.0, "kind": "lago"},
		{"x": 2000.0, "y": 1800.0, "r": 20.0, "kind": "charco"},
	]
	s["insects"] = [
		_bug(2000.0, 1850.0), _bug(2050.0, 1800.0),
		_bug(800.0, 750.0),
		_bug(3000.0, 2200.0),
	]
	var zones: Dictionary = KarmaGame.insect_zone_counts(s)
	assert_int(int(zones["charco"])).is_equal(2)
	assert_int(int(zones["lago"])).is_equal(1)


func test_short_charco_zone_refills_in_ring() -> void:
	var s := _fresh()
	s["waters"] = [{"x": 1600.0, "y": 1200.0, "r": 20.0, "kind": "charco"}]
	s["insects"] = []
	for i in 9:
		(s["insects"] as Array).append(_bug(1600.0 + 30.0 + float(i), 1200.0))
	s["insectT"] = 11.9
	KarmaGame.age_world(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(10)
	var zones: Dictionary = KarmaGame.insect_zone_counts(s)
	assert_int(int(zones["charco"])).is_equal(10)


func test_new_worlds_start_stocked() -> void:
	var s := _fresh()
	var zones: Dictionary = KarmaGame.insect_zone_counts(s)
	assert_bool(int(zones["charco"]) >= 10).is_true()
	assert_bool(int(zones["lago"]) >= 20).is_true()


func test_insects_respawn_one_per_window() -> void:
	var s := _fresh()
	s["insects"] = []
	s["insectT"] = 11.9
	KarmaGame.age_world(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(1)


func test_insects_climb_past_old_cap() -> void:
	var s := _fresh()
	s["insects"] = [_bug(100.0, 100.0), _bug(200.0, 200.0), _bug(300.0, 300.0),
		_bug(400.0, 400.0), _bug(500.0, 500.0), _bug(600.0, 600.0)]
	s["insectT"] = 11.9
	KarmaGame.age_world(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(7)


func test_insects_saturate_at_new_cap() -> void:
	var s := _fresh()
	s["waters"] = [
		{"x": 1600.0, "y": 1200.0, "r": 20.0, "kind": "charco"},
		{"x": 800.0, "y": 600.0, "r": 95.0, "kind": "lago"},
	]
	s["insects"] = []
	for i in 10:
		(s["insects"] as Array).append(_bug(1600.0 + 50.0 + float(i), 1200.0))
	for i in 20:
		(s["insects"] as Array).append(_bug(800.0, 600.0 + 150.0 + float(i)))
	for i in 10:
		(s["insects"] as Array).append(_bug(3000.0, 2200.0))
	s["insectT"] = 999.0
	KarmaGame.age_world(s, 0.2, _rng)
	assert_int((s["insects"] as Array).size()).is_equal(40)
