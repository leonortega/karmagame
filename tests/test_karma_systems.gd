extends GdUnitTestSuite

# Systems parity: eat payoffs, carrion lifecycle, predators, verbs, buy.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 99


func _fresh(species := "raton") -> Dictionary:
	return KarmaState.new_run(species, 0.0, 0.0, 0, _rng)


func test_sustainable_eat_pays() -> void:
	var s := _fresh("raton")
	var bush: Dictionary = (s["bushes"] as Array)[0]
	bush["amount"] = 3
	bush["alive"] = true
	bush["mimic"] = false
	s["hp"] = 10.0
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_true()
	assert_float(s["hp"]).is_equal(25.0) # +15 berries
	assert_float(s["pa"]).is_equal(5.0)


func test_last_fruit_selfish() -> void:
	var s := _fresh("raton")
	var bush: Dictionary = (s["bushes"] as Array)[0]
	bush["amount"] = 1
	bush["alive"] = true
	bush["mimic"] = false
	bush["mimicEaten"] = true
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_true()
	assert_float(s["karma"]).is_equal(-15.0)
	assert_bool(bush["alive"]).is_false()


func test_off_diet_refused() -> void:
	var s := _fresh("sapo")
	var bush: Dictionary = (s["bushes"] as Array)[0]
	bush["amount"] = 3
	bush["alive"] = true
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_false()
	assert_int(bush["amount"]).is_equal(3)


func test_carrion_lifecycle() -> void:
	var s := _fresh("zorro")
	KarmaEat.add_carrion(s, 100.0, 100.0)
	assert_int((s["carrions"] as Array).size()).is_equal(1)
	var c: Dictionary = (s["carrions"] as Array)[0]
	assert_str(KarmaEat.carrion_stage(c)).is_equal("fresh")
	c["age"] = 40.0
	assert_str(KarmaEat.carrion_stage(c)).is_equal("stale")
	c["age"] = 70.0
	assert_str(KarmaEat.carrion_stage(c)).is_equal("rotten")


func test_edible_for_chain() -> void:
	assert_bool(KarmaPredators.edible_for("zorro", "raton", 10.0)).is_true()
	assert_bool(KarmaPredators.edible_for("zorro", "lobo", 10.0)).is_false()
	assert_bool(KarmaPredators.edible_for("lobo", "zorro", 10.0)).is_false() # lobo hunts tiers [2] via zorro rule, not edible_for
	assert_bool(KarmaPredators.edible_for("saponpc", "oruga", 10.0)).is_true()
	assert_bool(KarmaPredators.edible_for("saponpc", "raton", 10.0)).is_false()


func test_buy_rejects_debt_and_stacking() -> void:
	var s := _fresh("sapo")
	s["pa"] = 10.0
	assert_bool(KarmaShop.buy_item(s, s, "sapo_lengua").is_empty()).is_true()
	s["pa"] = 100.0
	var item := KarmaShop.buy_item(s, s, "sapo_lengua")
	assert_bool(item.is_empty()).is_false()
	assert_float(s["pa"]).is_equal(30.0)
	assert_bool(KarmaShop.buy_item(s, s, "sapo_lengua").is_empty()).is_true()


func test_cast_verb_cooldown_and_cost() -> void:
	var s := _fresh("topo")
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": float(s["px"]) + 5.0, "y": float(s["py"]), "dug": true})
	assert_bool(KarmaGame.cast_verb(s, 2)).is_true() # tunneline refuerza
	assert_float((s["verbCds"] as Array)[1]).is_equal(25.0)
	assert_bool(KarmaGame.cast_verb(s, 2)).is_false() # on cooldown


func test_karma_sight_mult() -> void:
	assert_bool(abs(KarmaAI.karma_sight_mult(50.0) - 0.8) < 0.001).is_true()
	assert_bool(abs(KarmaAI.karma_sight_mult(-50.0) - 1.2) < 0.001).is_true()
	assert_float(KarmaAI.karma_sight_mult(0.0)).is_equal(1.0)


