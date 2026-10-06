class_name KarmaEat
extends RefCounted

# Port of src/script/eat.js — eating, hunting, drinking, burrow, sense.


static func diet_key(state: Dictionary, for_agent: Variant) -> String:
	return str((for_agent as Dictionary)["speciesKey"]) if for_agent != null else str(state["speciesKey"])


static func heal_eater(state: Dictionary, for_agent: Variant, n: float) -> void:
	if for_agent != null:
		var a := for_agent as Dictionary
		a["hp"] = minf(KarmaState.eff_max_hp_for(a), float(a.get("hp", 0.0)) + n)
	else:
		state["hp"] = minf(KarmaState.eff_max_hp(state), float(state["hp"]) + n)


static func hurt_eater(state: Dictionary, for_agent: Variant, n: float) -> void:
	if for_agent != null:
		(for_agent as Dictionary)["hp"] = float((for_agent as Dictionary).get("hp", 0.0)) + n
	else:
		state["hp"] = float(state["hp"]) + n


static func refill_hambre(state: Dictionary, for_agent: Variant, n: float) -> void:
	if for_agent != null:
		(for_agent as Dictionary)["hambre"] = minf(100.0, float((for_agent as Dictionary).get("hambre", 100.0)) + n)
	else:
		state["hambre"] = minf(100.0, float(state["hambre"]) + n)


static func eat_range(state: Dictionary) -> float:
	if str(state["speciesKey"]) != "sapo":
		return float(KarmaData.TUNING["eatRange"])
	return float(KarmaData.TUNING["tongueRange"]) + (40.0 if KarmaShop.has_adapt(state, "tonguePlus") else 0.0)


static func nearest_water(state: Dictionary, max_d: float) -> Variant:
	return KarmaUtils.nearest_water_for(state, float(state["px"]), float(state["py"]), max_d)


static func drink_water(state: Dictionary, w: Variant, for_agent: Variant) -> bool:
	if w == null:
		return false
	if for_agent != null:
		var a := for_agent as Dictionary
		a["sed"] = minf(100.0, float(a.get("sed", 100.0)) + float(KarmaData.TUNING["sipSed"]))
		heal_eater(state, a, float(KarmaData.TUNING["sipHp"]))
		return true
	state["sed"] = minf(100.0, float(state["sed"]) + float(KarmaData.TUNING["sipSed"]))
	state["hp"] = minf(KarmaState.eff_max_hp(state), float(state["hp"]) + float(KarmaData.TUNING["sipHp"]))
	KarmaState.add_log(state, null, "Bebes agua (+sed, +vida)")
	return true


static func try_drink(state: Dictionary) -> bool:
	return drink_water(state, nearest_water(state, float(KarmaData.TUNING["drinkRange"])), null)


static func try_eat(state: Dictionary) -> bool:
	if bool(state.get("dead", false)) or bool(state.get("hidden", false)):
		return false
	match str(state["speciesKey"]):
		"zorro":
			return eat_as_zorro(state)
		"halcon":
			return eat_as_halcon(state)
		"topo":
			return eat_as_topo(state)
		"sapo":
			return eat_as_sapo(state)
		_:
			return eat_as_grazer(state)


static func eat_as_zorro(state: Dictionary) -> bool:
	if float(state.get("pounceCd", 0.0)) <= 0.0:
		var m: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.company_agents(state), float(KarmaData.TUNING["pounceRange"]))
		if m != null:
			return pounce_kill(state, m, null)
	if KarmaUtils.thirstier(state):
		if try_drink(state):
			return true
	var c: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	if c != null:
		if float(state["hp"]) >= float(KarmaData.TUNING["wastefulHpFrac"]) * KarmaState.eff_max_hp(state) and not bool((c as Dictionary).get("ceded", false)):
			return cede_carrion(state, c)
		return eat_carrion(state, c, null)
	if try_drink(state):
		return true
	return diet_hint_if_near(state)


static func cede_carrion(state: Dictionary, c: Dictionary) -> bool:
	c["ceded"] = true
	var k: float = float(KarmaData.TUNING["cedeKarma"]) * (2.0 if KarmaShop.has_adapt(state, "cedePlus") else 1.0)
	KarmaState.add_karma(state, null, k, "Cedes la presa a otros (+%d karma, la dejas)" % int(k))
	return true


