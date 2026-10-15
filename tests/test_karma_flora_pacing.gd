extends GdUnitTestSuite

# Kind-paced flora renewal: per-kind regrow table + derived seedling clock.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 4242


func test_kind_paced_tuning_table() -> void:
	var table: Dictionary = KarmaData.TUNING.get("fruitRegrowByKind", {})
	assert_float(float(table.get("berries", -1.0))).is_equal(20.0)
	assert_float(float(table.get("carrots", -1.0))).is_equal(25.0)
	assert_float(float(table.get("leaves", -1.0))).is_equal(30.0)
	assert_float(float(table.get("mushrooms", -1.0))).is_equal(30.0)
	assert_float(float(table.get("apples", -1.0))).is_equal(35.0)
	assert_float(float(table.get("nuts", -1.0))).is_equal(45.0)
	assert_float(float(KarmaData.TUNING.get("seedlingMult", -1.0))).is_equal(2.0)


func test_apple_full_load_is_two() -> void:
	assert_int(int(KarmaGame.FRUIT_CAP.get("apples", -1))).is_equal(2)


func test_berry_regrows_while_oak_waits() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["bushes"] = [KarmaUtils.mk_patch("berries", 100.0, 100.0, 2, {"regrowT": 0.0})]
	s["oaks"] = [KarmaUtils.mk_patch("nuts", 500.0, 500.0, 2, {"regrowT": 0.0})]
	s["shrubs"] = []
	s["patches"] = []
	s["clusters"] = []
	s["clumps"] = []
	s["seedlings"] = []
	KarmaGame.age_world(s, 20.0, _rng)
	assert_int(int((s["bushes"] as Array)[0]["amount"])).is_equal(3)
	assert_int(int((s["oaks"] as Array)[0]["amount"])).is_equal(2)


func test_stripped_bush_revives_and_leaves_share_table() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var dead := KarmaUtils.mk_patch("berries", 100.0, 100.0, 0, {"regrowT": 0.0})
	dead["alive"] = false
	s["bushes"] = [dead]
	s["clumps"] = [KarmaUtils.mk_patch("leaves", 500.0, 500.0, 2, {"regrowT": 0.0})]
	s["shrubs"] = []
	s["patches"] = []
	s["clusters"] = []
	s["oaks"] = []
	s["seedlings"] = []
	KarmaGame.age_world(s, 30.0, _rng)
	var bush: Dictionary = (s["bushes"] as Array)[0]
	assert_bool(bool(bush["alive"])).is_true()
	assert_int(int(bush["amount"])).is_equal(1)
	assert_int(int((s["clumps"] as Array)[0]["amount"])).is_equal(3)


func test_seedlings_mature_on_derived_clock() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["waters"] = []
	s["bushes"] = []
	s["shrubs"] = []
	s["seedlings"] = [{"kind": "berries", "x": 100.0, "y": 100.0, "age": 39.0}]
	KarmaGame.mature_seedlings(s, 1.0, _rng)
	assert_int((s["seedlings"] as Array).size()).is_equal(0)
	assert_int((s["bushes"] as Array).size()).is_equal(1)
	assert_int(int((s["bushes"] as Array)[0]["amount"])).is_equal(3)
	s["seedlings"] = [{"kind": "apples", "x": 200.0, "y": 200.0, "age": 69.0}]
	KarmaGame.mature_seedlings(s, 1.0, _rng)
	assert_int((s["seedlings"] as Array).size()).is_equal(0)
	assert_int((s["shrubs"] as Array).size()).is_equal(1)
	assert_int(int((s["shrubs"] as Array)[0]["amount"])).is_equal(2)


func test_buried_oak_matures_slow_and_bark_rides_nuts_rate() -> void:
	var s := KarmaState.new_run("ardilla", 0.0, 0.0, 0, _rng)
	s["waters"] = []
	s["oaks"] = []
	s["seedlings"] = [{"kind": "oak-tree", "x": 300.0, "y": 300.0, "age": 79.0}]
	KarmaGame.mature_seedlings(s, 1.0, _rng)
	assert_int((s["seedlings"] as Array).size()).is_equal(1)
	assert_int((s["oaks"] as Array).size()).is_equal(0)
	KarmaGame.mature_seedlings(s, 10.0, _rng)
	assert_int((s["seedlings"] as Array).size()).is_equal(0)
	assert_int((s["oaks"] as Array).size()).is_equal(1)
	assert_int(int((s["oaks"] as Array)[0]["amount"])).is_equal(3)
	var oak := KarmaUtils.mk_patch("nuts", float(s["px"]), float(s["py"]), 3)
	(s["oaks"] as Array).append(oak)
	assert_bool(KarmaGame.cast_verb(s, 4)).is_true()
	assert_float(float(oak["stripT"])).is_equal(KarmaGame.regrow_rate_for("nuts"))


func test_fresh_world_seeds_below_cap_for_growth() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var headroom := int(KarmaData.TUNING.get("floraHeadroom", 2))
	assert_int((s["bushes"] as Array).size()).is_equal(KarmaState.flora_cap("berries") - headroom)
	assert_int((s["shrubs"] as Array).size()).is_equal(KarmaState.flora_cap("apples") - headroom)
	assert_int((s["patches"] as Array).size()).is_equal(KarmaState.flora_cap("carrots") - headroom)
	assert_int((s["clusters"] as Array).size()).is_equal(KarmaState.flora_cap("mushrooms") - headroom)
	assert_int((s["oaks"] as Array).size()).is_equal(KarmaState.flora_cap("nuts") - headroom)
	assert_int((s["clumps"] as Array).size()).is_equal(KarmaState.flora_cap("leaves") - headroom)


func test_seedling_matures_in_fresh_world() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["waters"] = []
	var before := (s["bushes"] as Array).size()
	s["seedlings"] = [{"kind": "berries", "x": 100.0, "y": 100.0, "age": 39.0}]
	KarmaGame.mature_seedlings(s, 1.0, _rng)
	assert_int((s["seedlings"] as Array).size()).is_equal(0)
	assert_int((s["bushes"] as Array).size()).is_equal(before + 1)


func test_last_fruit_message_promises_recovery() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var bush: Dictionary = (s["bushes"] as Array)[0]
	bush["amount"] = 1
	bush["alive"] = true
	bush["mimic"] = false
	bush["mimicEaten"] = true
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_true()
	var msg := str((s["feed"] as Array).back())
	assert_bool(msg.contains("para siempre")).is_false()
	assert_bool(msg.contains("volverá a dar fruto")).is_true()


func test_eating_empty_bush_is_refused() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	var bush: Dictionary = (s["bushes"] as Array)[0]
	bush["amount"] = 1
	bush["alive"] = true
	bush["mimic"] = false
	bush["mimicEaten"] = true
	s["hp"] = 10.0
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_true()
	assert_float(float(s["hp"])).is_equal(30.0)
	assert_float(float(s["karma"])).is_equal(-15.0)
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_false()
	assert_bool(KarmaEat.eat_patch(s, bush, null)).is_false()
	assert_int(int(bush["amount"])).is_equal(0)
	assert_float(float(s["hp"])).is_equal(30.0)
	assert_float(float(s["karma"])).is_equal(-15.0)
