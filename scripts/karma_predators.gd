class_name KarmaPredators
extends RefCounted

# Port of src/script/predators.js — trophic chain + hunter stepping.


static func mk_predator(state: Dictionary, type: String, x: float, y: float, player_tier: int) -> Dictionary:
	var t: Dictionary = KarmaData.PRED.get(type, KarmaData.PRED_FALLBACK)
	var key := "sapo" if type == "saponpc" else type
	var speed: float = float(t["speed"]) + (25.0 if player_tier == 0 and type == "zorro" else 0.0)
	return {"type": type, "speciesKey": key, "kind": "hunter", "role": "hunter", "brain": "AI",
		"hp": float(KarmaData.SPECIES[key]["maxHp"]), "hambre": 100.0, "sed": 100.0, "edad": 0.0,
		"x": x, "y": y, "wx": x, "wy": y, "speed": speed,
		"mode": "wander", "campT": 0.0, "huntT": 0.0, "restT": 0.0, "satedT": 0.0,
		"fleeLatch": false, "huntingPlayer": false, "karma": 0.0, "pa": 0.0, "owned": {}, "lifeLog": [],
		"caution_food": randf(), "caution_water": randf()}


static func edible_for(hunter_type: String, victim_key: String, dist: float) -> bool:
	if hunter_type == "saponpc":
		return victim_key == "oruga"
	var t: Variant = KarmaData.PRED.get(hunter_type, null)
	if t == null or not (t as Dictionary).has("huntsTiers"):
		return false
	var v: Dictionary = KarmaData.SPECIES[victim_key]
	if not ((t as Dictionary)["huntsTiers"] as Array).has(int(v["tier"])):
		return false
	if hunter_type == "zorro" and float((t as Dictionary)["size"]) - float(v["size"]) >= 2.0 and dist > float(KarmaData.TUNING["snapRange"]):
		return false
	return true


static func player_edible_for(state: Dictionary, p: Dictionary, dist: float) -> bool:
	return edible_for(str(p["type"]), str(state["speciesKey"]), dist)


static func camouflaged_state(state: Dictionary) -> bool:
	return str(state["speciesKey"]) == "sapo" and float(state.get("stillT", 0.0)) >= 2.0


static func camouflaged_agent(agent: Dictionary) -> bool:
	return str(agent.get("speciesKey", "")) == "sapo" and float(agent.get("stillT", 0.0)) >= 2.0


static func canopy_blind(state: Dictionary, pred: Dictionary) -> bool:
	if not bool(state.get("hidden", false)):
		return false
	if str((state.get("hideRef", {}) as Dictionary).get("type", "")) == "old-oak" and str(pred.get("type", "")) == "halcon":
		return false
	return true


static func curled_state(state: Dictionary) -> bool:
	return str(state["speciesKey"]) == "oruga" and float(state.get("stillT", 0.0)) >= 0.01 and float(state.get("curlCd", 0.0)) <= 0.0 and not bool(state.get("moved", false))


static func curled_agent(agent: Dictionary) -> bool:
	return str(agent.get("speciesKey", "")) == "oruga" and float(agent.get("stillT", 0.0)) >= 0.01 and float(agent.get("curlCd", 0.0)) <= 0.0


static func update_predators(state: Dictionary, dt: float, rng: RandomNumberGenerator, solids: Array = []) -> void:
	var dead: Array = []
	var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
	for p in KarmaState.all_hunters(state):
		step_predator(state, p, dt, dead, rng, list)
	for z in dead:
		KarmaState.remove_agent(state, z)