static func eat_as_halcon(state: Dictionary) -> bool:
	var p: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.all_hunters(state), 60.0)
	if p != null and float(state.get("strikeCd", 0.0)) <= 0.0:
		return strike_predator(state, p, null)
	var m: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.company_agents(state), 60.0)
	if m != null:
		return dive_kill(state, m, null)
	return land_for_meal(state)


static func strike_predator(state: Dictionary, p: Dictionary, for_agent: Variant) -> bool:
	var ox := float((for_agent as Dictionary)["x"]) if for_agent != null else float(state["px"])
	var oy := float((for_agent as Dictionary)["y"]) if for_agent != null else float(state["py"])
	if for_agent == null:
		state["strikeCd"] = float(KarmaData.TUNING["strikeCd"])
	var is_lobo: bool = str(p.get("type", "")) == "lobo"
	p["x"] = float(p["x"]) + (float(p["x"]) - ox) * 0.6
	p["y"] = float(p["y"]) + (float(p["y"]) - oy) * 0.6
	p["hitCd"] = 2.0
	if for_agent != null:
		return true
	var k: float = (float(KarmaData.TUNING["loboStrikeKarma"]) if is_lobo else float(KarmaData.TUNING["strikeKarma"])) * (2.0 if KarmaShop.has_adapt(state, "strikePlus") else 1.0)
	KarmaState.add_karma(state, null, k, "¡Ahuyentas un Lobo! Hazaña (+%d karma)" % int(k) if is_lobo else "Caza necesaria: ahuyentas depredador (+%d karma)" % int(k))
	KarmaState.add_pa(state, null, float(KarmaData.TUNING["strikePa"]))
	state["hp"] = minf(KarmaState.eff_max_hp(state), float(state["hp"]) + float(KarmaData.TUNING["strikeHp"]))
	return true


static func land_for_meal(state: Dictionary) -> bool:
	var c: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	var w: Variant = nearest_water(state, float(KarmaData.TUNING["drinkRange"]))
	if c == null and w == null:
		return diet_hint_if_near(state)
	if not bool(state.get("grounded", false)):
		state["grounded"] = true
		state["landT"] = float(KarmaData.TUNING["landTime"])
		KarmaState.add_log(state, null, "Aterrizas para comer (vulnerable 1s)…")
		return true
	if float(state.get("landT", 0.0)) > 0.0:
		return true
	if KarmaUtils.thirstier(state):
		return try_drink(state) or (eat_carrion(state, c, null) if c != null else false)
	return (eat_carrion(state, c, null) if c != null else false) or try_drink(state)


static func eat_as_topo(state: Dictionary) -> bool:
	if KarmaUtils.thirstier(state):
		if try_drink(state):
			return true
	if eat_carrion(state, KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"])), null):
		return true
	if eat_insect(state, KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("insects", []), float(KarmaData.TUNING["eatRange"])), null):
		return true
	if eat_patch(state, nearest_edible_patch(state, float(KarmaData.TUNING["eatRange"])), null):
		return true
	if try_drink(state):
		return true
	return dig_burrow(state, null)


static func eat_as_sapo(state: Dictionary) -> bool:
	if KarmaUtils.thirstier(state):
		if try_drink(state):
			return true
	if eat_insect(state, KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("insects", []), eat_range(state)), null):
		return true
	if try_drink(state):
		return true
	return diet_hint_if_near(state)


static func eat_as_grazer(state: Dictionary) -> bool:
	if KarmaUtils.thirstier(state):
		if try_drink(state):
			return true
	if eat_carrion(state, KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"])), null):
		return true
	if eat_patch(state, nearest_edible_patch(state, float(KarmaData.TUNING["eatRange"])), null):
		return true
	if try_drink(state):
		return true
	return diet_hint_if_near(state)


static func diet_hint_if_near(state: Dictionary) -> bool:
	var all: Array = (state.get("bushes", []) as Array) + (state.get("shrubs", []) as Array) + (state.get("patches", []) as Array) + (state.get("clusters", []) as Array) + (state.get("clumps", []) as Array) + (state.get("oaks", []) as Array)
	var any_food: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]),
		all.filter(func(p): return bool(p.get("alive", false)) and int(p.get("amount", 0)) > 0), 60.0)
	if any_food == null:
		any_food = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("insects", []), 60.0)
	if any_food == null:
		any_food = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), 60.0)
	if any_food != null:
		KarmaState.diet_hint(state)
	return false


