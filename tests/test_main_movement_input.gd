extends GdUnitTestSuite

const AXES := ["move_left", "move_right", "move_up", "move_down"]


func after_test() -> void:
	for action in AXES:
		Input.action_release(action)


func _axis() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func test_right_is_unit_x() -> void:
	Input.action_press("move_right")
	assert_vector(_axis()).is_equal(Vector2.RIGHT)


func test_left_is_unit_negative_x() -> void:
	Input.action_press("move_left")
	assert_vector(_axis()).is_equal(Vector2.LEFT)


func test_diagonal_is_normalized() -> void:
	Input.action_press("move_right")
	Input.action_press("move_down")
	var axis := _axis()
	assert_float(axis.length()).is_equal_approx(1.0, 0.0001)
	assert_vector(axis).is_equal(Vector2(1.0, 1.0).normalized())


func test_opposing_keys_cancel() -> void:
	assert_bool(InputMap.has_action("move_left") and InputMap.has_action("move_right")).is_true()
	Input.action_press("move_right")
	Input.action_press("move_left")
	assert_vector(_axis()).is_equal(Vector2.ZERO)
