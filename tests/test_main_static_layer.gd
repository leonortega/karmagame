extends GdUnitTestSuite

# Behavior pins for the baked static-furniture painter's content signature:
# - Waters are NOT part of the sig (their fill animates per frame on the
#   overlay; including them would rebake every tick during rain).
# - Flora amounts/states ARE part of the sig (eaten bushes must rebake).

const MainScript := preload("res://scripts/main.gd")


func _boot_with_run() -> Node:
	var main: Node = MainScript.new()
	auto_free(main)
	main.call("_build_static_layer")
	main.state = KarmaState.new_run("raton", 0.0, 0.0, 0, RandomNumberGenerator.new())
	return main


func test_water_levels_are_not_in_the_furniture_sig() -> void:
	var main := _boot_with_run()
	var layer: Node = main.get("_world_layer")
	var waters: Array = (main.state as Dictionary)["waters"]
	var w: Dictionary = waters[0]
	var base: int = int(layer.call("_content_sig"))
	w["level"] = float(w["level"]) + 3.0
	assert_int(int(layer.call("_content_sig"))).is_equal(base)


func test_flora_amount_change_switches_sig() -> void:
	var main := _boot_with_run()
	var layer: Node = main.get("_world_layer")
	var bushes: Array = (main.state as Dictionary)["bushes"]
	assert_int(bushes.size()).is_greater(0)
	var p: Dictionary = bushes[0]
	var base: int = int(layer.call("_content_sig"))
	p["amount"] = int(p["amount"]) + 1
	assert_bool(int(layer.call("_content_sig")) != base).is_true()


func test_seedling_arrival_switches_sig() -> void:
	var main := _boot_with_run()
	var layer: Node = main.get("_world_layer")
	var base: int = int(layer.call("_content_sig"))
	var st: Dictionary = main.state
	(st["seedlings"] as Array).append({"x": 100.0, "y": 100.0})
	assert_bool(int(layer.call("_content_sig")) != base).is_true()
