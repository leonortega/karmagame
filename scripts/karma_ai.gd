class_name KarmaAI
extends RefCounted

# Port of src/script/ai.js — species behavior engine for agents.

const AI_SHOUTERS := ["raton", "topo", "sapo", "ardilla", "lobo"]


static func karma_sight_mult(karma: float) -> float:
	if karma >= float(KarmaData.TUNING["aiKarmaGood"]):
		return 1.0 - float(KarmaData.TUNING["aiPredPerceptMod"])
	if karma <= float(KarmaData.TUNING["aiKarmaBad"]):
		return 1.0 + float(KarmaData.TUNING["aiPredPerceptMod"])
	return 1.0


static func nearest_victim_karma_aware(ax: float, ay: float, list: Array, max_d: float) -> Variant:
	var best: Variant = null
	var be: float = max_d * max_d
	for o in list:
		var dx: float = ax - float(o["x"])
		var dy: float = ay - float(o["y"])
		var m: float = karma_sight_mult(float(o.get("karma", 0.0)))
		var e: float = (dx * dx + dy * dy) / (m * m)
		if e < be:
			be = e
			best = o
	return best


static func ai_pred_row(a: Dictionary) -> Dictionary:
	if KarmaData.PRED.has(str(a.get("speciesKey", ""))):
		return KarmaData.PRED[str(a["speciesKey"])]
	return {"perception": float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]), "damage": 15.0, "body": 18.0}


static func nearest_ai_prey(state: Dictionary, a: Dictionary, rnge: float) -> Variant:
	var prey: Array = []
	for v in state["agents"]:
		if v == a or bool(v.get("hidden", false)):
			continue
		if KarmaPredators.can_eat_agent(a, v):
			prey.append(v)
	return nearest_victim_karma_aware(float(a["x"]), float(a["y"]), prey, rnge)


static func kill_range(a: Dictionary) -> float:
	return 60.0 if str(a.get("speciesKey", "")) == "halcon" else 20.0