func test_draw_lookups() -> void:
	assert_str(KarmaDraw.species_icon("lobo")).is_equal("🐺")
	assert_str(KarmaDraw.food_icon("berries")).is_equal("🍒")
	assert_float(KarmaDraw.animal_emoji_size("lobo")).is_equal(34.0)
	assert_str(KarmaDraw.carrion_look("rotten")["label"]).is_equal("¡podrida: -25!")


func test_seek_water_treks_beyond_scout_range() -> void:
	var s := _fresh("raton")
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	s["waters"] = [{"x": 2000.0, "y": 500.0, "r": 20.0, "kind": "charco"}]
	var x0 := float(a["x"])
	assert_bool(KarmaAI.ai_seek_water(s, a, 0.1)).is_true()
	assert_bool(float(a["x"]) > x0).is_true()


func test_seek_water_fails_with_no_water() -> void:
	var s := _fresh("raton")
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	s["waters"] = []
	assert_bool(KarmaAI.ai_seek_water(s, a, 0.1)).is_false()


func test_agents_cannot_leave_world() -> void:
	var s := _fresh("raton")
	var a := KarmaState.spawn_fauna(s, "raton", -50.0, -30.0)
	var h := KarmaPredators.mk_predator(s, "zorro", float(KarmaData.WORLD["w"]) + 100.0, float(KarmaData.WORLD["h"]) + 100.0, 1)
	(s["agents"] as Array).append(h)
	KarmaGame.update(s, 0.1, _rng)
	assert_bool(float(a["x"]) >= 20.0).is_true()
	assert_bool(float(a["y"]) >= 20.0).is_true()
	assert_bool(float(h["x"]) <= float(KarmaData.WORLD["w"]) - 20.0).is_true()
	assert_bool(float(h["y"]) <= float(KarmaData.WORLD["h"]) - 20.0).is_true()


