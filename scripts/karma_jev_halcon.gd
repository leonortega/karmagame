class_name KarmaJevHalcon
extends RefCounted

# Halcon NanoJev bridge (Option B): GDScript builds the legal candidate menu,
# the local sidecar only ranks. Micro steering never waits for answers.
# Behavior-preserving extraction from KarmaJev.

const SCHEMA_VERSION := "jev-halcon/v1"
const QUESTION := "Que hace el halcon ahora? Elige un candidato."
const USE_JEV := true
const MOCK_ORDER := ["eat", "courtesy", "dive", "scare", "bone", "thermal", "drink", "seek_carrion", "flee", "wander"]


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
	if prey != null and KarmaJevBridge.verb_ready(a, 1):
		menu.append({"kind": "dive", "label": "Dive prey", "x": float((prey as Dictionary)["x"]), "y": float((prey as Dictionary)["y"]), "target": prey})
	var meal: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), eat_range)
	if meal != null:
		var eat_label := "Eat carrion"
		if float(a.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]):
			eat_label = "Eat carrion (you are hungry: eat now!)"
		menu.append({"kind": "eat", "label": eat_label, "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
		if bool(a.get("grounded", false)) and KarmaEat.carrion_stage(meal) == "fresh" and not bool((meal as Dictionary).get("ceded", false)) and KarmaJevBridge.verb_ready(a, 3):
			menu.append({"kind": "courtesy", "label": "Share carrion", "x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"]), "target": meal})
	elif KarmaAI.is_hungry(a):
		var far: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), hunt_range)
		if far != null:
			menu.append({"kind": "seek_carrion", "label": "Seek carrion", "x": float((far as Dictionary)["x"]), "y": float((far as Dictionary)["y"]), "target": far})
	var small: Variant = KarmaUtils.nearest_from(ax, ay,
		(state["agents"] as Array).filter(func(o): return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) != str(state["speciesKey"]) and int(KarmaData.SPECIES.get(str(o.get("speciesKey", "raton")), {"size": 9})["size"]) <= 2), 90.0)
	if small != null and KarmaJevBridge.verb_ready(a, 4):
		menu.append({"kind": "scare", "label": "Scare prey", "x": float((small as Dictionary)["x"]), "y": float((small as Dictionary)["y"]), "target": small})
	if KarmaJevBridge.verb_ready(a, 5):
		menu.append({"kind": "bone", "label": "Drop bone", "x": ax, "y": ay})
	if KarmaJevBridge.verb_ready(a, 2) and float(a.get("thermalT", 0.0)) <= 0.0 and float(a.get("pa", 0.0)) >= float((KarmaData.VERB_DEFS["halcon"] as Array)[1]["costPa"]):
		menu.append({"kind": "thermal", "label": "Ride thermal (-%d PA)" % int(float((KarmaData.VERB_DEFS["halcon"] as Array)[1]["costPa"])), "x": ax, "y": ay})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var forage := float(KarmaData.SPECIES["halcon"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	if KarmaAI.is_hunted(state, a):
		var cover_range: float = float(KarmaData.TUNING["aiCoverRange"])
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["halcon"], r, "halcon") and KarmaUtils.dist2(float(r["x"]), float(r["y"]), ax, ay) <= cover_range * cover_range:
				menu.append({"kind": "flee", "label": "Flee to refuge", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_halcon_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := KarmaState.eff_max_hp_for(a)
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
	}.merged(KarmaJev.age_fields(state, a))


static func all_jev_halcons(state: Dictionary) -> Array:
	return KarmaJevBridge.all_agents(state, "halcon")


static func halcon_state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_halcon_state(state, a)
	return KarmaJevBridge.state_text("Halcon", snap, "grounded=%s landT=%.1f prey=%s carrion=%s water=%s",
		[str(snap["grounded"]), float(snap["landT"]),
		str(snap["prey_visible"]), str(snap["carrion_near"]), str(snap["water_near"])])


static func build_halcon_http_body(state: Dictionary) -> Dictionary:
	return build_halcon_http_body_for(state, all_jev_halcons(state))


static func build_halcon_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevBridge.build_http_body_for(state, agents,
		Callable(KarmaJevHalcon, "build_halcon_menu"), Callable(KarmaJevHalcon, "halcon_state_text"), QUESTION)


static func halcon_mock_choice(menu: Array) -> int:
	return KarmaJevBridge.mock_choice(menu, MOCK_ORDER)


static func mock_halcon_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevBridge.mock_macro(state, a,
		Callable(KarmaJevHalcon, "build_halcon_menu"), MOCK_ORDER, Callable(KarmaJevHalcon, "apply_halcon_answer"))


static func apply_halcon_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	a["jev_emocion"] = str(answer.get("emocion", ""))
	if bool(answer.get("target_gone", false)):
		KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var idx := int(answer.get("choice", -1))
	if idx < 0 or idx >= menu.size():
		KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var pick := menu[idx] as Dictionary
	match str(pick["kind"]):
		"eat":
			if not (state["carrions"] as Array).has(pick.get("target")):
				KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			KarmaJevBridge.set_intent(a, "eat", float(pick["x"]), float(pick["y"]), pick.get("target"))
			return KarmaEat.eat_carrion(state, pick.get("target"), a)
		"courtesy":
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"scare", "bone":
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4 if str(pick["kind"]) == "scare" else 5)
		"thermal":
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 2)
		"dive", "seek_carrion", "drink", "flee":
			KarmaJevBridge.set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target"))
			return true
		_:
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
