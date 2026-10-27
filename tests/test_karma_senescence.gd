extends GdUnitTestSuite

# Senescence stages: prime/worn/frail derived from animal-years per species.

var _rng := RandomNumberGenerator.new()


func test_oruga_prime_at_birth() -> void:
	assert_str(KarmaData.age_stage("oruga", 0.0)).is_equal("prime")


func test_oruga_worn_midlife() -> void:
	# 30s at 15s/yr = 2.0yr: past prime (1.5), before frail (3.0).
	assert_str(KarmaData.age_stage("oruga", 30.0)).is_equal("worn")


func test_oruga_frail_late() -> void:
	# 50s at 15s/yr = 3.33yr: past frail onset (3.0).
	assert_str(KarmaData.age_stage("oruga", 50.0)).is_equal("frail")


func test_raton_stages() -> void:
	assert_str(KarmaData.age_stage("raton", 0.0)).is_equal("prime")
	assert_str(KarmaData.age_stage("raton", 100.0)).is_equal("worn")
	assert_str(KarmaData.age_stage("raton", 140.0)).is_equal("frail")


func test_lobo_prime_lasts_longer_than_raton() -> void:
	# 200s: lobo at 6.67yr still prime (prime until 8.0);
	# raton at 10yr long frail (frail from 6.0).
	assert_str(KarmaData.age_stage("lobo", 200.0)).is_equal("prime")
	assert_str(KarmaData.age_stage("raton", 200.0)).is_equal("frail")


func test_lobo_worn_then_frail() -> void:
	assert_str(KarmaData.age_stage("lobo", 300.0)).is_equal("worn")
	assert_str(KarmaData.age_stage("lobo", 360.0)).is_equal("frail")


func test_stages_never_move_backward() -> void:
	var rank := {"prime": 0, "worn": 1, "frail": 2}
	var last := -1
	for secs in [0.0, 20.0, 60.0, 100.0, 140.0, 200.0]:
		var r: int = rank[KarmaData.age_stage("raton", secs)]
		assert_bool(r >= last).is_true()
		if is_failure():
			return
		last = r


func test_unknown_species_defaults_to_prime_at_birth() -> void:
	assert_str(KarmaData.age_stage("pato", 0.0)).is_equal("prime")


func test_prime_speed_is_base_speed() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	assert_bool(abs(KarmaState.eff_speed(s) - float(KarmaData.SPECIES["raton"]["speed"])) < 0.01).is_true()


func test_frail_raton_slower_than_prime() -> void:
	var prime := KarmaState.blank_state("raton", 0.0, 0.0)
	var frail := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.player(frail)["edad"] = 140.0
	assert_bool(KarmaState.eff_speed(frail) < KarmaState.eff_speed(prime)).is_true()
	assert_bool(abs(KarmaState.eff_speed(frail) - float(KarmaData.SPECIES["raton"]["speed"]) * 0.55) < 1.0).is_true()


func test_prime_zorro_chase_still_closes_on_prime_raton() -> void:
	var z := KarmaState.blank_state("zorro", 0.0, 0.0)
	var r := KarmaState.blank_state("raton", 0.0, 0.0)
	assert_bool(KarmaState.eff_speed(z) * float(KarmaData.TUNING["chaseMult"]) > KarmaState.eff_speed(r)).is_true()


func test_frail_regenerates_less_than_prime() -> void:
	var prime := KarmaState.blank_state("raton", 0.0, 0.0)
	var frail := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.player(prime)["hp"] = 50.0
	KarmaState.player(frail)["hp"] = 50.0
	KarmaState.player(frail)["edad"] = 140.0
	var max_hp := KarmaState.eff_max_hp_for(prime)
	KarmaUtils.update_needs(prime, max_hp, 10.0)
	KarmaUtils.update_needs(frail, max_hp, 10.0)
	assert_bool(float(KarmaState.player(frail)["hp"]) < float(KarmaState.player(prime)["hp"])).is_true()
	assert_bool(float(KarmaState.player(prime)["hp"]) > 50.0).is_true()


