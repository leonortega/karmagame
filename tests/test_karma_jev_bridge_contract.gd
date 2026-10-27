extends GdUnitTestSuite

# Characterization for the shared KarmaJevBridge extraction: every species keeps
# the same candidate ids, batch envelopes, state text, mock priority and stale
# target fallback before and after the plumbing is deduplicated.

var _rng: RandomNumberGenerator


func before_test() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 20261019


func _fixtures() -> Array:
	return [
		{
			"species": "raton",
			"label": "Raton",
			"question": KarmaJevRaton.QUESTION,
			"build_menu": Callable(KarmaJevRaton, "build_menu"),
			"build_state": Callable(KarmaJevRaton, "build_state"),
			"state_text": Callable(KarmaJevRaton, "state_text"),
			"build_batch": Callable(KarmaJevRaton, "build_batch"),
			"build_http_body": Callable(KarmaJevRaton, "build_http_body"),
			"candidate_ids": Callable(KarmaJevRaton, "candidate_ids"),
			"mock_choice": Callable(KarmaJevRaton, "mock_choice"),
			"apply_answer": Callable(KarmaJevRaton, "apply_answer"),
			"order": ["eat", "drink", "flee", "alarm", "scout", "groom", "seedcache", "seek_food", "wander"],
		},
		{
			"species": "ardilla",
			"label": "Ardilla",
			"question": KarmaJevArdilla.QUESTION,
			"build_menu": Callable(KarmaJevArdilla, "build_menu"),
			"build_state": Callable(KarmaJevArdilla, "build_state"),
			"state_text": Callable(KarmaJevArdilla, "state_text"),
			"build_batch": Callable(KarmaJevArdilla, "build_batch"),
			"build_http_body": Callable(KarmaJevArdilla, "build_http_body"),
			"candidate_ids": Callable(KarmaJevArdilla, "candidate_ids"),
			"mock_choice": Callable(KarmaJevArdilla, "mock_choice"),
			"apply_answer": Callable(KarmaJevArdilla, "apply_answer"),
			"order": ["eat", "drink", "flee", "bury_nut", "carry_nut", "bark", "groom", "tailflick", "falsecache", "seek_food", "wander"],
		},
		{
			"species": "sapo",
			"label": "Sapo",
			"question": KarmaJevSapo.QUESTION,
			"build_menu": Callable(KarmaJevSapo, "build_menu"),
			"build_state": Callable(KarmaJevSapo, "build_state"),
			"state_text": Callable(KarmaJevSapo, "state_text"),
			"build_batch": Callable(KarmaJevSapo, "build_batch"),
			"build_http_body": Callable(KarmaJevSapo, "build_http_body"),
			"candidate_ids": Callable(KarmaJevSapo, "candidate_ids"),
			"mock_choice": Callable(KarmaJevSapo, "mock_choice"),
			"apply_answer": Callable(KarmaJevSapo, "apply_answer"),
			"order": ["eat", "drink", "flee", "toxin", "pest", "burrowin", "croak", "chorus", "seek_food", "wander"],
		},
		{
			"species": "topo",
			"label": "Topo",
			"question": KarmaJevTopo.QUESTION,
			"build_menu": Callable(KarmaJevTopo, "build_menu"),
			"build_state": Callable(KarmaJevTopo, "build_state"),
			"state_text": Callable(KarmaJevTopo, "state_text"),
			"build_batch": Callable(KarmaJevTopo, "build_batch"),
			"build_http_body": Callable(KarmaJevTopo, "build_http_body"),
			"candidate_ids": Callable(KarmaJevTopo, "candidate_ids"),
			"mock_choice": Callable(KarmaJevTopo, "mock_choice"),
			"apply_answer": Callable(KarmaJevTopo, "apply_answer"),
			"order": ["eat", "drink", "flee", "alarm", "worm", "aerate", "tunneline", "larder", "seek_food", "wander"],
		},
		{
			"species": "zorro",
			"label": "Zorro",
			"question": KarmaJevZorro.QUESTION,
			"build_menu": Callable(KarmaJevZorro, "build_menu"),
			"build_state": Callable(KarmaJevZorro, "build_state"),
			"state_text": Callable(KarmaJevZorro, "state_text"),
			"build_batch": Callable(KarmaJevZorro, "build_batch"),
			"build_http_body": Callable(KarmaJevZorro, "build_http_body"),
			"candidate_ids": Callable(KarmaJevZorro, "candidate_ids"),
			"mock_choice": Callable(KarmaJevZorro, "mock_choice"),
			"apply_answer": Callable(KarmaJevZorro, "apply_answer"),
			"order": ["eat", "cede", "pounce", "hunt", "strike", "cache", "dendig", "drink", "flee", "seek_carrion", "wander"],
		},
		{
			"species": "halcon",
			"label": "Halcon",
			"question": KarmaJevHalcon.QUESTION,
			"build_menu": Callable(KarmaJevHalcon, "build_halcon_menu"),
			"build_state": Callable(KarmaJevHalcon, "build_halcon_state"),
			"state_text": Callable(KarmaJevHalcon, "halcon_state_text"),
			"build_http_body": Callable(KarmaJevHalcon, "build_halcon_http_body"),
			"candidate_ids": Callable(KarmaJev, "candidate_ids"),
			"mock_choice": Callable(KarmaJevHalcon, "halcon_mock_choice"),
			"apply_answer": Callable(KarmaJevHalcon, "apply_halcon_answer"),
			"order": ["eat", "courtesy", "dive", "scare", "bone", "thermal", "drink", "seek_carrion", "flee", "wander"],
		},
		{
			"species": "oruga",
			"label": "Oruga",
			"question": KarmaJevOruga.QUESTION,
			"build_menu": Callable(KarmaJevOruga, "build_menu"),
			"build_state": Callable(KarmaJevOruga, "build_state"),
			"state_text": Callable(KarmaJevOruga, "state_text"),
			"build_batch": Callable(KarmaJevOruga, "build_batch"),
			"build_http_body": Callable(KarmaJevOruga, "build_http_body"),
			"candidate_ids": Callable(KarmaJevOruga, "candidate_ids"),
			"mock_choice": Callable(KarmaJevOruga, "mock_choice"),
			"apply_answer": Callable(KarmaJevOruga, "apply_answer"),
			"order": ["eat", "drink", "flee", "silk", "bristle", "leafroll", "nectar", "seek_food", "wander"],
		},
		{
			"species": "lobo",
			"label": "Lobo",
			"question": KarmaJevLobo.QUESTION,
			"build_menu": Callable(KarmaJevLobo, "build_menu"),
			"build_state": Callable(KarmaJevLobo, "build_state"),
			"state_text": Callable(KarmaJevLobo, "state_text"),
			"build_batch": Callable(KarmaJevLobo, "build_batch"),
			"build_http_body": Callable(KarmaJevLobo, "build_http_body"),
			"candidate_ids": Callable(KarmaJevLobo, "candidate_ids"),
			"mock_choice": Callable(KarmaJevLobo, "mock_choice"),
			"apply_answer": Callable(KarmaJevLobo, "apply_answer"),
			"order": ["eat", "strike", "regurg", "escort", "hunt", "drink", "seek_carrion", "alarm", "wander"],
		},
	]