static func nearest_edible_patch(state: Dictionary, max_d: float) -> Variant:
	return nearest_edible_patch_for(state, {"speciesKey": state["speciesKey"], "x": state["px"], "y": state["py"]}, max_d)


static func nearest_edible_patch_for(state: Dictionary, a: Dictionary, max_d: float) -> Variant:
	var all: Array = (state.get("bushes", []) as Array) + (state.get("shrubs", []) as Array) + (state.get("patches", []) as Array) + (state.get("clusters", []) as Array) + (state.get("clumps", []) as Array) + (state.get("oaks", []) as Array)
	var best: Variant = null
	var bd := max_d
	for p in all:
		if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 0:
			continue
		if not (KarmaData.DIET[str(a["speciesKey"])] as Array).has(str(p["kind"])):
			continue
		var d := Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(float(a["x"]), float(a["y"])))
		if d < bd:
			bd = d
			best = p
	return best


static func nearest_oak_with_nuts_for(state: Dictionary, a: Dictionary, max_d: float) -> Variant:
	var ax := float(a.get("x", (state as Dictionary).get("px", 0.0)))
	var ay := float(a.get("y", (state as Dictionary).get("py", 0.0)))
	var best: Variant = null
	var bd := max_d
	for o in state.get("oaks", []):
		if not bool(o.get("alive", false)) or int(o.get("amount", 0)) <= 0:
			continue
		var d := Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(ax, ay))
		if d < bd:
			bd = d
			best = o
	return best


static func nearest_spare_flora_for(state: Dictionary, a: Dictionary, max_d: float) -> Variant:
	var ax := float(a.get("x", (state as Dictionary).get("px", 0.0)))
	var ay := float(a.get("y", (state as Dictionary).get("py", 0.0)))
	var all: Array = (state.get("bushes", []) as Array) + (state.get("shrubs", []) as Array) + (state.get("patches", []) as Array) + (state.get("clusters", []) as Array) + (state.get("oaks", []) as Array)
	var best: Variant = null
	var bd := max_d
	for p in all:
		if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 1:
			continue
		if not (KarmaData.DIET[str(a["speciesKey"])] as Array).has(str(p["kind"])):
			continue
		var d := Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(ax, ay))
		if d < bd:
			bd = d
			best = p
	return best


static func pounce_kill(state: Dictionary, m: Dictionary, for_agent: Variant) -> bool:
	add_carrion(state, float(m["x"]), float(m["y"]))
	if for_agent != null:
		(for_agent as Dictionary)["pounceCd"] = float(KarmaData.TUNING["pounceCd"])
		heal_eater(state, for_agent, float(KarmaData.TUNING["pounceHp"]))
		return true
	state["pounceCd"] = float(KarmaData.TUNING["pounceCd"])
	KarmaState.remove_agent(state, m)
	KarmaState.add_pa(state, null, float(KarmaData.TUNING["pouncePa"]))
	if float(state["hp"]) >= float(KarmaData.TUNING["wastefulHpFrac"]) * KarmaState.eff_max_hp(state):
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["wastefulKarma"]), "Mataste por deporte: %d karma" % int(KarmaData.TUNING["wastefulKarma"]))
	else:
		state["hp"] = minf(KarmaState.eff_max_hp(state), float(state["hp"]) + float(KarmaData.TUNING["pounceHp"]))
		KarmaState.add_log(state, null, "Zarpazo necesario (+vida)")
	return true


