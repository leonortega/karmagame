extends GdUnitTestSuite

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 99


func test_no_modal_in_play() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["introDone"] = true
	assert_str(KarmaModals.active_modal(s)).is_equal("")
	assert_bool(KarmaModals.is_modal_open(s)).is_false()


func test_shop_modal_when_open() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["introDone"] = true
	s["shopOpen"] = true
	assert_str(KarmaModals.active_modal(s)).is_equal("shop")


func test_pause_beats_shop() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["introDone"] = true
	s["shopOpen"] = true
	s["paused"] = true
	assert_str(KarmaModals.active_modal(s)).is_equal("pause")


func test_birth_beats_pause_and_shop() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["introDone"] = false
	s["paused"] = true
	s["shopOpen"] = true
	assert_str(KarmaModals.active_modal(s)).is_equal("birth")


func test_judgment_beats_all_and_closes_shop() -> void:
	var s := KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)
	s["introDone"] = true
	s["shopOpen"] = true
	s["paused"] = true
	s["dead"] = true
	s["pendingNext"] = "sapo"
	s["pendingPool"] = ["sapo", "raton"]
	assert_str(KarmaModals.active_modal(s)).is_equal("judgment")


func test_roulette_single_entry_settles_instantly() -> void:
	assert_str(KarmaModals.roulette_pick(["oruga"], "oruga", 0.0)).is_equal("oruga")
	assert_str(KarmaModals.roulette_pick(["oruga"], "oruga", 9.9)).is_equal("oruga")


func test_roulette_cycles_then_settles() -> void:
	var pool := ["sapo", "raton", "ardilla", "topo"]
	var early := KarmaModals.roulette_pick(pool, "raton", 0.0)
	assert_bool(pool.has(early)).is_true()
	assert_str(KarmaModals.roulette_pick(pool, "raton", 99.0)).is_equal("raton")


func test_shop_modal_rows_show_owned_and_locked() -> void:
	var s := KarmaState.new_run("raton", 0.0, 70.0, 0, _rng)
	s["introDone"] = true
	var rows := KarmaHud.shop_modal_rows(s)
	assert_int(rows.size()).is_equal(3)
	assert_bool(str(rows[0]).contains("[1]")).is_true()
