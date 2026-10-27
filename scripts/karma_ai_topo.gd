class_name KarmaAITopo
extends RefCounted

# Per-species AI for topo (Strategy). KarmaAI delegates here.
# Micro steering every tick + macro intent from KarmaJevTopo ranking.


static var _JEV_GATES := Callable(KarmaAI, "jev_gates_common")
static var _JEV_STEER := Callable(KarmaAITopo, "steer_intent")
static var _JEV_MOCK := Callable(KarmaJevTopo, "mock_macro")


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevTopo.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaState.eff_max_hp_for(a), dt)
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


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaAI.jev_step(state, a, dt, _JEV_GATES, _JEV_STEER, _JEV_MOCK)


static func steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var intent_v: Variant = KarmaAI.live_jev_intent(a)
	if intent_v == null:
		return false
	var intent := intent_v as Dictionary
	match str(intent.get("kind", "wander")):
		"eat":
			var target: Variant = intent.get("target", null)
			var eat_range := float(KarmaData.TUNING["eatRange"])
			if target != null:
				var tx := float((target as Dictionary).get("x", float(a["x"])))
				var ty := float((target as Dictionary).get("y", float(a["y"])))
				if KarmaUtils.dist2(tx, ty, float(a["x"]), float(a["y"])) <= eat_range * eat_range:
					if (state["insects"] as Array).has(target):
						return KarmaEat.eat_insect(state, target, a)
					if KarmaJevTopo.patch_still_edible(target):
						return KarmaEat.eat_patch(state, target, a)
				else:
					KarmaGame.move_toward(state, a, tx, ty, 1.0, dt)
					return true
			if KarmaAI.ai_grazer_eat(state, a, eat_range):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		"seek_food", "drink", "flee":
			if str(intent.get("kind", "")) == "drink" and KarmaAI.ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
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
