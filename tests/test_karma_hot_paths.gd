extends GdUnitTestSuite

# Characterization for the optimize-hot-paths refactor: every test pins a
# decision the later squared-distance, dedup, and allocation changes must
# preserve. One behavior per test.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 20261020


func _state(species := "raton") -> Dictionary:
	return KarmaState.blank_state(species, 0.0, 0.0)


func _pt(x: float, y: float) -> Dictionary:
	return {"x": x, "y": y}


# 1.1 nearest_from / nearest_hunter_in_fears.

func test_nearest_from_returns_closest_in_range() -> void:
	var near := _pt(510.0, 500.0)
	var far := _pt(540.0, 500.0)
	var hit: Variant = KarmaUtils.nearest_from(500.0, 500.0, [far, near], 100.0)
	assert_bool(hit == near).is_true()


func test_nearest_from_returns_null_out_of_range() -> void:
	var hit: Variant = KarmaUtils.nearest_from(500.0, 500.0, [_pt(560.0, 500.0)], 50.0)
	assert_bool(hit == null).is_true()


func test_nearest_from_equal_distance_keeps_first_listed() -> void:
	var first := _pt(490.0, 500.0)
	var second := _pt(510.0, 500.0)
	var hit: Variant = KarmaUtils.nearest_from(500.0, 500.0, [first, second], 100.0)
	assert_bool(hit == first).is_true()


func test_nearest_hunter_in_fears_filters_by_species() -> void:
	var wanted := {"speciesKey": "lobo", "x": 520.0, "y": 500.0}
	var wrong_species := {"speciesKey": "zorro", "x": 505.0, "y": 500.0}
	var hit: Variant = KarmaUtils.nearest_hunter_in_fears(
		500.0, 500.0, [wrong_species, wanted], ["lobo"], 100.0)
	assert_bool(hit == wanted).is_true()


func test_nearest_hunter_in_fears_returns_null_out_of_range() -> void:
	var hunter := {"speciesKey": "lobo", "x": 560.0, "y": 500.0}
	var hit: Variant = KarmaUtils.nearest_hunter_in_fears(500.0, 500.0, [hunter], ["lobo"], 50.0)
	assert_bool(hit == null).is_true()


func test_nearest_hunter_in_fears_equal_distance_keeps_first_listed() -> void:
	var first := {"speciesKey": "lobo", "x": 490.0, "y": 500.0}
	var second := {"speciesKey": "lobo", "x": 510.0, "y": 500.0}
	var hit: Variant = KarmaUtils.nearest_hunter_in_fears(
		500.0, 500.0, [first, second], ["lobo"], 100.0)
	assert_bool(hit == first).is_true()


# 1.2 nearest_water_for / inside_water / los_blocked.

func test_nearest_water_for_measures_to_surface() -> void:
	var s := _state()
	var lake := {"kind": "lago", "x": 540.0, "y": 500.0, "r": 20.0, "level": 10.0}
	s["waters"] = [lake]
	var hit: Variant = KarmaUtils.nearest_water_for(s, 500.0, 500.0, 25.0)
	assert_bool(hit == lake).is_true()


func test_nearest_water_for_misses_when_surface_is_beyond_range() -> void:
	var s := _state()
	s["waters"] = [{"kind": "lago", "x": 540.0, "y": 500.0, "r": 20.0, "level": 10.0}]
	assert_bool(KarmaUtils.nearest_water_for(s, 500.0, 500.0, 20.0) == null).is_true()


func test_inside_water_boundary_is_strict() -> void:
	var s := _state()
	s["waters"] = [{"kind": "charco", "x": 500.0, "y": 500.0, "r": 20.0, "level": 10.0}]
	assert_bool(KarmaUtils.inside_water(s, 520.0, 500.0)).is_false()
	assert_bool(KarmaUtils.inside_water(s, 519.9, 500.0)).is_true()


func test_inside_water_margin_extends_boundary() -> void:
	var s := _state()
	s["waters"] = [{"kind": "charco", "x": 500.0, "y": 500.0, "r": 20.0, "level": 10.0}]
	assert_bool(KarmaUtils.inside_water(s, 525.0, 500.0, 5.0)).is_false()
	assert_bool(KarmaUtils.inside_water(s, 524.9, 500.0, 5.0)).is_true()


func test_los_blocked_when_a_sample_falls_inside_solid() -> void:
	var s := _state()
	var solids := [{"x": 500.0, "y": 500.0, "r": float(KarmaData.TUNING["solidRefuge"])}]
	assert_bool(KarmaUtils.los_blocked(s, 400.0, 500.0, 600.0, 500.0, false, solids)).is_true()


