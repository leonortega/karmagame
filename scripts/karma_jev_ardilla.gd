class_name KarmaJevArdilla
extends RefCounted

# Ardilla NanoJev bridge (Option B, mirrors raton/zorro/halcon):
# GDScript builds the legal candidate menu, sidecar only ranks.
# Micro steering never waits for answers. Nut-carry state lives on the agent.

const SCHEMA_VERSION := "jev-ardilla/v1"
const QUESTION := "Que hace la ardilla ahora? Elige un candidato."
const USE_JEV := true


static func _set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	a["jev_intent"] = {"kind": kind, "x": x, "y": y, "ttl": 5.0}
	if target != null:
		(a["jev_intent"] as Dictionary)["target"] = target


static func _verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func ardilla_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["ardilla"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["ardilla"],
		"diet": KarmaData.DIET["ardilla"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["ardilla"],
		"tuning": {
			"eatRange": float(KarmaData.TUNING["eatRange"]),
			"drinkRange": float(KarmaData.TUNING["drinkRange"]),
			"forageRangeMult": float(KarmaData.TUNING["forageRangeMult"]),
			"hungerPriority": float(KarmaData.TUNING["hungerPriority"]),
			"aiFearRange": float(KarmaData.TUNING["aiFearRange"]),
			"aiCoverRange": float(KarmaData.TUNING["aiCoverRange"]),
			"groomRange": float(KarmaData.TUNING["groomRange"]),
			"regenSed": float(KarmaData.TUNING["regenSed"]),
		},
	}


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var forage := float(KarmaData.SPECIES["ardilla"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, eat_range)
	if patch != null:
		menu.append({"kind": "eat", "label": "Eat food", "x": float((patch as Dictionary)["x"]), "y": float((patch as Dictionary)["y"]), "target": patch})
	elif KarmaAI.is_hungry(a):
		var far_patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, forage)
		if far_patch != null:
			menu.append({"kind": "seek_food", "label": "Seek food", "x": float((far_patch as Dictionary)["x"]), "y": float((far_patch as Dictionary)["y"]), "target": far_patch})
	if bool(a.get("carriedNut", false)):
		menu.append({"kind": "bury_nut", "label": "Bury nut (plant it!)", "x": ax, "y": ay})
	else:
		var oak: Variant = KarmaEat.nearest_oak_with_nuts_for(state, a, eat_range)
		if oak != null:
			menu.append({"kind": "carry_nut", "label": "Carry nut (take it!)", "x": float((oak as Dictionary)["x"]), "y": float((oak as Dictionary)["y"]), "target": oak})
	if _verb_ready(a, 4):
		var bark_oak: Variant = KarmaEat.nearest_oak_with_nuts_for(state, a, eat_range)
		if bark_oak != null:
			menu.append({"kind": "bark", "label": "Harvest bark", "x": float((bark_oak as Dictionary)["x"]), "y": float((bark_oak as Dictionary)["y"]), "target": bark_oak})
	var hunted := KarmaAI.is_hunted(state, a)
	var cache_range := 300.0 if KarmaShop.has_adapt(a, "cachePlus") else 150.0
	var lurker: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" and KarmaPredators.edible_for(str(o.get("type", "")), "ardilla", float(KarmaData.TUNING["aiFearRange"]))), cache_range)
	if lurker != null and _verb_ready(a, 3):
		menu.append({"kind": "falsecache", "label": "False cache (hunted!)", "x": float((lurker as Dictionary)["x"]), "y": float((lurker as Dictionary)["y"]), "target": lurker})
	var danger: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["aiFearRange"]))
	if danger != null and _verb_ready(a, 1):
		var tf_label := "Tail flick (hunted!)" if hunted else "Tail flick"
		menu.append({"kind": "tailflick", "label": tf_label, "x": float((danger as Dictionary)["x"]), "y": float((danger as Dictionary)["y"]), "target": danger})
	if float(a.get("sed", 100.0)) < float(KarmaData.TUNING["regenSed"]):
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	if hunted:
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["ardilla"], r, "ardilla") and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["aiCoverRange"]):
				menu.append({"kind": "flee", "label": "Flee to refuge (hunted!)", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := KarmaAI.ai_max_hp(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	return {
		"schema": SCHEMA_VERSION,
		"species": "ardilla",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"carriedNut": bool(a.get("carriedNut", false)),
		"food_near": KarmaEat.nearest_edible_patch_for(state, a, eat_range) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
	}


static func mock_choice(menu: Array) -> int:
	var order := ["eat", "drink", "flee", "bury_nut", "carry_nut", "bark", "tailflick", "falsecache", "seek_food", "wander"]
	for want in order:
		for i in menu.size():
			if str((menu[i] as Dictionary)["kind"]) == want:
				return i
	return maxi(0, menu.size() - 1)


static func mock_macro(state: Dictionary, a: Dictionary) -> bool:
	var menu := build_menu(state, a)
	if menu.is_empty():
		return false
	var answer := {"choice": mock_choice(menu), "probs": [1.0], "emocion": "Instinto"}
	return apply_answer(state, a, menu, answer)


static func _resolve_carry(state: Dictionary, a: Dictionary) -> bool:
	KarmaEat.bury_or_carry_nut(state, a)
	if bool(a.get("carriedNut", false)):
		_set_intent(a, "bury_nut", float(a["x"]), float(a["y"]))
	else:
		_set_intent(a, "wander", float(a["x"]), float(a["y"]))
	return true


static func apply_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	a["jev_emocion"] = str(answer.get("emocion", ""))
	if bool(answer.get("target_gone", false)):
		_set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var idx := int(answer.get("choice", -1))
	if idx < 0 or idx >= menu.size():
		_set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var pick := menu[idx] as Dictionary
	if str(answer.get("emocion", "")) == "":
		answer["emocion"] = KarmaJev.appraise_emocion(build_state(state, a), str(pick["kind"]))
		a["jev_emocion"] = str(answer["emocion"])
	match str(pick["kind"]):
		"eat":
			var target: Variant = pick.get("target", null)
			if target == null:
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "eat", float(pick["x"]), float(pick["y"]), target)
			return KarmaEat.eat_patch(state, target, a)
		"carry_nut", "bury_nut":
			return _resolve_carry(state, a)
		"bark":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4)
		"tailflick":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 1)
		"falsecache":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"seek_food", "drink", "flee":
			_set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target", null))
			return true
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true


static func all_jev_ardillas(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "ardilla" and str(a.get("brain", "")) != "PLAYER")


static func candidate_ids(menu: Array) -> Array:
	var ids: Array = []
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		if kind != "" and not ids.has(kind):
			ids.append(kind)
	return ids


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return "Ardilla hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s carried=%s food=%s water=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["carriedNut"]), str(snap["food_near"]), str(snap["water_near"])]


static func build_batch(state: Dictionary) -> Array:
	var batch: Array = []
	for a in state["agents"] as Array:
		if str(a.get("speciesKey", "")) != "ardilla" or str(a.get("brain", "")) == "PLAYER":
			continue
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state(state, a),
			"question": QUESTION,
			"candidates": build_menu(state, a).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_ardillas(state))


static func build_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	var states: Array = []
	var menus := {}
	var included: Array = []
	for a in agents:
		var menu := build_menu(state, a)
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
			"state": state_text(state, a),
			"questions": {"intent": {"type": "choice", "instructions": QUESTION, "criteria": criteria}},
		})
		menus[rid] = menu
		included.append(a)
	return {"states": states, "menus": menus, "agents": included}
