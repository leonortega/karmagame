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
	var be := max_d
	for o in list:
		var d := Vector2(ax, ay).distance_to(Vector2(float(o["x"]), float(o["y"])))
		var e := d / karma_sight_mult(float(o.get("karma", 0.0)))
		if e < be:
			be = e
			best = o
	return best


static func ai_pred_row(a: Dictionary) -> Dictionary:
	if KarmaData.PRED.has(str(a.get("speciesKey", ""))):
		return KarmaData.PRED[str(a["speciesKey"])]
	return {"perception": float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]), "damage": 15.0, "body": 18.0}


static func nearest_ai_prey(state: Dictionary, a: Dictionary, rnge: float) -> Variant:
	var prey := (state["agents"] as Array).filter(func(v):
		if v == a or str(v.get("brain", "")) == "PLAYER" or str(v.get("role", "")) == "hunter" or bool(v.get("hidden", false)):
			return false
		if str(a.get("speciesKey", "")) == "halcon":
			return int(KarmaData.SPECIES[str(v.get("speciesKey", "raton"))]["size"]) <= 2
		return KarmaPredators.edible_for(str(a.get("speciesKey", "")), str(v.get("speciesKey", "raton")), 1e9))
	return nearest_victim_karma_aware(float(a["x"]), float(a["y"]), prey, rnge)


