class_name KarmaJevLobo
extends RefCounted

# Lobo NanoJev bridge (Option B, mirrors zorro/topo):
# GDScript builds the legal candidate menu, sidecar only ranks.
# Micro steering never waits for answers. howl/escort/cull stay player-only,
# so the menu never offers them.


const SCHEMA_VERSION := "jev-lobo/v1"
const QUESTION := "Que hace el lobo ahora? Elige un candidato."
const USE_JEV := true


static func _set_intent(a: Dictionary, kind: String, x: float, y: float, target: Variant = null) -> void:
	a["jev_intent"] = {"kind": kind, "x": x, "y": y, "ttl": 5.0}
	if target != null:
		(a["jev_intent"] as Dictionary)["target"] = target


static func _verb_ready(a: Dictionary, slot: int) -> bool:
	if not a.has("verbCds"):
		return true
	return float((a["verbCds"] as Array)[slot - 1]) <= 0.0


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var perception := float(KarmaAI.ai_pred_row(a).get("perception", 280.0))
	# Contact carrion first; distant carrion only when hungry.
	var meal: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), eat_range)
	if meal != null:
		menu.append({"kind": "eat", "label": "Eat carrion", "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
	elif KarmaAI.is_hungry(a):
		var trek := float(KarmaData.TUNING["wanderSeekRange"])
		var far: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), trek)
		if far != null:
			menu.append({"kind": "seek_carrion", "label": "Seek carrion", "x": float((far as Dictionary)["x"]), "y": float((far as Dictionary)["y"]), "target": far})
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, perception)
	if prey != null:
		menu.append({"kind": "hunt", "label": "Hunt prey", "x": float((prey as Dictionary)["x"]), "y": float((prey as Dictionary)["y"]), "target": prey})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var forage := float(KarmaData.SPECIES["lobo"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	var threat: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
	if threat != null and float(a.get("strikeCd", 0.0)) <= 0.0 and _verb_ready(a, 3):
		menu.append({"kind": "strike", "label": "Strike predator", "x": float((threat as Dictionary)["x"]), "y": float((threat as Dictionary)["y"]), "target": threat})
	if _verb_ready(a, 2) and float(a.get("hp", 0.0)) > float(KarmaData.TUNING["regurgCost"]):
		var den: Array = KarmaState.company_agents(state) + (state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "fauna")
		var pack := den.filter(func(o):
			return o != a and str(o.get("speciesKey", "")) == "lobo" and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
		var hungry_mate: Variant = KarmaUtils.nearest_from(ax, ay, pack, float(KarmaData.TUNING["groomRange"]))
		if hungry_mate != null:
			menu.append({"kind": "regurg", "label": "Feed packmate", "x": float((hungry_mate as Dictionary)["x"]), "y": float((hungry_mate as Dictionary)["y"]), "target": hungry_mate})
	if float(a.get("shoutCd", 0.0)) <= 0.0:
		var hunter: Variant = KarmaUtils.nearest_from(ax, ay,
			(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"]))
		if hunter != null:
			menu.append({"kind": "alarm", "label": "Alarm call", "x": float((hunter as Dictionary)["x"]), "y": float((hunter as Dictionary)["y"]), "target": hunter})
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func mock_choice(menu: Array) -> int:
	var order := ["eat", "strike", "regurg", "hunt", "alarm", "drink", "seek_carrion", "wander"]
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
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "eat", float(pick["x"]), float(pick["y"]), pick.get("target"))
			return KarmaEat.eat_carrion(state, pick.get("target"), a)
		"hunt":
			var prey: Variant = pick.get("target", null)
			if prey == null or not (state["agents"] as Array).has(prey) or bool((prey as Dictionary).get("hidden", false)):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "hunt", float(pick["x"]), float(pick["y"]), prey)
			return true
		"seek_carrion":
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			_set_intent(a, "seek_carrion", float(pick["x"]), float(pick["y"]), pick.get("target"))
			return true
		"drink":
			_set_intent(a, "drink", float(pick["x"]), float(pick["y"]))
			return true
		"strike":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"regurg":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 2)
		"alarm":
			var hunter: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"]))
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			if hunter == null:
				return true
			return KarmaState.ai_try_shout(state, a)
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true


static func lobo_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["lobo"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["lobo"],
		"diet": KarmaData.DIET["lobo"],
		"pred": KarmaData.PRED["lobo"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["lobo"],
		"tuning": {
			"eatRange": float(KarmaData.TUNING["eatRange"]),
			"drinkRange": float(KarmaData.TUNING["drinkRange"]),
			"strikeCd": float(KarmaData.TUNING["strikeCd"]),
			"regurgCost": float(KarmaData.TUNING["regurgCost"]),
			"forageRangeMult": float(KarmaData.TUNING["forageRangeMult"]),
			"hungerPriority": float(KarmaData.TUNING["hungerPriority"]),
			"aiFearRange": float(KarmaData.TUNING["aiFearRange"]),
			"aiCoverRange": float(KarmaData.TUNING["aiCoverRange"]),
			"regenSed": float(KarmaData.TUNING["regenSed"]),
		},
	}


static func build_batch(state: Dictionary) -> Array:
	var batch: Array = []
	for a in state["agents"] as Array:
		if str(a.get("speciesKey", "")) != "lobo" or str(a.get("brain", "")) == "PLAYER":
			continue
		batch.append({
			"id": str(a.get("instance_id", str(a))),
			"state": build_state(state, a),
			"question": QUESTION,
			"candidates": build_menu(state, a).map(func(c): return str((c as Dictionary)["kind"]) + ": " + str((c as Dictionary)["label"])),
		})
	return batch


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_lobos(state))


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


static func _max_hp(a: Dictionary) -> float:
	return KarmaAI.ai_max_hp(a)


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := _max_hp(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	var perception := float(KarmaAI.ai_pred_row(a).get("perception", 280.0))
	return {
		"schema": SCHEMA_VERSION,
		"species": "lobo",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"prey_visible": KarmaAI.nearest_ai_prey(state, a, perception) != null,
		"carrion_near": KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), float(KarmaData.TUNING["eatRange"])) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
	}


static func is_red_flag(snapshot: Dictionary, menu: Array, answer: Dictionary) -> bool:
	if not bool(snapshot.get("hungry", false)):
		return false
	var kinds: Array = menu.map(func(c): return str((c as Dictionary).get("kind", c)))
	if not kinds.has("eat"):
		return false
	var idx := int(answer.get("choice", -1))
	return idx >= 0 and idx < kinds.size() and str(kinds[idx]) == "wander"


static func need_token(state: Dictionary, a: Dictionary) -> String:
	if float(a.get("hambre", 100.0)) <= float(KarmaData.TUNING["regenHambre"]):
		return "urgent"
	if KarmaAI.is_hungry(a):
		return "hunger"
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		return "thirst"
	return "none"


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return "Lobo hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s prey=%s carrion=%s water=%s need=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["prey_visible"]),
		str(snap["carrion_near"]), str(snap["water_near"]), need_token(state, a)]


static func all_jev_lobos(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "lobo" and str(a.get("brain", "")) != "PLAYER")


static func candidate_ids(menu: Array) -> Array:
	var ids: Array = []
	for c in menu:
		var kind := str((c as Dictionary)["kind"])
		if kind != "" and not ids.has(kind):
			ids.append(kind)
	return ids