func test_natural_death_kills_fed_sheltered_agent() -> void:
	# raton lifespan 8yr × 20s/yr = 160s. Fed and at full hp past lifespan.
	var a := KarmaState.mk_agent({"speciesKey": "raton", "x": 10.0, "y": 10.0, "hp": 100.0, "edad": 161.0})
	KarmaUtils.update_needs(a, 100.0, 1.0)
	assert_bool(float(a["hp"]) <= 0.0).is_true()


func test_below_lifespan_keeps_hp() -> void:
	var a := KarmaState.mk_agent({"speciesKey": "raton", "x": 10.0, "y": 10.0, "hp": 50.0, "edad": 150.0})
	KarmaUtils.update_needs(a, 100.0, 1.0)
	assert_bool(float(a["hp"]) > 0.0).is_true()


func test_natural_death_leaves_carrion() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	a["edad"] = 200.0
	a["hambre"] = 100.0
	a["sed"] = 100.0
	a["hp"] = 100.0
	KarmaGame.update_agents(s, 0.1)
	assert_bool((s["agents"] as Array).has(a)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(1)


func test_player_old_age_judged_vejez() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.player(s)["edad"] = 200.0
	KarmaGame.update(s, 0.001, rng)
	assert_bool(bool(s["dead"])).is_true()
	assert_str(str(s["judgeReason"])).contains("Vejez")


func test_scaled_damage_prime_pair_is_base() -> void:
	var z := KarmaState.blank_state("zorro", 0.0, 0.0)
	var r := KarmaState.blank_state("raton", 0.0, 0.0)
	assert_bool(abs(KarmaData.scaled_damage(28.0, z, r) - 28.0) < 0.01).is_true()


func test_scaled_damage_old_attacker_weaker() -> void:
	# zorro frail onset 9.5yr x 30s/yr = 285s -> force floor 0.5.
	var z := KarmaState.blank_state("zorro", 0.0, 0.0)
	z["edad"] = 285.0
	var r := KarmaState.blank_state("raton", 0.0, 0.0)
	assert_bool(KarmaData.scaled_damage(28.0, z, r) < 28.0).is_true()


func test_scaled_damage_old_victim_frailer() -> void:
	# raton frail onset 6yr x 20s/yr = 120s -> frailty growth 1.6.
	var z := KarmaState.blank_state("zorro", 0.0, 0.0)
	var r := KarmaState.blank_state("raton", 0.0, 0.0)
	r["edad"] = 120.0
	assert_bool(KarmaData.scaled_damage(28.0, z, r) > 28.0).is_true()


func test_scaled_damage_combines_both_sides() -> void:
	var z := KarmaState.blank_state("zorro", 0.0, 0.0)
	z["edad"] = 285.0
	var r := KarmaState.blank_state("raton", 0.0, 0.0)
	r["edad"] = 120.0
	assert_bool(abs(KarmaData.scaled_damage(28.0, z, r) - 28.0 * 0.5 * 1.6) < 0.01).is_true()


func test_predator_dict_feeds_scaled_damage() -> void:
	var s := KarmaState.blank_state("oruga", 0.0, 0.0)
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	p["edad"] = 285.0
	KarmaState.player(s)["edad"] = 0.0
	assert_bool(KarmaData.scaled_damage(28.0, p, s) < 28.0).is_true()


func test_contact_bite_prime_pair_uses_base() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	KarmaPredators.strike_contact(s, p, KarmaData.PRED["zorro"], 0.0)
	assert_bool(abs(float(KarmaState.player(s)["hp"]) - (100.0 - 28.0)) < 0.01).is_true()


func test_contact_bite_frail_victim_takes_more() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.player(s)["edad"] = 120.0
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	KarmaPredators.strike_contact(s, p, KarmaData.PRED["zorro"], 0.0)
	assert_bool(abs(float(KarmaState.player(s)["hp"]) - (100.0 - 28.0 * 1.6)) < 0.01).is_true()


func test_contact_bite_old_attacker_deals_less() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	p["edad"] = 285.0
	KarmaPredators.strike_contact(s, p, KarmaData.PRED["zorro"], 0.0)
	assert_bool(abs(float(KarmaState.player(s)["hp"]) - (100.0 - 28.0 * 0.5)) < 0.01).is_true()


func test_contact_curl_halves_scaled_result() -> void:
	var s := KarmaState.blank_state("oruga", 0.0, 0.0)
	KarmaState.player(s)["stillT"] = 1.0
	KarmaState.player(s)["curlCd"] = 0.0
	KarmaState.player(s)["moved"] = false
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	KarmaPredators.strike_contact(s, p, KarmaData.PRED["zorro"], 0.0)
	assert_bool(abs(float(KarmaState.player(s)["hp"]) - (60.0 - ceil(28.0 / 2.0))) < 0.01).is_true()


func test_contact_bristle_reflects_scaled_result() -> void:
	var s := KarmaState.blank_state("oruga", 0.0, 0.0)
	KarmaState.player(s)["bristled"] = true
	var p := KarmaPredators.mk_predator(s, "zorro", 0.0, 0.0, 1)
	KarmaPredators.strike_contact(s, p, KarmaData.PRED["zorro"], 0.0)
	assert_bool(abs(float(KarmaState.player(s)["hp"]) - 60.0) < 0.01).is_true()
	assert_bool(abs(float(p["hp"]) - (120.0 - 28.0)) < 0.01).is_true()


# Failed kill verbs wound, burn cooldown, and open a decision-gated escape window.

func _predator_prey_setup(species: String, edad: float, prey_hp: float, prey_species: String = "") -> Array:
	var s := KarmaState.blank_state(species, 0.0, 0.0)
	var z := KarmaState.spawn_fauna(s, species, 500.0, 500.0)
	z["edad"] = edad
	z["hp"] = 50.0
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == z)
	var prey := KarmaState.mk_agent({"speciesKey": prey_species if prey_species != "" else species, "hp": prey_hp, "x": 510.0, "y": 500.0})
	(s["agents"] as Array).append(prey)
	return [s, z, prey]


