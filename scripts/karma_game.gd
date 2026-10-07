class_name KarmaGame
extends RefCounted

# Port of src/script/game.js simulation (DOM/input/render live in main.gd).

const FRUIT_CAP := {"berries": 3, "apples": 3, "carrots": 3, "mushrooms": 2, "nuts": 3}


static func draw_start_form(rng: RandomNumberGenerator) -> String:
	var keys := KarmaData.SPECIES.keys()
	return str(keys[rng.randi() % keys.size()])


static func update(state: Dictionary, dt: float, rng: RandomNumberGenerator, solids: Array = []) -> void:
	state["time"] = float(state.get("time", 0.0)) + dt
	state["paAcc"] = float(state.get("paAcc", 0.0)) + dt * float(KarmaData.TUNING["paPerSec"])
	if float(state["paAcc"]) >= 1.0:
		state["pa"] = float(state.get("pa", 0.0)) + floor(float(state["paAcc"]))
		state["paAcc"] = fmod(float(state["paAcc"]), 1.0)
	KarmaUtils.update_needs(state, KarmaState.eff_max_hp(state), dt)
	warn_needs(state)
	escort_tick(state, dt)
	for k in ["shoutCd", "strikeCd", "invuln", "lureTimer", "pounceCd", "digCd", "landT", "senseCd", "revealT", "trackT", "groomCd", "curlCd", "dietHintT", "thermalT"]:
		if float(state.get(k, 0.0)) > 0.0:
			state[k] = float(state[k]) - dt
	for i in (state["verbCds"] as Array).size():
		if float((state["verbCds"] as Array)[i]) > 0.0:
			(state["verbCds"] as Array)[i] = float((state["verbCds"] as Array)[i]) - dt
	age_world(state, dt, rng)
	groom_tick(state, dt)
	# One solids snapshot per tick shared by predators + agents + collisions.
	# Positions shift slightly mid-tick; the error is sub-pixel for 16ms.
	var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
	KarmaPredators.update_predators(state, dt, rng, list)
	update_agents(state, dt, list)
	wander_mates(state, dt, rng)
	clamp_agents(state)
	if float(state.get("hp", 1.0)) <= 0.0:
		state["hp"] = 0.0
		state["dead"] = true
		var j := KarmaShop.judge(state, rng)
		state["pendingNext"] = j["next"]
		state["pendingPool"] = j["pool"]


static func warn_needs(state: Dictionary) -> void:
	if float(state.get("hambre", 100.0)) <= float(KarmaData.TUNING["regenHambre"]) and not bool(state.get("hambreWarned", false)):
		state["hambreWarned"] = true
		KarmaState.add_log(state, null, "Hambre bajo el umbral: la vida no regenará hasta comer")
	elif float(state.get("hambre", 100.0)) > float(KarmaData.TUNING["regenHambre"]):
		state["hambreWarned"] = false
	if float(state.get("sed", 100.0)) <= float(KarmaData.TUNING["regenSed"]) and not bool(state.get("sedWarned", false)):
		state["sedWarned"] = true
		KarmaState.add_log(state, null, "Sed bajo el umbral: la vida no regenará hasta beber (E en el agua)")
	elif float(state.get("sed", 100.0)) > float(KarmaData.TUNING["regenSed"]):
		state["sedWarned"] = false


static func escort_tick(state: Dictionary, dt: float) -> void:
	if not float(state.get("escortT", 0.0)) > 0.0:
		return
	state["escortT"] = float(state["escortT"]) - dt
	var m: Variant = state.get("escortTarget", null)
	if m == null or not (state["agents"] as Array).has(m):
		state["escortT"] = 0.0
		state["escortTarget"] = null
		return
	if float(state["escortT"]) > 0.0:
		return
	state["escortTarget"] = null
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["escortKarma"]), "Escolta cumplida: tu protegido sobrevive (+karma)")


static func insect_zone_counts(state: Dictionary) -> Dictionary:
	var charco := 0
	var lago := 0
	for i in state.get("insects", []):
		var p := i as Dictionary
		for w in state.get("waters", []) as Array:
			var d := Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(float((w as Dictionary)["x"]), float((w as Dictionary)["y"])))
			if str((w as Dictionary).get("kind", "")) == "charco" and d <= float((w as Dictionary)["r"]) * 4.0:
				charco += 1
			elif str((w as Dictionary).get("kind", "")) == "lago" and d <= float((w as Dictionary)["r"]) + float(KarmaData.TUNING["lakeShore"]):
				lago += 1
	return {"charco": charco, "lago": lago}


static func seed_insect_minimums(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var charcos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
	if not charcos.is_empty():
		for i in int(KarmaData.TUNING["insectCharcoMin"]):
			var c: Dictionary = charcos[i % charcos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(c["x"]), float(c["y"]), float(c["r"]) + 8.0, float(c["r"]) * 4.0))
	var lagos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
	if not lagos.is_empty():
		for i in int(KarmaData.TUNING["insectLagoMin"]):
			var l: Dictionary = lagos[i % lagos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(l["x"]), float(l["y"]), float(l["r"]) + 8.0, float(l["r"]) + float(KarmaData.TUNING["lakeShore"])))


static func _spawn_water_ring(state: Dictionary, rng: RandomNumberGenerator, cx: float, cy: float, inner: float, outer: float) -> Dictionary:
	var ang := rng.randf() * 7.0
	var r: float = inner + rng.randf() * (outer - inner)
	var pt := {"x": clampf(cx + cos(ang) * r, 20.0, float(KarmaData.WORLD["w"]) - 20.0),
		"y": clampf(cy + sin(ang) * r, 20.0, float(KarmaData.WORLD["h"]) - 20.0)}
	return KarmaUtils.nudge_dry(state, pt)


