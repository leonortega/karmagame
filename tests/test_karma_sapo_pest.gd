extends GdUnitTestSuite

# Sapo pest AI mirror (sapo-pest-ai): slot 2 through the same verb core.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 99


func _fresh(species := "sapo") -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func test_ai_sapo_casts_pest_through_verb_core() -> void:
	var s := _fresh("sapo")
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	a["karma"] = 0.0
	a["pa"] = 0.0
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_float(float(a["hp"])).is_equal(20.0) # +10 insects
	assert_float(float(a["karma"])).is_equal(3.0) # pest control
	assert_float(float((a["verbCds"] as Array)[1])).is_equal(8.0)


func test_ai_pest_fails_quietly_with_no_prey() -> void:
	var s := _fresh("sapo")
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	a["karma"] = 0.0
	a["pa"] = 0.0
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	s["insects"] = []
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_false()
	assert_float(float(a["hp"])).is_equal(10.0)
	assert_float(float(a["karma"])).is_equal(0.0)
	assert_float(float((a["verbCds"] as Array)[1])).is_equal(0.0)


func test_ai_pest_reaches_further_with_long_tongue() -> void:
	var s := _fresh("sapo")
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	a["karma"] = 0.0
	a["pa"] = 0.0
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["owned"] = {"sapo_lengua": true}
	s["insects"] = [{"x": 620.0, "y": 500.0}] # 120px: beyond 90, within 130
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0)
	assert_float(float(a["karma"])).is_equal(3.0)


func test_ai_and_player_pest_pay_the_same() -> void:
	var s := _fresh("sapo")
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	a["hp"] = 10.0
	a["hambre"] = 50.0
	a["karma"] = 0.0
	a["pa"] = 0.0
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	s["insects"] = [{"x": 520.0, "y": 500.0}, {"x": 521.0, "y": 500.0}]
	s["hp"] = 10.0
	s["hambre"] = 50.0
	s["karma"] = 0.0
	s["pa"] = 0.0
	s["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	s["px"] = 500.0
	s["py"] = 500.0
	assert_bool(KarmaGame.cast_verb_for(s, a, 2)).is_true()
	assert_bool(KarmaGame.cast_verb(s, 2)).is_true()
	assert_float(float(a["hp"])).is_equal(20.0)
	assert_float(float(s["hp"])).is_equal(20.0)
	assert_float(float(a["karma"])).is_equal(3.0)
	assert_float(float(s["karma"])).is_equal(3.0)


func _sapo_agent(s: Dictionary) -> Dictionary:
	var a := KarmaState.spawn_fauna(s, "sapo", 500.0, 500.0)
	a["hp"] = 50.0
	a["hambre"] = 50.0
	a["karma"] = 0.0
	a["pa"] = 0.0
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	return a


func _hunter_at(s: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaState.mk_agent({"role": "hunter", "type": "zorro", "speciesKey": "zorro", "hp": 100.0, "x": x, "y": y})
	(s["agents"] as Array).append(h)
	return h


func test_toxin_outranks_pest() -> void:
	var s := _fresh("sapo")
	var a := _sapo_agent(s)
	_hunter_at(s, 530.0, 500.0) # 30px: toxin in reach
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	assert_bool(KarmaAI.ai_maybe_verb(s, a, 0.1)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(1) # pest never fired
	assert_float(float(a["karma"])).is_equal(float(KarmaData.TUNING["toxinKarma"]))


func test_pest_outranks_burrow_and_chorus() -> void:
	var s := _fresh("sapo")
	var a := _sapo_agent(s)
	_hunter_at(s, 650.0, 500.0) # 150px: pressure but no toxin
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "sapo", "hp": 80.0, "x": 510.0, "y": 500.0}))
	s["insects"] = [{"x": 520.0, "y": 500.0}]
	assert_bool(KarmaAI.ai_maybe_verb(s, a, 0.1)).is_true()
	assert_int((s["insects"] as Array).size()).is_equal(0) # pest fired
	assert_bool(bool(a.get("hidden", false))).is_false() # burrow never fired
	assert_float(float(a["karma"])).is_equal(float(KarmaData.TUNING["pestKarma"])) # chorus never fired