static func step_predator(state: Dictionary, p: Dictionary, dt: float, dead: Array, rng: RandomNumberGenerator, solids: Array = []) -> void:
	var t: Dictionary = KarmaData.PRED.get(str(p.get("type", "")), KarmaData.PRED_FALLBACK)
	p["hambre"] = clampf(float(p.get("hambre", 100.0)) - KarmaData.hunger_rate_for(str(p.get("speciesKey", "zorro"))) * dt, 0.0, 100.0)
	p["sed"] = clampf(float(p.get("sed", 100.0)) - KarmaData.thirst_rate_for(str(p.get("speciesKey", "zorro"))) * dt, 0.0, 100.0)
	p["edad"] = float(p.get("edad", 0.0)) + dt
	if float(p.get("satedT", 0.0)) > 0.0:
		p["satedT"] = float(p["satedT"]) - dt
	if float(p.get("restT", 0.0)) > 0.0:
		p["restT"] = float(p["restT"]) - dt
	if flee_check(state, p, t, dt):
		return
	if camp_step(state, p, dt):
		return
	if KarmaAI.ai_thirst(state, p, dt):
		return
	var dp := Vector2(float(state["px"]), float(state["py"])).distance_to(Vector2(float(p["x"]), float(p["y"])))
	var camo_hidden := camouflaged_state(state) and str(p.get("type", "")) == "zorro"
	var lure_on := float(state.get("lureTimer", 0.0)) > 0.0 and not bool(state.get("hidden", false)) and not (camouflaged_state(state) and str(p.get("type", "")) == "zorro")
	var hit := pick_target(state, p, t, dp, lure_on, camo_hidden, rng, solids)
	if str(hit.get("hunting", "")) != "":
		chase(p, t, hit, lure_on, dt)
	else:
		p["huntT"] = 0.0
		strike_agents(state, p, t, dt, solids)
	strike_contact(state, p, t, dp)
	feast(state, p, dead)


static func edible_agent_for(state: Dictionary, hunter_type: String, a: Dictionary, dist: float) -> bool:
	if str(a.get("brain", "")) == "PLAYER":
		return false
	if hunter_type == "halcon":
		return int(KarmaData.SPECIES[str(a.get("speciesKey", "raton"))]["size"]) <= 2
	return edible_for(hunter_type, str(a.get("speciesKey", "raton")), dist)


static func stalk_victims(state: Dictionary, p: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return a != p and str(a.get("role", "")) != "hunter" and edible_agent_for(state, str(p.get("type", "")), a, 1e9))


static func strike_agents(state: Dictionary, p: Dictionary, t: Dictionary, dt: float, solids: Array = []) -> void:
	if float(p.get("restT", 0.0)) > 0.0:
		return
	var flying: bool = str(p.get("type", "")) == "halcon"
	var sight := float(t["perception"]) * 1.25
	var cands := stalk_victims(state, p).filter(func(o): return Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(p["x"]), float(p["y"]))) <= sight and not KarmaUtils.los_blocked(state, float(p["x"]), float(p["y"]), float(o["x"]), float(o["y"]), flying, solids))
	var v: Variant = KarmaAI.nearest_victim_karma_aware(float(p["x"]), float(p["y"]), cands, float(t["perception"]))
	if v == null:
		return
	var d := Vector2(float(v["x"]), float(v["y"])).distance_to(Vector2(float(p["x"]), float(p["y"])))
	if d == 0.0:
		d = 1.0
	var kill_range := 60.0 if str(p.get("type", "")) == "halcon" else 20.0
	if d <= kill_range:
		if str(p.get("type", "")) == "halcon":
			KarmaEat.dive_kill(state, v, p)
			KarmaState.remove_agent(state, v)
			return
		KarmaState.remove_agent(state, v)
		KarmaEat.add_carrion(state, float(v["x"]), float(v["y"]))
		KarmaEat.heal_eater(state, p, float(KarmaData.TUNING["pounceHp"]))
		if str(p.get("type", "")) == "zorro":
			p["satedT"] = float(KarmaData.TUNING["satedTime"])
		return
	var mult: float = float(KarmaData.TUNING["loboChaseMult"]) if str(p.get("type", "")) == "lobo" else float(KarmaData.TUNING["chaseMult"])
	p["x"] = float(p["x"]) + (float(v["x"]) - float(p["x"])) / d * float(p.get("speed", 100.0)) * mult * dt
	p["y"] = float(p["y"]) + (float(v["y"]) - float(p["y"])) / d * float(p.get("speed", 100.0)) * mult * dt
	p["mode"] = "hunt"


