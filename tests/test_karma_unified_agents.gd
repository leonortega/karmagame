extends GdUnitTestSuite


func _player_agent(state: Dictionary) -> Variant:
	for a in state["agents"]:
		if str((a as Dictionary).get("brain", "")) == "PLAYER":
			return a
	return null


func _player_field(state: Dictionary, key: String, fallback: Variant) -> Variant:
	var a: Variant = _player_agent(state)
	if a != null:
		return (a as Dictionary).get(key, fallback)
	return state.get(key, fallback)


func _vida(state: Dictionary) -> float:
	return float(_player_field(state, "hp", 0.0))


func _invuln(state: Dictionary) -> float:
	return float(_player_field(state, "invuln", 0.0))


func _t1_scene(with_zorro: bool) -> Dictionary:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	(s["agents"] as Array).append(KarmaState.mk_agent({"speciesKey": "raton", "brain": "AI", "hp": 100.0, "x": 500.0, "y": 500.0}))
	KarmaState.possess_member(s)
	var p: Variant = KarmaState.player(s)
	p["invuln"] = 0.0
	p["hidden"] = false
	p["bristled"] = false
	if with_zorro:
		KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	return s


func test_fauna_zorro_contact_drops_t1_player_vida_by_28_and_sets_invuln() -> void:
	var hit := _t1_scene(true)
	var control := _t1_scene(false)
	var rng_hit := RandomNumberGenerator.new()
	rng_hit.seed = 20261023
	var rng_control := RandomNumberGenerator.new()
	rng_control.seed = 20261023

	KarmaGame.update(hit, 0.1, rng_hit)
	KarmaGame.update(control, 0.1, rng_control)

	assert_float(_vida(control) - _vida(hit)).is_equal_approx(28.0, 0.01)
	assert_float(_invuln(hit)).is_equal_approx(1.0, 0.01)


func test_fauna_zorro_ages_once_per_world_tick() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var z := KarmaState.spawn_fauna(s, "zorro", 700.0, 500.0)
	var e0 := float(z["edad"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023

	KarmaGame.update(s, 0.1, rng)

	assert_float(float(z["edad"]) - e0).is_equal_approx(0.1, 0.001)


func test_possessed_agent_needs_and_age_advance_once_per_world_tick() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, rng)
	var e0 := float(_player_field(s, "edad", 0.0))
	var h0 := float(_player_field(s, "hambre", 100.0))

	assert_bool(_player_agent(s) != null).is_true()
	KarmaGame.update(s, 0.1, rng)

	assert_float(float(_player_field(s, "edad", 0.0)) - e0).is_equal_approx(0.1, 0.001)
	var expected_drain: float = KarmaData.hunger_rate_for("raton") * 0.1
	assert_float(h0 - float(_player_field(s, "hambre", 100.0))).is_equal_approx(expected_drain, 0.001)


func test_world_tick_never_advances_an_agent_age_twice() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var a := KarmaState.spawn_fauna(s, "zorro", 700.0, 500.0)
	var b := KarmaState.spawn_fauna(s, "zorro", 900.0, 500.0)
	var c := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 500.0, "y": 500.0})
	(s["agents"] as Array).append(c)
	var ages := [float(a["edad"]), float(b["edad"]), float(c["edad"])]
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023

	KarmaGame.update(s, 0.1, rng)

	for i in [a, b, c].size():
		var agent: Dictionary = [a, b, c][i]
		assert_float(float(agent["edad"]) - float(ages[i])).is_equal_approx(0.1, 0.001)


func test_roster_has_no_role_kind_or_type_labels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, rng)
	for a in s["agents"]:
		for key in ["role", "kind", "type"]:
			assert_bool((a as Dictionary).has(key)).is_false()


func test_predator_table_has_no_saponpc_row() -> void:
	assert_bool(KarmaData.PRED.has("saponpc")).is_false()


func test_t0_start_spawns_no_saponpc() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var s := KarmaState.new_run("oruga", 0.0, 0.0, 0, rng)
	for a in s["agents"]:
		assert_str(str((a as Dictionary).get("type", ""))).is_not_equal("saponpc")


func test_zorro_can_eat_raton() -> void:
	assert_bool(KarmaPredators.can_eat("zorro", "raton", 1e9)).is_true()


func test_lobo_can_eat_halcon() -> void:
	assert_bool(KarmaPredators.can_eat("lobo", "halcon", 1e9)).is_true()


func test_halcon_can_eat_raton() -> void:
	assert_bool(KarmaPredators.can_eat("halcon", "raton", 1e9)).is_true()


func test_grazers_cannot_eat_animals() -> void:
	assert_bool(KarmaPredators.can_eat("oruga", "oruga", 1e9)).is_false()
	assert_bool(KarmaPredators.can_eat("raton", "oruga", 1e9)).is_false()
	assert_bool(KarmaPredators.can_eat("topo", "oruga", 1e9)).is_false()


func test_halcon_size_rule_rejects_lobo() -> void:
	assert_bool(KarmaPredators.can_eat("halcon", "lobo", 1e9)).is_false()


func test_t0_start_has_rolled_halcon() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var s := KarmaState.new_run("oruga", 0.0, 0.0, 0, rng)
	var expected := int(((s["census"] as Dictionary)["counts"] as Dictionary)["halcon"])
	var actual := 0
	for a in s["agents"]:
		if str((a as Dictionary).get("speciesKey", "")) == "halcon":
			actual += 1
	assert_int(actual).is_equal(expected)


func test_zorro_does_not_hunt_distant_oruga() -> void:
	assert_bool(KarmaPredators.can_eat("zorro", "oruga", 150.0)).is_false()
	assert_bool(KarmaPredators.can_eat("zorro", "oruga", 5.0)).is_true()


func test_lobo_does_not_begin_hunt_on_t1_player() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.player(s)["x"] = 500.0
	KarmaState.player(s)["y"] = 500.0
	var lobo := KarmaState.spawn_fauna(s, "lobo", 650.0, 500.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023

	KarmaGame.update(s, 0.1, rng)

	assert_str(str(lobo.get("mode", ""))).is_not_equal("hunt")


func _count_species(state: Dictionary, species: String) -> int:
	var n := 0
	for a in state["agents"]:
		if str((a as Dictionary).get("speciesKey", "")) == species:
			n += 1
	return n


func test_possess_member_keeps_the_member() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var member := KarmaState.mk_agent({"speciesKey": "raton", "x": 500.0, "y": 500.0})
	(s["agents"] as Array).append(member)

	KarmaState.possess_member(s)

	assert_bool((s["agents"] as Array).has(member)).is_true()
	assert_str(str(member["brain"])).is_equal("PLAYER")


func test_possess_member_creates_exactly_one_player_brain() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	(s["agents"] as Array).append(KarmaState.mk_agent({"speciesKey": "raton", "x": 500.0, "y": 500.0}))
	var before := (s["agents"] as Array).size()

	KarmaState.possess_member(s)

	var players := 0
	for a in s["agents"]:
		if str((a as Dictionary).get("brain", "")) == "PLAYER":
			players += 1
	assert_int((s["agents"] as Array).size()).is_equal(before)
	assert_int(players).is_equal(1)


func test_respawn_missing_counts_possessed_member_once() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, rng)
	var expected := int(((s["census"] as Dictionary)["counts"] as Dictionary)["raton"])
	KarmaState.possess_member(s)

	for i in 10:
		KarmaState.respawn_missing(s, rng)

	assert_int(_count_species(s, "raton")).is_equal(expected)
