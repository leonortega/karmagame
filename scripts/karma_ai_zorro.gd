class_name KarmaAIZorro
extends RefCounted

# Per-species AI for zorro (Strategy). KarmaAI delegates here.
# Behavior-preserving extraction of KarmaAI._ai_zorro*.


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevZorro.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	KarmaJev.intent_tick(a, dt)
	if KarmaAI.ai_flee(state, a, dt):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.is_hunted(state, a) and str((a.get("jev_intent", {}) as Dictionary).get("kind", "")) != "flee":
		a["jev_intent"] = {}
	if steer_intent(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	KarmaJevZorro.mock_macro(state, a)


static func steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not a.has("jev_intent") or (a["jev_intent"] as Dictionary).is_empty():
		return false
	if float((a["jev_intent"] as Dictionary).get("ttl", 0.0)) <= 0.0:
		a["jev_intent"] = {}
		return false
	var intent := a["jev_intent"] as Dictionary
	match str(intent.get("kind", "wander")):
		"eat", "seek_carrion":
			var c: Variant = intent.get("target", null)
			if c != null and (state["carrions"] as Array).has(c):
				if Vector2(float((c as Dictionary)["x"]), float((c as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"]))) <= float(KarmaData.TUNING["eatRange"]):
					return KarmaEat.eat_carrion(state, c, a)
				KarmaGame.move_toward(state, a, float((c as Dictionary)["x"]), float((c as Dictionary)["y"]), 1.0, dt)
				return true
			var near: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
			if near != null:
				return KarmaEat.eat_carrion(state, near, a)
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		"pounce", "hunt":
			var prey: Variant = intent.get("target", null)
			if prey == null or not (state["agents"] as Array).has(prey) or bool((prey as Dictionary).get("hidden", false)):
				a["jev_intent"] = {}
				return false
			var d := Vector2(float((prey as Dictionary)["x"]), float((prey as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
			if d <= 20.0:
				return KarmaAI.ai_hunt_eat(state, a, prey, dt)
			KarmaGame.move_toward(state, a, float((prey as Dictionary)["x"]), float((prey as Dictionary)["y"]), float(KarmaData.TUNING["chaseMult"]), dt)
			return true
		"drink", "flee":
			if str(intent.get("kind", "")) == "drink" and KarmaAI.ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		_:
			if KarmaAI.ai_maybe_verb(state, a, dt):
				return true
			if KarmaAI.is_hungry(a) and KarmaAI.ai_seek_carrion(state, a, dt):
				return true
			var quarry: Variant = KarmaAI.nearest_ai_prey(state, a, float(KarmaAI.ai_pred_row(a)["perception"]))
			if quarry != null:
				KarmaAI.ai_hunt_eat(state, a, quarry, dt)
				return true
			var meal: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
			if meal != null:
				return KarmaEat.eat_carrion(state, meal, a)
			var poi: Variant = KarmaGame.wander_poi(state, a)
			if poi != null:
				KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
			else:
				a["x"] = float(a["x"]) + (randf() - 0.5) * 60.0 * dt
				a["y"] = float(a["y"]) + (randf() - 0.5) * 60.0 * dt
			return true


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if KarmaAI.ai_flee(state, a, dt):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.ai_maybe_verb(state, a, dt):
		return
	if KarmaAI.is_hungry(a) and KarmaAI.ai_seek_carrion(state, a, dt):
		return
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, float(KarmaAI.ai_pred_row(a)["perception"]))
	if prey != null:
		KarmaAI.ai_hunt_eat(state, a, prey, dt)
		return
	var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c != null:
		KarmaEat.eat_carrion(state, c, a)
	elif not KarmaAI.ai_forage(state, a, dt):
		var poi: Variant = KarmaGame.wander_poi(state, a)
		if poi != null:
			KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
		else:
			a["x"] = float(a["x"]) + (randf() - 0.5) * 60.0 * dt
			a["y"] = float(a["y"]) + (randf() - 0.5) * 60.0 * dt
