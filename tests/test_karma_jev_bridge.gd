extends GdUnitTestSuite


func _agent() -> Dictionary:
	return KarmaState.mk_agent({"speciesKey": "raton", "x": 10.0, "y": 20.0})


func test_set_intent_keeps_target_and_ttl() -> void:
	var a := _agent()
	var target := {"id": 7}
	KarmaJevBridge.set_intent(a, "eat", 1.0, 2.0, target)
	assert_that(a["jev_intent"]).is_equal({"kind": "eat", "x": 1.0, "y": 2.0, "ttl": 5.0, "target": target})


func test_set_intent_omits_target_when_null() -> void:
	var a := _agent()
	KarmaJevBridge.set_intent(a, "wander", 3.0, 4.0)
	assert_that(a["jev_intent"]).is_equal({"kind": "wander", "x": 3.0, "y": 4.0, "ttl": 5.0})


func test_verb_ready_handles_missing_and_cooldown() -> void:
	var a := _agent()
	a.erase("verbCds")
	assert_bool(KarmaJevBridge.verb_ready(a, 3)).is_true()
	a["verbCds"] = [0.0, 0.0, 1.5, 0.0, 0.0]
	assert_bool(KarmaJevBridge.verb_ready(a, 3)).is_false()
	a["verbCds"][2] = 0.0
	assert_bool(KarmaJevBridge.verb_ready(a, 3)).is_true()


func test_candidate_ids_dedupe_and_skip_empty() -> void:
	var menu := [{"kind": "eat"}, {"kind": "eat"}, {"kind": ""}, {"kind": "wander"}]
	assert_that(KarmaJevBridge.candidate_ids(menu)).is_equal(["eat", "wander"])


func test_mock_choice_uses_order_then_last() -> void:
	var menu := [{"kind": "wander"}, {"kind": "eat"}, {"kind": "drink"}]
	assert_int(KarmaJevBridge.mock_choice(menu, ["drink", "eat"])).is_equal(2)
	assert_int(KarmaJevBridge.mock_choice(menu, ["unknown"])).is_equal(2)
	assert_int(KarmaJevBridge.mock_choice([], ["eat"])).is_equal(0)


func test_mock_macro_returns_false_on_empty_menu() -> void:
	var state := {"agents": []}
	var a := _agent()
	assert_bool(KarmaJevBridge.mock_macro(state, a,
		func(_s, _a): return [],
		["eat"],
		func(_s, _a, _m, _ans): return true)).is_false()


func test_mock_macro_uses_shared_choice_and_applies() -> void:
	var state := {"agents": []}
	var a := _agent()
	var captured := {}
	var applied := KarmaJevBridge.mock_macro(state, a,
		func(_s, _a): return [{"kind": "wander"}, {"kind": "eat"}],
		["eat"],
		func(_s, _a, _m, ans):
			captured["answer"] = ans
			return true)
	assert_bool(applied).is_true()
	assert_int(int(captured["answer"]["choice"])).is_equal(1)
	assert_that(captured["answer"]["probs"]).is_equal([1.0])
	assert_str(str(captured["answer"]["emocion"])).is_equal("Instinto")


func test_state_text_keeps_prefix_tail_and_age() -> void:
	var snap := {"hp_frac": 0.5, "hambre": 70.0, "sed": 60.0, "karma": 2.0, "pa": 3.0,
		"hungry": true, "threatened": false, "food_near": true, "stage": "prime",
		"force": 1.0, "frailty": 1.0, "threat_stage": "", "prey_stage": ""}
	var text := KarmaJevBridge.state_text("Raton", snap, "food=%s water=%s", [true, false])
	assert_str(text).is_equal(
		"Raton hp_frac=0.50 hambre=70 sed=60 karma=2 pa=3 hungry=true threatened=false food=true water=false"
		+ KarmaJev.age_text(snap))


func test_all_agents_filters_species_and_player() -> void:
	var state := {"agents": [
		{"speciesKey": "raton", "brain": "AI"},
		{"speciesKey": "raton", "brain": "PLAYER"},
		{"speciesKey": "zorro", "brain": "AI"},
	]}
	assert_that(KarmaJevBridge.all_agents(state, "raton")).is_equal([{"speciesKey": "raton", "brain": "AI"}])


func test_build_batch_filters_species_and_shapes_entries() -> void:
	var state := {"agents": [
		{"speciesKey": "raton", "brain": "AI", "instance_id": 5},
		{"speciesKey": "raton", "brain": "PLAYER", "instance_id": 6},
		{"speciesKey": "zorro", "brain": "AI", "instance_id": 7},
	] as Array}
	var build_state := func(_s, a): return {"schema": "x", "id": a.get("instance_id", -1)}
	var build_menu := func(_s, _a): return [{"kind": "eat", "label": "Eat"}, {"kind": "wander", "label": "Wander"}]
	var batch := KarmaJevBridge.build_batch(state, "raton", build_state, build_menu, "Que?")
	assert_int(batch.size()).is_equal(1)
	assert_that(batch[0]).is_equal({
		"id": "5",
		"state": {"schema": "x", "id": 5},
		"question": "Que?",
		"candidates": ["eat: Eat", "wander: Wander"],
	})


func test_build_http_body_for_skips_single_candidate_and_indexes() -> void:
	var state := {"agents": []}
	var a1 := {"id": "a1"}
	var a2 := {"id": "a2"}
	var build_menu := func(_s, a):
		if a["id"] == "a1":
			return [{"kind": "eat", "label": "Eat"}]
		return [{"kind": "eat", "label": "Eat"}, {"kind": "wander", "label": "Wander"}]
	var state_text := func(_s, a): return "st-" + str(a["id"])
	var body := KarmaJevBridge.build_http_body_for(state, [a1, a2], build_menu, state_text, "Que?")
	assert_int((body["states"] as Array).size()).is_equal(1)
	assert_that(body["states"][0]).is_equal({
		"id": "0",
		"state": "st-a2",
		"questions": {"intent": {"type": "choice", "instructions": "Que?", "criteria": {"eat": "Eat", "wander": "Wander"}}},
	})
	assert_that(body["menus"]).is_equal({"0": [{"kind": "eat", "label": "Eat"}, {"kind": "wander", "label": "Wander"}]})
	assert_that(body["agents"]).is_equal([a2])