static func dive_kill(state: Dictionary, m: Dictionary, for_agent: Variant) -> bool:
	add_carrion(state, float(m["x"]), float(m["y"]))
	if for_agent != null:
		(for_agent as Dictionary)["x"] = float(m["x"])
		(for_agent as Dictionary)["y"] = float(m["y"])
		heal_eater(state, for_agent, float(KarmaData.TUNING["pounceHp"]))
		return true
	state["px"] = float(m["x"])
	state["py"] = float(m["y"])
	KarmaState.remove_agent(state, m)
	KarmaState.add_pa(state, null, float(KarmaData.TUNING["divePa"]))
	state["grounded"] = true
	if float(state["hp"]) >= float(KarmaData.TUNING["wastefulHpFrac"]) * KarmaState.eff_max_hp(state):
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["wastefulKarma"]), "Cazaste por deporte desde el cielo (%d karma)" % int(KarmaData.TUNING["wastefulKarma"]))
	else:
		state["hp"] = minf(KarmaState.eff_max_hp(state), float(state["hp"]) + float(KarmaData.TUNING["pounceHp"]))
		KarmaState.add_log(state, null, "Picado necesario (+vida)")
	return true


static func dig_burrow(state: Dictionary, for_agent: Variant) -> bool:
	var t: Dictionary = for_agent if for_agent != null else state
	var dig_plus := 1 if KarmaShop.has_adapt(t, "digPlus") else 0
	if float(t.get("digCd", 0.0)) > 0.0 or int(t.get("dug", 0)) >= int(KarmaData.TUNING["digMax"]) + dig_plus:
		return false
	t["digCd"] = float(KarmaData.TUNING["digCd"])
	t["dug"] = int(t.get("dug", 0)) + 1
	var px := float((for_agent as Dictionary)["x"]) if for_agent != null else float(state["px"])
	var py := float((for_agent as Dictionary)["y"]) if for_agent != null else float(state["py"])
	(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": px, "y": py, "dug": true})
	if for_agent != null:
		KarmaState.add_karma(state, for_agent, float(KarmaData.TUNING["aerateKarma"]), "Airea la tierra (+karma)")
		return true
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["aerateKarma"]), "Aireas la tierra (+karma)")
	KarmaState.add_log(state, null, "Cavaste madriguera (%d/%d)" % [int(state["dug"]), int(KarmaData.TUNING["digMax"])])
	return true


static func eat_patch(state: Dictionary, p: Variant, for_agent: Variant) -> bool:
	if p == null:
		return false
	if not (KarmaData.DIET[diet_key(state, for_agent)] as Array).has(str((p as Dictionary)["kind"])):
		return false
	var patch := p as Dictionary
	if str(patch["kind"]) == "berries" and bool(patch.get("mimic", false)) and not bool(patch.get("mimicEaten", false)):
		return eat_mimic(state, patch, for_agent)
	if str(patch["kind"]) == "mushrooms" and int(patch.get("toxicLeft", 0)) > 0:
		return eat_toxic_shroom(state, patch, for_agent)
	patch["amount"] = int(patch["amount"]) - 1
	if str(patch["kind"]) != "leaves":
		KarmaGame.drop_seed(state, str(patch["kind"]), float(patch["x"]), float(patch["y"]))
	if int(patch["amount"]) <= 0 and str(patch["kind"]) != "leaves":
		return eat_last_fruit(state, patch, for_agent)
	return eat_sustainable(state, patch, KarmaData.FOODDEF[str(patch["kind"])], for_agent)


static func eat_mimic(state: Dictionary, p: Dictionary, for_agent: Variant) -> bool:
	p["mimicEaten"] = true
	p["amount"] = int(p["amount"]) - 1
	if int(p["amount"]) <= 0:
		p["alive"] = false
	hurt_eater(state, for_agent, float(KarmaData.TUNING["mimicHp"]))
	if for_agent == null:
		KarmaState.add_log(state, null, "¡Era un mímico! Fruto ponzoñoso (−20 vida)")
	return true


static func eat_toxic_shroom(state: Dictionary, p: Dictionary, for_agent: Variant) -> bool:
	p["toxicLeft"] = int(p["toxicLeft"]) - 1
	p["amount"] = int(p["amount"]) - 1
	if int(p["amount"]) <= 0:
		p["alive"] = false
	hurt_eater(state, for_agent, float(KarmaData.TUNING["mimicHp"]))
	if for_agent == null:
		KarmaState.add_log(state, null, "¡Seta tóxica! (−20 vida)")
	return true


