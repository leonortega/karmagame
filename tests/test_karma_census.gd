extends GdUnitTestSuite

# Rolled ecosystem census (ecosystem-census): same rules every game, different
# numbers every game. Roller lives in KarmaCensus; tables in KarmaData.


func _roll(seed: int, player_species := "raton", theme := "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return KarmaCensus.roll(rng, player_species, theme)


func test_rolls_vary_between_games() -> void:
	var seen := {}
	for i in 12:
		var roll := _roll(5000 + i)
		seen[JSON.stringify(roll["counts"])] = true
	assert_bool(seen.size() > 1).is_true()


func test_counts_stay_within_floor_and_cap() -> void:
	for i in 20:
		var counts: Dictionary = _roll(1000 + i)["counts"]
		for sp in KarmaData.CENSUS_FLOOR:
			assert_int(int(counts[sp])).is_greater_equal(int(KarmaData.CENSUS_FLOOR[sp]))
			assert_int(int(counts[sp])).is_less_equal(int(KarmaData.CENSUS_CAP[sp]))
		if is_failure():
			return


func test_player_species_count_includes_player() -> void:
	for sp in KarmaData.SPECIES:
		var counts: Dictionary = _roll(42, str(sp))["counts"]
		assert_int(int(counts[str(sp)])).is_greater_equal(1)
		if is_failure():
			return


func test_insect_gate_holds_across_seeds() -> void:
	for i in 30:
		var counts: Dictionary = _roll(7000 + i)["counts"]
		var demand := float(counts["sapo"]) + float(counts["topo"]) * 0.5
		assert_bool(demand <= float(KarmaData.CENSUS["insectMaxDemand"])).is_true()
		if is_failure():
			return


func test_prey_covers_hunters_three_to_one() -> void:
	for i in 30:
		var counts: Dictionary = _roll(9000 + i)["counts"]
		var prey := float(counts["oruga"] + counts["sapo"] + counts["raton"] + counts["ardilla"] + counts["topo"])
		var hunters := float(counts["zorro"] + counts["lobo"] + counts["halcon"])
		assert_bool(prey >= hunters * 3.0).is_true()
		if is_failure():
			return


func test_theme_names_the_year() -> void:
	var themes := ["bloom", "rodent", "wet", "lean", "balanced"]
	for t in themes:
		var roll := _roll(11, "raton", t)
		assert_str(str(roll["theme"])).is_equal(t)
	if is_failure():
		return


func test_balanced_stays_near_baseline() -> void:
	var counts: Dictionary = _roll(11, "raton", "balanced")["counts"]
	for sp in KarmaData.CENSUS_MID:
		assert_bool(abs(int(counts[sp]) - int(KarmaData.CENSUS_MID[sp])) <= 1).is_true()
	if is_failure():
		return


func test_wet_year_skews_sapo_high() -> void:
	var counts: Dictionary = _roll(11, "raton", "wet")["counts"]
	assert_int(int(counts["sapo"])).is_greater_equal(int(KarmaData.CENSUS_MID["sapo"]))


func test_lean_year_keeps_oruga_floor() -> void:
	var counts: Dictionary = _roll(11, "oruga", "lean")["counts"]
	assert_int(int(counts["oruga"])).is_greater_equal(4)


func test_oruga_baseline_holds_feeder_surplus() -> void:
	assert_int(int(KarmaData.CENSUS_MID["oruga"])).is_equal(8)
	assert_int(int(KarmaData.CENSUS_FLOOR["oruga"])).is_equal(4)
