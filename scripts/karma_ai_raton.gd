class_name KarmaAIRaton
extends RefCounted

# Per-species AI for raton (Strategy). KarmaAI delegates here.
# Micro steering every tick + macro intent from KarmaJevRaton ranking.


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevRaton.USE_JEV:
		_step_jev(state, a, dt)
		return
	_step_ladder(state, a, dt)


static func _step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaAI.ai_max_hp(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if KarmaAI.ai_hide_tick(state, a, dt):
		return
	if KarmaAI.is_hunted(state, a) and KarmaAI.ai_try_hide(state, a):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	if KarmaAI.ai_forage(state, a, dt):
		return
	if KarmaAI.ai_maybe_verb(state, a, dt):
		return
	var poi: Variant = KarmaGame.wander_poi(state, a)
	if poi != null:
		KarmaGame.move_toward(state, a, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), 1.0, dt)
	else:
		a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
		a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt


static func _step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
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
	if _steer_intent(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	KarmaJevRaton.mock_macro(state, a)


static func _steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
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
					if (state.get("insects", []) as Array).has(target):
						return KarmaEat.eat_insect(state, target, a)
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
		"groom":
			var mate: Variant = intent.get("target", null)
			if mate == null or not (state["agents"] as Array).has(mate):
				a["jev_intent"] = {}
				return false
			var md := Vector2(float((mate as Dictionary)["x"]), float((mate as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
			if md > float(KarmaData.TUNING["groomRange"]):
				KarmaGame.move_toward(state, a, float((mate as Dictionary)["x"]), float((mate as Dictionary)["y"]), 1.0, dt)
				return true
			KarmaAI.ai_maybe_verb(state, a, dt)
			return true
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