static func ai_hunt_eat(state: Dictionary, a: Dictionary, prey: Dictionary, dt: float) -> bool:
	var d: float = Vector2(float(prey["x"]), float(prey["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
	if d == 0.0:
		d = 1.0
	var reach: float = kill_range(a)
	if d <= reach:
		if str(a.get("speciesKey", "")) == "halcon":
			a["x"] = float(prey["x"])
			a["y"] = float(prey["y"])
		var lethal: bool = KarmaEat.resolve_strike(state, a, prey, KarmaState.eff_max_hp_for(prey))
		if lethal and str(a.get("speciesKey", "")) == "zorro":
			a["satedT"] = float(KarmaData.TUNING["satedTime"])
		if lethal:
			KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["pounceHp"]))
		return true
	var mult: float = float(KarmaData.TUNING["loboChaseMult"]) if str(a.get("speciesKey", "")) == "lobo" else float(KarmaData.TUNING["chaseMult"])
	KarmaGame.move_toward(state, a, float(prey["x"]), float(prey["y"]), mult, dt)
	return false


static func _hunter_within(state: Dictionary, a: Dictionary, max_d: float) -> bool:
	return KarmaState.nearest_hunter(float(a["x"]), float(a["y"]), state, max_d, a) != null


static func ai_flee(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not KarmaData.PRED.has(str(a.get("speciesKey", ""))):
		return false
	var fears: Array = (KarmaData.PRED[str(a["speciesKey"])] as Dictionary).get("fears", [])
	if fears.is_empty():
		return false
	var fear: Variant = KarmaUtils.nearest_hunter_in_fears(float(a["x"]), float(a["y"]), state["agents"], fears, 200.0)
	if fear == null:
		return false
	var dx: float = float(a["x"]) - float((fear as Dictionary)["x"])
	var dy: float = float(a["y"]) - float((fear as Dictionary)["y"])
	var d: float = Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	dx /= d
	dy /= d
	var cover: Variant = null
	var cover_range: float = float(KarmaData.TUNING["aiCoverRange"])
	var cover_d2: float = cover_range * cover_range
	for r in state.get("refuges", []):
		if refuge_fits_size(KarmaData.SPECIES[str(a["speciesKey"])], r, str(a["speciesKey"])) and KarmaUtils.dist2(float(r["x"]), float(r["y"]), float(a["x"]), float(a["y"])) <= cover_d2:
			cover = r
			break
	if cover != null:
		var cd: float = Vector2(float((cover as Dictionary)["x"]), float((cover as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
		if cd == 0.0:
			cd = 1.0
		var cover_w: float = float(KarmaData.TUNING["frailCoverBias"]) if is_senesced(a) else 0.4
		dx = dx * (1.0 - cover_w) + (float((cover as Dictionary)["x"]) - float(a["x"])) / cd * cover_w
		dy = dy * (1.0 - cover_w) + (float((cover as Dictionary)["y"]) - float(a["y"])) / cd * cover_w
	var dl: float = Vector2(dx, dy).length()
	if dl == 0.0:
		dl = 1.0
	KarmaGame.move_toward(state, a, float(a["x"]) + dx / dl * 100.0, float(a["y"]) + dy / dl * 100.0, 1.0, dt)
	return true


static func ai_shout_if_ready(state: Dictionary, a: Dictionary) -> bool:
	if not str(a.get("speciesKey", "")) in AI_SHOUTERS:
		return false
	if float(a.get("shoutCd", 0.0)) > 0.0:
		return false
	if not _hunter_within(state, a, float(KarmaData.TUNING["shoutLureRange"])):
		return false
	return KarmaState.ai_try_shout(state, a)


static func ai_base(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.tick_cooldowns(a, ["shoutCd", "pounceCd", "strikeCd", "digCd", "curlCd", "groomCd", "senseCd", "lureTimer", "satedT", "landT"], dt)
	KarmaUtils.tick_verb_cds(a, dt)
	ai_shout_if_ready(state, a)
	a["buyT"] = float(a.get("buyT", 0.0)) - dt
	if float(a["buyT"]) <= 0.0:
		a["buyT"] = float(KarmaData.TUNING["aiBuyEvery"])
		if a.has("owned"):
			ai_buy_adaptation(state, a)
	if float(a.get("lureTimer", 0.0)) > 0.0:
		var p: Variant = KarmaState.nearest_hunter(float(a["x"]), float(a["y"]), state, float(KarmaData.TUNING["shoutLureRange"]), a)
		if p != null:
			var d: float = Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(float((p as Dictionary)["x"]), float((p as Dictionary)["y"])))
			if d == 0.0:
				d = 1.0
			(p as Dictionary)["x"] = float((p as Dictionary)["x"]) + (float(a["x"]) - float((p as Dictionary)["x"])) / d * 60.0 * dt
			(p as Dictionary)["y"] = float((p as Dictionary)["y"]) + (float(a["y"]) - float((p as Dictionary)["y"])) / d * 60.0 * dt


static func ai_strike(state: Dictionary, a: Dictionary, p: Dictionary) -> void:
	KarmaEat.strike_predator(state, p, a)
	var k: float = (float(KarmaData.TUNING["loboStrikeKarma"]) if str(p.get("speciesKey", "")) == "lobo" else float(KarmaData.TUNING["strikeKarma"])) * (2.0 if KarmaShop.has_adapt(a, "strikePlus") else 1.0)
	KarmaState.add_karma(state, a, k, "¡Ahuyenta a un %s! (+%d karma)" % [str(p.get("speciesKey", "")), int(k)])
	KarmaState.add_pa(state, a, float(KarmaData.TUNING["strikePa"]))
	KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["strikeHp"]))
	a["strikeCd"] = float(KarmaData.TUNING["strikeCd"])


static func ai_buy_adaptation(state: Dictionary, a: Dictionary) -> bool:
	var cat: Array = KarmaShop.catalog_for(str(a.get("speciesKey", "")))
	if cat.is_empty():
		return false
	var owned: Dictionary = a.get("owned", {})
	var all_owned: bool = true
	for it in cat:
		if not bool(owned.get(str(it["id"]), false)):
			all_owned = false
			break
	if all_owned:
		return false
	var max_hp: float = KarmaState.eff_max_hp_for(a)
	var want: Variant = null
	if float(a.get("hp", max_hp)) < max_hp / 2.0:
		for it in cat:
			if str(it["effect"]) == "stomach" and not bool(owned.get(str(it["id"]), false)) and float(a.get("pa", 0.0)) >= float(it["cost"]):
				want = it
				break
	if want == null:
		for it in cat:
			if not bool(owned.get(str(it["id"]), false)) and float(a.get("pa", 0.0)) >= float(it["cost"]):
				want = it
				break
	if want == null:
		return false
	a["pa"] = float(a["pa"]) - float((want as Dictionary)["cost"])
	owned[str((want as Dictionary)["id"])] = true
	a["owned"] = owned
	if str((want as Dictionary)["effect"]) == "stomach":
		KarmaEat.heal_eater(state, a, 25.0)
	return true


static func is_senesced(a: Dictionary) -> bool:
	return KarmaData.age_stage(str(a.get("speciesKey", "raton")), float(a.get("edad", 0.0))) != "prime"


static func prefer_carrion(a: Dictionary) -> bool:
	var max_hp: float = KarmaState.eff_max_hp_for(a)
	if float(a.get("hp", max_hp)) < float(KarmaData.TUNING["scavengeHpFrac"]) * max_hp:
		return true
	return is_senesced(a)


static func fear_range_for(a: Dictionary) -> float:
	var base: float = float(KarmaData.TUNING["aiFearRange"])
	return base * (float(KarmaData.TUNING["frailFearMult"]) if is_senesced(a) else 1.0)


static func food_threshold(a: Dictionary) -> float:
	return 30.0 + 70.0 * float(a.get("caution_food", 1.0))


static func water_threshold(a: Dictionary) -> float:
	return 30.0 + 70.0 * float(a.get("caution_water", 1.0))


static func is_hungry(a: Dictionary) -> bool:
	return float(a.get("hambre", 100.0)) < food_threshold(a)


static func ai_forage(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not is_hungry(a):
		return false
	var rnge: float = float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var target: Variant = null
	var bd2: float = rnge * rnge
	if (KarmaData.DIET[str(a["speciesKey"])] as Array).has("insects"):
		var ins: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), rnge)
		if ins != null:
			target = ins
			var idx: float = float((ins as Dictionary)["x"]) - ax
			var idy: float = float((ins as Dictionary)["y"]) - ay
			bd2 = idx * idx + idy * idy
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, rnge)
	if patch != null:
		var pdx: float = float((patch as Dictionary)["x"]) - ax
		var pdy: float = float((patch as Dictionary)["y"]) - ay
		if pdx * pdx + pdy * pdy < bd2:
			target = patch
	if target == null:
		return false
	KarmaGame.move_toward(state, a, float((target as Dictionary)["x"]), float((target as Dictionary)["y"]), 1.0, dt)
	return true


static func ai_urgent_seek(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if float(a.get("hambre", 100.0)) > float(KarmaData.TUNING["regenHambre"]):
		return false
	var diet: Array = KarmaData.DIET.get(str(a.get("speciesKey", "raton")), [])
	var seek: float = float(KarmaData.TUNING["wanderSeekRange"])
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var target: Variant = null
	if diet.has("carrion"):
		target = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), seek)
	if target == null and diet.has("insects"):
		target = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), seek)
	if target == null:
		target = KarmaEat.nearest_edible_patch_for(state, a, seek)
	if target == null:
		return false
	KarmaGame.move_toward(state, a, float((target as Dictionary)["x"]), float((target as Dictionary)["y"]), 1.0, dt)
	a["stillT"] = 0.0
	return true


