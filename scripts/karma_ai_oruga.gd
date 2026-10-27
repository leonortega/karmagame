class_name KarmaAIOruga
extends RefCounted

# Per-species AI for oruga (Strategy). KarmaAI delegates here.
# Micro steering every tick + macro intent from KarmaJevOruga ranking.
# Wander keeps accumulating stillness (curl defense), never travels.


static var _JEV_GATES := Callable(KarmaAI, "jev_gates_common")
static var _JEV_STEER := Callable(KarmaAIOruga, "steer_intent")
static var _JEV_MOCK := Callable(KarmaJevOruga, "mock_macro")


static func step(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJevOruga.USE_JEV:
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
		a["stillT"] = 0.0
		return
	if KarmaAI.ai_urgent_seek(state, a, dt):
		return
	if KarmaAI.ai_forage(state, a, dt):
		a["stillT"] = 0.0
		return
	if KarmaAI.ai_maybe_verb(state, a, dt):
		return
	a["stillT"] = float(a.get("stillT", 0.0)) + dt


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
			var reach := float(KarmaData.TUNING["eatRange"])
			if KarmaJevOruga.patch_still_edible(state, target):
				if KarmaUtils.dist2(float((target as Dictionary).get("x", float(a["x"]))), float((target as Dictionary).get("y", float(a["y"]))), float(a["x"]), float(a["y"])) <= reach * reach:
					a["stillT"] = 0.0
					return KarmaEat.eat_patch(state, target, a)
				KarmaGame.move_toward(state, a, float((target as Dictionary).get("x", float(a["x"]))), float((target as Dictionary).get("y", float(a["y"]))), 1.0, dt)
				a["stillT"] = 0.0
				return true
			if KarmaAI.ai_grazer_eat(state, a, reach):
				a["stillT"] = 0.0
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			a["stillT"] = 0.0
			return true
		"seek_food", "drink", "flee":
			if str(intent.get("kind", "")) == "drink" and KarmaAI.ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			a["stillT"] = 0.0
			return true
		_:
			a["stillT"] = float(a.get("stillT", 0.0)) + dt
			return true
