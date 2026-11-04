extends GdUnitTestSuite

# Layout-contract pins: the HUD side panels anchor to opposite viewport edges
# and the modal panel lives inside a full-rect CenterContainer, so both keep
# their placement at any window size (resizable window).

const MainScript := preload("res://scripts/main.gd")


func _const(name: String) -> float:
	return float((MainScript as Script).get_script_constant_map()[name])


func _boot() -> Node:
	var main: Node = MainScript.new()
	auto_free(main)
	main.call("_build_hud")
	return main


func test_left_panel_anchors_to_left_edge() -> void:
	var main := _boot()
	var left: PanelContainer = main.get_node("HUD/LeftPanel")
	assert_float(left.anchor_left).is_equal(0.0)
	assert_float(left.anchor_right).is_equal(0.0)
	assert_float(left.offset_top).is_equal(_const("PANEL_MARGIN"))
	assert_float(left.offset_left).is_equal(_const("PANEL_MARGIN"))
	assert_float(left.offset_right).is_equal(_const("PANEL_MARGIN") + _const("PANEL_W"))
	assert_bool(left.grow_horizontal == Control.GROW_DIRECTION_END).is_true()


func test_right_panel_anchors_to_right_edge() -> void:
	var main := _boot()
	var right: PanelContainer = main.get_node("HUD/RightPanel")
	assert_float(right.anchor_left).is_equal(1.0)
	assert_float(right.anchor_right).is_equal(1.0)
	assert_float(right.offset_top).is_equal(_const("PANEL_MARGIN"))
	assert_float(right.offset_right).is_equal(-_const("PANEL_MARGIN"))
	assert_float(right.offset_left).is_equal(-(_const("PANEL_W") + _const("PANEL_MARGIN")))
	assert_bool(right.grow_horizontal == Control.GROW_DIRECTION_BEGIN).is_true()


func test_vital_bars_track_value_color_and_text() -> void:
	var main := _boot()
	var bar: ProgressBar = main.get_node("HUD/RightPanel/Box/vida_row/vida")
	assert_float(bar.max_value).is_equal(100.0)
	assert_bool(bar.show_percentage).is_false()
	main.call("_set_bar", "vida", 0.25, "10/60")
	assert_float(bar.value).is_equal(25.0)
	var val: Label = main.get_node("HUD/RightPanel/Box/vida_row/vida/vida_val")
	assert_str(val.text).is_equal("10/60")
	var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
	assert_str((fill as StyleBoxFlat).bg_color.to_html()).is_equal(KarmaDraw.hp_color(0.25).to_html())
	# The three vitals exist as drawn bars, not text bars.
	assert_bool(main.get_node("HUD/RightPanel/Box/hambre_row/hambre") is ProgressBar).is_true()
	assert_bool(main.get_node("HUD/RightPanel/Box/sed_row/sed") is ProgressBar).is_true()


func test_modal_sits_in_full_rect_center_container() -> void:
	var main: Node = MainScript.new()
	auto_free(main)
	main.call("_build_hud")
	main.call("_build_modal")
	var center: CenterContainer = main.get_node("HUD/ModalCenter")
	assert_float(center.anchor_left).is_equal(0.0)
	assert_float(center.anchor_top).is_equal(0.0)
	assert_float(center.anchor_right).is_equal(1.0)
	assert_float(center.anchor_bottom).is_equal(1.0)
	assert_bool(center.get_node("ModalPanel") is PanelContainer).is_true()