static func flee_check(state: Dictionary, p: Dictionary, t: Dictionary, dt: float) -> bool:
	var fears: Array = (t.get("fears", []) as Array)
	var range_mult := float(KarmaData.TUNING["fleeHysteresis"]) if bool(p.get("fleeLatch", false)) else 1.0
	var hunters := (state["agents"] as Array).filter(func(o): return (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter") and (o.get("type", "") in fears))
	var fear: Variant = KarmaUtils.nearest_from(float(p["x"]), float(p["y"]), hunters, float(t["perception"]) * range_mult)
	if fear != null:
		p["fleeLatch"] = true
	elif KarmaUtils.nearest_from(float(p["x"]), float(p["y"]), hunters, float(t["perception"]) * float(KarmaData.TUNING["fleeHysteresis"])) == null:
		p["fleeLatch"] = false
	if bool(p.get("fleeLatch", false)) and fear != null:
		var d := Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(float((fear as Dictionary)["x"]), float((fear as Dictionary)["y"])))
		if d == 0.0:
			d = 1.0
		p["x"] = float(p["x"]) + (float(p["x"]) - float((fear as Dictionary)["x"])) / d * float(p.get("speed", 100.0)) * 1.3 * dt
		p["y"] = float(p["y"]) + (float(p["y"]) - float((fear as Dictionary)["y"])) / d * float(p.get("speed", 100.0)) * 1.3 * dt
		p["mode"] = "flee"
		return true
	return false


static func camp_step(state: Dictionary, p: Dictionary, dt: float) -> bool:
	if str(p.get("mode", "")) == "camp":
		p["campT"] = float(p.get("campT", 0.0)) - dt
		if float(p["campT"]) <= 0.0:
			p["mode"] = "wander"
		elif state.get("hideRef", null) != null:
			var hr: Dictionary = state["hideRef"]
			var dx: float = float(hr["x"]) - float(p["x"])
			var dy: float = float(hr["y"]) - float(p["y"])
			var dd := Vector2(dx, dy).length()
			if dd == 0.0:
				dd = 1.0
			if dd > 30.0:
				p["x"] = float(p["x"]) + dx / dd * float(p.get("speed", 100.0)) * dt
				p["y"] = float(p["y"]) + dy / dd * float(p.get("speed", 100.0)) * dt
		return true
	if bool(state.get("hidden", false)) and bool(p.get("huntingPlayer", false)):
		if not canopy_blind(state, p):
			return false
		p["mode"] = "camp"
		p["campT"] = float(KarmaData.TUNING["campTime"])
		p["huntingPlayer"] = false
		return true
	return false


static func pick_target(state: Dictionary, p: Dictionary, t: Dictionary, dp: float, lure_on: bool, camo_hidden: bool, rng: RandomNumberGenerator, solids: Array = []) -> Dictionary:
	if (lure_on and dp < float(KarmaData.TUNING["shoutLureRange"])) or (not bool(state.get("hidden", false)) and not camo_hidden and player_edible_for(state, p, dp) and dp < float(t["perception"]) and float(p.get("restT", 0.0)) <= 0.0):
		p["huntingPlayer"] = true
		return {"tx": state["px"], "ty": state["py"], "hunting": "player"}
	p["huntingPlayer"] = false
	if str(p.get("type", "")) == "zorro" and float(p.get("satedT", 0.0)) <= 0.0:
		var sight := float(t["perception"]) * 1.25
		var mates := stalk_victims(state, p).filter(func(o): return Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(p["x"]), float(p["y"]))) <= sight and not KarmaUtils.los_blocked(state, float(p["x"]), float(p["y"]), float(o["x"]), float(o["y"]), false, solids))
		var m: Variant = KarmaUtils.nearest_from(float(p["x"]), float(p["y"]), mates, float(t["perception"]))
		if m != null and float(p.get("restT", 0.0)) <= 0.0:
			return {"tx": (m as Dictionary)["x"], "ty": (m as Dictionary)["y"], "hunting": "mate"}
	if str(p.get("type", "")) == "lobo":
		var z: Variant = KarmaUtils.nearest_from(float(p["x"]), float(p["y"]),
			(state["agents"] as Array).filter(func(o): return str(o.get("type", "")) == "zorro" and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), float(t["perception"]))
		if z != null and float(p.get("restT", 0.0)) <= 0.0:
			return {"tx": (z as Dictionary)["x"], "ty": (z as Dictionary)["y"], "hunting": "zorro"}
	if str(p.get("type", "")) == "saponpc":
		if str(state["speciesKey"]) == "oruga" and not bool(state.get("hidden", false)) and dp < float(t["perception"]) and float(p.get("restT", 0.0)) <= 0.0:
			p["huntingPlayer"] = true
			return {"tx": state["px"], "ty": state["py"], "hunting": "player"}
	if Vector2(float(p.get("wx", p["x"])), float(p.get("wy", p["y"]))).distance_to(Vector2(float(p["x"]), float(p["y"]))) < 20.0:
		p["wx"] = rng.randf() * float(KarmaData.WORLD["w"])
		p["wy"] = rng.randf() * float(KarmaData.WORLD["h"])
	p["mode"] = "wander"
	return {"tx": p.get("wx", p["x"]), "ty": p.get("wy", p["y"]), "hunting": ""}