func test_los_unblocked_when_line_is_clear() -> void:
	var s := _state()
	var solids := [{"x": 500.0, "y": 500.0, "r": float(KarmaData.TUNING["solidRefuge"])}]
	assert_bool(KarmaUtils.los_blocked(s, 400.0, 300.0, 600.0, 300.0, false, solids)).is_false()


func test_los_flying_ignores_solids() -> void:
	var s := _state()
	var solids := [{"x": 500.0, "y": 500.0, "r": float(KarmaData.TUNING["solidRefuge"])}]
	assert_bool(KarmaUtils.los_blocked(s, 400.0, 500.0, 600.0, 500.0, true, solids)).is_false()


# 1.3 resolve_collisions.

func test_resolve_collisions_pushes_solid_hit_to_surface() -> void:
	var s := _state()
	var solids := [{"x": 500.0, "y": 500.0, "r": 16.0}]
	var out: Vector2 = KarmaUtils.resolve_collisions(s, Vector2(505.0, 500.0), 10.0, false, false, solids)
	assert_vector(out).is_equal(Vector2(526.0, 500.0))


func test_resolve_collisions_leaves_near_miss_untouched() -> void:
	var s := _state()
	var solids := [{"x": 500.0, "y": 500.0, "r": 16.0}]
	var out: Vector2 = KarmaUtils.resolve_collisions(s, Vector2(530.0, 500.0), 10.0, false, false, solids)
	assert_vector(out).is_equal(Vector2(530.0, 500.0))


# 1.4 wander_mates movement with multiple mates and hunters.

func _mate(s: Dictionary, x: float, y: float, saved := false) -> Dictionary:
	var m := KarmaState.mk_agent({"speciesKey": "raton", "x": x, "y": y, "saved": saved})
	(s["agents"] as Array).append(m)
	return m


func _hunter(s: Dictionary, x: float, y: float) -> Dictionary:
	var h := KarmaPredators.mk_predator(s, "zorro", x, y, 1)
	(s["agents"] as Array).append(h)
	return h


func test_wander_mates_moves_toward_player_and_flees_when_saved() -> void:
	var s := _state()
	KarmaState.player(s)["x"] = 100.0
	KarmaState.player(s)["y"] = 100.0
	var near := _mate(s, 300.0, 100.0)
	var diagonal := _mate(s, 500.0, 400.0)
	var saved := _mate(s, 500.0, 500.0, true)
	_hunter(s, 520.0, 500.0)
	_hunter(s, 1000.0, 1000.0)

	KarmaGame.wander_mates(s, 0.1, _rng)

	assert_float(float(near["x"])).is_equal_approx(281.0, 0.0001)
	assert_float(float(near["y"])).is_equal_approx(100.0, 0.0001)
	assert_float(float(diagonal["x"])).is_equal_approx(484.8, 0.0001)
	assert_float(float(diagonal["y"])).is_equal_approx(388.6, 0.0001)
	assert_float(float(saved["x"])).is_equal_approx(491.0, 0.0001)
	assert_float(float(saved["y"])).is_equal_approx(500.0, 0.0001)


# 1.5 Cooldown parity (player dictionary + agent dictionary + verbCds arrays).

func test_player_tick_decrements_cooldowns_and_verb_slots() -> void:
	var s := _state()
	KarmaState.player(s)["shoutCd"] = 1.0
	KarmaState.player(s)["strikeCd"] = 0.05
	KarmaState.player(s)["verbCds"] = [1.0, 0.0, 2.0, 0.0, 0.0]

	KarmaGame.update(s, 0.1, _rng)

	assert_float(float(KarmaState.player(s)["shoutCd"])).is_equal_approx(0.9, 0.0001)
	assert_float(float(KarmaState.player(s)["strikeCd"])).is_equal_approx(-0.05, 0.0001)
	var cds: Array = KarmaState.player(s)["verbCds"]
	assert_float(float(cds[0])).is_equal_approx(0.9, 0.0001)
	assert_float(float(cds[1])).is_equal_approx(0.0, 0.0001)
	assert_float(float(cds[2])).is_equal_approx(1.9, 0.0001)


