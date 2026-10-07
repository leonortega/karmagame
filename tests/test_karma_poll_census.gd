extends GdUnitTestSuite

# Poll census (poll-census): population and supply snapshot for log diagnosis.


func test_census_counts_supply_and_agents() -> void:
	var state := {
		"insects": [{"x": 1.0, "y": 1.0}, {"x": 2.0, "y": 2.0}],
		"carrions": [{"x": 3.0, "y": 3.0}],
		"agents": [
			{"speciesKey": "sapo", "role": "fauna"},
			{"speciesKey": "sapo", "role": "company"},
			{"speciesKey": "raton", "role": "fauna"},
		],
	}
	var census: Dictionary = KarmaJev.census(state)
	assert_int(int(census["insects"])).is_equal(2)
	assert_int(int(census["carrions"])).is_equal(1)
	assert_int(int((census["agents"] as Dictionary)["sapo"])).is_equal(2)
	assert_int(int((census["agents"] as Dictionary)["raton"])).is_equal(1)


func test_census_empty_state_counts_zero() -> void:
	var census: Dictionary = KarmaJev.census({"insects": [], "carrions": [], "agents": []})
	assert_int(int(census["insects"])).is_equal(0)
	assert_int(int(census["carrions"])).is_equal(0)
	assert_bool((census["agents"] as Dictionary).is_empty()).is_true()


func test_census_tolerates_missing_lists() -> void:
	var census: Dictionary = KarmaJev.census({})
	assert_int(int(census["insects"])).is_equal(0)
	assert_int(int(census["carrions"])).is_equal(0)
	assert_bool((census["agents"] as Dictionary).is_empty()).is_true()
