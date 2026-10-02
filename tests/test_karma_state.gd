extends GdUnitTestSuite

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1234


func test_new_run_seeds_world() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_float(s["hp"]).is_equal(float(KarmaData.SPECIES["raton"]["maxHp"]))
	assert_bool((s["bushes"] as Array).size() > 0).is_true()
	assert_bool((s["agents"] as Array).size() > 0).is_true()
	assert_bool((s["refuges"] as Array).size() > 0).is_true()
	assert_bool((s["waters"] as Array).size() > 0).is_true()


func test_karma_clamps() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	KarmaState.add_karma(s, null, 200.0, "boom")
	assert_float(s["karma"]).is_equal(100.0)
	KarmaState.add_karma(s, null, -300.0, "doom")
	assert_float(s["karma"]).is_equal(-100.0)


func test_eff_adaptations() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_bool(abs(KarmaState.eff_speed(s) - float(KarmaData.SPECIES["raton"]["speed"])) < 0.01).is_true()
	s["owned"]["raton_zarpas"] = true
	assert_bool(abs(KarmaState.eff_speed(s) - float(KarmaData.SPECIES["raton"]["speed"]) * 1.15) < 0.01).is_true()
	assert_float(KarmaState.eff_max_hp(s)).is_equal(float(KarmaData.SPECIES["raton"]["maxHp"]))
	assert_bool(KarmaShop.has_adapt(s, "swift")).is_true()


func test_refuge_fits_and_hide() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	# Place a fitting refuge at the player.
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": s["px"], "y": s["py"], "dug": false})
	assert_bool(KarmaState.toggle_hide(s)).is_true()
	assert_bool(s["hidden"]).is_true()
	assert_bool(KarmaState.toggle_hide(s)).is_true()
	assert_bool(s["hidden"]).is_false()


func test_shout_pays_and_lures() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_bool(KarmaState.try_shout(s)).is_true()
	assert_float(s["karma"]).is_equal(30.0)
	assert_float(s["pa"]).is_equal(50.0)
	assert_float(s["lureTimer"]).is_equal(5.0)


func test_predator_cannot_shout() -> void:
	var s := KarmaState.new_run("zorro", 0.0, 0.0, 0, _rng)
	assert_bool(KarmaState.try_shout(s)).is_false()
	assert_float(s["karma"]).is_equal(0.0)


func test_reincarnate_carries() -> void:
	var s := KarmaState.new_run("raton", 40.0, 30.0, 0, _rng)
	s["dead"] = true
	s["pendingNext"] = "sapo"
	var n := KarmaState.reincarnate(s, _rng)
	assert_str(n["speciesKey"]).is_equal("sapo")
	assert_float(n["karma"]).is_equal(8.0) # 20% of 40
	assert_float(n["pa"]).is_equal(30.0)