func test_failed_pounce_wounds_prime_prey_alive() -> void:
	var t := _predator_prey_setup("zorro", 285.0, 100.0)
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	var prey: Dictionary = t[2]
	var carrion_n := (s["carrions"] as Array).size()
	KarmaGame._verb_pounce(s, z)
	assert_bool((s["agents"] as Array).has(prey)).is_true()
	assert_bool(abs(float(prey["hp"]) - 40.0) < 0.01).is_true()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n)


func test_failed_pounce_burns_attacker_cooldown() -> void:
	var t := _predator_prey_setup("zorro", 285.0, 100.0)
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	z["pounceCd"] = 0.0
	KarmaGame._verb_pounce(s, z)
	assert_bool(float(z["pounceCd"]) > 0.0).is_true()


func test_failed_pounce_grants_no_heal() -> void:
	var t := _predator_prey_setup("zorro", 285.0, 100.0)
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	assert_bool(abs(float(z["hp"]) - 50.0) < 0.01).is_true()
	KarmaGame._verb_pounce(s, z)
	assert_bool(abs(float(z["hp"]) - 50.0) < 0.01).is_true()


func test_failed_pounce_victim_survives_to_decide() -> void:
	# Escape window: the wounded raton stays a live company agent, so its next
	# decision may select flee/hide instead of being removed outright by the blow.
	var t := _predator_prey_setup("zorro", 285.0, 100.0)
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	var prey: Dictionary = t[2]
	KarmaGame._verb_pounce(s, z)
	assert_bool(KarmaState.company_agents(s).has(prey)).is_true()
	assert_bool(float(prey["hp"]) > 0.0).is_true()


func test_lethal_pounce_still_kills_and_heals() -> void:
	var t := _predator_prey_setup("zorro", 0.0, 100.0)
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	var prey: Dictionary = t[2]
	var carrion_n := (s["carrions"] as Array).size()
	KarmaGame._verb_pounce(s, z)
	assert_bool((s["agents"] as Array).has(prey)).is_false()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n + 1)
	assert_bool(abs(float(z["hp"]) - 75.0) < 0.01).is_true()


