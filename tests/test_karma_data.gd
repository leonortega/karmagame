extends GdUnitTestSuite

# Parity with node:test diet/tuning/shop tables.


func test_species_table() -> void:
	assert_int(KarmaData.SPECIES.size()).is_equal(8)
	assert_float(KarmaData.SPECIES["lobo"]["maxHp"]).is_equal(160.0)
	assert_int(KarmaData.SPECIES["oruga"]["tier"]).is_equal(0)
	assert_int(KarmaData.SPECIES["lobo"]["tier"]).is_equal(2)


func test_diet_matrix() -> void:
	assert_array(KarmaData.DIET["oruga"]).is_equal(["leaves"])
	assert_bool((KarmaData.DIET["raton"] as Array).has("berries")).is_true()
	assert_bool((KarmaData.DIET["sapo"] as Array).has("berries")).is_false()
	assert_bool((KarmaData.DIET["zorro"] as Array).has("carrion")).is_true()


func test_tuning_anchor_lobo_30min() -> void:
	# Lobo starves in ~30 min below threshold: rate * time == maxHp.
	var rate: float = KarmaData.TUNING["hungerPerSec"] * float(KarmaData.SPECIES["lobo"]["hungerMult"])
	assert_bool(abs(rate * 1800.0 - 160.0) < 0.5).is_true()
	assert_float(KarmaData.TUNING["vidaRegenPerSec"]).is_equal(float(KarmaData.TUNING["hungerPerSec"]) * 2.0)


func test_shop_catalogs() -> void:
	for k in KarmaData.SPECIES:
		assert_int(KarmaShop.catalog_for(k).size()).is_equal(3)
	var sapo := KarmaShop.catalog_for("sapo")
	assert_str(sapo[0]["effect"]).is_equal("tonguePlus")


func test_pool_judge_rules() -> void:
	assert_array(KarmaShop.pool_for(-60.0)).is_equal(["oruga"])
	assert_array(KarmaShop.pool_for(0.0)).is_equal(KarmaData.T1POOL)
	assert_int(KarmaShop.pool_for(80.0).size()).is_equal(KarmaData.T1POOL.size() + KarmaData.T2POOL.size())


func test_verb_defs_five_per_species() -> void:
	for k in KarmaData.SPECIES:
		assert_int((KarmaData.VERB_DEFS[k] as Array).size()).is_equal(5)


func test_animal_years() -> void:
	assert_bool(abs(KarmaData.animal_years("raton", 40.0) - 2.0) < 0.01).is_true()
	assert_bool(abs(KarmaData.animal_years("lobo", 30.0) - 1.0) < 0.01).is_true()
