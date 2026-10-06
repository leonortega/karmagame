class_name KarmaJevHalcon
extends RefCounted

# Halcon NanoJev bridge (Option B): GDScript builds the legal candidate menu,
# the local sidecar only ranks. Micro steering never waits for answers.
# Behavior-preserving extraction from KarmaJev.

const SCHEMA_VERSION := "jev-halcon/v1"
const QUESTION := "Que hace el halcon ahora? Elige un candidato."
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


static func halcon_definition() -> Dictionary:
	var defs: Array = KarmaData.VERB_DEFS["halcon"]
	return {
		"schema": SCHEMA_VERSION,
		"species": KarmaData.SPECIES["halcon"],
		"diet": KarmaData.DIET["halcon"],
		"verbs": defs,
		"shop": KarmaData.SHOP_BY_SPECIES["halcon"],
		"tuning": {
			"eatRange": float(KarmaData.TUNING["eatRange"]),
			"drinkRange": float(KarmaData.TUNING["drinkRange"]),
			"landTime": float(KarmaData.TUNING["landTime"]),
			"forageRangeMult": float(KarmaData.TUNING["forageRangeMult"]),
			"hungerPriority": float(KarmaData.TUNING["hungerPriority"]),
			"aiFearRange": float(KarmaData.TUNING["aiFearRange"]),
			"aiCoverRange": float(KarmaData.TUNING["aiCoverRange"]),
			"regenSed": float(KarmaData.TUNING["regenSed"]),
		},
	}


static func build_halcon_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var hunt_range := 200.0
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, hunt_range)
	if prey != null and _verb_ready(a, 1):
		menu.append({"kind": "dive", "label": "Dive prey", "x": float((prey as Dictionary)["x"]), "y": float((prey as Dictionary)["y"]), "target": prey})
	var meal: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), eat_range)
	if meal != null:
		var eat_label := "Eat carrion"
		if float(a.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]):
			eat_label = "Eat carrion (you are hungry: eat now!)"
		menu.append({"kind": "eat", "label": eat_label, "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
		if bool(a.get("grounded", false)) and KarmaEat.carrion_stage(meal) == "fresh" and not bool((meal as Dictionary).get("ceded", false)) and _verb_ready(a, 3):
			menu.append({"kind": "courtesy", "label": "Share carrion", "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
	elif KarmaAI.is_hungry(a):
		var far: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), hunt_range)
		if far != null:
			menu.append({"kind": "seek_carrion", "label": "Seek carrion", "x": float((far as Dictionary)["x"]), "y": float((far as Dictionary)["y"]), "target": far})
	var small: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return o != a and str(o.get("role", "")) == "fauna" and int(KarmaData.SPECIES.get(str(o.get("speciesKey", "raton")), {"size": 9})["size"]) <= 2), 90.0)
	if small != null and _verb_ready(a, 4):
		menu.append({"kind": "scare", "label": "Scare prey", "x": float((small as Dictionary)["x"]), "y": float((small as Dictionary)["y"]), "target": small})
	if _verb_ready(a, 5):
		menu.append({"kind": "bone", "label": "Drop bone", "x": ax, "y": ay})
	if _verb_ready(a, 2) and float(a.get("thermalT", 0.0)) <= 0.0 and float(a.get("pa", 0.0)) >= float((KarmaData.VERB_DEFS["halcon"] as Array)[1]["costPa"]):
		menu.append({"kind": "thermal", "label": "Ride thermal (-%d PA)" % int(float((KarmaData.VERB_DEFS["halcon"] as Array)[1]["costPa"])), "x": ax, "y": ay})
	if float(a.get("sed", 100.0)) < float(KarmaData.TUNING["regenSed"]):
		var forage := float(KarmaData.SPECIES["halcon"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	if KarmaAI.is_hunted(state, a):
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["halcon"], r, "halcon") and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(ax, ay)) <= float(KarmaData.TUNING["aiCoverRange"]):
				menu.append({"kind": "flee", "label": "Flee to refuge", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_halcon_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := _max_hp(a)
	return {
		"schema": SCHEMA_VERSION,
		"species": "halcon",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"grounded": bool(a.get("grounded", false)),
		"landT": float(a.get("landT", 0.0)),
		"prey_visible": KarmaAI.nearest_ai_prey(state, a, 200.0) != null,
		"carrion_near": KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"])) != null,
		"water_near": KarmaUtils.nearest_water_for(state, float(a["x"]), float(a["y"]), float(KarmaData.TUNING["drinkRange"])) != null,
	}


static func all_jev_halcons(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == "halcon" and str(a.get("brain", "")) != "PLAYER")


static func halcon_state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_halcon_state(state, a)
	return "Halcon hp_frac=%.2f hambre=%d sed=%d karma=%d pa=%d hungry=%s threatened=%s grounded=%s landT=%.1f prey=%s carrion=%s water=%s" % [
		float(snap["hp_frac"]), int(snap["hambre"]), int(snap["sed"]),
		int(snap["karma"]), int(snap["pa"]), str(snap["hungry"]),
		str(snap["threatened"]), str(snap["grounded"]), float(snap["landT"]),
		str(snap["prey_visible"]), str(snap["carrion_near"]), str(snap["water_near"])]


static func build_halcon_http_body(state: Dictionary) -> Dictionary:
	return build_halcon_http_body_for(state, all_jev_halcons(state))


static func build_halcon_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	var states: Array = []
	var menus := {}
	var included: Array = []
	for a in agents:
		var menu := build_halcon_menu(state, a)
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
			"state": halcon_state_text(state, a),
			"questions": {"intent": {"type": "choice", "instructions": QUESTION, "criteria": criteria}},
		})
		menus[rid] = menu
		included.append(a)
	return {"states": states, "menus": menus, "agents": included}