func test_failed_dive_wounds_prime_prey_alive() -> void:
	var t := _predator_prey_setup("halcon", 285.0, 100.0, "raton")
	var s: Dictionary = t[0]
	var z: Dictionary = t[1]
	var prey: Dictionary = t[2]
	var carrion_n := (s["carrions"] as Array).size()
	KarmaGame._verb_dive(s, z)
	assert_bool((s["agents"] as Array).has(prey)).is_true()
	var expected := 100.0 - KarmaData.scaled_damage(KarmaState.eff_max_hp_for(prey), z, prey)
	assert_bool(abs(float(prey["hp"]) - expected) < 0.01).is_true()
	assert_int((s["carrions"] as Array).size()).is_equal(carrion_n)


# Lone hunters run the shared needs+age drain through the one agent pipeline.

func _lone_hunter(species: String = "zorro") -> Array:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var h := KarmaState.mk_agent(KarmaPredators.mk_predator(s, species, 500.0, 500.0, 1))
	s["agents"] = [h]
	return [s, h]


func test_lone_hunter_vida_drains_from_needs() -> void:
	var t := _lone_hunter()
	var s: Dictionary = t[0]
	var h: Dictionary = t[1]
	h["hambre"] = 0.0
	h["sed"] = 0.0
	h["hp"] = 120.0
	KarmaGame.step_agent(s, h, 1.0)
	assert_bool(float(h["hp"]) < 120.0).is_true()


func test_lone_hunter_dies_of_old_age_in_one_step() -> void:
	var t := _lone_hunter()
	var s: Dictionary = t[0]
	var h: Dictionary = t[1]
	h["hambre"] = 100.0
	h["sed"] = 100.0
	h["hp"] = 120.0
	h["edad"] = 99999.0
	KarmaGame.step_agent(s, h, 0.1)
	assert_bool(float(h["hp"]) <= 0.0).is_true()


func test_world_tick_ages_each_hunter_once() -> void:
	# Every animal goes through one step_agent: edad advances exactly once.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var s := KarmaState.new_run("oruga", 0.0, 0.0, 0, rng)
	var hunters := KarmaState.predator_agents(s)
	assert_bool(hunters.size() > 0).is_true()
	if hunters.is_empty():
		return
	var h: Dictionary = hunters[0]
	var e0 := float(h.get("edad", 0.0))
	KarmaGame.update(s, 0.1, rng)
	var e1 := float(h.get("edad", 0.0))
	assert_bool(abs((e1 - e0) - 0.1) < 0.01).is_true()


func test_fauna_hunter_ages_once_per_tick() -> void:
	# Fauna carnivores are stepped by update_agents (species JEV) only.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var f := KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	s["agents"] = [f]
	var e0 := float(f.get("edad", 0.0))
	KarmaGame.update(s, 0.1, rng)
	var e1 := float(f.get("edad", 0.0))
	assert_bool(abs((e1 - e0) - 0.1) < 0.01).is_true()


# Predator-wave respawn: rolled carnivores regenerate to their census count.

func _count_species(s: Dictionary, k: String) -> int:
	var n := 0
	for a in (s["agents"] as Array):
		if str((a as Dictionary).get("speciesKey", "")) == k:
			n += 1
	return n


func _wipe_hunters(s: Dictionary) -> void:
	var survivors: Array = []
	for a in (s["agents"] as Array):
		if not KarmaData.PRED.has(str((a as Dictionary).get("speciesKey", ""))):
			survivors.append(a)
	s["agents"] = survivors


func test_respawn_keeps_sapo_at_census() -> void:
	var s := KarmaState.new_run("oruga", 0.0, 0.0, 0, _rng)
	_wipe_hunters(s)
	for i in 10:
		KarmaState.respawn_missing(s, _rng)
	assert_int(_count_species(s, "sapo")).is_equal(int((s["census"] as Dictionary)["counts"]["sapo"]))


func test_respawn_restores_hunter_wave() -> void:
	var s := KarmaState.new_run("oruga", 0.0, 0.0, 0, _rng)
	_wipe_hunters(s)
	for i in 10:
		KarmaState.respawn_missing(s, _rng)
	var counts: Dictionary = (s["census"] as Dictionary)["counts"]
	for k in ["zorro", "lobo", "halcon"]:
		assert_int(_count_species(s, str(k))).is_equal(int(counts[k]))