static func spawn_insect_pt(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var lagos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
	if not lagos.is_empty() and rng.randf() < float(KarmaData.TUNING["lakeInsectBias"]):
		var l: Dictionary = lagos[rng.randi() % lagos.size()]
		return _spawn_water_ring(state, rng, float(l["x"]), float(l["y"]), float(l["r"]) + 8.0, float(l["r"]) + float(KarmaData.TUNING["lakeShore"]))
	var charcos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
	if not charcos.is_empty() and rng.randf() < float(KarmaData.TUNING["charcoInsectBias"]):
		var c: Dictionary = charcos[rng.randi() % charcos.size()]
		return _spawn_water_ring(state, rng, float(c["x"]), float(c["y"]), float(c["r"]) + 8.0, float(c["r"]) * 4.0)
	var dry := KarmaUtils.scatter_dry(state, 1, rng)
	if dry.is_empty():
		var fallback: Dictionary = KarmaUtils.scatter(1, rng)[0]
		return KarmaUtils.nudge_dry(state, fallback)
	return dry[0]


static func drop_seed(state: Dictionary, kind: String, x: float, y: float, rng: RandomNumberGenerator = null) -> void:
	var r := rng if rng != null else KarmaUtils.rng()
	if kind != "oak-tree" and r.randf() >= float(KarmaData.TUNING["seedSproutChance"]):
		return
	if (state.get("seedlings", []) as Array).size() >= int(KarmaData.TUNING["seedlingMax"]):
		return
	var ang := r.randf() * 7.0
	var rr := r.randf() * float(KarmaData.TUNING["seedScatter"])
	var pt := {"x": clampf(x + cos(ang) * rr, 20.0, float(KarmaData.WORLD["w"]) - 20.0),
		"y": clampf(y + sin(ang) * rr, 20.0, float(KarmaData.WORLD["h"]) - 20.0)}
	KarmaUtils.nudge_dry(state, pt)
	(state["seedlings"] as Array).append({"kind": kind, "x": pt["x"], "y": pt["y"], "age": 0.0})


static func mature_seedlings(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	for i in range((state["seedlings"] as Array).size() - 1, -1, -1):
		var s: Dictionary = (state["seedlings"] as Array)[i]
		s["age"] = float(s.get("age", 0.0)) + dt
		if float(s["age"]) < float(KarmaData.TUNING["seedlingMaturity"]):
			continue
		if KarmaUtils.inside_water(state, float(s["x"]), float(s["y"])):
			continue
		if str(s["kind"]) == "oak-tree":
			if (state["oaks"] as Array).size() < KarmaState.flora_cap("nuts") + int(KarmaData.TUNING["oakTreeCap"]):
				(state["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", float(s["x"]), float(s["y"]), 3))
				(state["seedlings"] as Array).remove_at(i)
			continue
		var list: Variant = state.get(str(KarmaState.FLORA_KIND.get(str(s["kind"]), "")), null)
		if list == null or (list as Array).size() >= KarmaState.flora_cap(str(s["kind"])):
			continue
		var patch := KarmaUtils.mk_patch(str(s["kind"]), float(s["x"]), float(s["y"]), int(FRUIT_CAP.get(str(s["kind"]), 1)))
		if str(s["kind"]) == "berries":
			patch["mimic"] = rng.randf() < 1.0 / 3.0
			patch["mimicEaten"] = false
		if str(s["kind"]) == "mushrooms":
			patch["toxicLeft"] = 1 if rng.randf() < 0.5 else 0
			patch["toxicEaten"] = false
		(list as Array).append(patch)
		(state["seedlings"] as Array).remove_at(i)


static func regrow_fruit(list: Array, cap: int, dt: float, rate := -1.0) -> void:
	var cycle: float = rate if rate >= 0.0 else float(KarmaData.TUNING["fruitRegrow"])
	for p in list:
		if int(p.get("amount", 0)) >= cap:
			p["regrowT"] = 0.0
			continue
		p["regrowT"] = float(p.get("regrowT", 0.0)) + dt
		if float(p["regrowT"]) >= cycle:
			p["amount"] = int(p["amount"]) + 1
			p["alive"] = true
			p["regrowT"] = 0.0


static func age_world(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	for c in state.get("carrions", []):
		c["age"] = float(c.get("age", 0.0)) + dt
	for i in range((state["refuges"] as Array).size() - 1, -1, -1):
		var r: Dictionary = (state["refuges"] as Array)[i]
		if r.get("ttl", null) != null:
			r["ttl"] = float(r["ttl"]) - dt
			if float(r["ttl"]) <= 0.0:
				(state["refuges"] as Array).remove_at(i)
	regrow_fruit(state.get("bushes", []), int(FRUIT_CAP["berries"]), dt)
	regrow_fruit(state.get("shrubs", []), int(FRUIT_CAP["apples"]), dt)
	regrow_fruit(state.get("patches", []), int(FRUIT_CAP["carrots"]), dt)
	regrow_fruit(state.get("clusters", []), int(FRUIT_CAP["mushrooms"]), dt)
	regrow_fruit(state.get("oaks", []), int(FRUIT_CAP["nuts"]), dt)
	regrow_fruit(state.get("clumps", []), 3, dt, float(KarmaData.TUNING["leafRegrow"]))
	mature_seedlings(state, dt, rng)
	for ins in state.get("insects", []):
		ins["x"] = float(ins["x"]) + (rng.randf() - 0.5) * 60.0 * dt
		ins["y"] = float(ins["y"]) + (rng.randf() - 0.5) * 60.0 * dt
	state["insectT"] = float(state.get("insectT", 0.0)) + dt
	if float(state["insectT"]) >= float(KarmaData.TUNING["insectRespawn"]):
		var zones := insect_zone_counts(state)
		var charcos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
		var lagos := (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
		if int(zones["charco"]) < int(KarmaData.TUNING["insectCharcoMin"]) and not charcos.is_empty():
			var c: Dictionary = charcos[rng.randi() % charcos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(c["x"]), float(c["y"]), float(c["r"]) + 8.0, float(c["r"]) * 4.0))
			state["insectT"] = 0.0
		elif int(zones["lago"]) < int(KarmaData.TUNING["insectLagoMin"]) and not lagos.is_empty():
			var l: Dictionary = lagos[rng.randi() % lagos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(l["x"]), float(l["y"]), float(l["r"]) + 8.0, float(l["r"]) + float(KarmaData.TUNING["lakeShore"])))
			state["insectT"] = 0.0
		elif (state["insects"] as Array).size() < int(KarmaData.TUNING["insectMax"]):
			state["insectT"] = 0.0
			(state["insects"] as Array).append(spawn_insect_pt(state, rng))
	state["mateT"] = float(state.get("mateT", 0.0)) + dt
	if float(state["mateT"]) >= float(KarmaData.TUNING["mateRespawn"]) and KarmaState.company_agents(state).size() < int(KarmaData.TUNING["mateMax"]):
		state["mateT"] = 0.0
		var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
		(state["agents"] as Array).append(KarmaState.mk_agent({"role": "company", "speciesKey": state["speciesKey"],
			"hp": float(state["sp"]["maxHp"]), "x": pt["x"], "y": pt["y"], "saved": false}))
	state["respawnT"] = float(state.get("respawnT", 0.0)) + dt
	if float(state["respawnT"]) >= float(KarmaData.TUNING["respawnTime"]):
		state["respawnT"] = 0.0
		KarmaState.respawn_missing(state, rng)


static func loco_mult(species_key: String, grounded: bool, clock: float) -> float:
	if grounded and species_key == "halcon":
		return 0.5
	var loco: Dictionary = KarmaData.LOCO.get(species_key, {})
	match str(loco.get("mode", "continuous")):
		"hop":
			var t := fmod(clock + species_key.length(), float(KarmaData.TUNING["hopImpulse"]) + float(KarmaData.TUNING["hopRest"]))
			return 1.0 if t < float(KarmaData.TUNING["hopImpulse"]) else 0.0
		"inchworm":
			var t2 := fmod(clock + species_key.length() * 2.0, float(KarmaData.TUNING["wormStretch"]) + float(KarmaData.TUNING["wormBurst"]))
			return 1.0 if t2 < float(KarmaData.TUNING["wormBurst"]) else 0.0
		"tunnel":
			return float(KarmaData.TUNING["tunnelSpeed"])
	return 1.0


static func move_player(state: Dictionary, ix: float, iy: float, dt: float, solids: Array = []) -> void:
	state["moved"] = false
	if not bool(state.get("hidden", false)):
		if ix != 0.0 or iy != 0.0:
			state["moved"] = true
			var l := Vector2(ix, iy).length()
			if l == 0.0:
				l = 1.0
			state["face"] = {"x": ix / l, "y": iy / l}
			if bool(state.get("grounded", false)):
				state["grounded"] = false
		var ll := Vector2(ix, iy).length()
		if ll == 0.0:
			ll = 1.0
		var envelope := loco_mult(str(state["speciesKey"]), bool(state.get("grounded", false)), float(state.get("time", 0.0)))
		state["px"] = clampf(float(state["px"]) + ix / ll * KarmaState.eff_speed(state) * envelope * dt, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		state["py"] = clampf(float(state["py"]) + iy / ll * KarmaState.eff_speed(state) * envelope * dt, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
		var skip_rock: bool = str(state["speciesKey"]) == "topo"
		var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
		var p := KarmaUtils.resolve_collisions(state, Vector2(float(state["px"]), float(state["py"])),
			float(state["sp"]["radius"]), skip_rock, KarmaUtils.skips_water(str(state["speciesKey"]), bool(state.get("grounded", false))), list)
		state["px"] = p.x
		state["py"] = p.y
	if not bool(state.get("moved", false)):
		state["stillT"] = float(state.get("stillT", 0.0)) + dt
	else:
		state["stillT"] = 0.0


static func wander_poi(state: Dictionary, a: Dictionary) -> Variant:
	var ax := float(a["x"])
	var ay := float(a["y"])
	var seek := float(KarmaData.TUNING["wanderSeekRange"])
	var diet: Array = KarmaData.DIET.get(str(a.get("speciesKey", "raton")), [])
	if diet.has("carrion"):
		var meal: Variant = KarmaUtils.nearest_from(ax, ay, state.get("carrions", []), seek)
		if meal != null:
			return {"x": float((meal as Dictionary)["x"]), "y": float((meal as Dictionary)["y"])}
	else:
		var bite: Variant = KarmaEat.nearest_edible_patch_for(state, a, seek)
		if diet.has("insects"):
			var bug: Variant = KarmaUtils.nearest_from(ax, ay, state.get("insects", []), seek)
			if bug != null and (bite == null or Vector2(float((bug as Dictionary)["x"]), float((bug as Dictionary)["y"])).distance_to(Vector2(ax, ay)) < Vector2(float((bite as Dictionary)["x"]), float((bite as Dictionary)["y"])).distance_to(Vector2(ax, ay))):
				bite = bug
		if bite != null:
			return {"x": float((bite as Dictionary)["x"]), "y": float((bite as Dictionary)["y"])}
	var water: Variant = KarmaUtils.nearest_water_for(state, ax, ay, seek)
	if water != null:
		return {"x": float((water as Dictionary)["x"]), "y": float((water as Dictionary)["y"])}
	var sp: Dictionary = KarmaData.SPECIES.get(str(a.get("speciesKey", "raton")), {"size": 9})
	var cover: Variant = KarmaUtils.nearest_from(ax, ay,
		(state.get("refuges", []) as Array).filter(func(r): return KarmaAI.refuge_fits_size(sp, r, str(a.get("speciesKey", "raton")))), float(KarmaData.TUNING["aiCoverRange"]))
	if cover != null:
		return {"x": float((cover as Dictionary)["x"]), "y": float((cover as Dictionary)["y"])}
	var mate: Variant = KarmaUtils.nearest_from(ax, ay,
		KarmaState.company_agents(state).filter(func(o): return o != a), seek)
	if mate != null:
		return {"x": float((mate as Dictionary)["x"]), "y": float((mate as Dictionary)["y"])}
	return null


static func move_toward(state: Dictionary, a: Dictionary, tx: float, ty: float, mult: float, dt: float) -> void:
	var d := Vector2(tx, ty).distance_to(Vector2(float(a["x"]), float(a["y"])))
	if d == 0.0:
		d = 1.0
	a["locoT"] = float(a.get("locoT", 0.0)) + dt
	var envelope := loco_mult(str(a.get("speciesKey", "raton")), bool(a.get("grounded", false)), float(a.get("locoT", 0.0)))
	var step: float = float(KarmaData.SPECIES[str(a.get("speciesKey", "raton"))]["speed"]) * mult * envelope * dt
	a["x"] = float(a["x"]) + (tx - float(a["x"])) / d * step
	a["y"] = float(a["y"]) + (ty - float(a["y"])) / d * step


static func clamp_agents(state: Dictionary) -> void:
	for a in state["agents"] as Array:
		(a as Dictionary)["x"] = clampf(float((a as Dictionary)["x"]), 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		(a as Dictionary)["y"] = clampf(float((a as Dictionary)["y"]), 20.0, float(KarmaData.WORLD["h"]) - 20.0)


static func cast_verb(state: Dictionary, slot: int) -> bool:
	var defs: Array = KarmaData.VERB_DEFS.get(str(state["speciesKey"]), [])
	if slot < 1 or slot > defs.size():
		return false
	var def: Dictionary = defs[slot - 1]
	if float((state["verbCds"] as Array)[slot - 1]) > 0.0:
		return false
	if float(state.get("pa", 0.0)) < float(def["costPa"]):
		return false
	if not call_verb(state, null, str(def["id"])):
		return false
	state["hp"] = float(state["hp"]) - float(def["costHp"])
	state["pa"] = float(state["pa"]) - float(def["costPa"])
	(state["verbCds"] as Array)[slot - 1] = float(def["cd"])
	return true


static func cast_verb_for(state: Dictionary, a: Dictionary, slot: int) -> bool:
	var defs: Array = KarmaData.VERB_DEFS.get(str(a.get("speciesKey", "")), [])
	if slot < 1 or slot > defs.size():
		return false
	var def: Dictionary = defs[slot - 1]
	if not a.has("verbCds"):
		a["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	if float((a["verbCds"] as Array)[slot - 1]) > 0.0:
		return false
	if float(a.get("pa", 0.0)) < float(def["costPa"]):
		return false
	if not call_verb(state, a, str(def["id"])):
		return false
	a["hp"] = float(a.get("hp", 0.0)) - float(def["costHp"])
	a["pa"] = float(a.get("pa", 0.0)) - float(def["costPa"])
	(a["verbCds"] as Array)[slot - 1] = float(def["cd"])
	return true


static func call_verb(state: Dictionary, a: Variant, verb_id: String) -> bool:
	match verb_id:
		"aerate":
			return KarmaEat.dig_burrow(state, a)
		"tunneline":
			return _verb_tunneline(state, a)
		"worm":
			return _verb_worm(state, a)
		"larder":
			return _verb_larder(state, a)
		"nestdig":
			return _verb_nestdig(state, a)
		"alarm":
			return KarmaState.ai_try_shout(state, a) if a != null else (KarmaState.try_shout(state) or true)
		"pest":
			return KarmaEat.eat_as_sapo(state) if a == null else _verb_pest(state, a)
		"croak":
			return KarmaState.ai_try_shout(state, a) if a != null else (KarmaState.try_shout(state) or true)
		"burrowin":
			return _verb_burrowin(state, a)
		"toxin":
			return _verb_toxin(state, a)
		"chorus":
			return _verb_chorus(state, a)
		"prudent":
			return KarmaEat.eat_as_grazer(state) if a == null else false
		"groom":
			return _verb_groom(state, a)
		"seedcache":
			return _verb_seedcache(state, a)
		"scout":
			return _verb_scout(state, a)
		"share":
			return _verb_share(state, a)
		"plantoak":
			return KarmaEat.bury_or_carry_nut(state, a) if a != null else KarmaEat.carry_action(state)
		"tailflick":
			return _verb_tailflick(state, a)
		"falsecache":
			return _verb_falsecache(state, a)
		"bark":
			return _verb_bark(state, a)
		"cede":
			return _verb_cede(state, a)
		"pounce":
			return KarmaEat.eat_as_zorro(state) if a == null else false
		"howl":
			return _verb_howl(state, a)
		"regurg":
			return _verb_regurg(state, a)
		"escort":
			return _verb_escort(state, a)
		"cull":
			return _verb_cull(state, a)
		"cachecarrion":
			return _verb_cachecarrion(state, a)
		"dendig":
			return _verb_dendig(state, a)
		"dive":
			return KarmaEat.eat_as_halcon(state) if a == null else false
		"thermal":
			return _verb_thermal(state, a)
		"courtesy":
			return _verb_courtesy(state, a)
		"scare":
			return _verb_scare(state, a)
		"bone":
			return _verb_bone(state, a)
		"strike":
			return _verb_strike(state, a)
		"silk":
			return silk_drop(state, a)
		"nectar":
			return _verb_nectar(state, a)
		"leafroll":
			return _verb_leafroll(state, a)
		"bristle":
			return _verb_bristle(state, a)
	return false


static func _verb_tunneline(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var r: Variant = KarmaUtils.nearest_from(px, py,
		(state["refuges"] as Array).filter(func(o): return bool(o.get("dug", false))), float(KarmaData.TUNING["eatRange"]))
	if r == null:
		return false
	(r as Dictionary)["firm"] = true
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["aerateKarma"]), "Túnel reforzado (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["aerateKarma"]), "Refuerzas el túnel (+karma)")
	return true


static func _verb_worm(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var r: Variant = KarmaUtils.nearest_from(px, py,
		(state["refuges"] as Array).filter(func(o): return bool(o.get("dug", false))), float(KarmaData.TUNING["eatRange"]))
	if r == null:
		return false
	var t: Dictionary = a if a != null else state
	var wh: float = float(KarmaData.TUNING["wormHp"]) + (8.0 if KarmaShop.has_adapt(t, "wormPlus") else 0.0)
	KarmaEat.heal_eater(state, a, wh)
	KarmaEat.refill_hambre(state, a, wh)
	if a != null:
		return true
	KarmaState.add_pa(state, null, float(KarmaData.TUNING["wormPa"]))
	KarmaState.add_log(state, null, "Rescatas una lombriz (+vida)")
	return true


static func _verb_larder(state: Dictionary, a: Variant) -> bool:
	var t: Dictionary = a if a != null else state
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var mates := KarmaState.company_agents(state).filter(func(o):
		return (str(o.get("speciesKey", "")) == str((a as Dictionary).get("speciesKey", "")) if a != null else true) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var hungry_mate: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	if int(t.get("larder", 0)) > 0 and hungry_mate != null:
		t["larder"] = int(t["larder"]) - 1
		(hungry_mate as Dictionary)["hp"] = minf(float(KarmaData.SPECIES[str((hungry_mate as Dictionary)["speciesKey"])]["maxHp"]), float((hungry_mate as Dictionary).get("hp", 0.0)) + float(KarmaData.TUNING["wormHp"]))
		(hungry_mate as Dictionary)["hambre"] = minf(100.0, float((hungry_mate as Dictionary).get("hambre", 100.0)) + float(KarmaData.TUNING["wormHp"]))
		if a != null:
			KarmaState.add_karma(state, a, float(KarmaData.TUNING["shareKarma"]), "Lombriz compartida (+karma)")
		else:
			KarmaState.add_karma(state, null, float(KarmaData.TUNING["shareKarma"]), "Compartes lombriz con un hambriento (+karma)")
		return true
	if int(t.get("larder", 0)) > 0 and float(t.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]):
		t["larder"] = int(t["larder"]) - 1
		KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["wormHp"]))
		KarmaEat.refill_hambre(state, a, float(KarmaData.TUNING["wormHp"]))
		return true
	var ins: Variant = KarmaUtils.nearest_from(px, py, state.get("insects", []), float(KarmaData.TUNING["eatRange"]))
	if ins == null or int(t.get("larder", 0)) > 0:
		return false
	(state["insects"] as Array).erase(ins)
	t["larder"] = 1
	return true


static func _verb_nestdig(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	if float(state.get("digCd", 0.0)) > 0.0:
		return false
	state["digCd"] = float(KarmaData.TUNING["digCd"])
	(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": state["px"], "y": state["py"], "dug": true})
	KarmaState.add_log(state, null, "Excavas un nido extra (cuesta vida)")
	return true


static func _verb_pest(state: Dictionary, a: Variant) -> bool:
	var reach := float(KarmaData.TUNING["tongueRange"]) + (40.0 if KarmaShop.has_adapt(a, "tonguePlus") else 0.0)
	var bug: Variant = KarmaUtils.nearest_from(float((a as Dictionary)["x"]), float((a as Dictionary)["y"]), state.get("insects", []), reach)
	if bug == null:
		return false
	return KarmaEat.eat_insect(state, bug, a)


static func _verb_burrowin(state: Dictionary, a: Variant) -> bool:
	if a != null:
		if bool((a as Dictionary).get("hidden", false)):
			return false
		(a as Dictionary)["hidden"] = true
		(a as Dictionary)["hideRef"] = null
		(a as Dictionary)["hideT"] = float(KarmaData.TUNING["aiHideMax"])
		return true
	if bool(state.get("hidden", false)):
		return false
	state["hidden"] = true
	state["hideRef"] = null
	KarmaState.add_log(state, null, "Te entierras en tierra blanda (H para salir)")
	return true


static func _verb_toxin(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var p: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), 60.0)
	if p == null:
		return false
	(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	var t: Dictionary = a if a != null else state
	var tk: float = float(KarmaData.TUNING["toxinKarma"]) * (2.0 if KarmaShop.has_adapt(t, "toxinPlus") else 1.0)
	if a != null:
		KarmaState.add_karma(state, a, tk, "Rocío tóxico (+karma)")
	else:
		KarmaState.add_karma(state, null, tk, "Rocío tóxico: el depredador retrocede (+karma)")
	return true


static func _verb_chorus(state: Dictionary, a: Variant) -> bool:
	var sk := str((a as Dictionary)["speciesKey"]) if a != null else str(state["speciesKey"])
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var choir := (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("speciesKey", "")) == sk and str(o.get("role", "")) in ["company", "fauna"] and Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(px, py)) <= float(KarmaData.TUNING["groomRange"])
	)
	if choir.is_empty():
		return false
	var t: Dictionary = a if a != null else state
	var k: float = float(KarmaData.TUNING["chorusKarma"]) * float(1 + choir.size()) * (2.0 if KarmaShop.has_adapt(t, "chorusPlus") else 1.0)
	KarmaState.add_karma(state, a, k, "Coro de croac con %d cantores (+%d karma)" % [1 + choir.size(), int(k)])
	return true


static func _verb_groom(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	var m: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.company_agents(state), float(KarmaData.TUNING["groomRange"]))
	if m == null:
		return false
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["groomSocialKarma"]), "Acicalas a un congénere (+karma)")
	return true


static func _verb_seedcache(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var who: Dictionary = a if a != null else {"speciesKey": state["speciesKey"], "x": px, "y": py}
	var best: Variant = KarmaEat.nearest_spare_flora_for(state, who, float(KarmaData.TUNING["eatRange"]))
	if best == null:
		return false
	(best as Dictionary)["amount"] = int((best as Dictionary)["amount"]) - 1
	drop_seed(state, str((best as Dictionary)["kind"]), px, py)
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["seedCacheKarma"]), "Cacha de semilla (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["seedCacheKarma"]), "Cachas una semilla (+karma)")
	return true


static func _verb_scout(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	state["revealT"] = float(KarmaData.TUNING["revealTime"]) * (2.0 if KarmaShop.has_adapt(state, "scoutPlus") else 1.0)
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["prudentKarma"]), "Ojeas madrigueras (+karma)")
	return true


static func _verb_share(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var sk: float = float(KarmaData.TUNING["shareKarma"]) * (2.0 if KarmaShop.has_adapt(t, "sharePlus") else 1.0)
	var mates := KarmaState.company_agents(state).filter(func(o):
		return (str(o.get("speciesKey", "")) == str((a as Dictionary).get("speciesKey", "")) if a != null else true) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var m: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	if m == null or float(t.get("hp", 0.0)) <= float(KarmaData.TUNING["shareBiteHp"]):
		return false
	t["hp"] = float(t["hp"]) - float(KarmaData.TUNING["shareBiteHp"])
	(m as Dictionary)["hp"] = minf(float(KarmaData.SPECIES[str((m as Dictionary)["speciesKey"])]["maxHp"]), float((m as Dictionary).get("hp", 0.0)) + float(KarmaData.TUNING["shareBiteHp"]))
	(m as Dictionary)["hambre"] = minf(100.0, float((m as Dictionary).get("hambre", 100.0)) + float(KarmaData.TUNING["shareBiteHp"]))
	if a != null:
		KarmaState.add_karma(state, a, sk, "Bocado compartido (+karma)")
	else:
		KarmaState.add_karma(state, null, sk, "Compartes tu bocado con un hambriento (+karma)")
	return true


static func _verb_tailflick(state: Dictionary, a: Variant) -> bool:
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["tailflickKarma"]), "Cola al aire (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["tailflickKarma"]), "Cola al aire: avisas sin exponerte (+karma)")
	for m in KarmaState.company_agents(state):
		m["saved"] = true
	return true


static func _verb_falsecache(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var p: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), 300.0 if KarmaShop.has_adapt(t, "cachePlus") else 150.0)
	if p == null:
		return false
	(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["falseCacheKarma"]), "Cacha falsa (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["falseCacheKarma"]), "Cacha falsa: el cazador pica (+karma)")
	return true


static func _verb_bark(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var who: Dictionary = a if a != null else {"speciesKey": state["speciesKey"], "x": px, "y": py}
	var oak: Variant = KarmaEat.nearest_oak_with_nuts_for(state, who, float(KarmaData.TUNING["eatRange"]))
	if oak == null:
		return false
	var bp: float = float(KarmaData.TUNING["barkPa"]) * (2.0 if KarmaShop.has_adapt(t, "barkPlus") else 1.0)
	var bk: float = float(KarmaData.TUNING["barkKarma"]) * (2.0 if KarmaShop.has_adapt(t, "barkPlus") else 1.0)
	if a != null:
		KarmaState.add_pa(state, a, bp)
		KarmaState.add_karma(state, a, bk, "Corteza cosechada (+karma)")
		return true
	KarmaState.add_pa(state, null, bp)
	KarmaState.add_karma(state, null, bk, "Cosechas corteza sin comer (+PA, +karma)")
	return true


static func _verb_cede(state: Dictionary, a: Variant) -> bool:
	if a != null:
		var w: Variant = KarmaUtils.nearest_from(float((a as Dictionary)["x"]), float((a as Dictionary)["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
		if w == null or bool((w as Dictionary).get("ceded", false)):
			return false
		(w as Dictionary)["ceded"] = true
		var ck: float = float(KarmaData.TUNING["cedeKarma"]) * (2.0 if KarmaShop.has_adapt(a, "cedePlus") else 1.0)
		KarmaState.add_karma(state, a, ck, "Cede la presa a otros (+karma)")
		return true
	var c: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	return c != null and not bool((c as Dictionary).get("ceded", false)) and KarmaEat.cede_carrion(state, c)


static func _verb_howl(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	if KarmaState.company_agents(state).is_empty():
		return false
	var ht: float = float(KarmaData.TUNING["howlTime"]) * (2.0 if KarmaShop.has_adapt(state, "howlPlus") else 1.0)
	for m in KarmaState.company_agents(state):
		m["rallyT"] = ht
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["howlKarma"]), "Aúllas: la manada se anima (+karma)")
	return true


static func _verb_regurg(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var mates := KarmaState.company_agents(state).filter(func(o):
		return (str(o.get("speciesKey", "")) == str((a as Dictionary).get("speciesKey", "")) if a != null else true) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var m: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	var cost := float(KarmaData.TUNING["regurgCost"])
	if m == null or float(t.get("hp", 0.0)) <= cost:
		return false
	t["hp"] = float(t["hp"]) - cost
	(m as Dictionary)["hp"] = minf(float(KarmaData.SPECIES[str((m as Dictionary)["speciesKey"])]["maxHp"]), float((m as Dictionary).get("hp", 0.0)) + cost)
	(m as Dictionary)["hambre"] = minf(100.0, float((m as Dictionary).get("hambre", 100.0)) + cost)
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["regurgKarma"]), "Regurgito (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["regurgKarma"]), "Regurgitas para un hambriento (+karma)")
	return true


static func _verb_escort(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	var threatened: Variant = null
	for m in KarmaState.company_agents(state):
		for o in state["agents"]:
			if str(o.get("role", "")) == "hunter" and Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(m["x"]), float(m["y"]))) <= 150.0:
				threatened = m
				break
		if threatened != null:
			break
	if threatened == null:
		return false
	var d := Vector2(float((threatened as Dictionary)["x"]), float((threatened as Dictionary)["y"])).distance_to(Vector2(float(state["px"]), float(state["py"])))
	if d == 0.0:
		d = 1.0
	var step: float = minf(50.0, d)
	state["px"] = clampf(float(state["px"]) + (float((threatened as Dictionary)["x"]) - float(state["px"])) / d * step, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	state["py"] = clampf(float(state["py"]) + (float((threatened as Dictionary)["y"]) - float(state["py"])) / d * step, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	state["escortT"] = float(KarmaData.TUNING["escortTime"])
	state["escortTarget"] = threatened
	KarmaState.add_log(state, null, "Escoltas a un congénere amenazado (sobrevive y hay karma)")
	return true


static func _verb_cull(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	var sick: Variant = null
	var sick_frac := 2.0
	for o in state["agents"]:
		if str(o.get("role", "")) != "fauna":
			continue
		if not KarmaPredators.edible_agent_for(state, "lobo", o, 1e9):
			continue
		if Vector2(float(o["x"]), float(o["y"])).distance_to(Vector2(float(state["px"]), float(state["py"]))) > float(KarmaData.TUNING["pounceRange"]):
			continue
		var frac: float = float(o.get("hp", 0.0)) / float(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["maxHp"])
		if frac < sick_frac:
			sick_frac = frac
			sick = o
	if sick == null:
		return false
	var weak: bool = sick_frac < (0.5 if KarmaShop.has_adapt(state, "cullPlus") else 0.3)
	if not KarmaEat.pounce_kill(state, sick, null):
		return false
	if weak:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["cullKarma"]), "Caza al débil, selección natural (+karma)")
	return true


static func _verb_cachecarrion(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	if int(state.get("stash", 0)) > 0:
		return false
	var c: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]),
		(state.get("carrions", []) as Array).filter(func(k): return KarmaEat.carrion_stage(k) != "rotten"), float(KarmaData.TUNING["eatRange"]))
	if c == null:
		return false
	(state["carrions"] as Array).erase(c)
	state["stash"] = 1
	KarmaState.add_log(state, null, "Entierras carroña para después (+PA en la próxima)")
	return true


static func _verb_dendig(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": state["px"], "y": state["py"], "dug": true})
	KarmaState.add_log(state, null, "Excavas una guarida (cuesta vida)")
	return true


static func _verb_thermal(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	if float(state.get("thermalT", 0.0)) > 0.0:
		return false
	state["thermalT"] = float(KarmaData.TUNING["thermalTime"]) * (2.0 if KarmaShop.has_adapt(state, "thermalPlus") else 1.0)
	KarmaState.add_log(state, null, "Térmica: ojo de águila (visión extra unos segundos)")
	return true


static func _verb_courtesy(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	var c: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]),
		(state.get("carrions", []) as Array).filter(func(k): return KarmaEat.carrion_stage(k) == "fresh"), float(KarmaData.TUNING["eatRange"]))
	if c == null or bool((c as Dictionary).get("ceded", false)):
		return false
	(c as Dictionary)["ceded"] = true
	KarmaState.add_karma(state, null, float(KarmaData.TUNING["cedeKarma"]), "Carroña compartida (+karma, la dejas)")
	return true


static func _verb_scare(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var v: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return o != a and str(o.get("role", "")) == "fauna" and int(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["size"]) <= 2), 90.0)
	if v == null:
		return false
	var d := Vector2(float((v as Dictionary)["x"]), float((v as Dictionary)["y"])).distance_to(Vector2(px, py))
	if d == 0.0:
		d = 1.0
	(v as Dictionary)["x"] = clampf(float((v as Dictionary)["x"]) + (float((v as Dictionary)["x"]) - px) / d * 60.0, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	(v as Dictionary)["y"] = clampf(float((v as Dictionary)["y"]) + (float((v as Dictionary)["y"]) - py) / d * 60.0, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	var k: float = float(KarmaData.TUNING["scareKarma"]) * (2.0 if KarmaShop.has_adapt(t, "scarePlus") else 1.0)
	KarmaState.add_karma(state, a, k, "Ahuyentas sin matar (+karma)")
	return true


static func _verb_bone(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	KarmaEat.add_carrion(state, px, py)
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["boneKarma"]), "Hueso suelto (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["boneKarma"]), "Sueltas un hueso (+karma, carroña fresca)")
	return true


static func _verb_strike(state: Dictionary, a: Variant) -> bool:
	if a != null:
		var p: Variant = KarmaUtils.nearest_from(float((a as Dictionary)["x"]), float((a as Dictionary)["y"]),
			(state["agents"] as Array).filter(func(o): return o != a and (str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter")), 60.0)
		if p == null or float((a as Dictionary).get("strikeCd", 0.0)) > 0.0:
			return false
		KarmaAI.ai_strike(state, a, p)
		return true
	var q: Variant = KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.all_hunters(state), 60.0)
	if q == null or float(state.get("strikeCd", 0.0)) > 0.0:
		return false
	return KarmaEat.strike_predator(state, q, null)


static func silk_drop(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var h: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter" or str(o.get("kind", "")) == "hunter"), 150.0)
	if h == null:
		return false
	var d := Vector2(px, py).distance_to(Vector2(float((h as Dictionary)["x"]), float((h as Dictionary)["y"])))
	if d == 0.0:
		d = 1.0
	var dist := 80.0 if KarmaShop.has_adapt(t, "silkPlus") else 40.0
	var nx := clampf(px + (px - float((h as Dictionary)["x"])) / d * dist, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	var ny := clampf(py + (py - float((h as Dictionary)["y"])) / d * dist, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	if a != null:
		(a as Dictionary)["x"] = nx
		(a as Dictionary)["y"] = ny
		return true
	state["px"] = nx
	state["py"] = ny
	return true


static func _verb_nectar(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var p: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return str(o.get("role", "")) == "hunter"), 150.0)
	if p == null:
		return false
	if (state["insects"] as Array).size() < int(KarmaData.TUNING["insectMax"]):
		(state["insects"] as Array).append({"x": px, "y": py})
	(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["nectarKarma"]), "Néctar para hormigas (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["nectarKarma"]), "Néctar para hormigas: una aliada distrae (+karma)")
	return true


static func _verb_leafroll(state: Dictionary, a: Variant) -> bool:
	var px := float((a as Dictionary)["x"]) if a != null else float(state["px"])
	var py := float((a as Dictionary)["y"]) if a != null else float(state["py"])
	var t: Dictionary = a if a != null else state
	var clump: Variant = KarmaUtils.nearest_from(px, py, state.get("clumps", []), float(KarmaData.TUNING["eatRange"]))
	if clump == null:
		return false
	(state["refuges"] as Array).append({"type": "leafroll", "maxSize": 1, "orugaOnly": true, "x": px, "y": py, "dug": false,
		"ttl": float(KarmaData.TUNING["leafrollTtl"]) * (2.0 if KarmaShop.has_adapt(t, "leafrollPlus") else 1.0)})
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["leafrollKarma"]), "Hoja enrollada (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["leafrollKarma"]), "Enrollas una hoja (+karma)")
	return true


static func _verb_bristle(state: Dictionary, a: Variant) -> bool:
	if a != null:
		return false
	state["bristled"] = true
	KarmaState.add_log(state, null, "Erizas espinas (el próximo zarpazo se revierte)")
	return true


static func groom_tick(state: Dictionary, dt: float) -> void:
	if str(state["speciesKey"]) == "raton" and float(state.get("groomCd", 0.0)) <= 0.0:
		if KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), KarmaState.company_agents(state), float(KarmaData.TUNING["groomRange"])) != null:
			state["groomT"] = float(state.get("groomT", 0.0)) + dt
			if float(state["groomT"]) >= float(KarmaData.TUNING["groomTime"]):
				state["groomT"] = 0.0
				state["groomCd"] = float(KarmaData.TUNING["groomCd"])
				KarmaState.add_karma(state, null, float(KarmaData.TUNING["groomKarma"]), "Acicalas a un congénere (+karma)")
		else:
			state["groomT"] = 0.0
	else:
		state["groomT"] = 0.0


static func update_agents(state: Dictionary, dt: float, solids: Array = []) -> void:
	var dead: Array = []
	var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
	for a in (state["agents"] as Array).duplicate():
		KarmaAI.ai_step(state, a, dt)
		if float(a.get("hp", 1.0)) > 0.0:
			var p := KarmaUtils.resolve_collisions(state, Vector2(float(a["x"]), float(a["y"])),
				float(KarmaData.SPECIES[str(a.get("speciesKey", "raton"))]["radius"]),
				str(a.get("speciesKey", "")) == "topo",
				KarmaUtils.skips_water(str(a.get("speciesKey", "")), bool(a.get("grounded", false))), list)
			a["x"] = p.x
			a["y"] = p.y
		if float(a.get("hp", 1.0)) <= 0.0:
			dead.append(a)
	for a in dead:
		KarmaState.remove_agent(state, a)
		KarmaEat.add_carrion(state, float(a["x"]), float(a["y"]))


static func wander_mates(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	for m in KarmaState.company_agents(state):
		if float(m.get("rallyT", 0.0)) > 0.0:
			m["rallyT"] = float(m["rallyT"]) - dt
		var boost := 1.5 if float(m.get("rallyT", 0.0)) > 0.0 else 1.0
		var pred: Variant = KarmaUtils.nearest_from(float(m["x"]), float(m["y"]), KarmaState.all_hunters(state), 999.0)
		if bool(m.get("saved", false)) and pred != null:
			var d := Vector2(float(m["x"]), float(m["y"])).distance_to(Vector2(float((pred as Dictionary)["x"]), float((pred as Dictionary)["y"])))
			if d == 0.0:
				d = 1.0
			m["x"] = float(m["x"]) + (float(m["x"]) - float((pred as Dictionary)["x"])) / d * 90.0 * boost * dt
			m["y"] = float(m["y"]) + (float(m["y"]) - float((pred as Dictionary)["y"])) / d * 90.0 * boost * dt
		else:
			var pd := Vector2(float(state["px"]), float(state["py"])).distance_to(Vector2(float(m["x"]), float(m["y"])))
			if pd > float(KarmaData.TUNING["groomRange"]):
				KarmaGame.move_toward(state, m, float(state["px"]), float(state["py"]), boost, dt)
			else:
				var poi: Variant = KarmaGame.wander_poi(state, m)
				if poi != null:
					KarmaGame.move_toward(state, m, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), boost, dt)
				else:
					m["x"] = float(m["x"]) + (rng.randf() - 0.5) * 40.0 * boost * dt
					m["y"] = float(m["y"]) + (rng.randf() - 0.5) * 40.0 * boost * dt
