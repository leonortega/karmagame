class_name KarmaAILobo
extends RefCounted

# Per-species AI for lobo (Strategy). KarmaAI delegates here.
# Micro steering every tick + macro intent from KarmaJevLobo ranking.


static var _JEV_GATES := Callable(KarmaAILobo, "_jev_gates")
static var _JEV_STEER := Callable(KarmaAILobo, "steer_intent")
static var _JEV_MOCK := Callable(KarmaJevLobo, "mock_macro")


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevLobo.USE_JEV:
		step_jev(state, a, dt)
		return
	step_ladder(state, a, dt)


static func step_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaAI.jev_step(state, a, dt, _JEV_GATES, _JEV_STEER, _JEV_MOCK)


static func _jev_gates(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if KarmaAI.ai_thirst(state, a, dt):
		return true
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return true
	return false


static func steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
	return KarmaJev.steer_intent(state, a, dt, ["hunt"], "loboChaseMult", false)


static func step_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, KarmaState.eff_max_hp_for(a), dt)
	KarmaAI.ai_base(state, a, dt)
	if float(a.get("strikeCd", 0.0)) <= 0.0:
		var kill_r: float = KarmaAI.kill_range(a)
		var own: String = str(a.get("speciesKey", ""))
		var targets: Array = []
		for o in state["agents"]:
			if o == a or str(o.get("speciesKey", "")) == own:
				continue
			if not KarmaData.PRED.has(str(o.get("speciesKey", ""))):
				continue
			# Contact prey is a meal, not a rival to scare: skip it here.
			if KarmaPredators.can_eat_agent(a, o) and KarmaUtils.dist2(float(o["x"]), float(o["y"]), float(a["x"]), float(a["y"])) <= kill_r * kill_r:
				continue
			targets.append(o)
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), targets, 60.0)
		if p != null:
			KarmaAI.ai_strike(state, a, p)
			return
	if KarmaAI.ai_thirst(state, a, dt):
		return
	if KarmaAI.is_hungry(a) and KarmaAI.ai_seek_carrion(state, a, dt):
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	if KarmaAI.ai_maybe_verb(state, a, dt):
		return
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, float(KarmaAI.ai_pred_row(a)["perception"]))
	if prey != null:
		KarmaAI.ai_hunt_eat(state, a, prey, dt)
		return
	var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c != null:
		KarmaEat.eat_carrion(state, c, a)
