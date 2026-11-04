extends GdUnitTestSuite

# Log-feed contract: the right-panel log (state.feed) carries ONLY the
# player's story; CPU (AI) activity surfaces in state.otherFeed prefixed
# with the actor's species emoji, throttled for everyday acts.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1234


func _state() -> Dictionary:
	return KarmaState.new_run("raton", 0.0, 0.0, 0, _rng)


func _ai(s: Dictionary) -> Dictionary:
	for a: Dictionary in s["agents"] as Array:
		if str(a.get("brain", "")) != "PLAYER":
			return a
	assert_bool(false).is_true()
	return {}


func test_ai_log_goes_to_agent_ledger_and_other_feed_with_species_prefix() -> void:
	var s := _state()
	var ai := _ai(s)
	var feed_n := (s["feed"] as Array).size()
	KarmaState.add_log(s, ai, "Bebe agua")
	assert_bool((s["feed"] as Array).size() == feed_n).is_true()
	assert_str((ai["lifeLog"] as Array).back()).is_equal("Bebe agua")
	var last: String = str((s["otherFeed"] as Array).back())
	assert_bool(last.begins_with(KarmaDraw.species_icon(str(ai["speciesKey"])))).is_true()
	assert_bool(last.contains("Bebe agua")).is_true()


func test_ai_karma_entry_prefixes_other_feed() -> void:
	var s := _state()
	var ai := _ai(s)
	KarmaState.add_karma(s, ai, 5.0, "Acicala a un congénere (+karma)")
	assert_bool(str((s["otherFeed"] as Array).back()).contains("Acicala a un congénere")).is_true()


func test_ai_eat_drink_kills_show_in_other_feed_not_player_feed() -> void:
	var s := _state()
	var ai := _ai(s)
	ai["x"] = 500.0
	ai["y"] = 500.0
	var feed: Array = s["feed"] as Array
	var feed_n := feed.size()
	# Drink at a crafted water spot right next to the AI.
	KarmaEat.drink_water(s, {"kind": "charco", "x": 505.0, "y": 505.0, "r": 20.0, "level": 5.0, "cap": 5.0}, ai)
	# Eat the first kind in the AI's diet from a fresh patch.
	var kinds: Array = KarmaData.DIET[str(ai["speciesKey"])]
	var patch := KarmaUtils.mk_patch(str(kinds[0]), 500.0, 500.0, 3)
	KarmaEat.eat_patch(s, patch, ai)
	# A lethal bite on a weaker AI neighbour becomes a logged hunt.
	var prey: Variant = null
	for a: Dictionary in s["agents"] as Array:
		if str(a.get("brain", "")) != "PLAYER" and a != ai:
			prey = a
			break
	if prey != null:
		(prey as Dictionary)["hp"] = 1.0
		KarmaEat.resolve_strike(s, ai, prey, 30.0)
	assert_bool(feed.size() == feed_n).is_true()
	var o := s["otherFeed"] as Array
	assert_bool(o.size() > 0).is_true()
	assert_bool(str(o[o.size() - 1]).contains("Caza")).is_true()


func test_record_activity_throttles_repeat_and_skips_player_body() -> void:
	var s := _state()
	var ai := _ai(s)
	KarmaState.record_activity(s, ai, "Come bayas")
	assert_int((s["otherFeed"] as Array).size()).is_equal(1)
	# Same tick again: everyday chatter is throttled; karma entries are not.
	KarmaState.record_activity(s, ai, "Come bayas")
	assert_int((s["otherFeed"] as Array).size()).is_equal(1)
	s["time"] = float(KarmaData.TUNING["aiActLogCd"]) + 0.5
	KarmaState.record_activity(s, ai, "Come bayas")
	assert_int((s["otherFeed"] as Array).size()).is_equal(2)
	# The possessed body never writes everyday chatter: its actions belong
	# to the player log via explicit add_log(state, null, ...) calls.
	KarmaState.record_activity(s, KarmaState.player(s), "Come bayas")
	assert_int((s["otherFeed"] as Array).size()).is_equal(2)


func test_log_arrays_capped() -> void:
	var s := _state()
	var ai := _ai(s)
	var feed_cap := int(KarmaData.TUNING["logCapFeed"])
	var life_cap := int(KarmaData.TUNING["logCapLife"])
	for i in feed_cap + 10:
		KarmaState.add_log(s, null, "p%d" % i)
		KarmaState.add_log(s, ai, "x%d" % i)
	assert_int((s["feed"] as Array).size()).is_equal(feed_cap)
	assert_int((s["otherFeed"] as Array).size()).is_equal(feed_cap)
	assert_int((ai["lifeLog"] as Array).size()).is_equal(life_cap)
	assert_str(str((s["otherFeed"] as Array).back())).contains("x%d" % (feed_cap + 9))


func test_hud_other_feed_lines_is_a_single_rolling_log() -> void:
	var s := _state()
	var ai := _ai(s)
	for i in 20:
		KarmaState.add_log(s, ai, "acto %d" % i)
	var lines: Array = KarmaHud.other_feed_lines(s)
	assert_int(lines.size()).is_equal(int(KarmaData.TUNING["otherFeedLines"]))
	assert_str(str(lines.back())).contains("acto 19")
	assert_str(str(lines.front())).contains("acto 6")