# Action-time aging: verb cooldowns/durations stretch with age; costs unchanged.

func _topo(edad: float) -> Dictionary:
	var s := KarmaState.blank_state("topo", 0.0, 0.0)
	(s["agents"] as Array).append(KarmaState.mk_agent({"speciesKey": "topo", "brain": "AI", "hp": 60.0, "x": 0.0, "y": 0.0}))
	KarmaState.possess_member(s)
	KarmaState.player(s)["edad"] = edad
	return s


func test_aged_time_leaves_prime_untouched() -> void:
	assert_bool(abs(KarmaData.aged_time(_topo(0.0), 20.0) - 20.0) < 0.01).is_true()


func test_aged_time_stretches_frail() -> void:
	# Frail topo: action growth 1.5x.
	assert_bool(abs(KarmaData.aged_time(_topo(150.0), 20.0) - 30.0) < 0.01).is_true()


func test_frail_topo_dig_cd_longer_than_prime() -> void:
	var prime := _topo(0.0)
	var frail := _topo(150.0)
	KarmaEat.dig_burrow(prime, null)
	KarmaEat.dig_burrow(frail, null)
	assert_bool(float(KarmaState.player(frail)["digCd"]) > float(KarmaState.player(prime)["digCd"])).is_true()
	assert_bool(abs(float(KarmaState.player(prime)["digCd"]) - float(KarmaData.TUNING["digCd"])) < 0.01).is_true()


func test_frail_topo_tremor_cd_longer_than_prime() -> void:
	var prime := _topo(0.0)
	var frail := _topo(150.0)
	KarmaEat.sense_pulse(prime)
	KarmaEat.sense_pulse(frail)
	assert_bool(float(KarmaState.player(frail)["senseCd"]) > float(KarmaState.player(prime)["senseCd"])).is_true()


func test_frail_halcon_thermal_lasts_longer_than_prime() -> void:
	var prime := KarmaState.blank_state("halcon", 0.0, 0.0)
	var frail := KarmaState.blank_state("halcon", 0.0, 0.0)
	KarmaState.player(frail)["edad"] = 300.0
	KarmaState.spawn_fauna(prime, "raton", float(KarmaState.px(prime)) + 10.0, float(KarmaState.py(prime)))
	KarmaState.spawn_fauna(frail, "raton", float(KarmaState.px(frail)) + 10.0, float(KarmaState.py(frail)))
	KarmaGame._verb_thermal(prime, null)
	KarmaGame._verb_thermal(frail, null)
	assert_bool(float(KarmaState.player(frail)["thermalT"]) > float(KarmaState.player(prime)["thermalT"])).is_true()


# Locomotion aging: displacement scales by age, gait envelope shape unchanged.

func test_move_toward_prime_keeps_base_displacement() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var prime := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 100.0, "y": 100.0, "edad": 0.0})
	KarmaGame.move_toward(s, prime, 1000.0, 100.0, 1.0, 1.0)
	assert_bool(abs(float(prime["x"]) - (100.0 + float(KarmaData.SPECIES["raton"]["speed"]))) < 0.5).is_true()


func test_move_toward_scales_displacement_by_age() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var prime := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 100.0, "y": 100.0, "edad": 0.0})
	var frail := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 100.0, "y": 100.0, "edad": 140.0})
	KarmaGame.move_toward(s, prime, 1000.0, 100.0, 1.0, 1.0)
	KarmaGame.move_toward(s, frail, 1000.0, 100.0, 1.0, 1.0)
	assert_bool(float(frail["x"]) < float(prime["x"])).is_true()


func test_old_hunter_closes_slower_than_prime() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var prime := KarmaPredators.mk_predator(s, "zorro", 100.0, 100.0, 1)
	var old := KarmaPredators.mk_predator(s, "zorro", 100.0, 100.0, 1)
	old["edad"] = 285.0
	var prey := {"speciesKey": "raton", "x": 1000.0, "y": 100.0, "hp": 60.0}
	KarmaAI.ai_hunt_eat(s, prime, prey, 1.0)
	KarmaAI.ai_hunt_eat(s, old, prey, 1.0)
	assert_bool(float(old["x"]) < float(prime["x"])).is_true()


