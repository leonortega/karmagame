class_name KarmaJevBridge
extends RefCounted

# Shared NanoJev bridge plumbing. Per-species files keep their menus, schemas,
# log flags, definitions and verb application; only the identical contract lives here.

const INTENT_TTL := 5.0


static func verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func max_hp(a: Dictionary) -> float:
	return KarmaAI.ai_max_hp(a)


static func set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	var intent := {"kind": kind, "x": x, "y": y, "ttl": INTENT_TTL}
	if target != null:
		intent["target"] = target
	a["jev_intent"] = intent


static func candidate_ids(menu: Array) -> Array:
	var ids: Array = []
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		if kind != "" and not ids.has(kind):
			ids.append(kind)
	return ids


static func mock_choice(menu: Array, order: Array) -> int:
	for want in order:
		for i in menu.size():
			if str((menu[i] as Dictionary)["kind"]) == want:
				return i
	return maxi(0, menu.size() - 1)


static func mock_macro(state: Dictionary, a: Dictionary, build_menu: Callable, order: Array, apply_answer: Callable) -> bool:
	var menu: Array = build_menu.call(state, a)
	if menu.is_empty():
		return false
	var answer := {"choice": mock_choice(menu, order), "probs": [1.0], "emocion": "Instinto"}
	return bool(apply_answer.call(state, a, menu, answer))


static func state_text(label: String, snap: Dictionary, extra_format: String, extra_values: Array) -> String:
	var text := "%s hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s" % [
		label, float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]), str(snap["threatened"])]
	if extra_format != "":
		text += " " + (extra_format % extra_values)
	return text + KarmaJev.age_text(snap)


static func all_agents(state: Dictionary, species: String) -> Array:
	return (state["agents"] as Array).filter(
		func(a): return str(a.get("speciesKey", "")) == species and str(a.get("brain", "")) != "PLAYER")


static func build_batch(state: Dictionary, species: String, build_state: Callable, build_menu: Callable, question: String) -> Array:
	var batch: Array = []
	for a in all_agents(state, species):
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state.call(state, a),
			"question": question,
			"candidates": (build_menu.call(state, a) as Array).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func build_http_body_for(state: Dictionary, agents: Array, build_menu: Callable, build_state_text: Callable, question: String) -> Dictionary:
	var states: Array = []
	var menus := {}
	var included: Array = []
	for a in agents:
		var menu: Array = build_menu.call(state, a)
		var criteria := {}
		for c in menu:
			var kind := str((c as Dictionary)["kind"])
			var label := str((c as Dictionary)["label"])
			if kind != "" and label != "" and not criteria.has(kind):
				criteria[kind] = label
		if criteria.size() < 2:
			continue
		var rid := "%d" % included.size()
		states.append({
			"id": rid,
			"state": build_state_text.call(state, a),
			"questions": {"intent": {"type": "choice", "instructions": question, "criteria": criteria}},
		})
		menus[rid] = menu
		included.append(a)
	return {"states": states, "menus": menus, "agents": included}
