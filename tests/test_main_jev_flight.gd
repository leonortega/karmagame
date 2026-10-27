extends GdUnitTestSuite

# Characterization for collapsing the eight duplicated JEV flight field groups
# in main.gd into one in-flight record. Pins the behavior the refactor must
# preserve: fair-share selection, busy-skip telemetry, per-species sent /
# mark_served, the flushed counters, and the terminal clear paths
# (success / error / timeout) that must return _jev_busy to false.
#
# The send functions end in HTTPRequest.request(); the node is never added to
# the tree, so the engine short-circuits that call with ERR_UNCONFIGURED and no
# network I/O. Telemetry is written before the request, so it still holds.

const MainScript := preload("res://scripts/main.gd")

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 20261019


func after_test() -> void:
	KarmaJev.LOG_JEV_ZORRO = false


func _boot(state: Dictionary) -> Node:
	var main: Node = MainScript.new()
	auto_free(main)
	main.set("state", state)
	var http := HTTPRequest.new()
	auto_free(http)
	main.set("_jev_http", http)
	return main


func _zorro_ready() -> Dictionary:
	var s := KarmaState.new_run("zorro", 0.0, 0.0, 0, _rng)
	(s["agents"] as Array).clear()
	KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	KarmaEat.add_carrion(s, 500.0, 500.0)
	return s


func _due(s: Dictionary) -> Array:
	return KarmaJev.all_jev_zorros(s)


func _ok_payload() -> PackedByteArray:
	return JSON.stringify({
		"states": [{"id": "0", "answers": {"intent": {"choice": "wander", "probabilities": {}, "emocion": ""}}}],
	}).to_utf8_buffer()


# 1.1 Fair-share selection across two due species (picker + last-served record).

func test_fair_share_prefers_least_recently_served_of_two_due() -> void:
	var served := {"zorro": 100.0, "halcon": 40.0}
	assert_str(KarmaJev.pick_batch_species_8(true, true, false, false, false, false, false, false, "zorro", served)).is_equal("halcon")


func test_fair_share_ties_break_on_rotation_from_last_served() -> void:
	var served := {"zorro": 10.0, "halcon": 10.0}
	assert_str(KarmaJev.pick_batch_species_8(true, true, false, false, false, false, false, false, "zorro", served)).is_equal("halcon")
	assert_str(KarmaJev.pick_batch_species_8(true, true, false, false, false, false, false, false, "halcon", served)).is_equal("zorro")


# 1.2 Busy-skip telemetry, per-species sent, mark_served, and flushed counters.

func test_send_records_sent_mark_served_and_live_flags() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	var due := _due(s)
	main.call("_jev_poll")
	assert_bool(bool(main.get("_jev_busy"))).is_true()
	assert_str(str(main.get("_jev_last_species"))).is_equal("zorro")
	assert_int(int((s["jev_poll"] as Dictionary)["sent"]["zorro"])).is_equal(1)
	assert_float(float((s["jev_last_served"] as Dictionary)["zorro"])).is_equal(float(s["time"]))
	for a in due:
		assert_bool(bool(a.get("jev_live", false))).is_true()


func test_busy_poll_notes_skip_without_sending() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	main.set("_jev_busy", true)
	main.call("_jev_poll")
	assert_int(int((s["jev_poll"] as Dictionary)["busy_skip"])).is_equal(1)
	assert_bool(((s["jev_poll"] as Dictionary)["sent"] as Dictionary).is_empty()).is_true()


func test_multi_species_poll_sends_one_due_species_then_notes_busy_skip() -> void:
	var s := KarmaState.blank_state("raton", 0.0, 0.0)
	KarmaState.spawn_fauna(s, "zorro", 500.0, 500.0)
	KarmaState.spawn_fauna(s, "halcon", 600.0, 600.0)
	var main := _boot(s)
	main.set("_jev_last_species", "halcon")
	main.call("_jev_poll")
	assert_bool(bool(main.get("_jev_busy"))).is_true()
	assert_str(str(main.get("_jev_last_species"))).is_equal("zorro")
	var sent := (s["jev_poll"] as Dictionary)["sent"] as Dictionary
	assert_int(int(sent.get("zorro", 0))).is_equal(1)
	assert_int(int(sent.get("halcon", 0))).is_equal(0)
	main.call("_jev_poll")
	assert_int(int((s["jev_poll"] as Dictionary)["busy_skip"])).is_equal(1)
	assert_int(int(sent.get("zorro", 0))).is_equal(1)
	assert_int(int(sent.get("halcon", 0))).is_equal(0)


func test_flush_log_advances_species_counter() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	KarmaJev.LOG_JEV_ZORRO = true
	s["jev_log_zorro"] = [{"schema": "jev-zorro/v1"}, {"schema": "jev-zorro/v1"}]
	main.call("_jev_flush_log")
	assert_int(int((main.get("_jev_flushed") as Dictionary)["zorro"])).is_equal(2)


# 1.3 Terminal clear paths: _jev_busy resets and the flight record empties.

func test_success_path_clears_busy_and_flight() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	var due := _due(s)
	main.call("_jev_poll")
	main.call("_on_jev_done", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), _ok_payload())
	assert_bool(bool(main.get("_jev_busy"))).is_false()
	for a in due:
		assert_bool(bool(a.get("jev_live", false))).is_false()
	var next := float((due[0] as Dictionary).get("jev_next", 0.0))
	main.call("_on_jev_done", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), _ok_payload())
	assert_float(float((due[0] as Dictionary).get("jev_next", 0.0))).is_equal(next)


func test_error_path_clears_busy_and_notes_error() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	var due := _due(s)
	main.call("_jev_poll")
	main.call("_on_jev_done", HTTPRequest.RESULT_SUCCESS, 500, PackedStringArray(), "boom".to_utf8_buffer())
	assert_bool(bool(main.get("_jev_busy"))).is_false()
	assert_int(int((s["jev_poll"] as Dictionary)["error"])).is_equal(1)
	for a in due:
		assert_bool(bool(a.get("jev_live", false))).is_false()


func test_timeout_path_clears_busy_and_flight() -> void:
	var s := _zorro_ready()
	var main := _boot(s)
	var due := _due(s)
	main.call("_jev_poll")
	main.call("_on_jev_done", HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	assert_bool(bool(main.get("_jev_busy"))).is_false()
	for a in due:
		assert_bool(bool(a.get("jev_live", false))).is_false()
