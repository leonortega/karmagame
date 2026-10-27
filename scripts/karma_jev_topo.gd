class_name KarmaJevTopo
extends RefCounted

# Topo NanoJev bridge (Option B, mirrors sapo/raton/ardilla):
# GDScript builds the legal candidate menu, sidecar only ranks.
# Micro steering never waits for answers. nestdig stays player-only,
# so the menu never offers it.


const SCHEMA_VERSION := "jev-topo/v1"
const QUESTION := "Que hace el topo ahora? Elige un candidato."
const USE_JEV := true
const MOCK_ORDER := ["eat", "drink", "flee", "alarm", "worm", "aerate", "tunneline", "larder", "seek_food", "wander"]


static func _dug_near(state: Dictionary, a: Dictionary) -> Variant:
	return KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["refuges"] as Array).filter(func(r): return bool(r.get("dug", false))),
		float(KarmaData.TUNING["eatRange"]))


static func patch_still_edible(target: Variant) -> bool:
	if not (target as Dictionary).has("kind"):
		return false
	if not bool((target as Dictionary).get("alive", false)):
		return false
	return int((target as Dictionary).get("amount", 0)) > 0


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	var menu: Array = []
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	var forage := float(KarmaData.SPECIES["topo"]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	# Contact food, insect-first like ai_grazer_eat.
	var bug: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), eat_range)
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, eat_range)
	if bug != null:
		menu.append({"kind": "eat", "label": "Eat insect", "x": float((bug as Dictionary)["x"]), "y": float((bug as Dictionary)["y"]), "target": bug})
	elif patch != null:
		menu.append({"kind": "eat", "label": "Eat food", "x": float((patch as Dictionary)["x"]), "y": float((patch as Dictionary)["y"]), "target": patch})
	elif KarmaAI.is_hungry(a):
		var far_bug: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), forage)
		var far_patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, forage)
		if far_bug != null:
			menu.append({"kind": "seek_food", "label": "Seek insect", "x": float((far_bug as Dictionary)["x"]), "y": float((far_bug as Dictionary)["y"]), "target": far_bug})
		elif far_patch != null:
			menu.append({"kind": "seek_food", "label": "Seek food", "x": float((far_patch as Dictionary)["x"]), "y": float((far_patch as Dictionary)["y"]), "target": far_patch})
	if float(a.get("sed", 100.0)) < KarmaAI.water_threshold(a):
		var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, forage)
		if water != null:
			menu.append({"kind": "drink", "label": "Drink water", "x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])})
	if KarmaAI.is_hunted(state, a):
		var cover_range: float = float(KarmaData.TUNING["aiCoverRange"])
		for r in state.get("refuges", []):
			if KarmaAI.refuge_fits_size(KarmaData.SPECIES["topo"], r, "topo") and KarmaUtils.dist2(float(r["x"]), float(r["y"]), ax, ay) <= cover_range * cover_range:
				menu.append({"kind": "flee", "label": "Flee to refuge", "x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "target": r})
				break
	var dug: Variant = _dug_near(state, a)
	if KarmaJevBridge.verb_ready(a, 1):
		menu.append({"kind": "aerate", "label": "Aerate soil", "x": ax, "y": ay})
	if dug != null and KarmaJevBridge.verb_ready(a, 2):
		menu.append({"kind": "tunneline", "label": "Line tunnel", "x": float((dug as Dictionary)["x"]), "y": float((dug as Dictionary)["y"]), "target": dug})
	if dug != null and KarmaAI.is_hungry(a) and KarmaJevBridge.verb_ready(a, 3):
		menu.append({"kind": "worm", "label": "Rescue worm", "x": float((dug as Dictionary)["x"]), "y": float((dug as Dictionary)["y"]), "target": dug})
	if KarmaJevBridge.verb_ready(a, 4) and (KarmaUtils.nearest_from(ax, ay, state.get("insects", []), eat_range) != null or int(a.get("larder", 0)) > 0):
		menu.append({"kind": "larder", "label": "Larder worm", "x": ax, "y": ay})
	if float(a.get("shoutCd", 0.0)) <= 0.0:
		var hunter: Variant = KarmaState.nearest_hunter(ax, ay, state, float(KarmaData.TUNING["shoutLureRange"]), a)
		if hunter != null:
			menu.append({"kind": "alarm", "label": "Alarm call", "x": float((hunter as Dictionary)["x"]), "y": float((hunter as Dictionary)["y"]), "target": hunter})
	menu.append({"kind": "wander", "label": "Wander", "x": ax, "y": ay})
	return menu


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	var max_hp := KarmaState.eff_max_hp_for(a)
	var ax := float(a["x"])
	var ay := float(a["y"])
	var eat_range := float(KarmaData.TUNING["eatRange"])
	return {
		"schema": SCHEMA_VERSION,
		"species": "topo",
		"t": float(state.get("time", 0.0)),
		"hp_frac": float(a.get("hp", max_hp)) / max_hp,
		"hambre": float(a.get("hambre", 100.0)),
		"sed": float(a.get("sed", 100.0)),
		"karma": float(a.get("karma", 0.0)),
		"pa": float(a.get("pa", 0.0)),
		"hungry": KarmaAI.is_hungry(a),
		"threatened": KarmaAI.is_hunted(state, a),
		"pressure_near": KarmaState.nearest_hunter(ax, ay, state, float(KarmaData.TUNING["aiFearRange"]), a) != null,
		"food_near": KarmaUtils.nearest_from(ax, ay, state.get("insects", []), eat_range) != null or KarmaEat.nearest_edible_patch_for(state, a, eat_range) != null,
		"water_near": KarmaUtils.nearest_water_for(state, ax, ay, float(KarmaData.TUNING["drinkRange"])) != null,
		"dug_near": _dug_near(state, a) != null,
		"larder": int(a.get("larder", 0)),
	}.merged(KarmaJev.age_fields(state, a))


static func state_text(state: Dictionary, a: Dictionary) -> String:
	var snap := build_state(state, a)
	return KarmaJevBridge.state_text("Topo", snap, "pressure=%s food=%s water=%s dug=%s larder=%d",
		[str(snap["pressure_near"]), str(snap["food_near"]), str(snap["water_near"]),
		str(snap["dug_near"]), int(snap["larder"])])


static func mock_choice(menu: Array) -> int:
	return KarmaJevBridge.mock_choice(menu, MOCK_ORDER)


static func mock_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevBridge.mock_macro(state, a,
		Callable(KarmaJevTopo, "build_menu"), MOCK_ORDER, Callable(KarmaJevTopo, "apply_answer"))


static func apply_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	a["jev_emocion"] = str(answer.get("emocion", ""))
	if bool(answer.get("target_gone", false)):
		KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var idx := int(answer.get("choice", -1))
	if idx < 0 or idx >= menu.size():
		KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
		return true
	var pick := menu[idx] as Dictionary
	if str(answer.get("emocion", "")) == "":
		answer["emocion"] = KarmaJev.appraise_emocion(build_state(state, a), str(pick["kind"]))
		a["jev_emocion"] = str(answer["emocion"])
	match str(pick["kind"]):
		"eat":
			var target: Variant = pick.get("target", null)
			if target != null and (state["insects"] as Array).has(target):
				KarmaJevBridge.set_intent(a, "eat", float(pick["x"]), float(pick["y"]), target)
				return KarmaEat.eat_insect(state, target, a)
			if target != null and patch_still_edible(target):
				KarmaJevBridge.set_intent(a, "eat", float(pick["x"]), float(pick["y"]), target)
				return KarmaEat.eat_patch(state, target, a)
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true
		"seek_food", "drink", "flee":
			KarmaJevBridge.set_intent(a, str(pick["kind"]), float(pick["x"]), float(pick["y"]), pick.get("target", null))
			return true
		"aerate":
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 1)
		"tunneline":
			if _dug_near(state, a) == null:
				KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 2)
		"worm":
			if _dug_near(state, a) == null:
				KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
				return true
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 3)
		"larder":
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return KarmaGame.cast_verb_for(state, a, 4)
		"alarm":
			var hunter: Variant = KarmaState.nearest_hunter(float(a["x"]), float(a["y"]), state, float(KarmaData.TUNING["shoutLureRange"]), a)
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			if hunter == null:
				return true
			return KarmaState.ai_try_shout(state, a)
		_:
			KarmaJevBridge.set_intent(a, "wander", float(a["x"]), float(a["y"]))
			return true


static func all_jev_topos(state: Dictionary) -> Array:
	return KarmaJevBridge.all_agents(state, "topo")


static func candidate_ids(menu: Array) -> Array:
	return KarmaJevBridge.candidate_ids(menu)


static func build_batch(state: Dictionary) -> Array:
	return KarmaJevBridge.build_batch(state, "topo",
		Callable(KarmaJevTopo, "build_state"), Callable(KarmaJevTopo, "build_menu"), QUESTION)


static func build_http_body(state: Dictionary) -> Dictionary:
	return build_http_body_for(state, all_jev_topos(state))


static func build_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevBridge.build_http_body_for(state, agents,
		Callable(KarmaJevTopo, "build_menu"), Callable(KarmaJevTopo, "state_text"), QUESTION)
