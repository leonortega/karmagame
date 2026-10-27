extends GdUnitTestSuite

# Characterization + cache policy for the draw-text refactor. The cache keeps
# shaped label widths keyed by text and font size, activates only when a frame
# draws many labels, resets when the fallback font changes, and stays bounded.

const MainScript := preload("res://scripts/main.gd")


func _boot() -> Node:
	var main: Node = MainScript.new()
	auto_free(main)
	return main


func _font() -> Font:
	return SystemFont.new()


func _cache_limit(name: String) -> int:
	return int((MainScript as Script).get_script_constant_map()[name])


func test_measure_without_cache_leaves_cache_empty() -> void:
	var main := _boot()
	var font := _font()
	main.call("_measure_label", font, "bayas x3", 11, false)
	main.call("_measure_label", font, "bayas x3", 11, false)
	assert_int((main.get("_label_sizes") as Dictionary).size()).is_equal(0)


func test_measure_with_cache_remembers_text_and_size() -> void:
	var main := _boot()
	var font := _font()
	var first: Vector2 = main.call("_measure_label", font, "bayas x3", 11, true)
	var second: Vector2 = main.call("_measure_label", font, "bayas x3", 11, true)
	assert_int((main.get("_label_sizes") as Dictionary).size()).is_equal(1)
	assert_vector(first).is_equal(second)


func test_measure_cache_separates_same_text_by_size() -> void:
	var main := _boot()
	var font := _font()
	var small: Vector2 = main.call("_measure_label", font, "lago", 11, true)
	var big: Vector2 = main.call("_measure_label", font, "lago", 18, true)
	assert_int((main.get("_label_sizes") as Dictionary).size()).is_equal(2)
	assert_bool(small.y != big.y).is_true()


func test_measure_cache_is_bounded() -> void:
	var main := _boot()
	var font := _font()
	var cache_max := _cache_limit("LABEL_CACHE_MAX")
	for i in range(cache_max + 20):
		main.call("_measure_label", font, "label %d" % i, 11, true)
	var cached: Dictionary = main.get("_label_sizes")
	assert_int(cached.size()).is_less_equal(cache_max)


func test_cache_activates_only_above_label_threshold() -> void:
	var main := _boot()
	var min_calls := _cache_limit("LABEL_CACHE_MIN_CALLS")
	main.set("_pill_calls", min_calls)
	assert_bool(bool(main.call("_uses_label_cache"))).is_false()
	main.set("_pill_calls", min_calls + 1)
	assert_bool(bool(main.call("_uses_label_cache"))).is_true()


func test_font_change_clears_cached_widths() -> void:
	var main := _boot()
	var first_font := _font()
	var second_font := _font()
	main.call("_measure_label", first_font, "lago", 11, true)
	main.call("_sync_label_font", second_font)
	assert_int((main.get("_label_sizes") as Dictionary).size()).is_equal(0)
	main.call("_measure_label", second_font, "lago", 11, true)
	assert_int((main.get("_label_sizes") as Dictionary).size()).is_equal(1)