static func ai_hunt_eat(state: Dictionary, a: Dictionary, prey: Dictionary, dt: float) -> bool:
	var d := Vector2(float(prey["x"]), float(prey["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
	if d == 0.0:
		d = 1.0
	var kill_range := 60.0 if str(a.get("speciesKey", "")) == "halcon" else 20.0
	if d <= kill_range:
		if str(a.get("speciesKey", "")) == "halcon":
			a["x"] = float(prey["x"])
			a["y"] = float(prey["y"])
		KarmaState.remove_agent(state, prey)
		KarmaEat.add_carrion(state, float(prey["x"]), float(prey["y"]))
		KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["pounceHp"]))
		if str(a.get("speciesKey", "")) == "zorro":
			a["satedT"] = float(KarmaData.TUNING["satedTime"])
		return true
	var mult: float = float(KarmaData.TUNING["loboChaseMult"]) if str(a.get("speciesKey", "")) == "lobo" else float(KarmaData.TUNING["chaseMult"])
	KarmaGame.move_toward(state, a, float(prey["x"]), float(prey["y"]), mult, dt)
	return false


static func ai_flee(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not KarmaData.PRED.has(str(a.get("speciesKey", ""))):
		return false
	var fears: Array = (KarmaData.PRED[str(a["speciesKey"])] as Dictionary).get("fears", [])
	if fears.is_empty():
		return false
	var fear: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["agents"] as Array).filter(func(o): return (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter") and str(o.get("type", "")) in fears), 200.0)
	if fear == null:
		return false
	var dx := float(a["x"]) - float((fear as Dictionary)["x"])
	var dy := float(a["y"]) - float((fear as Dictionary)["y"])
	var d := Vector2(dx, dy).length()
	if d == 0.0:
		d = 1.0
	dx /= d
	dy /= d
	var cover: Variant = null
	for r in state.get("refuges", []):
		if refuge_fits_size(KarmaData.SPECIES[str(a["speciesKey"])], r, str(a["speciesKey"])) and Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(float(a["x"]), float(a["y"]))) <= float(KarmaData.TUNING["aiCoverRange"]):
			cover = r
			break
	if cover != null:
		var cd := Vector2(float((cover as Dictionary)["x"]), float((cover as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
		if cd == 0.0:
			cd = 1.0
		dx = dx * 0.6 + (float((cover as Dictionary)["x"]) - float(a["x"])) / cd * 0.4
		dy = dy * 0.6 + (float((cover as Dictionary)["y"]) - float(a["y"])) / cd * 0.4
	var dl := Vector2(dx, dy).length()
	if dl == 0.0:
		dl = 1.0
	KarmaGame.move_toward(state, a, float(a["x"]) + dx / dl * 100.0, float(a["y"]) + dy / dl * 100.0, 1.0, dt)
	return true


static func ai_shout_if_ready(state: Dictionary, a: Dictionary) -> bool:
	if not str(a.get("speciesKey", "")) in AI_SHOUTERS:
		return false
	if float(a.get("shoutCd", 0.0)) > 0.0:
		return false
	if KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"])) == null:
		return false
	return KarmaState.ai_try_shout(state, a)


static func ai_base(state: Dictionary, a: Dictionary, dt: float) -> void:
	for k in ["shoutCd", "pounceCd", "strikeCd", "digCd", "curlCd", "groomCd", "senseCd", "lureTimer", "satedT", "landT"]:
		if float(a.get(k, 0.0)) > 0.0:
			a[k] = float(a[k]) - dt
	if a.has("verbCds"):
		for i in (a["verbCds"] as Array).size():
			if float((a["verbCds"] as Array)[i]) > 0.0:
				(a["verbCds"] as Array)[i] = float((a["verbCds"] as Array)[i]) - dt
	ai_shout_if_ready(state, a)
	a["buyT"] = float(a.get("buyT", 0.0)) - dt
	if float(a["buyT"]) <= 0.0:
		a["buyT"] = float(KarmaData.TUNING["aiBuyEvery"])
		if a.has("owned"):
			ai_buy_adaptation(state, a)
	if float(a.get("lureTimer", 0.0)) > 0.0:
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), KarmaState.all_hunters(state), float(KarmaData.TUNING["shoutLureRange"]))
		if p != null:
			var d := Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(float((p as Dictionary)["x"]), float((p as Dictionary)["y"])))
			if d == 0.0:
				d = 1.0
			(p as Dictionary)["x"] = float((p as Dictionary)["x"]) + (float(a["x"]) - float((p as Dictionary)["x"])) / d * 60.0 * dt
			(p as Dictionary)["y"] = float((p as Dictionary)["y"]) + (float(a["y"]) - float((p as Dictionary)["y"])) / d * 60.0 * dt


static func ai_strike(state: Dictionary, a: Dictionary, p: Dictionary) -> void:
	KarmaEat.strike_predator(state, p, a)
	var k: float = (float(KarmaData.TUNING["loboStrikeKarma"]) if str(p.get("type", "")) == "lobo" else float(KarmaData.TUNING["strikeKarma"])) * (2.0 if KarmaShop.has_adapt(a, "strikePlus") else 1.0)
	KarmaState.add_karma(state, a, k, "¡Ahuyenta a un %s! (+%d karma)" % [str(p.get("type", "")), int(k)])
	KarmaState.add_pa(state, a, float(KarmaData.TUNING["strikePa"]))
	a["hp"] = minf(float(KarmaData.SPECIES[str(a["speciesKey"])]["maxHp"]), float(a.get("hp", 0.0)) + float(KarmaData.TUNING["strikeHp"]))
	a["strikeCd"] = float(KarmaData.TUNING["strikeCd"])


static func ai_buy_adaptation(state: Dictionary, a: Dictionary) -> bool:
	var cat := KarmaShop.catalog_for(str(a.get("speciesKey", "")))
	if cat.is_empty():
		return false
	var owned: Dictionary = a.get("owned", {})
	var all_owned := true
	for it in cat:
		if not bool(owned.get(str(it["id"]), false)):
			all_owned = false
			break
	if all_owned:
		return false
	var max_hp := KarmaState.eff_max_hp_for(a)
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
		a["hp"] = minf(float(KarmaData.SPECIES[str(a["speciesKey"])]["maxHp"]) + 25.0, float(a.get("hp", 0.0)) + 25.0)
	return true


static func ai_max_hp(a: Dictionary) -> float:
	return float(KarmaData.SPECIES[str(a["speciesKey"])]["maxHp"]) + (25.0 if KarmaShop.has_adapt(a, "stomach") else 0.0)


static func is_hungry(a: Dictionary) -> bool:
	return float(a.get("hp", 0.0)) < float(KarmaData.SPECIES[str(a["speciesKey"])]["maxHp"]) * float(KarmaData.TUNING["hungerPriority"])


static func ai_forage(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var rnge: float = float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var target: Variant = null
	var bd := rnge
	if (KarmaData.DIET[str(a["speciesKey"])] as Array).has("insects"):
		var ins: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("insects", []), rnge)
		if ins != null:
			target = ins
			bd = Vector2(float((ins as Dictionary)["x"]), float((ins as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, bd)
	if patch != null:
		target = patch
	if target == null:
		return false
	KarmaGame.move_toward(state, a, float((target as Dictionary)["x"]), float((target as Dictionary)["y"]), 1.0, dt)
	return true


static func ai_drink(state: Dictionary, a: Dictionary, rnge := -1.0) -> bool:
	var r: float = rnge if rnge >= 0.0 else float(KarmaData.TUNING["drinkRange"])
	var w: Variant = KarmaUtils.nearest_water_for(state, float(a["x"]), float(a["y"]), r)
	return w != null and KarmaEat.drink_water(state, w, a)


static func seeks_water(a: Dictionary) -> bool:
	return (100.0 - float(a.get("sed", 100.0))) > (100.0 - float(a.get("hambre", 100.0)))


static func ai_seek_water(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var rnge: float = float(KarmaData.SPECIES[str(a["speciesKey"])]["vision"]) * float(KarmaData.TUNING["forageRangeMult"])
	var best: Variant = null
	var bd := rnge
	for w in state.get("waters", []):
		var d := Vector2(float(w["x"]), float(w["y"])).distance_to(Vector2(float(a["x"]), float(a["y"]))) - float(w["r"])
		if d < bd:
			bd = d
			best = w
	if best == null:
		return false
	KarmaGame.move_toward(state, a, float((best as Dictionary)["x"]), float((best as Dictionary)["y"]), 1.0, dt)
	return true


static func ai_thirst(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if float(a.get("sed", 100.0)) >= float(KarmaData.TUNING["regenSed"]):
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
			if float(a.get("groomCd", 0.0)) > 0.0 or KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), KarmaState.company_agents(state), float(KarmaData.TUNING["groomRange"])) == null:
				a["groomT"] = 0.0
			else:
				a["groomT"] = float(a.get("groomT", 0.0)) + dt
				if float(a["groomT"]) >= float(KarmaData.TUNING["groomTime"]):
					a["groomT"] = 0.0
					a["groomCd"] = float(KarmaData.TUNING["groomCd"])
					KarmaState.add_karma(state, a, float(KarmaData.TUNING["groomKarma"]), "Acicala a un congénere (+karma)")
					return true
			return KarmaGame.cast_verb_for(state, a, 5)
		"topo":
			var dug_near: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["refuges"] as Array).filter(func(r): return bool(r.get("dug", false))), float(KarmaData.TUNING["eatRange"]))
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
			var danger: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["shoutLureRange"]))
			if danger != null and float(a.get("shoutCd", 0.0)) > 0.0 and KarmaGame.cast_verb_for(state, a, 1):
				return true
			if danger != null and KarmaGame.cast_verb_for(state, a, 3):
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
			var pressure: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(KarmaData.TUNING["aiFearRange"]))
			if pressure != null:
				return KarmaGame.cast_verb_for(state, a, 3)
			return KarmaGame.cast_verb_for(state, a, 5)
		"oruga":
			var h: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter"), 150.0)
			if h != null:
				return KarmaGame.cast_verb_for(state, a, 2)
			return KarmaGame.cast_verb_for(state, a, 4)
		"lobo":
			var hungry: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
				KarmaState.company_agents(state).filter(func(o): return str(o.get("speciesKey", "")) == str(a.get("speciesKey", "")) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"])), float(KarmaData.TUNING["groomRange"]))
			if hungry != null:
				return KarmaGame.cast_verb_for(state, a, 2)
			return false
	return false


static func ai_try_hide(state: Dictionary, a: Dictionary) -> bool:
	if bool(a.get("hidden", false)):
		return true
	var near := (state["refuges"] as Array).filter(func(r): return Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(float(a["x"]), float(a["y"]))) <= float(KarmaData.TUNING["hideRange"]))
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
	return KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" and KarmaPredators.edible_for(str(o.get("type", "")), str(a.get("speciesKey", "")), 1e9)), float(KarmaData.TUNING["aiFearRange"])) != null


