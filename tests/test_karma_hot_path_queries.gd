extends GdUnitTestSuite

# Characterization for the hot-path query refactor: pin the existing
# is_hunted predicate and the predator victim selection/ordering so the
# filter-to-loop rewrite cannot change any outcome.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 20261019


func _state() -> Dictionary:
	return KarmaState.blank_state("raton", 0.0, 0.0)


func _subject(s: Dictionary, x := 500.0, y := 500.0) -> Dictionary:
	var a := KarmaState.mk_agent({"speciesKey": "raton", "x": x, "y": y})
	(s["agents"] as Array).append(a)
	return a


func _hunter(s: Dictionary, species: String, x: float, y: float) -> Dictionary:
	var h := KarmaPredators.mk_predator(s, species, x, y, 1)
	(s["agents"] as Array).append(h)
	return h


func _victim(s: Dictionary, x: float, y: float) -> Dictionary:
	return KarmaState.spawn_fauna(s, "raton", x, y)


# 1.1 is_hunted outcomes.

func test_is_hunted_true_for_edible_hunter_in_fear_range() -> void:
	var s := _state()
	var a := _subject(s)
	_hunter(s, "zorro", 600.0, 500.0)
	assert_bool(KarmaAI.is_hunted(s, a)).is_true()


func test_is_hunted_false_for_edible_hunter_out_of_fear_range() -> void:
	var s := _state()
	var a := _subject(s)
	_hunter(s, "zorro", 900.0, 500.0)
	assert_bool(KarmaAI.is_hunted(s, a)).is_false()


func test_is_hunted_counts_hidden_hunter() -> void:
	var s := _state()
	var a := _subject(s)
	var h := _hunter(s, "zorro", 600.0, 500.0)
	h["hidden"] = true
	assert_bool(KarmaAI.is_hunted(s, a)).is_true()


func test_is_hunted_false_for_non_edible_hunter() -> void:
	var s := _state()
	var a := _subject(s)
	_hunter(s, "lobo", 600.0, 500.0)
	assert_bool(KarmaAI.is_hunted(s, a)).is_false()


# 1.2 Predator victim selection: the per-pair query picks the nearest edible agent.

func test_nearest_ai_prey_targets_nearest_edible_agent() -> void:
	var s := _state()
	var near := _victim(s, 508.0, 500.0)
	_victim(s, 515.0, 500.0)
	var p := _hunter(s, "zorro", 500.0, 500.0)
	assert_bool(KarmaAI.nearest_ai_prey(s, p, 100.0) == near).is_true()


func test_nearest_ai_prey_skips_non_edible_species() -> void:
	var s := _state()
	_hunter(s, "lobo", 505.0, 500.0)
	var p := _hunter(s, "zorro", 500.0, 500.0)
	assert_bool(KarmaAI.nearest_ai_prey(s, p, 100.0) == null).is_true()


# 1.3 A kill inside a world tick must not hide another eligible victim.

func test_world_tick_kills_each_eligible_victim_once() -> void:
	var s := _state()
	var first := _victim(s, 505.0, 500.0)
	var second := _victim(s, 510.0, 500.0)
	_hunter(s, "halcon", 500.0, 500.0)
	_hunter(s, "halcon", 500.0, 500.0)
	for i in 3:
		KarmaGame.update(s, 0.1, _rng)
	assert_bool((s["agents"] as Array).has(first)).is_false()
	assert_bool((s["agents"] as Array).has(second)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(2)