func test_agent_base_decrements_cooldowns_and_verb_slots() -> void:
	var s := _state()
	var a := KarmaState.mk_agent({"speciesKey": "raton", "x": 500.0, "y": 500.0})
	a["shoutCd"] = 1.0
	a["pounceCd"] = 0.5
	a["buyT"] = 100.0
	a["lureTimer"] = 0.0
	a["verbCds"] = [1.0, 0.0, 2.0, 0.0, 0.0]

	KarmaAI.ai_base(s, a, 0.1)

	assert_float(float(a["shoutCd"])).is_equal_approx(0.9, 0.0001)
	assert_float(float(a["pounceCd"])).is_equal_approx(0.4, 0.0001)
	var cds: Array = a["verbCds"]
	assert_float(float(cds[0])).is_equal_approx(0.9, 0.0001)
	assert_float(float(cds[1])).is_equal_approx(0.0, 0.0001)
	assert_float(float(cds[2])).is_equal_approx(1.9, 0.0001)


# 1.6 cast_verb / cast_verb_for: success, cooldown rejection, insufficient PA.

func test_player_cast_verb_success_pays_hp_and_sets_cooldown() -> void:
	var s := _state("topo")
	var before_pa: float = float(s["pa"])
	assert_bool(KarmaGame.cast_verb(s, 5)).is_true()
	assert_float(float(KarmaState.player(s)["hp"])).is_equal(float(KarmaData.SPECIES["topo"]["maxHp"]) - 10.0)
	assert_float(float(s["pa"])).is_equal(before_pa)
	assert_float(float((KarmaState.player(s)["verbCds"] as Array)[4])).is_equal(30.0)


func test_player_cast_verb_rejects_active_cooldown() -> void:
	var s := _state("topo")
	var before_hp: float = float(KarmaState.player(s)["hp"])
	(KarmaState.player(s)["verbCds"] as Array)[4] = 5.0
	assert_bool(KarmaGame.cast_verb(s, 5)).is_false()
	assert_float(float(KarmaState.player(s)["hp"])).is_equal(before_hp)
	assert_float(float((KarmaState.player(s)["verbCds"] as Array)[4])).is_equal(5.0)


func test_player_cast_verb_rejects_insufficient_pa() -> void:
	var s := _state("raton")
	s["pa"] = 0.0
	assert_bool(KarmaGame.cast_verb(s, 4)).is_false()
	assert_float(float((KarmaState.player(s)["verbCds"] as Array)[3])).is_equal(0.0)


func test_agent_cast_verb_success_pays_hp_and_sets_cooldown() -> void:
	var s := _state()
	var a := KarmaState.mk_agent({"speciesKey": "topo", "x": 500.0, "y": 500.0, "hp": 50.0, "pa": 0.0})
	assert_bool(KarmaGame.cast_verb_for(s, a, 5)).is_true()
	assert_float(float(a["hp"])).is_equal(40.0)
	assert_float(float(a["pa"])).is_equal(0.0)
	assert_float(float((a["verbCds"] as Array)[4])).is_equal(30.0)


func test_agent_cast_verb_rejects_active_cooldown() -> void:
	var s := _state()
	var a := KarmaState.mk_agent({"speciesKey": "topo", "x": 500.0, "y": 500.0, "hp": 50.0, "pa": 0.0})
	(a["verbCds"] as Array)[4] = 5.0
	assert_bool(KarmaGame.cast_verb_for(s, a, 5)).is_false()
	assert_float(float(a["hp"])).is_equal(50.0)
	assert_float(float((a["verbCds"] as Array)[4])).is_equal(5.0)


func test_agent_cast_verb_rejects_insufficient_pa() -> void:
	var s := _state()
	var a := KarmaState.mk_agent({"speciesKey": "raton", "x": 500.0, "y": 500.0, "pa": 5.0})
	assert_bool(KarmaGame.cast_verb_for(s, a, 4)).is_false()
	assert_float(float((a["verbCds"] as Array)[3])).is_equal(0.0)


# 1.7 effective max HP, flora tie order, fresh camera per state.

func test_eff_max_hp_for_without_stomach_matches_species_base() -> void:
	var a := {"speciesKey": "raton"}
	assert_float(KarmaState.eff_max_hp_for(a)).is_equal(float(KarmaData.SPECIES["raton"]["maxHp"]))


func test_eff_max_hp_for_with_stomach_adds_adapt_bonus() -> void:
	var a := {"speciesKey": "raton", "owned": {"stomach": true}}
	assert_float(KarmaState.eff_max_hp_for(a)).is_equal(125.0)


func test_edible_patch_equal_distance_keeps_category_order() -> void:
	var s := _state("raton")
	var bush := KarmaUtils.mk_patch("berries", 500.0, 495.0, 3)
	var oak := KarmaUtils.mk_patch("nuts", 500.0, 505.0, 3)
	s["bushes"] = [bush]
	s["oaks"] = [oak]
	var who := {"speciesKey": "raton", "x": 500.0, "y": 500.0}
	var hit: Variant = KarmaEat.nearest_edible_patch_for(s, who, 100.0)
	assert_bool(hit == bush).is_true()


