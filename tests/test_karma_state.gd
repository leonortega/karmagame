extends GdUnitTestSuite

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1234


func test_new_run_seeds_world() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_float(KarmaState.player(s)["hp"]).is_equal(float(KarmaData.SPECIES["raton"]["maxHp"]))
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
	assert_float(KarmaState.eff_max_hp_for(s)).is_equal(float(KarmaData.SPECIES["raton"]["maxHp"]))
	assert_bool(KarmaShop.has_adapt(s, "swift")).is_true()


func test_refuge_fits_and_hide() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	# Place a fitting refuge at the player.
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": KarmaState.px(s), "y": KarmaState.py(s), "dug": false})
	assert_bool(KarmaState.toggle_hide(s)).is_true()
	assert_bool(KarmaState.player(s)["hidden"]).is_true()
	assert_bool(KarmaState.toggle_hide(s)).is_true()
	assert_bool(KarmaState.player(s)["hidden"]).is_false()


func test_shout_pays_and_lures() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_bool(KarmaState.try_shout(s)).is_true()
	assert_float(s["karma"]).is_equal(30.0)
	assert_float(s["pa"]).is_equal(50.0)
	assert_float(KarmaState.player(s)["lureTimer"]).is_equal(5.0)


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


func test_new_run_matches_rolled_census() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var counts: Dictionary = (s["census"] as Dictionary)["counts"]
	var expect := 0
	for sp in counts:
		expect += int(counts[sp])
	assert_int((s["agents"] as Array).size()).is_equal(expect)


func test_player_species_not_stacked() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var counts: Dictionary = (s["census"] as Dictionary)["counts"]
	var ratons := 0
	for a in s["agents"]:
		if str(a["speciesKey"]) == "raton":
			ratons += 1
	assert_int(ratons).is_equal(int(counts["raton"]))


func test_reincarnate_carries_census() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["dead"] = true
	s["pendingNext"] = "sapo"
	var n := KarmaState.reincarnate(s, _rng)
	assert_bool(n.has("census")).is_true()
	if is_failure():
		return
	assert_int(int((n["census"] as Dictionary)["counts"]["sapo"])).is_equal(int((s["census"] as Dictionary)["counts"]["sapo"]))


func _member_positions(s: Dictionary, sp: String) -> Array:
	var pts := []
	for a in s["agents"]:
		if str(a["speciesKey"]) == sp:
			pts.append(Vector2(float(a["x"]), float(a["y"])))
	return pts
	return pts


func _max_pairwise(pts: Array) -> float:
	var bd := 0.0
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			bd = maxf(bd, (pts[i] as Vector2).distance_to(pts[j]))
	return bd


func _min_pairwise(pts: Array) -> float:
	var bd := 1e9
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			bd = minf(bd, (pts[i] as Vector2).distance_to(pts[j]))
	return bd


func test_communities_cluster_within_travel_range() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	for sp in ["oruga", "sapo", "raton", "ardilla", "topo"]:
		assert_bool(_max_pairwise(_member_positions(s, sp)) <= 750.0).is_true()
		if is_failure():
			return


func test_social_pair_starts_in_verb_range() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	assert_bool(_min_pairwise(_member_positions(s, "raton")) <= float(KarmaData.TUNING["groomRange"])).is_true()


func test_spawns_avoid_water() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	for a in s["agents"]:
		assert_bool(KarmaUtils.inside_water(s, float(a["x"]), float(a["y"]))).is_false()
		if is_failure():
			return
	assert_bool(KarmaUtils.inside_water(s, float(KarmaState.px(s)), float(KarmaState.py(s)))).is_false()


func test_no_scripted_pressure_agents() -> void:
	# The roster is exactly the rolled census: the possessed member stays in agents.
	var t0 := KarmaState.new_run("oruga", 0.0, 0.0, 0, _rng)
	var counts: Dictionary = (t0["census"] as Dictionary)["counts"]
	var expected := 0
	for k in counts:
		expected += int(counts[k])
	assert_int((t0["agents"] as Array).size()).is_equal(expected)


func test_lobo_does_not_hunt_t0_agents() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	KarmaState.player(s)["x"] = 3000.0
	KarmaState.player(s)["y"] = 2200.0
	var lobo := KarmaPredators.mk_predator(s, "lobo", 500.0, 500.0, 1)
	(s["agents"] as Array).append(lobo)
	var prey: Dictionary = KarmaState.spawn_fauna(s, "oruga", 550.0, 500.0)
	KarmaGame.step_agent(s, lobo, 0.1)
	assert_bool((s["agents"] as Array).has(prey)).is_true()


func test_birth_log_names_the_year() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var named := false
	for entry in s["feed"]:
		if str(entry).contains("Año"):
			named = true
	assert_bool(named).is_true()


func test_all_themes_keep_communities_clustered() -> void:
	var themes := {}
	var lean_t0_ok := false
	for i in 30:
		var r := RandomNumberGenerator.new()
		r.seed = 20000 + i
		var sp := "oruga" if i % 2 == 0 else "raton"
		var s := KarmaState.new_run(sp, 0.0, 0.0, 0, r)
		var theme := str((s["census"] as Dictionary)["theme"])
		themes[theme] = true
		for g in ["oruga", "sapo", "raton", "ardilla", "topo"]:
			assert_bool(_max_pairwise(_member_positions(s, g)) <= 750.0).is_true()
			if is_failure():
				return
		for a in s["agents"]:
			assert_bool(KarmaUtils.inside_water(s, float(a["x"]), float(a["y"]))).is_false()
			if is_failure():
				return
		if theme == "lean" and sp == "oruga":
			var halcones := 0
			for a in s["agents"]:
				if str(a.get("speciesKey", "")) == "halcon":
					halcones += 1
			lean_t0_ok = halcones >= 1 and _member_positions(s, "oruga").size() >= int((s["census"] as Dictionary)["counts"]["oruga"])
	assert_int(themes.size()).is_equal(5)
	assert_bool(lean_t0_ok).is_true()
