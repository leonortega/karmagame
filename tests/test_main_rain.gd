extends GdUnitTestSuite

# Rain coverage pins: the drawn rain must scale its streak count with the
# viewport width so every window size gets a full-stage storm (not a thin
# line), with a floor of RAIN_STREAKS_FLOOR streaks even on small windows.

const MainScript := preload("res://scripts/main.gd")


func _count(vp: Vector2) -> int:
	var main: Node = MainScript.new()
	auto_free(main)
	return int(main.call("_rain_streak_count", vp))


func test_streak_count_scales_with_viewport_width() -> void:
	var base: int = int((MainScript as Script).get_script_constant_map()["RAIN_STREAKS"])
	assert_int(_count(Vector2(1280, 800))).is_equal(base)
	assert_int(_count(Vector2(960, 600))).is_equal(int(base * 960.0 / 1280.0))


func test_streak_count_has_a_floor_for_narrow_windows() -> void:
	var floor_n: int = int((MainScript as Script).get_script_constant_map()["RAIN_STREAKS_FLOOR"])
	assert_int(_count(Vector2(480, 320))).is_equal(floor_n)
