class_name KarmaJevZorro
extends RefCounted

# Zorro NanoJev bridge (Option B): GDScript builds the legal candidate menu,
# the local sidecar only ranks. Micro steering never waits for answers.
# Behavior-preserving extraction from KarmaJev.

const SCHEMA_VERSION := "jev-zorro/v1"
const QUESTION := "Que hace el zorro ahora? Elige un candidato."
const USE_JEV := true


static func _verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func _max_hp(a: Dictionary) -> float:
	return KarmaAI.ai_max_hp(a)


static func _set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	a["jev_intent"] = {"kind": kind, "x": x, "y": y, "ttl": 5.0}


static func _flavor(a: Dictionary) -> String:
	var e := str(a.get("jev_emocion", ""))
	return " [" + e + "]" if e != "" else ""


static func zorro_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["zorro"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["zorro"],
		"diet": KarmaData.DIET["zorro"],
		"pred": KarmaData.PRED["zorro"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["zorro"],
		"tuning": {
			"eatRange": float(KarmaData.TUNING["eatRange"]),
			"drinkRange": float(KarmaData.TUNING["drinkRange"]),
			"pounceRange": float(KarmaData.TUNING["pounceRange"]),
			"pounceCd": float(KarmaData.TUNING["pounceCd"]),
			"strikeCd": float(KarmaData.TUNING["strikeCd"]),
			"cedeKarma": float(KarmaData.TUNING["cedeKarma"]),
			"forageRangeMult": float(KarmaData.TUNING["forageRangeMult"]),
			"hungerPriority": float(KarmaData.TUNING["hungerPriority"]),
			"aiFearRange": float(KarmaData.TUNING["aiFearRange"]),
			"aiCoverRange": float(KarmaData.TUNING["aiCoverRange"]),
			"wastefulHpFrac": float(KarmaData.TUNING["wastefulHpFrac"]),
			"regenSed": float(KarmaData.TUNING["regenSed"]),
		},
	}


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var pounce_range := float(KarmaData.TUNING["pounceRange"])
	var perception := float(KarmaAI.ai_pred_row(a).get("perception", 200.0))
	var max_hp := _max_hp(a)
	var defs: Array = KarmaData.VERB_DEFS["zorro"]
	var dendig_cost := float(defs[3]["costHp"])
	var mate: Variant = KarmaUtils.nearest_from(ax, ay, KarmaState.company_agents(state), pounce_range)
	if float(a.get("pounceCd", 0.0)) <= 0.0 and mate != null:
		menu.append({"kind": "pounce", "label": "Pounce raton", "x": float((mate as Dictionary)["x"]), "y": float((mate as Dictionary)["y"]), "target": mate})
	if KarmaAI.nearest_ai_prey(state, a, perception) != null:
		var prey: Variant = KarmaAI.nearest_ai_prey(state, a, perception)
		menu.append({"kind": "hunt", "label": "Hunt prey", "x": float((prey as Dictionary)["x"]), "y": float((prey as Dictionary)["y"]), "target": prey})
	var meal: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), eat_range)
	if meal != null:
		menu.append({"kind": "eat", "label": "Eat carrion", "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
		if not bool((meal as Dictionary).get("ceded", false)) and float(a.get("hp", max_hp)) >= float(KarmaData.TUNING["wastefulHpFrac"]) * max_hp and _verb_ready(a, 3):
			menu.append({"kind": "cede", "label": "Cede carrion", "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
		if KarmaEat.carrion_stage(meal) != "rotten" and int(a.get("stash", 0)) <= 0 and _verb_ready(a, 2):
			var cache_label := "Cache carrion"
			if float(a.get("hambre", 100.0)) >= float(KarmaData.TUNING["cacheFullHambre"]):
				cache_label = "Cache carrion (you are full: store it for later)"
			menu.append({"kind": "cache", "label": cache_label, "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
	elif KarmaAI.is_hungry(a):
		var far: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), perception)
		if far != null:
			menu.append({"kind": "seek_carrion", "label": "Seek carrion", "x": float((far as Dictionary)["x"]), "y": float((far as Dictionary)["y"]), "target": far})
	if float(a.get("hp", max_hp)) > dendig_cost and _verb_ready(a, 4):
		menu.append({"kind": "dendig", "label": "Dig den", "x": ax, "y": ay})
	var threat: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
	if threat != null and float(a.get("strikeCd", 0.0)) <= 0.0 and _verb_ready(a, 5):
		menu.append({"kind": "strike", "label": "Strike predator", "x": float((threat as Dictionary)["x"]), "y": float((threat as Dictionary)["y"]), "target": threat})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var forage := float(KarmaData.SPECIES["zorro"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	var fear: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" and str(o.get("type", "")) in (KarmaData.PRED["zorro"] as Dictionary).get("fears", [])), float(KarmaData.TUNING["aiFearRange"]))
	if fear != null:
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["zorro"], r, "zorro") and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["aiCoverRange"]):
				menu.append({"kind": "flee", "label": "Flee to refuge", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := _max_hp(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	var perception := float(KarmaAI.ai_pred_row(a).get("perception", 200.0))
	return {
		"schema": SCHEMA_VERSION,
		"species": "zorro",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"sated": float(a.get("satedT", 0.0)) > 0.0,
		"cds": {
			"pounce": float(a.get("pounceCd", 0.0)),
			"strike": float(a.get("strikeCd", 0.0)),
			"verbs": (a.get("verbCds", [0.0, 0.0, 0.0, 0.0, 0.0]) as Array).duplicate(),
		},
		"prey_visible": KarmaAI.nearest_ai_prey(state, a, perception) != null,
		"carrion_near": KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), float(KarmaData.TUNING["eatRange"])) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
	}


static func build_batch(state: Dictionary) -> Array:
	var batch: Array = []
	for a in state["agents"] as Array:
		if str(a.get("speciesKey", "")) != "zorro" or str(a.get("brain", "")) == "PLAYER":
			continue
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state(state, a),
			"question": QUESTION,
			"candidates": build_menu(state, a).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func mock_choice(menu: Array) -> int:
	var order := ["eat", "cede", "pounce", "hunt", "strike", "cache", "dendig", "drink", "flee", "seek_carrion", "wander"]
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


static func all_jev_zorros(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "zorro" and str(a.get("brain", "")) != "PLAYER")


static func candidate_ids(menu: Array) -> Array:
	var ids: Array = []
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		if kind != "" and not ids.has(kind):
			ids.append(kind)
	return ids


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return "Zorro hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s sated=%s pounce_cd=%.0f strike_cd=%.0f prey=%s carrion=%s water=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["sated"]),
		float((snap["cds"] as Dictionary)["pounce"]), float((snap["cds"] as Dictionary)["strike"]),
		str(snap["prey_visible"]), str(snap["carrion_near"]), str(snap["water_near"])]


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_zorros(state))


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
	match str(pick["kind"]):
		"eat":
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "eat", float(pick["x"]), float(pick["y"]), pick.get("target"))
			return KarmaEat.eat_carrion(state, pick.get("target"), a)
		"cede":
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			(pick.get("target") as Dictionary)["ceded"] = true
			var ck: float = float(KarmaData.TUNING["cedeKarma"]) * (2.0 if KarmaShop.has_adapt(a, "cedePlus") else 1.0)
			KarmaState.add_karma(state, a, ck, "Cede la presa a otros (+karma)" + _flavor(a))
			(a["verbCds"] as Array)[2] = float((KarmaData.VERB_DEFS["zorro"] as Array)[2]["cd"])
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"cache":
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			(state["carrions"] as Array).erase(pick.get("target"))
			a["stash"] = 1
			(a["verbCds"] as Array)[1] = float((KarmaData.VERB_DEFS["zorro"] as Array)[1]["cd"])
			KarmaState.add_log(state, a, "Entierras carroña para después" + _flavor(a))
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"dendig":
			(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": float(a["x"]), "y": float(a["y"]), "dug": true})
			a["hp"] = float(a.get("hp", 0.0)) - float((KarmaData.VERB_DEFS["zorro"] as Array)[3]["costHp"])
			a["pa"] = float(a.get("pa", 0.0)) - float((KarmaData.VERB_DEFS["zorro"] as Array)[3]["costPa"])
			(a["verbCds"] as Array)[3] = float((KarmaData.VERB_DEFS["zorro"] as Array)[3]["cd"])
			KarmaState.add_log(state, a, "Excavas una guarida" + _flavor(a))
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"strike":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 5)
		"pounce", "hunt", "seek_carrion", "drink", "flee":
			_set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target"))
			return true
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