static func ai_hide_tick(state: Dictionary, a: Dictionary, dt: float) -> bool:
	if not bool(a.get("hidden", false)):
		return false
	a["hideT"] = float(a.get("hideT", 0.0)) - dt
	var danger: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), float(ai_pred_row(a).get("perception", 200.0)))
	if float(a.get("hideT", 0.0)) <= 0.0 or danger == null:
		a["hidden"] = false
		a["hideRef"] = null
	return true


static func ai_seek_carrion(state: Dictionary, a: Dictionary, dt: float) -> bool:
	var percept: float = float(ai_pred_row(a)["perception"]) * (float(KarmaData.TUNING["lowHpPercept"]) if is_hungry(a) else 1.0)
	var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
		(state.get("carrions", []) as Array).filter(func(k): return not bool(k.get("ceded", false)) or is_hungry(a)), percept)
	if c == null:
		return false
	var d := Vector2(float((c as Dictionary)["x"]), float((c as Dictionary)["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
	if d == 0.0:
		d = 1.0
	if d > float(KarmaData.TUNING["eatRange"]):
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
			_ai_oruga(state, a, dt)
		"sapo":
			_ai_sapo(state, a, dt)
		"raton":
			_ai_raton(state, a, dt)
		"ardilla":
			_ai_ardilla(state, a, dt)
		"topo":
			_ai_topo(state, a, dt)
		"zorro":
			_ai_zorro(state, a, dt)
		"lobo":
			_ai_lobo(state, a, dt)
		"halcon":
			_ai_halcon(state, a, dt)


static func _ai_oruga(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_hide_tick(state, a, dt):
		return
	if is_hunted(state, a) and ai_try_hide(state, a):
		return
	if ai_thirst(state, a, dt):
		return
	if ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		a["stillT"] = 0.0
		return
	if ai_forage(state, a, dt):
		a["stillT"] = 0.0
		return
	if ai_maybe_verb(state, a, dt):
		return
	a["stillT"] = float(a.get("stillT", 0.0)) + dt


static func _ai_sapo(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_hide_tick(state, a, dt):
		return
	if is_hunted(state, a) and ai_try_hide(state, a):
		return
	if ai_flee(state, a, dt):
		a["stillT"] = 0.0
		return
	if ai_thirst(state, a, dt):
		return
	if ai_grazer_eat(state, a, float(KarmaData.TUNING["tongueRange"]) + (40.0 if KarmaShop.has_adapt(a, "tonguePlus") else 0.0)):
		a["stillT"] = 0.0
		return
	if ai_forage(state, a, dt):
		a["stillT"] = 0.0
		return
	if ai_maybe_verb(state, a, dt):
		return
	a["stillT"] = float(a.get("stillT", 0.0)) + dt


static func _ai_raton(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_hide_tick(state, a, dt):
		return
	if is_hunted(state, a) and ai_try_hide(state, a):
		return
	if ai_thirst(state, a, dt):
		return
	if ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		return
	if ai_forage(state, a, dt):
		return
	if ai_maybe_verb(state, a, dt):
		return
	a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
	a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt


static func _ai_ardilla(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_hide_tick(state, a, dt):
		return
	if is_hunted(state, a) and ai_try_hide(state, a):
		return
	if ai_thirst(state, a, dt):
		return
	if ai_maybe_verb(state, a, dt):
		return
	if ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		return
	a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
	a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt


static func _ai_topo(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_hide_tick(state, a, dt):
		return
	if is_hunted(state, a) and ai_try_hide(state, a):
		return
	if ai_thirst(state, a, dt):
		return
	if ai_grazer_eat(state, a, float(KarmaData.TUNING["eatRange"])):
		return
	if ai_forage(state, a, dt):
		return
	if ai_maybe_verb(state, a, dt):
		return
	a["x"] = float(a["x"]) + (randf() - 0.5) * 40.0 * dt
	a["y"] = float(a["y"]) + (randf() - 0.5) * 40.0 * dt


static func _ai_zorro(state: Dictionary, a: Dictionary, dt: float) -> void:
	if KarmaJev.USE_JEV:
		_ai_zorro_jev(state, a, dt)
		return
	_ai_zorro_ladder(state, a, dt)


static func _ai_zorro_jev(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	KarmaJev.intent_tick(a, dt)
	if ai_flee(state, a, dt):
		return
	if ai_thirst(state, a, dt):
		return
	if is_hunted(state, a) and str((a.get("jev_intent", {}) as Dictionary).get("kind", "")) != "flee":
		a["jev_intent"] = {}
	if _ai_zorro_steer_intent(state, a, dt):
		return
	if bool(a.get("jev_live", false)):
		a["jev_intent"] = {"kind": "wander", "x": float(a["x"]), "y": float(a["y"]), "ttl": 5.0}
		return
	KarmaJev.mock_macro(state, a)


static func _ai_zorro_steer_intent(state: Dictionary, a: Dictionary, dt: float) -> bool:
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
				return ai_hunt_eat(state, a, prey, dt)
			KarmaGame.move_toward(state, a, float((prey as Dictionary)["x"]), float((prey as Dictionary)["y"]), float(KarmaData.TUNING["chaseMult"]), dt)
			return true
		"drink", "flee":
			if str(intent.get("kind", "")) == "drink" and ai_drink(state, a, float(KarmaData.TUNING["drinkRange"])):
				return true
			KarmaGame.move_toward(state, a, float(intent.get("x", float(a["x"]))), float(intent.get("y", float(a["y"]))), 1.0, dt)
			return true
		_:
			a["x"] = float(a["x"]) + (randf() - 0.5) * 60.0 * dt
			a["y"] = float(a["y"]) + (randf() - 0.5) * 60.0 * dt
			return true


static func _ai_zorro_ladder(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if ai_flee(state, a, dt):
		return
	if ai_thirst(state, a, dt):
		return
	if ai_maybe_verb(state, a, dt):
		return
	if is_hungry(a) and ai_seek_carrion(state, a, dt):
		return
	var prey: Variant = nearest_ai_prey(state, a, float(ai_pred_row(a)["perception"]))
	if prey != null:
		ai_hunt_eat(state, a, prey, dt)
		return
	var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c != null:
		KarmaEat.eat_carrion(state, c, a)
	elif not ai_forage(state, a, dt):
		a["x"] = float(a["x"]) + (randf() - 0.5) * 60.0 * dt
		a["y"] = float(a["y"]) + (randf() - 0.5) * 60.0 * dt


static func _ai_lobo(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if float(a.get("strikeCd", 0.0)) <= 0.0:
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
			(state["agents"] as Array).filter(func(o): return o != a and str(o.get("role", "")) == "hunter" and str(o.get("type", "")) != str(a.get("speciesKey", ""))), 60.0)
		if p != null:
			ai_strike(state, a, p)
			return
	if ai_thirst(state, a, dt):
		return
	if is_hungry(a) and ai_seek_carrion(state, a, dt):
		return
	if ai_maybe_verb(state, a, dt):
		return
	var prey: Variant = nearest_ai_prey(state, a, float(ai_pred_row(a)["perception"]))
	if prey != null:
		ai_hunt_eat(state, a, prey, dt)
		return
	var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c != null:
		KarmaEat.eat_carrion(state, c, a)


static func _ai_halcon(state: Dictionary, a: Dictionary, dt: float) -> void:
	KarmaUtils.update_needs(a, ai_max_hp(a), dt)
	ai_base(state, a, dt)
	if not bool(a.get("grounded", false)) and float(a.get("strikeCd", 0.0)) <= 0.0:
		var p: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]),
			(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
		if p != null:
			ai_strike(state, a, p)
			return
	if ai_thirst(state, a, dt):
		return
	if bool(a.get("grounded", false)):
		var c: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
		if c != null and float(a.get("landT", 0.0)) <= 0.0 and KarmaEat.eat_carrion(state, c, a):
			a["grounded"] = false
			return
		if float(a.get("landT", 0.0)) <= 0.0:
			a["grounded"] = false
		return
	var prey: Variant = nearest_ai_prey(state, a, 200.0)
	if prey != null:
		if ai_hunt_eat(state, a, prey, dt):
			a["grounded"] = true
			a["landT"] = float(KarmaData.TUNING["landTime"])
		return
	var c2: Variant = KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c2 != null:
		a["grounded"] = true
		a["landT"] = float(KarmaData.TUNING["landTime"])
		return
	a["x"] = float(a["x"]) + (randf() - 0.5) * 80.0 * dt
	a["y"] = float(a["y"]) + (randf() - 0.5) * 80.0 * dt