func test_gait_envelope_is_age_independent() -> void:
	# Aging changes displacement magnitude, never the gait envelope: grounded
	# halcon stays at half speed and continuous gait stays at one.
	assert_bool(abs(KarmaGame.loco_mult("halcon", true, 3.0) - 0.5) < 0.01).is_true()
	assert_bool(abs(KarmaGame.loco_mult("raton", false, 3.0) - 1.0) < 0.01).is_true()


# Age-aware micro reflexes: frail hides earlier, biases to cover, and scavenges
# over unwinnable hunts when carrion is perceived.

func _first_kind(a: Dictionary) -> String:
	return str(((a.get("jev_intent", {}) as Dictionary).get("kind", "")))


func test_frail_prey_senses_fear_at_longer_range() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var prime := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 500.0, "y": 500.0, "edad": 0.0})
	var frail := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 500.0, "y": 500.0, "edad": 140.0})
	(s["agents"] as Array).append(prime)
	(s["agents"] as Array).append(frail)
	var hunter := KarmaPredators.mk_predator(s, "zorro", 760.0, 500.0, 1)
	(s["agents"] as Array).append(hunter)
	assert_bool(float(KarmaData.TUNING["aiFearRange"]) < 260.0).is_true()
	assert_bool(float(KarmaData.TUNING["aiFearRange"]) * float(KarmaData.TUNING["frailFearMult"]) > 260.0).is_true()
	assert_bool((s["agents"] as Array).has(hunter)).is_true()
	assert_bool(KarmaAI.is_hunted(s, prime)).is_false()
	assert_bool(KarmaAI.is_hunted(s, frail)).is_true()


func test_frail_flee_biases_harder_to_cover() -> void:
	var prime_frac := _flee_upward_fraction(0.0)
	var frail_frac := _flee_upward_fraction(285.0)
	assert_bool(frail_frac > prime_frac + 0.1).is_true()


func _flee_upward_fraction(edad: float) -> float:
	var s := KarmaState.blank_state("zorro", 0.0, 0.0)
	var z := KarmaState.mk_agent({"role": "company", "speciesKey": "zorro", "x": 500.0, "y": 500.0, "edad": edad})
	(s["agents"] as Array).append(z)
	(s["agents"] as Array).append(KarmaPredators.mk_predator(s, "lobo", 600.0, 500.0, 1))
	(s["refuges"] as Array).append({"x": 500.0, "y": 400.0, "maxSize": 4})
	var x0 := float(z["x"])
	var y0 := float(z["y"])
	assert_bool(KarmaAI.ai_flee(s, z, 1.0)).is_true()
	var d := Vector2(float(z["x"]) - x0, float(z["y"]) - y0)
	if d.length() == 0.0:
		return 0.0
	return absf(d.y) / d.length()


func test_frail_zorro_scavenges_instead_of_hunting() -> void:
	var t := _scavenge_scene("zorro", 285.0, float(KarmaData.SPECIES["zorro"]["maxHp"]))
	var kinds := _menu_kinds(KarmaJevZorro.build_menu(t[0], t[1]))
	assert_bool(kinds.has("hunt")).is_false()
	assert_bool(kinds.has("pounce")).is_false()
	assert_bool(kinds.has("seek_carrion")).is_true()


func test_prime_zorro_still_hunts_live_prey() -> void:
	var t := _scavenge_scene("zorro", 0.0, float(KarmaData.SPECIES["zorro"]["maxHp"]))
	var kinds := _menu_kinds(KarmaJevZorro.build_menu(t[0], t[1]))
	assert_bool(kinds.has("hunt")).is_true()
	assert_bool(kinds.has("seek_carrion")).is_false()


func test_prime_lobo_still_hunts_live_prey() -> void:
	var t := _scavenge_scene("lobo", 0.0, float(KarmaData.SPECIES["lobo"]["maxHp"]))
	var kinds := _menu_kinds(KarmaJevLobo.build_menu(t[0], t[1]))
	assert_bool(kinds.has("hunt")).is_true()
	assert_bool(kinds.has("seek_carrion")).is_false()


