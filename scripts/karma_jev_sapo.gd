class_name KarmaJevSapo
extends RefCounted

# Sapo NanoJev bridge (Option B, mirrors raton/ardilla):
# GDScript builds the legal candidate menu, sidecar only ranks.
# Micro steering never waits for answers.

const SCHEMA_VERSION := "jev-sapo/v1"
const QUESTION := "Que hace el sapo ahora? Elige un candidato."
const USE_JEV := true


static func _set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	a["jev_intent"] = {"kind": kind, "x": x, "y": y, "ttl": 5.0}
	if target != null:
		(a["jev_intent"] as Dictionary)["target"] = target


static func _verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func _tongue_reach(a: Dictionary) -> float:
	return float(KarmaData.TUNING["tongueRange"]) + (40.0 if KarmaShop.has_adapt(a, "tonguePlus") else 0.0)


static func sapo_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["sapo"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["sapo"],
		"diet": KarmaData.DIET["sapo"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["sapo"],
		"tuning": {
			"tongueRange": float(KarmaData.TUNING["tongueRange"]),
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
	var reach := _tongue_reach(a)
	var forage := float(KarmaData.SPECIES["sapo"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var bug: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), reach)
	if bug != null:
		menu.append({"kind": "eat", "label": "Eat insect", "x": float((bug as Dictionary)["x"]), "y": float((bug as Dictionary)["y"]), "target": bug})
	elif KarmaAI.is_hungry(a):
		var far_bug: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), forage)
		if far_bug != null:
			menu.append({"kind": "seek_food", "label": "Seek insect", "x": float((far_bug as Dictionary)["x"]), "y": float((far_bug as Dictionary)["y"]), "target": far_bug})
	if bug != null and _verb_ready(a, 2):
		menu.append({"kind": "pest", "label": "Pest sweep", "x": float((bug as Dictionary)["x"]), "y": float((bug as Dictionary)["y"]), "target": bug})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	var pressure: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["aiFearRange"]))
	if pressure != null:
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["sapo"], r, "sapo") and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["aiCoverRange"]):
				menu.append({"kind": "flee", "label": "Flee to refuge", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	if pressure != null and not bool(a.get("hidden", false)) and _verb_ready(a, 3):
		menu.append({"kind": "burrowin", "label": "Burrow in", "x": ax, "y": ay})
	var close_hunter: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), 60.0)
	var toxin_cost := float((KarmaData.VERB_DEFS["sapo"] as Array)[3]["costHp"])
	if close_hunter != null and _verb_ready(a, 4) and float(a.get("hp", 0.0)) > toxin_cost:
		menu.append({"kind": "toxin", "label": "Toxin spray", "x": float((close_hunter as Dictionary)["x"]), "y": float((close_hunter as Dictionary)["y"]), "target": close_hunter})
	if float(a.get("shoutCd", 0.0)) <= 0.0:
		var lurker: Variant = KarmaUtils.nearest_from(ax, ay,
			(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"]))
		if lurker != null:
			menu.append({"kind": "croak", "label": "Croak alarm", "x": float((lurker as Dictionary)["x"]), "y": float((lurker as Dictionary)["y"]), "target": lurker})
	var choir := (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("speciesKey", "")) == "sapo" and str(o.get("role", "")) in ["company", "fauna"] and Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["groomRange"]))
	if not choir.is_empty() and _verb_ready(a, 5):
		menu.append({"kind": "chorus", "label": "Chorus", "x": ax, "y": ay})
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := KarmaAI.ai_max_hp(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	return {
		"schema": SCHEMA_VERSION,
		"species": "sapo",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"pressure_near": KarmaUtils.nearest_from(ax, ay,
			(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["aiFearRange"])) != null,
		"insect_near": KarmaUtils.nearest_from(ax, ay, state.get("insects", []), _tongue_reach(a)) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
	}


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return "Sapo hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s pressure=%s insects=%s water=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["pressure_near"]), str(snap["insect_near"]), str(snap["water_near"])]


static func mock_choice(menu: Array) -> int:
	var order := ["eat", "drink", "flee", "toxin", "pest", "burrowin", "croak", "chorus", "seek_food", "wander"]
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
			if target == null or not (state["insects"] as Array).has(target):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "eat", float(pick["x"]), float(pick["y"]), target)
			return KarmaEat.eat_insect(state, target, a)
		"seek_food", "drink", "flee":
			_set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target", null))
			return true
		"pest":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 2)
		"burrowin":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"toxin":
			var toxin_cost := float((KarmaData.VERB_DEFS["sapo"] as Array)[3]["costHp"])
			if float(a.get("hp", 0.0)) <= toxin_cost:
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return false
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4)
		"croak":
			var hunter: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"]))
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			if hunter == null:
				return true
			return KarmaGame.cast_verb_for(state, a, 1)
		"chorus":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 5)
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true


static func all_jev_sapos(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "sapo" and str(a.get("brain", "")) != "PLAYER")


static func candidate_ids(menu: Array) -> Array:
	var ids: Array = []
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		if kind != "" and not ids.has(kind):
			ids.append(kind)
	return ids


static func build_batch(state: Dictionary) -> Array:
	var batch: Array = []
	for a in state["agents"] as Array:
		if str(a.get("speciesKey", "")) != "sapo" or str(a.get("brain", "")) == "PLAYER":
			continue
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state(state, a),
			"question": QUESTION,
			"candidates": build_menu(state, a).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_sapos(state))


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