static func ai_drink(state: Dictionary, a: Dictionary, rnge: float = -1.0) -> bool:
	var r: float = rnge if rnge >= 0.0 else float(KarmaData.TUNING["drinkRange"])
	var w: Variant = KarmaUtils.nearest_water_for(state, float(a["x"]), float(a["y"]), r)
	return w != null and KarmaEat.drink_water(state, w, a)


static func seeks_water(a: Dictionary) -> bool:
	return (100.0 - float(a.get("sed", 100.0))) > (100.0 - float(a.get("hambre", 100.0)))


static func ai_seek_water(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var rnge: float = float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var wet: Array = []
	var best: Variant = null
	var bd: float = rnge
	for w in state.get("waters", []):
		if float(w.get("level", 1.0)) <= 0.0:
			continue
		wet.append(w)
		var d: float = Vector2(float(w["x"]), float(w["y"])).distance_to(Vector2(ax, ay)) - float(w["r"])
		if d < bd:
			bd = d
			best = w
	if best == null:
		best = KarmaUtils.nearest_from(ax, ay, wet, 1e9)
	if best == null:
		return false
	KarmaGame.move_toward(state, a, float((best as Dictionary)["x"]), float((best as Dictionary)["y"]), 1.0, dt)
	return true


static func ai_thirst(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if float(a.get("sed", 100.0)) >= water_threshold(a):
		return false
	if not seeks_water(a):
		return false
	if ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
		a["stillT"] = 0.0
		return true
	if ai_seek_water(state, a, dt):
		a["stillT"] = 0.0
		return true
	return false


static func ai_maybe_verb(state: Dictionary, a: Dictionary, dt: float) -> bool:
	match str(a.get("speciesKey", "")):
		"raton":
			if float(a.get("groomCd", 0.0)) > 0.0 or KarmaState.nearest_company(float(a["x"]), float(a["y"]), state, float(KarmaData.TUNING["groomRange"]), a) == null:
				a["groomT"] = 0.0
			else:
				a["groomT"] = float(a.get("groomT", 0.0)) + dt
				if float(a["groomT"]) >= KarmaData.aged_time(a, float(KarmaData.TUNING["groomTime"])):
					a["groomT"] = 0.0
					a["groomCd"] = KarmaData.aged_time(a, float(KarmaData.TUNING["groomCd"]))
					KarmaState.add_karma(state, a, float(KarmaData.TUNING["groomKarma"]), "Acicala a un congénere (+karma)")
					return true
			return KarmaGame.cast_verb_for(state, a, 5)
		"topo":
			var dug: Array = []
			for r in state["refuges"]:
				if bool(r.get("dug", false)):
					dug.append(r)
			var dug_near: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), dug, float(KarmaData.TUNING["eatRange"]))
			if is_hungry(a) and dug_near != null and KarmaGame.cast_verb_for(state, a, 3):
				return true
			if dug_near != null and KarmaGame.cast_verb_for(state, a, 2):
				return true
			if KarmaGame.cast_verb_for(state, a, 1):
				return true
			return KarmaGame.cast_verb_for(state, a, 4)
		"ardilla":
			if bool(a.get("carriedNut", false)) and is_hungry(a):
				a["carriedNut"] = false
			var danger: bool = _hunter_within(state, a, float(KarmaData.TUNING["shoutLureRange"]))
			if danger and float(a.get("shoutCd", 0.0)) > 0.0 and KarmaGame.cast_verb_for(state, a, 1):
				return true
			if danger and KarmaGame.cast_verb_for(state, a, 3):
				return true
			if bool(a.get("carriedNut", false)):
				return KarmaGame.cast_verb_for(state, a, 2)
			if is_hungry(a):
				return false
			if KarmaGame.cast_verb_for(state, a, 4):
				return true
			return KarmaEat.bury_or_carry_nut(state, a)
		"zorro":
			if float(a.get("satedT", 0.0)) <= 0.0:
				return false
			KarmaGame.cast_verb_for(state, a, 3)
			return true
		"sapo":
			if KarmaGame.cast_verb_for(state, a, 4):
				return true
			if KarmaGame.cast_verb_for(state, a, 2):
				return true
			if _hunter_within(state, a, float(KarmaData.TUNING["aiFearRange"])):
				return KarmaGame.cast_verb_for(state, a, 3)
			return KarmaGame.cast_verb_for(state, a, 5)
		"oruga":
			if _hunter_within(state, a, 150.0):
				return KarmaGame.cast_verb_for(state, a, 2)
			return KarmaGame.cast_verb_for(state, a, 4)
		"lobo":
			var a_key: String = str(a.get("speciesKey", ""))
			var regen_hambre: float = float(KarmaData.TUNING["regenHambre"])
			var flock: Array = []
			for o in KarmaState.company_agents(state):
				if str(o.get("speciesKey", "")) == a_key and float(o.get("hambre", 100.0)) < regen_hambre:
					flock.append(o)
			var hungry: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), flock, float(KarmaData.TUNING["groomRange"]))
			if hungry != null:
				return KarmaGame.cast_verb_for(state, a, 2)
			return false
	return false


