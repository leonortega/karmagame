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
