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
	var a := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": x, "y": y})
	(s["agents"] as Array).append(a)
	return a


func _hunter(s: Dictionary, type: String, x: float, y: float) -> Dictionary:
	var h := KarmaPredators.mk_predator(s, type, x, y, 1)
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
	_hunter(s, "saponpc", 600.0, 500.0)
	assert_bool(KarmaAI.is_hunted(s, a)).is_false()


# 1.2 Predator victim selection.

func test_strike_agents_targets_nearest_victim() -> void:
	var s := _state()
	var near := _victim(s, 508.0, 500.0)
	var far := _victim(s, 515.0, 500.0)
	var p := _hunter(s, "zorro", 500.0, 500.0)
	KarmaPredators.strike_agents(s, p, KarmaData.PRED["zorro"], 0.1, KarmaPredators.stalk_victims(s, p))
	assert_bool((s["agents"] as Array).has(near)).is_false()
	assert_bool((s["agents"] as Array).has(far)).is_true()


func test_strike_agents_equal_distance_keeps_first_listed_victim() -> void:
	var s := _state()
	var first := _victim(s, 490.0, 500.0)
	var second := _victim(s, 510.0, 500.0)
	var p := _hunter(s, "zorro", 500.0, 500.0)
	KarmaPredators.strike_agents(s, p, KarmaData.PRED["zorro"], 0.1, KarmaPredators.stalk_victims(s, p))
	assert_bool((s["agents"] as Array).has(first)).is_false()
	assert_bool((s["agents"] as Array).has(second)).is_true()


# 1.3 A kill inside a predator tick must not hide another eligible victim.

func test_predator_tick_kills_each_eligible_victim_once() -> void:
	var s := _state()
	var first := _victim(s, 505.0, 500.0)
	var second := _victim(s, 510.0, 500.0)
	var p1 := _hunter(s, "zorro", 500.0, 500.0)
	var p2 := _hunter(s, "zorro", 500.0, 500.0)
	p1["satedT"] = 1.0
	p2["satedT"] = 1.0
	KarmaPredators.update_predators(s, 0.1, _rng)
	assert_bool((s["agents"] as Array).has(first)).is_false()
	assert_bool((s["agents"] as Array).has(second)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(2)
