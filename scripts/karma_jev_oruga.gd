class_name KarmaJevOruga
extends RefCounted

# Oruga NanoJev bridge (Option B, mirrors sapo):
# GDScript builds the legal candidate menu, sidecar only ranks.
# Micro steering never waits for answers. prudent is covered by eat
# (eat_patch pays prudentKarma automatically) and bristle stays
# player-only, so the menu never offers either.

const SCHEMA_VERSION := "jev-oruga/v1"
const QUESTION := "Que hace la oruga ahora? Elige un candidato."
const USE_JEV := true
# Same hunter range as the ladder silk/nectar verbs.
const HUNTER_RANGE := 150.0


static func _set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	a["jev_intent"] = {"kind": kind, "x": x, "y": y, "ttl": 5.0}
	if target != null:
		(a["jev_intent"] as Dictionary)["target"] = target


static func _verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func _silk_cost() -> float:
	return float((KarmaData.VERB_DEFS["oruga"] as Array)[1]["costHp"])


static func _nectar_costs() -> Array:
	var def: Dictionary = (KarmaData.VERB_DEFS["oruga"] as Array)[2]
	return [float(def["costHp"]), float(def["costPa"])]


static func _hunter_near(state: Dictionary, a: Dictionary) -> Variant:
	return KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter"), HUNTER_RANGE)


static func _clump_near(state: Dictionary, a: Dictionary) -> Variant:
	return KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		state.get("clumps", []), float(KarmaData.TUNING["eatRange"]))


static func _flora_lists(state: Dictionary) -> Array:
	var out: Array = []
	for key in ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks"]:
		out.append_array(state.get(key, []))
	return out


static func patch_still_edible(state: Dictionary, target: Variant) -> bool:
	if not (target is Dictionary):
		return false
	if str((target as Dictionary).get("kind", "")) == "":
		return false
	if not bool((target as Dictionary).get("alive", false)):
		return false
	if int((target as Dictionary).get("amount", 0)) <= 0:
		return false
	return _flora_lists(state).has(target)


static func oruga_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["oruga"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["oruga"],
		"diet": KarmaData.DIET["oruga"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["oruga"],
		"tuning": {
			"eatRange": float(KarmaData.TUNING["eatRange"]),
			"drinkRange": float(KarmaData.TUNING["drinkRange"]),
			"forageRangeMult": float(KarmaData.TUNING["forageRangeMult"]),
			"hungerPriority": float(KarmaData.TUNING["hungerPriority"]),
			"aiFearRange": float(KarmaData.TUNING["aiFearRange"]),
			"aiCoverRange": float(KarmaData.TUNING["aiCoverRange"]),
			"regenSed": float(KarmaData.TUNING["regenSed"]),
		},
	}


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var forage := float(KarmaData.SPECIES["oruga"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, eat_range)
	if patch != null:
		var eat_label := "Eat leaves"
		if float(a.get("hambre", 100.0)) <= float(KarmaData.TUNING["regenHambre"]):
			eat_label = "Eat leaves (you are hungry: eat now!)"
		menu.append({"kind": "eat", "label": eat_label, "x": float((patch as Dictionary)["x"]), "y": float((patch as Dictionary)["y"]), "target": patch})
	elif KarmaAI.is_hungry(a):
		var far_patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, forage)
		if far_patch != null:
			var seek_label := "Seek leaves"
			if float(a.get("hambre", 100.0)) <= float(KarmaData.TUNING["regenHambre"]):
				seek_label = "Seek leaves (you are hungry: seek now!)"
			menu.append({"kind": "seek_food", "label": seek_label, "x": float((far_patch as Dictionary)["x"]), "y": float((far_patch as Dictionary)["y"]), "target": far_patch})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			var drink_label := "Drink water"
			if float(a.get("sed", 100.0)) <= float(KarmaData.TUNING["regenSed"]):
				drink_label = "Drink water (you are thirsty: drink now!)"
			menu.append({"kind": "drink", "label": drink_label, "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	if KarmaAI.is_hunted(state, a):
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["oruga"], r, "oruga") and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["aiCoverRange"]):
				menu.append({"kind": "flee", "label": "Flee to refuge (hunted!)", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	var hunter: Variant = _hunter_near(state, a)
	if hunter != null and _verb_ready(a, 2) and float(a.get("hp", 0.0)) > _silk_cost():
		menu.append({"kind": "silk", "label": "Silk escape (hunted!)", "x": float((hunter as Dictionary)["x"]), "y": float((hunter as Dictionary)["y"]), "target": hunter})
	var costs := _nectar_costs()
	if hunter != null and _verb_ready(a, 3) and float(a.get("hp", 0.0)) > float(costs[0]) and float(a.get("pa", 0.0)) >= float(costs[1]):
		menu.append({"kind": "nectar", "label": "Ant-ally nectar", "x": float((hunter as Dictionary)["x"]), "y": float((hunter as Dictionary)["y"]), "target": hunter})
	var clump: Variant = _clump_near(state, a)
	if clump != null and _verb_ready(a, 4):
		menu.append({"kind": "leafroll", "label": "Roll leaf shelter", "x": float((clump as Dictionary)["x"]), "y": float((clump as Dictionary)["y"]), "target": clump})
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := KarmaAI.ai_max_hp(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	return {
		"schema": SCHEMA_VERSION,
		"species": "oruga",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"pressure_near": KarmaUtils.nearest_from(ax, ay,
			(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter"), float(KarmaData.TUNING["aiFearRange"])) != null,
		"food_near": KarmaEat.nearest_edible_patch_for(state, a, eat_range) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
		"clump_near": _clump_near(state, a) != null,
	}


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return "Oruga hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s pressure=%s food=%s water=%s clump=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["pressure_near"]), str(snap["food_near"]),
		str(snap["water_near"]), str(snap["clump_near"])]


static func mock_choice(menu: Array) -> int:
	var order := ["eat", "drink", "flee", "silk", "leafroll", "nectar", "seek_food", "wander"]
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
			if not patch_still_edible(state, target):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "eat", float(pick["x"]), float(pick["y"]), target)
			return KarmaEat.eat_patch(state, target, a)
		"seek_food", "drink", "flee":
			_set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target", null))
			return true
		"silk":
			if _hunter_near(state, a) == null or float(a.get("hp", 0.0)) <= _silk_cost():
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 2)
		"nectar":
			var costs := _nectar_costs()
			if _hunter_near(state, a) == null or float(a.get("hp", 0.0)) <= float(costs[0]) or float(a.get("pa", 0.0)) < float(costs[1]):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"leafroll":
			if _clump_near(state, a) == null:
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4)
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true


static func all_jev_orugas(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "oruga" and str(a.get("brain", "")) != "PLAYER")


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
		if str(a.get("speciesKey", "")) != "oruga" or str(a.get("brain", "")) == "PLAYER":
			continue
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state(state, a),
			"question": QUESTION,
			"candidates": build_menu(state, a).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_orugas(state))


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