func _poi_world() -> Dictionary:
	var s := _fresh("raton")
	for list in ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks"]:
		s[list] = []
	s["waters"] = []
	s["refuges"] = []
	s["agents"] = (s["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "company")
	return s


func test_wander_poi_prefers_food_over_water() -> void:
	var s := _poi_world()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 800.0, 500.0, 3))
	(s["waters"] as Array).append({"x": 510.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	var poi: Variant = KarmaGame.wander_poi(s, a)
	assert_bool(poi != null).is_true()
	assert_float(float((poi as Dictionary)["x"])).is_equal(800.0)
	assert_float(float((poi as Dictionary)["y"])).is_equal(500.0)


func test_wander_poi_falls_back_to_water() -> void:
	var s := _poi_world()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	(s["waters"] as Array).append({"x": 600.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	var poi: Variant = KarmaGame.wander_poi(s, a)
	assert_bool(poi != null).is_true()
	assert_float(float((poi as Dictionary)["x"])).is_equal(600.0)


func test_wander_poi_falls_back_to_cover() -> void:
	var s := _poi_world()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	(s["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": 550.0, "y": 500.0, "dug": false})
	var poi: Variant = KarmaGame.wander_poi(s, a)
	assert_bool(poi != null).is_true()
	assert_float(float((poi as Dictionary)["x"])).is_equal(550.0)


func test_wander_poi_falls_back_to_company() -> void:
	var s := _poi_world()
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	(s["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 520.0, "y": 500.0}))
	var poi: Variant = KarmaGame.wander_poi(s, a)
	assert_bool(poi != null).is_true()
	assert_float(float((poi as Dictionary)["x"])).is_equal(520.0)


func test_wander_poi_null_when_world_empty() -> void:
	var s := _poi_world()
	s["agents"] = []
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	s["agents"] = (s["agents"] as Array).filter(func(o): return o == a)
	assert_bool(KarmaGame.wander_poi(s, a) == null).is_true()


func test_wander_poi_carnivore_seeks_carrion() -> void:
	var s := _poi_world()
	var a := KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	KarmaEat.add_carrion(s, 700.0, 500.0)
	var c: Dictionary = (s["carrions"] as Array)[0]
	var poi: Variant = KarmaGame.wander_poi(s, a)
	assert_bool(poi != null).is_true()
	assert_float(float((poi as Dictionary)["x"])).is_equal(float(c["x"]))


func _bare_world(species := "raton") -> Dictionary:
	var s := _fresh(species)
	for list in ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks"]:
		s[list] = []
	s["waters"] = []
	s["refuges"] = []
	s["insects"] = []
	s["agents"] = []
	return s


func _trek_distance(s: Dictionary, a: Dictionary, tx: float, ty: float) -> float:
	return Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(tx, ty))


func test_raton_wander_travels_to_distant_patch() -> void:
	var s := _bare_world("raton")
	var a := KarmaState.spawn_fauna(s, "raton", 500.0, 500.0)
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 800.0, 500.0, 3))
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 30.0}
	var d0 := _trek_distance(s, a, 800.0, 500.0)
	for i in 10:
		KarmaAI._ai_raton(s, a, 0.1)
	assert_bool(d0 - _trek_distance(s, a, 800.0, 500.0) > 50.0).is_true()


func test_zorro_wander_travels_to_water() -> void:
	var s := _bare_world("zorro")
	var a := KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["pounceCd"] = 0.0
	a["strikeCd"] = 0.0
	(s["waters"] as Array).append({"x": 800.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 30.0}
	var d0 := _trek_distance(s, a, 800.0, 500.0)
	for i in 10:
		KarmaAI._ai_zorro(s, a, 0.1)
	assert_bool(d0 - _trek_distance(s, a, 800.0, 500.0) > 50.0).is_true()


func test_halcon_wander_travels_to_water() -> void:
	var s := _bare_world("halcon")
	var a := KarmaState.spawn_fauna(s, "halcon", 500.0, 500.0)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["strikeCd"] = 0.0
	a["grounded"] = false
	a["landT"] = 0.0
	(s["waters"] as Array).append({"x": 800.0, "y": 500.0, "r": 20.0, "kind": "charco"})
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 30.0}
	var d0 := _trek_distance(s, a, 800.0, 500.0)
	for i in 10:
		KarmaAI._ai_halcon(s, a, 0.1)
	assert_bool(d0 - _trek_distance(s, a, 800.0, 500.0) > 50.0).is_true()


func test_ardilla_wander_travels_to_distant_patch() -> void:
	var s := _bare_world("ardilla")
	var a := KarmaState.spawn_fauna(s, "ardilla", 500.0, 500.0)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	(s["bushes"] as Array).append(KarmaUtils.mk_patch("berries", 800.0, 500.0, 3))
	a["jev_intent"] = {"kind": "wander", "x": 500.0, "y": 500.0, "ttl": 30.0}
	var d0 := _trek_distance(s, a, 800.0, 500.0)
	for i in 10:
		KarmaAI._ai_ardilla(s, a, 0.1)
	assert_bool(d0 - _trek_distance(s, a, 800.0, 500.0) > 50.0).is_true()


func test_topo_ladder_wander_travels_to_distant_patch() -> void:
	var s := _bare_world("topo")
	var a := KarmaState.spawn_fauna(s, "topo", 500.0, 500.0)
	a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	a["digCd"] = float(KarmaData.TUNING["digCd"])
	(s["patches"] as Array).append(KarmaUtils.mk_patch("carrots", 800.0, 500.0, 3))
	var d0 := _trek_distance(s, a, 800.0, 500.0)
	for i in 10:
		KarmaAI._ai_topo(s, a, 0.1)
	assert_bool(d0 - _trek_distance(s, a, 800.0, 500.0) > 50.0).is_true()


func test_mates_drift_toward_player() -> void:
	var s := _bare_world("raton")
	var m := KarmaState.mk_agent({"role": "company", "speciesKey": "raton", "hp": 100.0, "x": 500.0, "y": 500.0})
	(s["agents"] as Array).append(m)
	var d0 := Vector2(500.0, 500.0).distance_to(Vector2(float(s["px"]), float(s["py"])))
	for i in 10:
		KarmaGame.wander_mates(s, 0.1, _rng)
	var d1 := Vector2(float(m["x"]), float(m["y"])).distance_to(Vector2(float(s["px"]), float(s["py"])))
	assert_bool(d0 - d1 > 50.0).is_true()