func _state_for(fixture: Dictionary) -> Dictionary:
	var species := str(fixture["species"])
	var state := KarmaState.new_run(species, 0.0, 0.0, 0, _rng)
	var count := _ai_agents(state, species).size()
	for i in maxi(0, 2 - count):
		KarmaState.spawn_fauna(state, species, 420.0 + 60.0 * i, 420.0)
	return state


func _ai_agents(state: Dictionary, species: String) -> Array:
	return (state["agents"] as Array).filter(
		func(a): return str(a.get("speciesKey", "")) == species and str(a.get("brain", "")) != "PLAYER")


func _criteria(menu: Array) -> Dictionary:
	var criteria := {}
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		var label := str((c as Dictionary)["label"])
		if kind != "" and label != "" and not criteria.has(kind):
			criteria[kind] = label
	return criteria


func _expected_body(fixture: Dictionary, state: Dictionary) -> Dictionary:
	var states: Array = []
	var menus := {}
	var included: Array = []
	for a in _ai_agents(state, str(fixture["species"])):
		var menu: Array = fixture["build_menu"].call(state, a)
		var criteria := _criteria(menu)
		if criteria.size() < 2:
			continue
		var rid := "%d" % included.size()
		states.append({
			"id": rid,
			"state": fixture["state_text"].call(state, a),
			"questions": {"intent": {"type": "choice", "instructions": fixture["question"], "criteria": criteria}},
		})
		menus[rid] = menu
		included.append(a)
	return {"states": states, "menus": menus, "agents": included}


