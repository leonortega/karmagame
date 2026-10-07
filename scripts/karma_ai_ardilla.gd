class_name KarmaAIArdilla
extends RefCounted

# Per-species AI for ardilla (Strategy). KarmaAI delegates here.
# Micro steering every tick + macro intent from KarmaJevArdilla ranking.


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevArdilla.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if KarmaAI.ai_hide_tick(state, a, dt):
		return
	if KarmaAI.is_hunted(state, a) and KarmaAI.ai_try_hide(state, a):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.ai_maybe_verb(state, a, dt):
		return
	if KarmaAI.ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	var poi: Variant = KarmaGame.wander_poi(state, a)
	if poi != null:
		KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
	else:
		a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
		a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	KarmaJev.intent_tick(a, dt)
	if KarmaAI.ai_hide_tick(state, a, dt):
		return
	if KarmaAI.is_hunted(state, a) and KarmaAI.ai_try_hide(state, a):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	if bool(a.get("carriedNut", false)) and KarmaAI.is_hungry(a):
		a["carriedNut"] = false
	if steer_intent(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	KarmaJevArdilla.mock_macro(state, a)


static func steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not a.has("jev_intent") or (a["jev_intent"] as Dictionary).is_empty():
		return false
	if float((a["jev_intent"] as Dictionary).get("ttl", 0.0)) <= 0.0:
		a["jev_intent"] = {}
		return false
	var intent := a["jev_intent"] as Dictionary
	match str(intent.get("kind", "wander")):
		"eat":
			var target: Variant = intent.get("target", null)
			var eat_range := float(KarmaData.TUNING["eatRange"])
			if target != null:
				var d := Vector2(float((target as Dictionary).get("x", float(a["x"]))), float((target as Dictionary).get("y", float(a["y"])))).distance_to(Vector2(float(a["x"]), float(a["y"])))
				if d <= eat_range:
					return KarmaEat.eat_patch(state, target, a)
				KarmaGame.move_toward(state, a, float((target as Dictionary).get("x", float(a["x"]))), float((target as Dictionary).get("y", float(a["y"]))), 1.0, dt)
				return true
			var near: Variant = KarmaEat.nearest_edible_patch_for(state, a, eat_range)
			if near != null:
				return KarmaEat.eat_patch(state, near, a)
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		"seek_food", "drink", "flee":
			if str(intent.get("kind", "")) == "drink" and KarmaAI.ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		"carry_nut", "bury_nut":
			if KarmaEat.bury_or_carry_nut(state, a):
				if bool(a.get("carriedNut", false)):
					a["jev_intent"] = {"kind": "bury_nut", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
				else:
					a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
				return true
			a["jev_intent"] = {}
			return false
		_:
			if KarmaAI.ai_maybe_verb(state, a, dt):
				return true
			var poi: Variant = KarmaGame.wander_poi(state, a)
			if poi != null:
				KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
			else:
				a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
				a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt
			return true