static func chase(p: Dictionary, t: Dictionary, hit: Dictionary, lure_on: bool, dt: float) -> void:
	var mult: float = float(KarmaData.TUNING["loboChaseMult"]) if str(p.get("type", "")) == "lobo" else float(KarmaData.TUNING["chaseMult"])
	var dd := Vector2(float(hit["tx"]), float(hit["ty"])).distance_to(Vector2(float(p["x"]), float(p["y"])))
	if dd == 0.0:
		dd = 1.0
	p["x"] = float(p["x"]) + (float(hit["tx"]) - float(p["x"])) / dd * float(p.get("speed", 100.0)) * mult * dt
	p["y"] = float(p["y"]) + (float(hit["ty"]) - float(p["y"])) / dd * float(p.get("speed", 100.0)) * mult * dt
	p["mode"] = "hunt"
	p["huntT"] = float(p.get("huntT", 0.0)) + dt
	if float(p["huntT"]) > float(KarmaData.TUNING["chaseMax"]) and not lure_on:
		p["mode"] = "wander"
		p["huntT"] = 0.0
		p["restT"] = float(KarmaData.TUNING["restTime"])


static func strike_contact(state: Dictionary, p: Dictionary, t: Dictionary, dp: float) -> void:
	if bool(state.get("hidden", false)) or dp >= float(state["sp"]["radius"]) + float(t["body"]) / 2.0 or float(state.get("invuln", 0.0)) > 0.0:
		return
	var dmg := float(t["damage"])
	if bool(state.get("bristled", false)):
		state["bristled"] = false
		p["hp"] = float(p.get("hp", 60.0)) - dmg
		state["invuln"] = float(KarmaData.TUNING["predatorInvuln"])
		KarmaState.add_log(state, null, "¡Espinas! El zarpazo se revierte")
		return
	if curled_state(state):
		dmg = ceil(dmg / 2.0)
		state["curlCd"] = float(KarmaData.TUNING["curlCd"])
	state["hp"] = float(state["hp"]) - dmg
	state["invuln"] = float(KarmaData.TUNING["predatorInvuln"])
	KarmaState.add_log(state, null, "%s te muerde (−%d vida)" % [str(t["name"]), int(dmg)])


static func feast(state: Dictionary, p: Dictionary, dead: Array) -> void:
	if str(p.get("type", "")) == "zorro" and float(p.get("satedT", 0.0)) <= 0.0:
		var m: Variant = KarmaUtils.nearest_from(float(p["x"]), float(p["y"]), stalk_victims(state, p), 16.0)
		if m != null:
			KarmaState.remove_agent(state, m)
			KarmaEat.add_carrion(state, float((m as Dictionary)["x"]), float((m as Dictionary)["y"]))
			p["satedT"] = float(KarmaData.TUNING["satedTime"])
			KarmaState.add_log(state, null, "Un zorro cazó un congénere (hay carroña fresca)")
	if str(p.get("type", "")) == "lobo":
		var z: Variant = KarmaUtils.nearest_from(float(p["x"]), float(p["y"]),
			(state["agents"] as Array).filter(func(o): return str(o.get("type", "")) == "zorro" and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 20.0)
		if z != null:
			dead.append(z)
			KarmaEat.add_carrion(state, float((z as Dictionary)["x"]), float((z as Dictionary)["y"]))
			KarmaState.add_log(state, null, "Un lobo mató un zorro (hay carroña fresca)")
