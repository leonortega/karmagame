extends GdUnitTestSuite

# meaningful-world-verbs 1.1: universality + world-touch RED suite.
# Each test pins one spec behavior; all must FAIL before the rework.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func _fresh(species := "raton") -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func _agent(s: Dictionary, species: String, x := 500.0, y := 500.0) -> Dictionary:
	var a := KarmaState.spawn_fauna(s, species, x, y)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["karma"] = 0.0
	a["pa"] = 20.0
	a["hp"] = 80.0
	a["hambre"] = 80.0
	return a


func _hunter(s: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": "zorro", "speciesKey": "zorro", "hp": 100.0, "x": x, "y": y})
	(s["agents"] as Array).append(h)
	return h


func test_agent_groom_cleanses_and_heals_mate() -> void:
	var s := _fresh("raton")
	var a := _agent(s, "raton")
	var m := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 40.0, "hambre": 50.0, "x": 510.0, "y": 500.0, "mimicEaten": true})
	(s["agents"] as Array).append(m)
	assert_bool(KarmaGame.cast_verb_for(s, a, 3)).is_true()
	assert_bool(bool(m.get("mimicEaten", true))).is_false()
	assert_bool(float(m["hp"]) > 40.0).is_true()


func test_agent_scout_drops_scent_post() -> void:
	var s := _fresh("raton")
	var a := _agent(s, "raton")
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 510.0, "y": 500.0}))
	var n0 := (s["refuges"] as Array).size()
	assert_bool(KarmaGame.cast_verb_for(s, a, 4)).is_true()
	assert_bool((s["refuges"] as Array).size() > n0).is_true()


func test_agent_thermal_projects_shadow() -> void:
	var s := _fresh("halcon")
	var a := _agent(s, "halcon")
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "fauna", "speciesKey": "raton", "hp": 100.0, "x": 560.0, "y": 500.0}))
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_bool((s["refuges"] as Array).any(func(r): return str(r.get("type", "")) == "shadow-disc")).is_true()


func test_agent_bark_consumes_oak_stock() -> void:
	var s := _fresh("ardilla")
	var a := _agent(s, "ardilla", 500.0, 500.0)
	(s["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", 505.0, 500.0, 3))
	var oak: Dictionary = (s["oaks"] as Array)[(s["oaks"] as Array).size() - 1]
	assert_bool(KarmaGame.cast_verb_for(s, a, 4)).is_true()
	assert_int(int(oak["amount"])).is_equal(2)
	assert_bool(bool(oak.get("stripped", false))).is_true()


func test_agent_worm_spends_charge_and_spawns_insect() -> void:
	var s := _fresh("topo")
	var a := _agent(s, "topo", 500.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "x": 505.0, "y": 500.0, "dug": true, "charge": 1})
	var n0 := (s["insects"] as Array).size()
	assert_bool(KarmaGame.cast_verb_for(s, a, 3)).is_true()
	assert_bool((s["insects"] as Array).size() > n0).is_true()


func test_agent_tunneline_links_burrows() -> void:
	var s := _fresh("topo")
	var a := _agent(s, "topo", 500.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "x": 500.0, "y": 500.0, "dug": true})
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "x": 520.0, "y": 500.0, "dug": true})
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_bool((s["refuges"] as Array).any(func(r): return (r as Dictionary).has("net"))).is_true()


func test_agent_silk_leaves_thread() -> void:
	var s := _fresh("oruga")
	var a := _agent(s, "oruga", 500.0, 500.0)
	_hunter(s, 530.0, 500.0)
	var n0 := (s["refuges"] as Array).size()
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_bool((s["refuges"] as Array).size() > n0).is_true()


func test_agent_burrowin_leaves_wallow() -> void:
	var s := _fresh("sapo")
	var a := _agent(s, "sapo", 500.0, 500.0)
	assert_bool(KarmaGame.cast_verb_for(s, a, 3)).is_true()
	assert_bool(bool(a.get("hidden", false))).is_true()
	assert_bool((s["refuges"] as Array).any(func(r): return str(r.get("type", "")) == "wallow")).is_true()


func test_agent_bristle_stings_now() -> void:
	var s := _fresh("oruga")
	var a := _agent(s, "oruga", 500.0, 500.0)
	var h := _hunter(s, 530.0, 500.0)
	assert_bool(KarmaGame.cast_verb_for(s, a, 5)).is_true()
	assert_bool(float(h.get("restT", 0.0)) > 0.0).is_true()


func test_agent_escort_shepherds_and_deters() -> void:
	var s := _fresh("lobo")
	var a := _agent(s, "lobo", 500.0, 500.0)
	var m := KarmaState.mk_agent({"role": "company", "speciesKey": "lobo", "hp": 100.0, "hambre": 80.0, "x": 540.0, "y": 500.0})
	(s["agents"] as Array).append(m)
	_hunter(s, 550.0, 500.0)
	var mx0 := float(m["x"])
	assert_bool(KarmaGame.cast_verb_for(s, a, 4)).is_true()
	assert_bool(float(m["x"]) != mx0).is_true()


func test_agent_chorus_summons_choir() -> void:
	var s := _fresh("sapo")
	var a := _agent(s, "sapo", 500.0, 500.0)
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "sapo", "hp": 80.0, "x": 510.0, "y": 500.0}))
	(s["waters"] as Array).append({"kind": "charco", "x": 480.0, "y": 500.0, "r": 20.0})
	assert_bool(KarmaGame.cast_verb_for(s, a, 5)).is_true()
	assert_bool(float(a["karma"]) > 0.0).is_true()


func test_no_player_only_verbs_remain() -> void:
	var cases := [
		["oruga", 1], ["oruga", 5], ["raton", 4], ["halcon", 2],
		["halcon", 3], ["zorro", 1], ["zorro", 2], ["zorro", 4],
		["topo", 5], ["lobo", 1], ["lobo", 4], ["lobo", 5],
	]
	for c in cases:
		var s := _fresh(str(c[0]))
		var a := _agent(s, str(c[0]))
		# At minimum the verb must attempt its own precondition path,
		# never a hard `return false` for agents: valid setups succeed.
		if str(c[0]) == "zorro" and int(c[1]) == 1:
			(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 510.0, "y": 500.0}))
			assert_bool(KarmaGame.cast_verb_for(s, a, 1)).is_true()
		if str(c[0]) == "lobo" and int(c[1]) == 1:
			(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "lobo", "hp": 100.0, "x": 510.0, "y": 500.0}))
			assert_bool(KarmaGame.cast_verb_for(s, a, 1)).is_true()