func test_weak_lobo_scavenges_instead_of_hunting() -> void:
	var t := _scavenge_scene("lobo", 0.0, 1.0)
	var kinds := _menu_kinds(KarmaJevLobo.build_menu(t[0], t[1]))
	assert_bool(kinds.has("hunt")).is_false()
	assert_bool(kinds.has("seek_carrion")).is_true()


func test_weak_lobo_mock_seeks_carrion_not_hunt() -> void:
	var t := _scavenge_scene("lobo", 0.0, 1.0)
	var s: Dictionary = t[0]
	var a: Dictionary = t[1]
	assert_bool(KarmaJevLobo.mock_macro(s, a)).is_true()
	assert_str(_first_kind(a)).is_equal("seek_carrion")


func _scavenge_scene(species: String, edad: float, hp: float) -> Array:
	var s := KarmaState.blank_state(species, 0.0, 0.0)
	var a := KarmaState.mk_agent({"role": "fauna", "speciesKey": species, "x": 500.0, "y": 500.0, "hp": hp, "edad": edad})
	(s["agents"] as Array).append(a)
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 560.0, "y": 500.0}))
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "halcon", "x": 560.0, "y": 560.0}))
	(s["carrions"] as Array).append({"x": 500.0, "y": 600.0})
	return [s, a]


func _menu_kinds(menu: Array) -> Array:
	var kinds: Array = []
	for c in menu:
		kinds.append(str((c as Dictionary)["kind"]))
	return kinds


# Age signals ride every species JEV snapshot and state text; wander stays.

func test_raton_state_text_carries_own_and_hunter_stage() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	var frail := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "x": 500.0, "y": 500.0, "edad": 140.0})
	(s["agents"] as Array).append(frail)
	(s["agents"] as Array).append(KarmaPredators.mk_predator(s, "zorro", 600.0, 500.0, 1))
	var text := KarmaJevRaton.state_text(s, frail)
	assert_bool(text.contains("stage=frail")).is_true()
	assert_bool(text.contains("threat_stage=prime")).is_true()


func test_zorro_snapshot_carries_prey_stage() -> void:
	var t := _scavenge_scene("zorro", 0.0, float(KarmaData.SPECIES["zorro"]["maxHp"]))
	var snap := KarmaJevZorro.build_state(t[0], t[1])
	assert_str(str(snap["prey_stage"])).is_equal("prime")


func test_every_species_snapshot_carries_age_signals() -> void:
	for sp in ["oruga", "sapo", "raton", "ardilla", "topo", "zorro", "lobo", "halcon"]:
		var s := KarmaState.blank_state(sp, 0.0, 0.0)
		var a := KarmaState.mk_agent({"role": "company", "speciesKey": sp, "x": 500.0, "y": 500.0, "edad": 0.0})
		(s["agents"] as Array).append(a)
		var snap := _snapshot_for(sp, s, a)
		for key in ["stage", "force", "frailty", "threat_stage", "prey_stage"]:
			assert_bool(snap.has(key)).is_true()
		assert_bool(KarmaJev.age_text(snap).contains("stage=prime")).is_true()


func test_age_signals_keep_wander_fallback() -> void:
	var t := _scavenge_scene("lobo", 0.0, 1.0)
	assert_bool(_menu_kinds(KarmaJevLobo.build_menu(t[0], t[1])).has("wander")).is_true()


func _snapshot_for(sp: String, s: Dictionary, a: Dictionary) -> Dictionary:
	match sp:
		"oruga": return KarmaJevOruga.build_state(s, a)
		"sapo": return KarmaJevSapo.build_state(s, a)
		"raton": return KarmaJevRaton.build_state(s, a)
		"ardilla": return KarmaJevArdilla.build_state(s, a)
		"topo": return KarmaJevTopo.build_state(s, a)
		"zorro": return KarmaJevZorro.build_state(s, a)
		"lobo": return KarmaJevLobo.build_state(s, a)
		"halcon": return KarmaJevHalcon.build_halcon_state(s, a)
	return {}