static func eat_last_fruit(state: Dictionary, p: Dictionary, for_agent: Variant) -> bool:
	p["alive"] = false
	heal_eater(state, for_agent, float(KarmaData.TUNING["lastFruitHp"]))
	refill_hambre(state, for_agent, float(KarmaData.TUNING["lastFruitHp"]))
	if for_agent == null:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["lastFruitKarma"]), "Último %s: se seca para siempre (%d karma)" % [str(p["kind"]), int(KarmaData.TUNING["lastFruitKarma"])])
	return true


static func eat_sustainable(state: Dictionary, p: Dictionary, pay: Dictionary, for_agent: Variant) -> bool:
	if int(p.get("amount", 0)) <= 0:
		p["alive"] = false
		p["regrowT"] = 0.0
	heal_eater(state, for_agent, float(pay["hp"]))
	refill_hambre(state, for_agent, float(pay["hp"]))
	if for_agent != null:
		if str((for_agent as Dictionary).get("speciesKey", "")) == "oruga" and str(p["kind"]) == "leaves" and int(p.get("amount", 0)) > 0:
			KarmaState.add_karma(state, for_agent, float(KarmaData.TUNING["prudentKarma"]), "Mordisqueo prudente (+karma)")
		return true
	KarmaState.add_pa(state, null, float(pay["pa"]))
	if str(state["speciesKey"]) == "oruga" and str(p["kind"]) == "leaves" and int(p.get("amount", 0)) > 0:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["prudentKarma"]), "Mordisqueo prudente (+karma)")
	KarmaState.add_log(state, null, "Comida sostenible (+vida)")
	return true


static func eat_insect(state: Dictionary, i: Variant, for_agent: Variant) -> bool:
	if i == null:
		return false
	if not (KarmaData.DIET[diet_key(state, for_agent)] as Array).has("insects"):
		return false
	(state["insects"] as Array).erase(i)
	var pay: Dictionary = KarmaData.FOODDEF["insects"]
	heal_eater(state, for_agent, float(pay["hp"]))
	refill_hambre(state, for_agent, float(pay["hp"]))
	if for_agent != null:
		if str((for_agent as Dictionary).get("speciesKey", "")) == "sapo":
			KarmaState.add_karma(state, for_agent, float(KarmaData.TUNING["pestKarma"]), "Control de plagas (+karma)")
		return true
	KarmaState.add_pa(state, null, float(pay["pa"]))
	if str(state["speciesKey"]) == "sapo":
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["pestKarma"]), "Control de plagas (+karma)")
	KarmaState.add_log(state, null, "Insecto (+vida)")
	return true


static func carrion_stage(c: Dictionary) -> String:
	if float(c.get("age", 0.0)) < float(KarmaData.TUNING["carrionFreshT"]):
		return "fresh"
	if float(c.get("age", 0.0)) < float(KarmaData.TUNING["carrionRottenT"]):
		return "stale"
	return "rotten"


static func add_carrion(state: Dictionary, x: float, y: float) -> void:
	var pt := {"x": x, "y": y}
	KarmaUtils.nudge_dry(state, pt)
	(state["carrions"] as Array).append({"x": float(pt["x"]), "y": float(pt["y"]), "age": 0.0})
	while (state["carrions"] as Array).size() > int(KarmaData.TUNING["carrionCap"]):
		var idx := 0
		var worst := -1.0
		for ci in (state["carrions"] as Array).size():
			var c: Dictionary = (state["carrions"] as Array)[ci]
			var score := (10000.0 if carrion_stage(c) == "rotten" else 0.0) + float(c.get("age", 0.0))
			if score > worst:
				worst = score
				idx = ci
		(state["carrions"] as Array).remove_at(idx)


