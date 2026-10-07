class_name KarmaAIHalcon
extends RefCounted

# Per-species AI for halcon (Strategy). KarmaAI delegates here.
# Behavior-preserving extraction of KarmaAI._ai_halcon*.


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevHalcon.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	KarmaJev.intent_tick(a, dt)
	if not bool(a.get("grounded", false)) and float(a.get("strikeCd", 0.0)) <= 0.0:
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
			(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
		if p != null:
			KarmaAI.ai_strike(state, a, p)
			return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if bool(a.get("grounded", false)):
		var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
		if c != null and float(a.get("landT", 0.0)) <= 0.0 and KarmaEat.eat_carrion(state, c, a):
			a["grounded"] = false
			return
		if float(a.get("landT", 0.0)) <= 0.0:
			a["grounded"] = false
			return
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	if steer_intent(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	KarmaJevHalcon.mock_halcon_macro(state, a)


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
					if KarmaEat.eat_carrion(state, c, a):
						a["grounded"] = false
					return true
				KarmaGame.move_toward(state, a, float((c as Dictionary)["x"]), float((c as Dictionary)["y"]), 1.0, dt)
				return true
			var near: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
			if near != null:
				if KarmaEat.eat_carrion(state, near, a):
					a["grounded"] = false
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		"dive":
			var prey: Variant = intent.get("target", null)
			if prey == null or not (state["agents"] as Array).has(prey) or bool((prey as Dictionary).get("hidden", false)):
				a["jev_intent"] = {}
				return false
			var d := Vector2(float((prey as Dictionary)["x"]), float((prey as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
			if d <= 60.0:
				if KarmaAI.ai_hunt_eat(state, a, prey, dt):
					a["grounded"] = true
					a["landT"] = float(KarmaData.TUNING["landTime"])
				return true
			KarmaGame.move_toward(state, a, float((prey as Dictionary)["x"]), float((prey as Dictionary)["y"]), float(KarmaData.TUNING["chaseMult"]), dt)
			return true
		"drink", "flee":
			if str(intent.get("kind", "")) == "drink" and KarmaAI.ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		_:
			var quarry: Variant = KarmaAI.nearest_ai_prey(state, a, 200.0)
			if quarry != null:
				if KarmaAI.ai_hunt_eat(state, a, quarry, dt):
					a["grounded"] = true
					a["landT"] = float(KarmaData.TUNING["landTime"])
				return true
			var meal: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
			if meal != null:
				a["grounded"] = true
				a["landT"] = float(KarmaData.TUNING["landTime"])
				return true
			var poi: Variant = KarmaGame.wander_poi(state, a)
			if poi != null:
				KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
			else:
				a["x"] = float(a["x"]) + (randf() - 0.5) * 80.0 * dt
				a["y"] = float(a["y"]) + (randf() - 0.5) * 80.0 * dt
			return true


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if not bool(a.get("grounded", false)) and float(a.get("strikeCd", 0.0)) <= 0.0:
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
			(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
		if p != null:
			KarmaAI.ai_strike(state, a, p)
			return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if bool(a.get("grounded", false)):
		var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
		if c != null and float(a.get("landT", 0.0)) <= 0.0 and KarmaEat.eat_carrion(state, c, a):
			a["grounded"] = false
			return
		if float(a.get("landT", 0.0)) <= 0.0:
			a["grounded"] = false
			return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, 200.0)
	if prey != null:
		if KarmaAI.ai_hunt_eat(state, a, prey, dt):
			a["grounded"] = true
			a["landT"] = float(KarmaData.TUNING["landTime"])
		return
	var c2: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c2 != null:
		a["grounded"] = true
		a["landT"] = float(KarmaData.TUNING["landTime"])
		return
	var poi: Variant = KarmaGame.wander_poi(state, a)
	if poi != null:
		KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
	else:
		a["x"] = float(a["x"]) + (randf() - 0.5) * 80.0 * dt
		a["y"] = float(a["y"]) + (randf() - 0.5) * 80.0 * dt