func test_candidate_ids_match_menu_kinds_for_every_species() -> void:
	for fixture in _fixtures():
		var state := _state_for(fixture)
		for a in _ai_agents(state, str(fixture["species"])):
			var menu: Array = fixture["build_menu"].call(state, a)
			var expected: Array = []
			for c in menu:
				var kind := str((c as Dictionary)["kind"])
				if kind != "" and not expected.has(kind):
					expected.append(kind)
			assert_that(fixture["candidate_ids"].call(menu)) \
				.override_failure_message("%s candidate ids" % str(fixture["species"])) \
				.is_equal(expected)


func test_build_batch_envelope_matches_direct_builders_for_every_species() -> void:
	for fixture in _fixtures():
		if not fixture.has("build_batch"):
			continue
		var state := _state_for(fixture)
		var expected: Array = []
		for a in _ai_agents(state, str(fixture["species"])):
			var menu: Array = fixture["build_menu"].call(state, a)
			expected.append({
				"id": str(a.get("instance_id", str(a))),
				"state": fixture["build_state"].call(state, a),
				"question": fixture["question"],
				"candidates": menu.map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
			})
		assert_that(fixture["build_batch"].call(state)) \
			.override_failure_message("%s build_batch envelope" % str(fixture["species"])) \
			.is_equal(expected)


func test_http_body_envelope_matches_direct_builders_for_every_species() -> void:
	for fixture in _fixtures():
		var state := _state_for(fixture)
		assert_that(fixture["build_http_body"].call(state)) \
			.override_failure_message("%s http body envelope" % str(fixture["species"])) \
			.is_equal(_expected_body(fixture, state))


func test_state_text_keeps_common_prefix_and_age_suffix_for_every_species() -> void:
	for fixture in _fixtures():
		var state := _state_for(fixture)
		for a in _ai_agents(state, str(fixture["species"])).slice(0, 1):
			var snap: Dictionary = fixture["build_state"].call(state, a)
			var head := "%s hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s" % [
				fixture["label"], float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
				int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]), str(snap["threatened"])]
			var text := str(fixture["state_text"].call(state, a))
			assert_bool(text.begins_with(head)) \
				.override_failure_message("%s state text prefix: %s" % [str(fixture["species"]), text]) \
				.is_true()
			assert_bool(text.ends_with(KarmaJev.age_text(snap))) \
				.override_failure_message("%s state text age suffix" % str(fixture["species"])) \
				.is_true()


func test_mock_choice_priority_order_for_every_species() -> void:
	for fixture in _fixtures():
		var order: Array = fixture["order"]
		var menu: Array = []
		for i in range(order.size() - 1, -1, -1):
			menu.append({"kind": order[i], "label": order[i]})
		for i in order.size():
			var narrowed: Array = menu.slice(0, order.size() - i)
			var expected := _kind_index(narrowed, str(order[i]))
			assert_int(fixture["mock_choice"].call(narrowed)) \
				.override_failure_message("%s mock priority %s" % [str(fixture["species"]), str(order[i])]) \
				.is_equal(expected)
		assert_int(fixture["mock_choice"].call([{"kind": "unknown", "label": "Unknown"}])) \
			.override_failure_message("%s mock fallback" % str(fixture["species"])) \
			.is_equal(0)


func test_apply_stale_target_wanders_for_every_species() -> void:
	for fixture in _fixtures():
		var state := _state_for(fixture)
		var agents := _ai_agents(state, str(fixture["species"]))
		var a: Dictionary = agents[0]
		var applied: bool = fixture["apply_answer"].call(state, a, [], {"target_gone": true})
		assert_bool(applied) \
			.override_failure_message("%s stale target applied" % str(fixture["species"])) \
			.is_true()
		assert_str(str((a.get("jev_intent", {}) as Dictionary).get("kind", ""))) \
			.override_failure_message("%s stale target intent" % str(fixture["species"])) \
			.is_equal("wander")


func _kind_index(menu: Array, kind: String) -> int:
	for i in menu.size():
		if str((menu[i] as Dictionary)["kind"]) == kind:
			return i
	return -1