func test_blank_state_camera_is_fresh_per_state() -> void:
	var first := _state()
	var second := _state()
	(KarmaState.player(first)["cam"] as Dictionary)["x"] = 42.0
	assert_float(float((KarmaState.player(second)["cam"] as Dictionary)["x"])).is_equal(0.0)
	assert_bool(KarmaState.player(first)["cam"] == KarmaState.player(second)["cam"]).is_false()


# 2.1 nearest_hunter: species trophic data, exclusion, tie order.

func test_nearest_hunter_finds_predator() -> void:
	var s := _state()
	var hunter := _hunter(s, 520.0, 500.0)
	var hit: Variant = KarmaState.nearest_hunter(500.0, 500.0, s, 100.0)
	assert_bool(hit == hunter).is_true()


func test_nearest_hunter_ignores_prey_species() -> void:
	var s := _state()
	_mate(s, 501.0, 500.0)
	assert_bool(KarmaState.nearest_hunter(500.0, 500.0, s, 100.0) == null).is_true()


func test_nearest_hunter_finds_fauna_carnivore_by_species() -> void:
	var s := _state()
	var carnivore := KarmaState.spawn_fauna(s, "zorro", 510.0, 500.0)
	var hit: Variant = KarmaState.nearest_hunter(500.0, 500.0, s, 100.0)
	assert_bool(hit == carnivore).is_true()


func test_nearest_hunter_exclude_skips_the_given_agent() -> void:
	var s := _state()
	var hunter := _hunter(s, 510.0, 500.0)
	var hit: Variant = KarmaState.nearest_hunter(500.0, 500.0, s, 100.0, hunter)
	assert_bool(hit == null).is_true()


func test_nearest_hunter_equal_distance_keeps_first_listed() -> void:
	var s := _state()
	var first := _hunter(s, 490.0, 500.0)
	_hunter(s, 510.0, 500.0)
	var hit: Variant = KarmaState.nearest_hunter(500.0, 500.0, s, 100.0)
	assert_bool(hit == first).is_true()


# 2.2 nearest_company.

func test_nearest_company_finds_closest_company_agent() -> void:
	var s := _state()
	_mate(s, 540.0, 500.0)
	var near := _mate(s, 520.0, 500.0)
	var hit: Variant = KarmaState.nearest_company(500.0, 500.0, s, 100.0)
	assert_bool(hit == near).is_true()


func test_nearest_company_ignores_hunters() -> void:
	var s := _state()
	_hunter(s, 501.0, 500.0)
	assert_bool(KarmaState.nearest_company(500.0, 500.0, s, 100.0) == null).is_true()


func test_nearest_company_returns_null_out_of_range() -> void:
	var s := _state()
	_mate(s, 560.0, 500.0)
	assert_bool(KarmaState.nearest_company(500.0, 500.0, s, 50.0) == null).is_true()


# 2.3 dist2.

func test_dist2_is_the_squared_distance() -> void:
	assert_float(KarmaUtils.dist2(0.0, 0.0, 3.0, 4.0)).is_equal(25.0)


# 2.4 live_jev_intent.

func test_live_jev_intent_returns_null_without_intent() -> void:
	var a := {"speciesKey": "raton"}
	assert_bool(KarmaAI.live_jev_intent(a) == null).is_true()


func test_live_jev_intent_clears_expired_intent() -> void:
	var a := {"speciesKey": "raton", "jev_intent": {"kind": "wander", "ttl": 0.0}}
	assert_bool(KarmaAI.live_jev_intent(a) == null).is_true()
	assert_bool((a["jev_intent"] as Dictionary).is_empty()).is_true()


func test_live_jev_intent_returns_live_intent() -> void:
	var a := {"speciesKey": "raton", "jev_intent": {"kind": "eat", "ttl": 5.0}}
	var intent: Variant = KarmaAI.live_jev_intent(a)
	assert_bool(intent == null).is_false()
	assert_str(str((intent as Dictionary)["kind"])).is_equal("eat")


# 2.5 shop adapt effect lookup.

func test_adapt_effect_maps_item_id_to_effect() -> void:
	assert_str(KarmaShop.adapt_effect("sapo_lengua")).is_equal("tonguePlus")


func test_adapt_effect_returns_item_id_when_unknown() -> void:
	assert_str(KarmaShop.adapt_effect("not_an_item")).is_equal("not_an_item")