static func halcon_mock_choice(menu: Array) -> int:
	var order := ["eat", "courtesy", "dive", "scare", "bone", "thermal", "drink", "seek_carrion", "flee", "wander"]
	for want in order:
		for i in menu.size():
			if str((menu[i] as Dictionary)["kind"]) == want:
				return i
	return maxi(0, menu.size() - 1)


static func mock_halcon_macro(state: Dictionary, a: Dictionary) -> bool:
	var menu := build_halcon_menu(state, a)
	if menu.is_empty():
		return false
	var answer := {"choice": halcon_mock_choice(menu), "probs": [1.0], "emocion": "Instinto"}
	return apply_halcon_answer(state, a, menu, answer)


static func apply_halcon_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
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
		"courtesy":
			if not (state["carrions"] as Array).has(pick.get("target")):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			if KarmaEat.carrion_stage(pick.get("target")) != "fresh" or bool((pick.get("target") as Dictionary).get("ceded", false)):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			(pick.get("target") as Dictionary)["ceded"] = true
			KarmaState.add_karma(state, a, float(KarmaData.TUNING["cedeKarma"]), "Carroña compartida (+karma)" + _flavor(a))
			(a["verbCds"] as Array)[2] = float((KarmaData.VERB_DEFS["halcon"] as Array)[2]["cd"])
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"scare", "bone":
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4 if str(pick["kind"]) == "scare" else 5)
		"thermal":
			var defs: Array = KarmaData.VERB_DEFS["halcon"]
			if float(a.get("pa", 0.0)) < float(defs[1]["costPa"]):
				_set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return false
			a["pa"] = float(a.get("pa", 0.0)) - float(defs[1]["costPa"])
			(a["verbCds"] as Array)[1] = float(defs[1]["cd"])
			a["thermalT"] = float(KarmaData.TUNING["thermalTime"]) * (2.0 if KarmaShop.has_adapt(a, "thermalPlus") else 1.0)
			KarmaState.add_log(state, a, "Térmica: ojo de águila" + _flavor(a))
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"dive", "seek_carrion", "drink", "flee":
			_set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target"))
			return true
		_:
			_set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
