extends GdUnitTestSuite

# Visual-look helpers: pure data for medals, bars, and HUD emphasis.
# No behavior change; these back the _draw/HUD overhaul.


func test_species_medal_matches_species_color() -> void:
	for k in KarmaData.SPECIES:
		assert_str(KarmaDraw.species_medal(str(k)).to_html()).is_equal(Color(str((KarmaData.SPECIES[k] as Dictionary)["color"])).to_html())


func test_food_medals_are_distinct_per_kind() -> void:
	var seen := {}
	for kind in ["berries", "apples", "carrots", "mushrooms", "nuts", "leaves", "insects", "carrion"]:
		seen[KarmaDraw.food_medal(kind).to_html()] = true
	assert_int(seen.size()).is_equal(8)


func test_hp_frac_clamps_and_colors() -> void:
	assert_float(KarmaDraw.hp_frac(200.0, 100.0)).is_equal(1.0)
	assert_float(KarmaDraw.hp_frac(-5.0, 100.0)).is_equal(0.0)
	assert_str(KarmaDraw.hp_color(0.8).to_html()).is_equal(Color("#66bb6a").to_html())
	assert_str(KarmaDraw.hp_color(0.4).to_html()).is_equal(Color("#ffca28").to_html())
	assert_str(KarmaDraw.hp_color(0.1).to_html()).is_equal(Color("#ef5350").to_html())


func test_bar_text_fills_proportionally() -> void:
	assert_str(KarmaHud.bar(1.0, 4)).is_equal("■■■■")
	assert_str(KarmaHud.bar(0.0, 4)).is_equal("□□□□")
	assert_str(KarmaHud.bar(0.5, 4)).is_equal("■■□□")


func test_vital_fracs_derive_from_state() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	s["hp"] = 50.0
	s["hambre"] = 25.0
	s["sed"] = 75.0
	assert_bool(abs(KarmaHud.hp_frac(s) - 0.5) < 0.001).is_true()
	assert_bool(abs(KarmaHud.hunger_frac(s) - 0.25) < 0.001).is_true()
	assert_bool(abs(KarmaHud.thirst_frac(s) - 0.75) < 0.001).is_true()


func test_refuge_medal_differs_by_type() -> void:
	assert_bool(KarmaDraw.refuge_medal("burrow-S").to_html() != KarmaDraw.refuge_medal("old-oak").to_html()).is_true()


func test_viewport_enlarged() -> void:
	assert_int(int(ProjectSettings.get_setting("display/window/size/viewport_width"))).is_equal(1280)
	assert_int(int(ProjectSettings.get_setting("display/window/size/viewport_height"))).is_equal(800)