static func eat_carrion(state: Dictionary, c: Variant, for_agent: Variant) -> bool:
	if c == null:
		return false
	if not (KarmaData.DIET[diet_key(state, for_agent)] as Array).has("carrion"):
		return false
	var car := c as Dictionary
	var stage := carrion_stage(car)
	(state["carrions"] as Array).erase(car)
	if stage == "fresh":
		heal_eater(state, for_agent, float(KarmaData.TUNING["carrionFreshHp"]))
		refill_hambre(state, for_agent, float(KarmaData.TUNING["carrionFreshHp"]))
		if for_agent != null and int((for_agent as Dictionary).get("stash", 0)) > 0:
			(for_agent as Dictionary)["stash"] = int((for_agent as Dictionary)["stash"]) - 1
			KarmaState.add_pa(state, for_agent, float(KarmaData.TUNING["pouncePa"]))
		if for_agent == null:
			KarmaState.add_pa(state, null, float(KarmaData.TUNING["carrionFreshPa"]))
			if int(state.get("stash", 0)) > 0:
				state["stash"] = int(state["stash"]) - 1
				KarmaState.add_pa(state, null, float(KarmaData.TUNING["pouncePa"]))
			KarmaState.add_log(state, null, "Comes carroña fresca (+vida)")
	elif stage == "stale":
		heal_eater(state, for_agent, float(KarmaData.TUNING["carrionStaleHp"]))
		refill_hambre(state, for_agent, float(KarmaData.TUNING["carrionStaleHp"]))
		if for_agent == null:
			if int(state.get("stash", 0)) > 0:
				state["stash"] = int(state["stash"]) - 1
				KarmaState.add_pa(state, null, float(KarmaData.TUNING["pouncePa"]))
			KarmaState.add_log(state, null, "Carroña pasada (+poca vida)")
	else:
		hurt_eater(state, for_agent, float(KarmaData.TUNING["carrionRottenHp"]))
		if for_agent == null:
			KarmaState.add_log(state, null, "¡Podrida! Carroña en mal estado (−25 vida)")
	return true


static func bury_or_carry_nut(state: Dictionary, for_agent: Variant) -> bool:
	var t: Dictionary = for_agent if for_agent != null else state
	var px := float((for_agent as Dictionary)["x"]) if for_agent != null else float(state["px"])
	var py := float((for_agent as Dictionary)["y"]) if for_agent != null else float(state["py"])
	if bool(t.get("carriedNut", false)):
		t["carriedNut"] = false
		if for_agent != null:
			t["saplings"] = int(t.get("saplings", 0)) + 1
		else:
			state["saplings"] = int(state.get("saplings", 0)) + 1
		KarmaGame.drop_seed(state, "oak-tree", px, py)
		if for_agent != null:
			KarmaState.add_karma(state, for_agent, float(KarmaData.TUNING["plantKarma"]), "Planta un bosque futuro (+karma)")
			return true
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["plantKarma"]), "Plantas un bosque futuro (+karma)")
		return true
	var oak: Variant = null
	for o in state.get("oaks", []):
		if bool(o.get("alive", false)) and int(o.get("amount", 0)) > 0 and Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(px, py)) <= 46.0:
			oak = o
			break
	if oak == null:
		return false
	(oak as Dictionary)["amount"] = int((oak as Dictionary)["amount"]) - 1
	if int((oak as Dictionary)["amount"]) <= 0:
		(oak as Dictionary)["alive"] = false
	t["carriedNut"] = true
	if for_agent == null:
		KarmaState.add_log(state, null, "Llevas una nuez (C para enterrar)")
	return true


static func carry_action(state: Dictionary) -> bool:
	if bool(state.get("dead", false)) or bool(state.get("hidden", false)) or str(state["speciesKey"]) != "ardilla":
		return false
	return bury_or_carry_nut(state, null)


static func sense_pulse(state: Dictionary) -> bool:
	if bool(state.get("dead", false)) or bool(state.get("hidden", false)) or float(state.get("senseCd", 0.0)) > 0.0:
		return false
	if str(state["speciesKey"]) == "topo":
		state["senseCd"] = float(KarmaData.TUNING["senseTremorCd"])
		state["revealT"] = float(KarmaData.TUNING["revealTime"])
		KarmaState.add_log(state, null, "Temblor: sientes comida y peligro (3s)")
		return true
	if str(state["speciesKey"]) == "zorro":
		if (state.get("carrions", []) as Array).is_empty():
			KarmaState.add_log(state, null, "Sin rastro de carroña")
			return false
		state["senseCd"] = float(KarmaData.TUNING["senseTrackCd"])
		state["trackT"] = float(KarmaData.TUNING["trackTime"])
		KarmaState.add_log(state, null, "Rastro: hueles carroña (5s)")
		return true
	return false