static func ai_try_hide(state: Dictionary, a: Dictionary) -> bool:
	if bool(a.get("hidden", false)):
		return true
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var hide_range: float = float(KarmaData.TUNING["hideRange"])
	var near: Array = []
	for r in state["refuges"]:
		if KarmaUtils.dist2(float(r["x"]), float(r["y"]), ax, ay) <= hide_range * hide_range:
			near.append(r)
	for r in near:
		if refuge_fits_size(KarmaData.SPECIES[str(a["speciesKey"])], r, str(a["speciesKey"])):
			a["hidden"] = true
			a["hideRef"] = r
			a["hideT"] = float(KarmaData.TUNING["aiHideMax"])
			return true
	return false


static func refuge_fits_size(sp: Dictionary, r: Dictionary, key: String) -> bool:
	if int(sp["size"]) > int(r["maxSize"]):
		return false
	if bool(r.get("climbOnly", false)) and not bool(sp.get("climb", false)):
		return false
	if bool(r.get("orugaOnly", false)) and key != "oruga":
		return false
	return true


static func is_hunted(state: Dictionary, a: Dictionary) -> bool:
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var max_d: float = fear_range_for(a)
	for o in state["agents"]:
		if not KarmaPredators.can_eat_agent(o, a):
			continue
		if KarmaUtils.dist2(ax, ay, float(o["x"]), float(o["y"])) < max_d * max_d:
			return true
	return false


