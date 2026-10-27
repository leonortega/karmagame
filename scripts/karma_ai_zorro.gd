class_name KarmaAIZorro
extends RefCounted

# Per-species AI for zorro (Strategy). KarmaAI delegates here.
# Behavior-preserving extraction from the KarmaAI.ai_step dispatch.


static var _JEV_GATES := Callable(KarmaAIZorro, "_jev_gates")
static var _JEV_STEER := Callable(KarmaAIZorro, "steer_intent")
static var _JEV_MOCK := Callable(KarmaJevZorro, "mock_macro")


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevZorro.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaAI.jev_step(state, a, dt, _JEV_GATES, _JEV_STEER, _JEV_MOCK)


static func _jev_gates(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if KarmaAI.ai_flee(state, a, dt):
		return true
	if KarmaAI.ai_thirst(state, a, dt):
		return true
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return true
	if KarmaAI.is_hunted(state, a) and str((a.get("jev_intent", {}) as Dictionary).get("kind", "")) != "flee":
		a["jev_intent"] = {}
	return false


static func steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
	return KarmaJev.steer_intent(state, a, dt, ["pounce", "hunt"], "chaseMult", true)


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaState.eff_max_hp_for(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if KarmaAI.ai_flee(state, a, dt):
		return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
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