static func ai_hide_tick(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not bool(a.get("hidden", false)):
		return false
	a["hideT"] = float(a.get("hideT", 0.0)) - dt
	var danger: bool = _hunter_within(state, a, float(ai_pred_row(a).get("perception", 200.0)))
	if float(a.get("hideT", 0.0)) <= 0.0 or not danger:
		a["hidden"] = false
		a["hideRef"] = null
	return true


static func ai_seek_carrion(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var hungry: bool = is_hungry(a)
	var percept: float = float(ai_pred_row(a)["perception"]) * (float(KarmaData.TUNING["lowHpPercept"]) if hungry else 1.0)
	var carrions: Array = []
	for k in state.get("carrions", []):
		if not bool(k.get("ceded", false)) or hungry:
			carrions.append(k)
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var c: Variant = KarmaUtils.nearest_from(ax, ay, carrions, percept)
	if c == null:
		return false
	var dx: float = float((c as Dictionary)["x"]) - ax
	var dy: float = float((c as Dictionary)["y"]) - ay
	var er: float = float(KarmaData.TUNING["eatRange"])
	if dx * dx + dy * dy > er * er:
		KarmaGame.move_toward(state, a, float((c as Dictionary)["x"]), float((c as Dictionary)["y"]), 1.0, dt)
		return true
	return KarmaEat.eat_carrion(state, c, a)


static func ai_grazer_eat(state: Dictionary, a: Dictionary, rnge: float) -> bool:
	if (KarmaData.DIET[str(a["speciesKey"])] as Array).has("insects"):
		var ins: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("insects", []), rnge)
		if ins != null and KarmaEat.eat_insect(state, ins, a):
			return true
	var p: Variant = KarmaEat.nearest_edible_patch_for(state, a, rnge)
	return p != null and KarmaEat.eat_patch(state, p, a)


static func ai_step(state: Dictionary, a: Dictionary, dt: float) -> void:
	match str(a.get("speciesKey", "")):
		"oruga":
			KarmaAIOruga.step(state, a, dt)
		"sapo":
			KarmaAISapo.step(state, a, dt)
		"raton":
			KarmaAIRaton.step(state, a, dt)
		"ardilla":
			KarmaAIArdilla.step(state, a, dt)
		"topo":
			KarmaAITopo.step(state, a, dt)
		"zorro":
			KarmaAIZorro.step(state, a, dt)
		"lobo":
			KarmaAILobo.step(state, a, dt)
		"halcon":
			KarmaAIHalcon.step(state, a, dt)


static func jev_step(state: Dictionary, a: Dictionary, dt: float, gates: Callable, steer: Callable, mock: Callable) -> void:
	KarmaUtils.update_needs(a, KarmaState.eff_max_hp_for(a), dt)
	ai_base(state, a, dt)
	KarmaJev.intent_tick(a, dt)
	if gates.call(state, a, dt):
		return
	if steer.call(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	mock.call(state, a)


# Returns the agent's live jev_intent, or null when absent or expired (expired is cleared).
static func live_jev_intent(a: Dictionary) -> Variant:
	if not a.has("jev_intent") or (a["jev_intent"] as Dictionary).is_empty():
		return null
	if float((a["jev_intent"] as Dictionary).get("ttl", 0.0)) <= 0.0:
		a["jev_intent"] = {}
		return null
	return a["jev_intent"] as Dictionary


static func jev_gates_common(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if ai_hide_tick(state, a, dt):
		return true
	if is_hunted(state, a) and ai_try_hide(state, a):
		return true
	if ai_thirst(state, a, dt):
		return true
	if ai_urgent_seek(state, a, dt):
		return true
	return false
