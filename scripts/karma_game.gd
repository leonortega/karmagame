class_name KarmaGame
extends RefCounted

# Port of src/script/game.js simulation (DOM/input/render live in main.gd).

const FRUIT_CAP := {"berries": 3, "apples": 2, "carrots": 3, "mushrooms": 2, "nuts": 3}


static func draw_start_form(rng: RandomNumberGenerator) -> String:
	var keys: Array = KarmaData.SPECIES.keys()
	return str(keys[rng.randi() % keys.size()])


static func update(state: Dictionary, dt: float, rng: RandomNumberGenerator, solids: Array = []) -> void:
	state["time"] = float(state.get("time", 0.0)) + dt
	state["paAcc"] = float(state.get("paAcc", 0.0)) + dt * float(KarmaData.TUNING["paPerSec"])
	if float(state["paAcc"]) >= 1.0:
		state["pa"] = float(state.get("pa", 0.0)) + floor(float(state["paAcc"]))
		state["paAcc"] = fmod(float(state["paAcc"]), 1.0)
	warn_needs(state)
	escort_tick(state, dt)
	var _pp: Variant = KarmaState.player(state)
	if _pp != null:
		KarmaUtils.tick_cooldowns(_pp, ["shoutCd", "strikeCd", "invuln", "lureTimer", "pounceCd", "digCd", "landT", "senseCd", "revealT", "trackT", "groomCd", "curlCd", "dietHintT", "thermalT"], dt)
		KarmaUtils.tick_verb_cds(_pp, dt)
	age_world(state, dt, rng)
	groom_tick(state, dt)
	# One solids snapshot per tick shared by agents + collisions.
	# Positions shift slightly mid-tick; the error is sub-pixel for 16ms.
	var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
	update_agents(state, dt, list)
	wander_mates(state, dt, rng)
	clamp_agents(state)
	if float(KarmaState.player(state).get("hp", 1.0)) <= 0.0:
		KarmaState.player(state)["hp"] = 0.0
		state["dead"] = true
		var j: Dictionary = KarmaShop.judge(state, rng)
		state["pendingNext"] = j["next"]
		state["pendingPool"] = j["pool"]
		state["judgeReason"] = j["reason"]
		if KarmaData.is_natural_death(str(state["speciesKey"]), float(KarmaState.player(state).get("edad", 0.0))):
			state["judgeReason"] = "Vejez: el cuerpo cede, pero el karma decide tu próxima forma. " + str(j["reason"])
		state["shopOpen"] = false
		state["paused"] = false


static func warn_needs(state: Dictionary) -> void:
	if float(KarmaState.player(state).get("hambre", 100.0)) <= float(KarmaData.TUNING["regenHambre"]) and not bool(state.get("hambreWarned", false)):
		state["hambreWarned"] = true
		KarmaState.add_log(state, null, "Hambre bajo el umbral: la vida no regenará hasta comer")
	elif float(KarmaState.player(state).get("hambre", 100.0)) > float(KarmaData.TUNING["regenHambre"]):
		state["hambreWarned"] = false
	if float(KarmaState.player(state).get("sed", 100.0)) <= float(KarmaData.TUNING["regenSed"]) and not bool(state.get("sedWarned", false)):
		state["sedWarned"] = true
		KarmaState.add_log(state, null, "Sed bajo el umbral: la vida no regenará hasta beber (E en el agua)")
	elif float(KarmaState.player(state).get("sed", 100.0)) > float(KarmaData.TUNING["regenSed"]):
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
	var charco: int = 0
	var lago: int = 0
	for i in state.get("insects", []):
		var p: Dictionary = i as Dictionary
		for w in state.get("waters", []) as Array:
			var d: float = Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(float((w as Dictionary)["x"]), float((w as Dictionary)["y"])))
			if str((w as Dictionary).get("kind", "")) == "charco" and d <= float((w as Dictionary)["r"]) * 4.0:
				charco += 1
			elif str((w as Dictionary).get("kind", "")) == "lago" and d <= float((w as Dictionary)["r"]) + float(KarmaData.TUNING["lakeShore"]):
				lago += 1
	return {"charco": charco, "lago": lago}


static func seed_insect_minimums(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var charcos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
	if not charcos.is_empty():
		for i in int(KarmaData.TUNING["insectCharcoMin"]):
			var c: Dictionary = charcos[i % charcos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(c["x"]), float(c["y"]), float(c["r"]) + 8.0, float(c["r"]) * 4.0))
	var lagos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
	if not lagos.is_empty():
		for i in int(KarmaData.TUNING["insectLagoMin"]):
			var l: Dictionary = lagos[i % lagos.size()]
			(state["insects"] as Array).append(_spawn_water_ring(state, rng, float(l["x"]), float(l["y"]), float(l["r"]) + 8.0, float(l["r"]) + float(KarmaData.TUNING["lakeShore"])))


static func _spawn_water_ring(state: Dictionary, rng: RandomNumberGenerator, cx: float, cy: float, inner: float, outer: float) -> Dictionary:
	var ang: float = rng.randf() * 7.0
	var r: float = inner + rng.randf() * (outer - inner)
	var pt: Dictionary = {"x": clampf(cx + cos(ang) * r, 20.0, float(KarmaData.WORLD["w"]) - 20.0),
		"y": clampf(cy + sin(ang) * r, 20.0, float(KarmaData.WORLD["h"]) - 20.0)}
	return KarmaUtils.nudge_dry(state, pt)


static func spawn_insect_pt(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var lagos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
	if not lagos.is_empty() and rng.randf() < float(KarmaData.TUNING["lakeInsectBias"]):
		var l: Dictionary = lagos[rng.randi() % lagos.size()]
		return _spawn_water_ring(state, rng, float(l["x"]), float(l["y"]), float(l["r"]) + 8.0, float(l["r"]) + float(KarmaData.TUNING["lakeShore"]))
	var charcos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
	if not charcos.is_empty() and rng.randf() < float(KarmaData.TUNING["charcoInsectBias"]):
		var c: Dictionary = charcos[rng.randi() % charcos.size()]
		return _spawn_water_ring(state, rng, float(c["x"]), float(c["y"]), float(c["r"]) + 8.0, float(c["r"]) * 4.0)
	var dry: Array = KarmaUtils.scatter_dry(state, 1, rng)
	if dry.is_empty():
		var fallback: Dictionary = KarmaUtils.scatter(1, rng)[0]
		return KarmaUtils.nudge_dry(state, fallback)
	return dry[0]


static func drop_seed(state: Dictionary, kind: String, x: float, y: float, rng: RandomNumberGenerator = null) -> void:
	var r: RandomNumberGenerator = rng if rng != null else KarmaUtils.rng()
	if kind != "oak-tree" and r.randf() >= float(KarmaData.TUNING["seedSproutChance"]):
		return
	if (state.get("seedlings", []) as Array).size() >= int(KarmaData.TUNING["seedlingMax"]):
		return
	var ang: float = r.randf() * 7.0
	var rr: float = r.randf() * float(KarmaData.TUNING["seedScatter"])
	var pt: Dictionary = {"x": clampf(x + cos(ang) * rr, 20.0, float(KarmaData.WORLD["w"]) - 20.0),
		"y": clampf(y + sin(ang) * rr, 20.0, float(KarmaData.WORLD["h"]) - 20.0)}
	KarmaUtils.nudge_dry(state, pt)
	(state["seedlings"] as Array).append({"kind": kind, "x": pt["x"], "y": pt["y"], "age": 0.0})


static func mature_seedlings(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	for i in range((state["seedlings"] as Array).size() - 1, -1, -1):
		var s: Dictionary = (state["seedlings"] as Array)[i]
		s["age"] = float(s.get("age", 0.0)) + dt
		if float(s["age"]) < seedling_maturity_for(str(s.get("kind", ""))):
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
		var patch: Dictionary = KarmaUtils.mk_patch(str(s["kind"]), float(s["x"]), float(s["y"]), int(FRUIT_CAP.get(str(s["kind"]), 1)))
		if str(s["kind"]) == "berries":
			patch["mimic"] = rng.randf() < 1.0 / 3.0
			patch["mimicEaten"] = false
		if str(s["kind"]) == "mushrooms":
			patch["toxicLeft"] = 1 if rng.randf() < 0.5 else 0
			patch["toxicEaten"] = false
		(list as Array).append(patch)
		(state["seedlings"] as Array).remove_at(i)


static func regrow_rate_for(kind: String) -> float:
	var table: Dictionary = KarmaData.TUNING.get("fruitRegrowByKind", {})
	return float(table.get(kind, 45.0))


static func seedling_maturity_for(kind: String) -> float:
	var key: String = "nuts" if kind == "oak-tree" else kind
	return regrow_rate_for(key) * float(KarmaData.TUNING.get("seedlingMult", 2.0))


static func regrow_fruit(list: Array, cap: int, dt: float) -> void:
	for p in list:
		var cycle: float = regrow_rate_for(str(p.get("kind", "")))
		if int(p.get("amount", 0)) >= cap:
			p["regrowT"] = 0.0
			continue
		p["regrowT"] = float(p.get("regrowT", 0.0)) + dt
		if float(p["regrowT"]) >= cycle:
			p["amount"] = int(p["amount"]) + 1
			p["alive"] = true
			p["regrowT"] = 0.0


static func weather_tick(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	var w: Dictionary = state["weather"]
	w["t"] = float(w.get("t", 0.0)) - dt
	if float(w["t"]) > 0.0:
		return
	if bool(w.get("raining", false)):
		w["raining"] = false
		w["t"] = rng.randf_range(float(KarmaData.TUNING["rainDryMin"]), float(KarmaData.TUNING["rainDryMax"]))
		KarmaState.add_log(state, null, "Escampa: el cielo se despeja")
		return
	w["raining"] = true
	w["t"] = rng.randf_range(float(KarmaData.TUNING["rainWetMin"]), float(KarmaData.TUNING["rainWetMax"]))
	KarmaState.add_log(state, null, "Empieza a llover: los charcos y lagos se recargan")
	rain_insect_burst(state, rng)


static func rain_insect_burst(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var ceiling: int = int(KarmaData.TUNING["insectMax"]) + int(KarmaData.TUNING["rainInsectBurst"])
	var room: int = ceiling - (state.get("insects", []) as Array).size()
	var n: int = mini(int(KarmaData.TUNING["rainInsectBurst"]), maxi(0, room))
	for i in n:
		(state["insects"] as Array).append(spawn_insect_pt(state, rng))


static func rain_refill(state: Dictionary, dt: float) -> void:
	for w in state.get("waters", []):
		var cap: float = float(w.get("cap", 0.0))
		if cap <= 0.0:
			continue
		w["level"] = minf(cap, float(w.get("level", 0.0)) + cap / float(KarmaData.TUNING["rainFillTime"]) * dt)


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
	regrow_fruit(state.get("clumps", []), 3, dt)
	mature_seedlings(state, dt, rng)
	for ins in state.get("insects", []):
		ins["x"] = float(ins["x"]) + (rng.randf() - 0.5) * 60.0 * dt
		ins["y"] = float(ins["y"]) + (rng.randf() - 0.5) * 60.0 * dt
	state["insectT"] = float(state.get("insectT", 0.0)) + dt
	if float(state["insectT"]) >= float(KarmaData.TUNING["insectRespawn"]):
		var zones: Dictionary = insect_zone_counts(state)
		var charcos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "charco")
		var lagos: Array = (state.get("waters", []) as Array).filter(func(w): return str(w.get("kind", "")) == "lago")
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
		(state["agents"] as Array).append(KarmaState.mk_agent({"brain": "AI", "speciesKey": state["speciesKey"], "hp": float(state["sp"]["maxHp"]), "x": pt["x"], "y": pt["y"], "saved": false}))
	state["respawnT"] = float(state.get("respawnT", 0.0)) + dt
	if float(state["respawnT"]) >= float(KarmaData.TUNING["respawnTime"]):
		state["respawnT"] = 0.0
		KarmaState.respawn_missing(state, rng)
	weather_tick(state, dt, rng)
	if bool((state["weather"] as Dictionary).get("raining", false)):
		rain_refill(state, dt)


static func loco_mult(species_key: String, grounded: bool, clock: float) -> float:
	if grounded and species_key == "halcon":
		return 0.5
	var loco: Dictionary = KarmaData.LOCO.get(species_key, {})
	match str(loco.get("mode", "continuous")):
		"hop":
			var t: float = fmod(clock + species_key.length(), float(KarmaData.TUNING["hopImpulse"]) + float(KarmaData.TUNING["hopRest"]))
			return 1.0 if t < float(KarmaData.TUNING["hopImpulse"]) else 0.0
		"inchworm":
			var t2: float = fmod(clock + species_key.length() * 2.0, float(KarmaData.TUNING["wormStretch"]) + float(KarmaData.TUNING["wormBurst"]))
			return 1.0 if t2 < float(KarmaData.TUNING["wormBurst"]) else 0.0
		"tunnel":
			return float(KarmaData.TUNING["tunnelSpeed"])
	return 1.0


static func move_player(state: Dictionary, ix: float, iy: float, dt: float, solids: Array = []) -> void:
	KarmaState.player(state)["moved"] = false
	if not bool(KarmaState.player(state).get("hidden", false)):
		var ll: float = Vector2(ix, iy).length()
		if ll == 0.0:
			ll = 1.0
		if ix != 0.0 or iy != 0.0:
			KarmaState.player(state)["moved"] = true
			KarmaState.player(state)["face"] = {"x": ix / ll, "y": iy / ll}
			if bool(KarmaState.player(state).get("grounded", false)):
				KarmaState.player(state)["grounded"] = false
		var envelope: float = loco_mult(str(state["speciesKey"]), bool(KarmaState.player(state).get("grounded", false)), float(state.get("time", 0.0)))
		var speed: float = KarmaState.eff_speed(state)
		KarmaState.player(state)["x"] = clampf(float(KarmaState.px(state)) + ix / ll * speed * envelope * dt, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		KarmaState.player(state)["y"] = clampf(float(KarmaState.py(state)) + iy / ll * speed * envelope * dt, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
		var skip_rock: bool = str(state["speciesKey"]) == "topo"
		var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
		var p: Vector2 = KarmaUtils.resolve_collisions(state, Vector2(float(KarmaState.px(state)), float(KarmaState.py(state))),
			float(state["sp"]["radius"]), skip_rock, KarmaUtils.skips_water(str(state["speciesKey"]), bool(KarmaState.player(state).get("grounded", false))), list)
		KarmaState.player(state)["x"] = p.x
		KarmaState.player(state)["y"] = p.y
	if not bool(KarmaState.player(state).get("moved", false)):
		KarmaState.player(state)["stillT"] = float(KarmaState.player(state).get("stillT", 0.0)) + dt
	else:
		KarmaState.player(state)["stillT"] = 0.0


static func wander_poi(state: Dictionary, a: Dictionary) -> Variant:
	var ax: float = float(a["x"])
	var ay: float = float(a["y"])
	var seek: float = float(KarmaData.TUNING["wanderSeekRange"])
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
	var d: float = Vector2(tx, ty).distance_to(Vector2(float(a["x"]), float(a["y"])))
	if d == 0.0:
		d = 1.0
	a["locoT"] = float(a.get("locoT", 0.0)) + dt
	var envelope: float = loco_mult(str(a.get("speciesKey", "raton")), bool(a.get("grounded", false)), float(a.get("locoT", 0.0)))
	var base: float = KarmaData.aged_speed(str(a.get("speciesKey", "raton")), float(KarmaData.SPECIES[str(a.get("speciesKey", "raton"))]["speed"]), float(a.get("edad", 0.0)))
	var step: float = base * mult * envelope * dt
	a["x"] = float(a["x"]) + (tx - float(a["x"])) / d * step
	a["y"] = float(a["y"]) + (ty - float(a["y"])) / d * step


static func clamp_agents(state: Dictionary) -> void:
	for a in state["agents"] as Array:
		(a as Dictionary)["x"] = clampf(float((a as Dictionary)["x"]), 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		(a as Dictionary)["y"] = clampf(float((a as Dictionary)["y"]), 20.0, float(KarmaData.WORLD["h"]) - 20.0)


static func cast_verb(state: Dictionary, slot: int) -> bool:
	return _cast_verb_core(state, null, slot)


static func cast_verb_for(state: Dictionary, a: Dictionary, slot: int) -> bool:
	return _cast_verb_core(state, a, slot)


# Shared verb gate for the player (actor null) and agents: slot bounds, cooldown,
# PA cost, verb effect, then HP/PA spend and cooldown start.
static func _cast_verb_core(state: Dictionary, actor: Variant, slot: int) -> bool:
	var t: Dictionary = KarmaState.body_actor(state, actor) as Dictionary
	var defs: Array = KarmaData.VERB_DEFS.get(str(t.get("speciesKey", "")), [])
	if slot < 1 or slot > defs.size():
		return false
	var def: Dictionary = defs[slot - 1]
	if not t.has("verbCds"):
		t["verbCds"] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var cds: Array = t["verbCds"]
	if float(cds[slot - 1]) > 0.0:
		return false
	if float(t.get("pa", 0.0)) < float(def["costPa"]):
		return false
	if not call_verb(state, actor, str(def["id"])):
		return false
	t["hp"] = float(t.get("hp", 0.0)) - float(def["costHp"])
	t["pa"] = float(t.get("pa", 0.0)) - float(def["costPa"])
	cds[slot - 1] = float(def["cd"])
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
			return KarmaEat.eat_as_grazer(state) if a == null else _verb_prudent(state, a)
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
			return KarmaEat.eat_as_zorro(state) if a == null else _verb_pounce(state, a)
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
			return KarmaEat.eat_as_halcon(state) if a == null else _verb_dive(state, a)
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
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var er2: float = float(KarmaData.TUNING["eatRange"]) * float(KarmaData.TUNING["eatRange"])
	var first: Variant = null
	var second: Variant = null
	var fd2: float = INF
	var sd2: float = INF
	for o: Variant in state["refuges"] as Array:
		if not bool(o.get("dug", false)):
			continue
		var dx: float = float((o as Dictionary)["x"]) - px
		var dy: float = float((o as Dictionary)["y"]) - py
		var d2: float = dx * dx + dy * dy
		if d2 > er2:
			continue
		if d2 < fd2:
			second = first
			sd2 = fd2
			first = o
			fd2 = d2
		elif d2 < sd2:
			second = o
			sd2 = d2
	if second == null:
		return false
	var net: String = "net-%d" % int(float(state.get("time", 0.0)) * 10.0)
	(first as Dictionary)["net"] = net
	(second as Dictionary)["net"] = net
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["aerateKarma"]), "Túnel reforzado (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["aerateKarma"]), "Refuerzas el túnel (+karma)")
	return true


static func _verb_worm(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var r: Variant = KarmaUtils.nearest_from(px, py,
		(state["refuges"] as Array).filter(func(o): return bool(o.get("dug", false))), float(KarmaData.TUNING["eatRange"]))
	if r == null or int((r as Dictionary).get("charge", 1)) <= 0:
		return false
	if (state["insects"] as Array).size() >= int(KarmaData.TUNING["insectMax"]):
		return false
	(r as Dictionary)["charge"] = int((r as Dictionary).get("charge", 1)) - 1
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var fat: bool = KarmaShop.has_adapt(t, "wormPlus")
	(state["insects"] as Array).append({"x": float((r as Dictionary)["x"]), "y": float((r as Dictionary)["y"]), "fat": fat})
	if a != null:
		KarmaState.add_log(state, a, "Remueves la tierra (hay lombriz)")
		return true
	KarmaState.add_pa(state, null, float(KarmaData.TUNING["wormPa"]))
	KarmaState.add_log(state, null, "Remueves la tierra (hay lombriz)")
	return true


static func _verb_larder(state: Dictionary, a: Variant) -> bool:
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var mates: Array = KarmaState.company_agents(state).filter(func(o):
		return (str(o.get("speciesKey", "")) == str((a as Dictionary).get("speciesKey", "")) if a != null else true) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var hungry_mate: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	if int(t.get("larder", 0)) > 0 and hungry_mate != null:
		t["larder"] = int(t["larder"]) - 1
		KarmaEat.heal_eater(state, hungry_mate, float(KarmaData.TUNING["wormHp"]))
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
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	if float(t.get("digCd", 0.0)) > 0.0:
		return false
	t["digCd"] = KarmaData.aged_time(t, float(KarmaData.TUNING["digCd"]))
	(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": px, "y": py, "dug": true, "charge": 1})
	KarmaState.add_log(state, a, "Excavas un nido extra (cuesta vida)")
	return true


static func _verb_pest(state: Dictionary, a: Variant) -> bool:
	var reach: float = float(KarmaData.TUNING["tongueRange"]) + (40.0 if KarmaShop.has_adapt(a, "tonguePlus") else 0.0)
	var bug: Variant = KarmaUtils.nearest_from(float((a as Dictionary)["x"]), float((a as Dictionary)["y"]), state.get("insects", []), reach)
	if bug == null:
		return false
	return KarmaEat.eat_insect(state, bug, a)


static func _verb_burrowin(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	if a != null:
		if bool((a as Dictionary).get("hidden", false)):
			return false
		(a as Dictionary)["hidden"] = true
		(a as Dictionary)["hideRef"] = null
		(a as Dictionary)["hideT"] = float(KarmaData.TUNING["aiHideMax"])
	else:
		if bool(KarmaState.player(state).get("hidden", false)):
			return false
		KarmaState.player(state)["hidden"] = true
		KarmaState.player(state)["hideRef"] = null
	# The pit stays behind: mud to sip, hard ground for hunters to cross.
	(state["refuges"] as Array).append({"type": "wallow", "maxSize": 0, "x": px, "y": py, "dug": false,
		"ttl": float(KarmaData.TUNING["leafrollTtl"])})
	if a == null:
		KarmaState.player(state)["sed"] = minf(100.0, float(KarmaState.player(state).get("sed", 100.0)) + float(KarmaData.TUNING["sipSed"]))
	var groom_range: float = float(KarmaData.TUNING["groomRange"])
	for o in KarmaState.company_agents(state) + (state["agents"] as Array).filter(func(x): return str(x.get("speciesKey", "")) == "sapo"):
		if KarmaUtils.dist2(float((o as Dictionary)["x"]), float((o as Dictionary)["y"]), px, py) <= groom_range * groom_range:
			(o as Dictionary)["sed"] = minf(100.0, float((o as Dictionary).get("sed", 100.0)) + float(KarmaData.TUNING["sipSed"]))
	if a == null:
		KarmaState.add_log(state, null, "Te entierras en tierra blanda (H para salir)")
	return true


static func _verb_toxin(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var p: Variant = KarmaState.nearest_hunter(px, py, state, 60.0)
	if p == null:
		return false
	(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var tk: float = float(KarmaData.TUNING["toxinKarma"]) * (2.0 if KarmaShop.has_adapt(t, "toxinPlus") else 1.0)
	if a != null:
		KarmaState.add_karma(state, a, tk, "Rocío tóxico (+karma)")
	else:
		KarmaState.add_karma(state, null, tk, "Rocío tóxico: el depredador retrocede (+karma)")
	return true


static func _verb_chorus(state: Dictionary, a: Variant) -> bool:
	var sk: String = str((a as Dictionary)["speciesKey"]) if a != null else str(state["speciesKey"])
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var groom_range: float = float(KarmaData.TUNING["groomRange"])
	var choir: Array = (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) == sk and KarmaUtils.dist2(float(o["x"]), float(o["y"]), px, py) <= groom_range * groom_range
	)
	if choir.is_empty():
		return false
	# The song moves bodies: singers gather toward the caller's water.
	var water: Variant = KarmaUtils.nearest_water_for(state, px, py, float(KarmaData.TUNING["wanderSeekRange"]))
	var gx: float = float((water as Dictionary)["x"]) if water != null else px
	var gy: float = float((water as Dictionary)["y"]) if water != null else py
	for o in choir:
		var d: float = Vector2(float((o as Dictionary)["x"]), float((o as Dictionary)["y"])).distance_to(Vector2(gx, gy))
		if d == 0.0:
			continue
		var step: float = minf(50.0, d)
		(o as Dictionary)["x"] = clampf(float((o as Dictionary)["x"]) + (gx - float((o as Dictionary)["x"])) / d * step, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		(o as Dictionary)["y"] = clampf(float((o as Dictionary)["y"]) + (gy - float((o as Dictionary)["y"])) / d * step, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var k: float = float(KarmaData.TUNING["chorusKarma"]) * float(1 + choir.size()) * (2.0 if KarmaShop.has_adapt(t, "chorusPlus") else 1.0)
	KarmaState.add_karma(state, a, k, "Coro de croac con %d cantores (+%d karma)" % [1 + choir.size(), int(k)])
	return true


static func _verb_prudent(state: Dictionary, a: Variant) -> bool:
	# Prudent bite: like E but refuses the last fruit, so the +2 karma is earned, never gambled.
	var patch: Variant = KarmaEat.nearest_edible_patch_for(state, a, float(KarmaData.TUNING["eatRange"]))
	if patch == null or int((patch as Dictionary).get("amount", 0)) <= 1:
		return false
	return KarmaEat.eat_patch(state, patch, a)


static func _verb_pounce(state: Dictionary, a: Variant) -> bool:
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, float(KarmaData.TUNING["pounceRange"]))
	if prey == null:
		return KarmaEat.eat_carrion(state, KarmaUtils.nearest_from(float((a as Dictionary)["x"]),
			float((a as Dictionary)["y"]), state.get("carrions", []), float(KarmaData.TUNING["eatRange"])), a)
	var lethal: bool = KarmaEat.resolve_strike(state, a, prey, KarmaState.eff_max_hp_for(prey))
	(a as Dictionary)["pounceCd"] = float(KarmaData.TUNING["pounceCd"])
	if lethal:
		KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["pounceHp"]))
	return true


static func _verb_dive(state: Dictionary, a: Variant) -> bool:
	var prey: Variant = KarmaAI.nearest_ai_prey(state, a, 60.0)
	if prey == null:
		return false
	(a as Dictionary)["x"] = float((prey as Dictionary)["x"])
	(a as Dictionary)["y"] = float((prey as Dictionary)["y"])
	var lethal: bool = KarmaEat.resolve_strike(state, a, prey, KarmaState.eff_max_hp_for(prey))
	if lethal:
		KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["pounceHp"]))
	return true


static func _verb_groom(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var m: Variant = KarmaState.nearest_company(px, py, state, float(KarmaData.TUNING["groomRange"]), a)
	if m == null:
		return false
	for foul in ["mimicEaten", "toxicEaten"]:
		(m as Dictionary)[foul] = false
	var soothe: float = float(KarmaData.TUNING["sipHp"])
	KarmaEat.heal_eater(state, m, soothe)
	(m as Dictionary)["hambre"] = minf(100.0, float((m as Dictionary).get("hambre", 100.0)) + soothe)
	KarmaState.add_karma(state, a, float(KarmaData.TUNING["groomSocialKarma"]), "Acicalas a un congénere (+karma)")
	return true


static func _verb_seedcache(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
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
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	# Solo radar is not a deed: the scent post must have someone to warn.
	if KarmaState.nearest_company(px, py, state, float(KarmaData.TUNING["aiCoverRange"]), a) == null:
		return false
	t["revealT"] = float(KarmaData.TUNING["revealTime"]) * (2.0 if KarmaShop.has_adapt(t, "scoutPlus") else 1.0)
	(state["refuges"] as Array).append({"type": "scent-post", "maxSize": 0, "x": px, "y": py, "dug": false,
		"ttl": float(KarmaData.TUNING["revealTime"]) * (2.0 if KarmaShop.has_adapt(t, "scoutPlus") else 1.0)})
	KarmaState.add_karma(state, a, float(KarmaData.TUNING["prudentKarma"]), "Ojeas madrigueras (+karma)")
	return true


static func _verb_share(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var sk: float = float(KarmaData.TUNING["shareKarma"]) * (2.0 if KarmaShop.has_adapt(t, "sharePlus") else 1.0)
	var mates: Array = KarmaState.company_agents(state).filter(func(o):
		return (str(o.get("speciesKey", "")) == str((a as Dictionary).get("speciesKey", "")) if a != null else true) and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var m: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	if m == null or float(t.get("hp", 0.0)) <= float(KarmaData.TUNING["shareBiteHp"]):
		return false
	t["hp"] = float(t["hp"]) - float(KarmaData.TUNING["shareBiteHp"])
	KarmaEat.heal_eater(state, m, float(KarmaData.TUNING["shareBiteHp"]))
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
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var p: Variant = KarmaState.nearest_hunter(px, py, state, 300.0 if KarmaShop.has_adapt(t, "cachePlus") else 150.0)
	if p == null:
		return false
	(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["falseCacheKarma"]), "Cacha falsa (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["falseCacheKarma"]), "Cacha falsa: el cazador pica (+karma)")
	return true


static func _verb_bark(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var who: Dictionary = a if a != null else {"speciesKey": state["speciesKey"], "x": px, "y": py}
	var oak: Variant = KarmaEat.nearest_oak_with_nuts_for(state, who, float(KarmaData.TUNING["eatRange"]))
	if oak == null or int((oak as Dictionary).get("amount", 0)) <= 0:
		return false
	(oak as Dictionary)["amount"] = int((oak as Dictionary)["amount"]) - 1
	if int((oak as Dictionary)["amount"]) <= 0:
		(oak as Dictionary)["alive"] = false
	(oak as Dictionary)["stripped"] = true
	(oak as Dictionary)["stripT"] = regrow_rate_for("nuts")
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
	var c: Variant = KarmaUtils.nearest_from(float(KarmaState.px(state)), float(KarmaState.py(state)), state.get("carrions", []), float(KarmaData.TUNING["eatRange"]))
	return c != null and not bool((c as Dictionary).get("ceded", false)) and KarmaEat.cede_carrion(state, c)


static func _verb_howl(state: Dictionary, a: Variant) -> bool:
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var sk: String = str(t.get("speciesKey", ""))
	var pool: Array = (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) == sk
	)
	if pool.is_empty():
		return false
	var ht: float = KarmaData.aged_time(t, float(KarmaData.TUNING["howlTime"])) * (2.0 if KarmaShop.has_adapt(t, "howlPlus") else 1.0)
	for m in pool:
		(m as Dictionary)["rallyT"] = ht
	KarmaState.add_karma(state, a, float(KarmaData.TUNING["howlKarma"]), "Aúllas: la manada se anima (+karma)")
	return true


static func _verb_regurg(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var sk: String = str(t.get("speciesKey", ""))
	var mates: Array = (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) == sk and float(o.get("hambre", 100.0)) < float(KarmaData.TUNING["regenHambre"]))
	var m: Variant = KarmaUtils.nearest_from(px, py, mates, float(KarmaData.TUNING["groomRange"]))
	var cost: float = float(KarmaData.TUNING["regurgCost"])
	if m == null or float(t.get("hp", 0.0)) <= cost:
		return false
	t["hp"] = float(t["hp"]) - cost
	KarmaEat.heal_eater(state, m, cost)
	(m as Dictionary)["hambre"] = minf(100.0, float((m as Dictionary).get("hambre", 100.0)) + cost)
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["regurgKarma"]), "Regurgito (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["regurgKarma"]), "Regurgitas para un hambriento (+karma)")
	return true


static func _verb_escort(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var sk: String = str((a as Dictionary)["speciesKey"]) if a != null else str(state["speciesKey"])
	var pool: Array = (state["agents"] as Array).filter(func(o):
		return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) == sk
	)
	var threatened: Variant = null
	var threat: Variant = null
	var threat_range: float = 150.0
	for m in pool:
		for o in state["agents"]:
			if not KarmaPredators.threatens_mate(o, m):
				continue
			var dx: float = float(o["x"]) - float(m["x"])
			var dy: float = float(o["y"]) - float(m["y"])
			if dx * dx + dy * dy <= threat_range * threat_range:
				threatened = m
				threat = o
				break
		if threatened != null:
			break
	if threatened == null:
		return false
	# Shepherd the mate toward cover (or away from the threat), then deter it.
	var hunter: Variant = threat
	var cover: Variant = null
	var best: float = 1e9
	for r in state.get("refuges", []):
		if KarmaAI.refuge_fits_size(KarmaData.SPECIES[str((threatened as Dictionary).get("speciesKey", "raton"))], r, str((threatened as Dictionary).get("speciesKey", "raton"))):
			var cd: float = Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(float((threatened as Dictionary)["x"]), float((threatened as Dictionary)["y"])))
			if cd < best:
				best = cd
				cover = r
	var tx: float = float((threatened as Dictionary)["x"])
	var ty: float = float((threatened as Dictionary)["y"])
	if cover != null:
		tx = float((cover as Dictionary)["x"])
		ty = float((cover as Dictionary)["y"])
	elif hunter != null:
		var hd: float = Vector2(tx, ty).distance_to(Vector2(float((hunter as Dictionary)["x"]), float((hunter as Dictionary)["y"])))
		if hd == 0.0:
			hd = 1.0
		tx = tx + (tx - float((hunter as Dictionary)["x"])) / hd * 50.0
		ty = ty + (ty - float((hunter as Dictionary)["y"])) / hd * 50.0
	var md: float = Vector2(float((threatened as Dictionary)["x"]), float((threatened as Dictionary)["y"])).distance_to(Vector2(tx, ty))
	if md > 0.0:
		var step: float = minf(50.0, md)
		(threatened as Dictionary)["x"] = clampf(float((threatened as Dictionary)["x"]) + (tx - float((threatened as Dictionary)["x"])) / md * step, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		(threatened as Dictionary)["y"] = clampf(float((threatened as Dictionary)["y"]) + (ty - float((threatened as Dictionary)["y"])) / md * step, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	var deter_range: float = 90.0
	var tdx: float = float((threatened as Dictionary)["x"])
	var tdy: float = float((threatened as Dictionary)["y"])
	for p in state["agents"]:
		if p == a or not KarmaPredators.threatens_mate(p, threatened):
			continue
		var dx: float = float(p["x"]) - tdx
		var dy: float = float(p["y"]) - tdy
		if dx * dx + dy * dy <= deter_range * deter_range:
			(p as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	if a != null:
		# Agents have no escort tick: same value now instead of later.
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["escortKarma"]), "Escoltas a un congénere (+karma)")
		return true
	state["escortT"] = KarmaData.aged_time(state, float(KarmaData.TUNING["escortTime"]))
	state["escortTarget"] = threatened
	KarmaState.add_log(state, null, "Escoltas a un congénere amenazado (sobrevive y hay karma)")
	return true


static func _verb_cull(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var sick: Variant = null
	var sick_frac: float = 2.0
	var pounce_range: float = float(KarmaData.TUNING["pounceRange"])
	for o in state["agents"]:
		if o == a or str(o.get("brain", "")) == "PLAYER":
			continue
		var d: float = Vector2(px, py).distance_to(Vector2(float(o["x"]), float(o["y"])))
		if not KarmaPredators.can_eat(str(t.get("speciesKey", "")), str(o.get("speciesKey", "")), d):
			continue
		if d > pounce_range:
			continue
		var frac: float = float(o.get("hp", 0.0)) / float(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["maxHp"])
		if frac < sick_frac:
			sick_frac = frac
			sick = o
	if sick == null:
		return false
	var weak: bool = sick_frac < (0.5 if KarmaShop.has_adapt(t, "cullPlus") else 0.3)
	var lethal: bool = false
	if a == null:
		if not KarmaEat.pounce_kill(state, sick, null):
			return false
	else:
		lethal = KarmaEat.resolve_strike(state, a, sick, KarmaState.eff_max_hp_for(sick))
		if lethal:
			KarmaEat.heal_eater(state, a, float(KarmaData.TUNING["pounceHp"]))
	if weak and lethal:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["cullKarma"]), "Caza al débil, selección natural (+karma)")
	return true


static func _verb_cachecarrion(state: Dictionary, a: Variant) -> bool:
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	if int(t.get("stash", 0)) > 0:
		return false
	var c: Variant = KarmaUtils.nearest_from(px, py,
		(state.get("carrions", []) as Array).filter(func(k): return KarmaEat.carrion_stage(k) != "rotten"), float(KarmaData.TUNING["eatRange"]))
	if c == null:
		return false
	(state["carrions"] as Array).erase(c)
	t["stash"] = 1
	KarmaState.add_log(state, a, "Entierras carroña para después (+PA en la próxima)")
	return true


static func _verb_dendig(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	(state["refuges"] as Array).append({"type": "burrow-M", "maxSize": 2, "climbOnly": false, "x": px, "y": py, "dug": true, "charge": 1})
	KarmaState.add_log(state, a, "Excavas una guarida (cuesta vida)")
	return true


static func _verb_thermal(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	if float(t.get("thermalT", 0.0)) > 0.0:
		return false
	# Solo soaring is not a deed: the shadow must have prey to scatter.
	var prey: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) != str(state["speciesKey"]) and int(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["size"]) <= 2), 150.0)
	if prey == null:
		return false
	t["thermalT"] = KarmaData.aged_time(t, float(KarmaData.TUNING["thermalTime"])) * (2.0 if KarmaShop.has_adapt(t, "thermalPlus") else 1.0)
	(state["refuges"] as Array).append({"type": "shadow-disc", "maxSize": 0, "x": float((prey as Dictionary)["x"]), "y": float((prey as Dictionary)["y"]), "dug": false,
		"ttl": KarmaData.aged_time(t, float(KarmaData.TUNING["thermalTime"]))})
	var thermal_range: float = 150.0
	for v in (state["agents"] as Array).filter(func(o): return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) != str(state["speciesKey"]) and int(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["size"]) <= 2 and KarmaUtils.dist2(float(o["x"]), float(o["y"]), px, py) <= thermal_range * thermal_range):
		var d: float = Vector2(float((v as Dictionary)["x"]), float((v as Dictionary)["y"])).distance_to(Vector2(px, py))
		if d == 0.0:
			d = 1.0
		(v as Dictionary)["x"] = clampf(float((v as Dictionary)["x"]) + (float((v as Dictionary)["x"]) - px) / d * 60.0, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
		(v as Dictionary)["y"] = clampf(float((v as Dictionary)["y"]) + (float((v as Dictionary)["y"]) - py) / d * 60.0, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	KarmaState.add_log(state, a, "Sombra en círculo: las presas se dispersan")
	return true


static func _verb_courtesy(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var c: Variant = KarmaUtils.nearest_from(px, py,
		(state.get("carrions", []) as Array).filter(func(k): return KarmaEat.carrion_stage(k) == "fresh"), float(KarmaData.TUNING["eatRange"]))
	if c == null or bool((c as Dictionary).get("ceded", false)):
		return false
	(c as Dictionary)["ceded"] = true
	KarmaState.add_karma(state, a, float(KarmaData.TUNING["cedeKarma"]), "Carroña compartida (+karma, la dejas)")
	return true


static func _verb_scare(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var v: Variant = KarmaUtils.nearest_from(px, py,
		(state["agents"] as Array).filter(func(o): return o != a and str(o.get("brain", "")) != "PLAYER" and str(o.get("speciesKey", "")) != str(state["speciesKey"]) and int(KarmaData.SPECIES[str(o.get("speciesKey", "raton"))]["size"]) <= 2), 90.0)
	if v == null:
		return false
	var d: float = Vector2(float((v as Dictionary)["x"]), float((v as Dictionary)["y"])).distance_to(Vector2(px, py))
	if d == 0.0:
		d = 1.0
	(v as Dictionary)["x"] = clampf(float((v as Dictionary)["x"]) + (float((v as Dictionary)["x"]) - px) / d * 60.0, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	(v as Dictionary)["y"] = clampf(float((v as Dictionary)["y"]) + (float((v as Dictionary)["y"]) - py) / d * 60.0, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	var k: float = float(KarmaData.TUNING["scareKarma"]) * (2.0 if KarmaShop.has_adapt(t, "scarePlus") else 1.0)
	KarmaState.add_karma(state, a, k, "Ahuyentas sin matar (+karma)")
	return true


static func _verb_bone(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	KarmaEat.add_carrion(state, px, py)
	if a != null:
		KarmaState.add_karma(state, a, float(KarmaData.TUNING["boneKarma"]), "Hueso suelto (+karma)")
	else:
		KarmaState.add_karma(state, null, float(KarmaData.TUNING["boneKarma"]), "Sueltas un hueso (+karma, carroña fresca)")
	return true


static func _verb_strike(state: Dictionary, a: Variant) -> bool:
	if a != null:
		var p: Variant = KarmaState.nearest_hunter(float((a as Dictionary)["x"]), float((a as Dictionary)["y"]), state, 60.0, a)
		if p == null or float((a as Dictionary).get("strikeCd", 0.0)) > 0.0:
			return false
		KarmaAI.ai_strike(state, a, p)
		return true
	var q: Variant = KarmaState.nearest_hunter(float(KarmaState.px(state)), float(KarmaState.py(state)), state, 60.0)
	if q == null or float(KarmaState.player(state).get("strikeCd", 0.0)) > 0.0:
		return false
	return KarmaEat.strike_predator(state, q, null)


static func silk_drop(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	var h: Variant = KarmaState.nearest_hunter(px, py, state, 150.0)
	if h == null:
		return false
	var d: float = Vector2(px, py).distance_to(Vector2(float((h as Dictionary)["x"]), float((h as Dictionary)["y"])))
	if d == 0.0:
		d = 1.0
	var dist: float = 80.0 if KarmaShop.has_adapt(t, "silkPlus") else 40.0
	var ox: float = px
	var oy: float = py
	var nx: float = clampf(px + (px - float((h as Dictionary)["x"])) / d * dist, 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	var ny: float = clampf(py + (py - float((h as Dictionary)["y"])) / d * dist, 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	# The thread stays behind: whoever crosses the old spot stalls.
	(state["refuges"] as Array).append({"type": "silk-thread", "maxSize": 0, "x": ox, "y": oy, "dug": false,
		"ttl": float(KarmaData.TUNING["leafrollTtl"])})
	(h as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	if a != null:
		(a as Dictionary)["x"] = nx
		(a as Dictionary)["y"] = ny
		return true
	KarmaState.player(state)["x"] = nx
	KarmaState.player(state)["y"] = ny
	return true


static func _verb_nectar(state: Dictionary, a: Variant) -> bool:
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var p: Variant = KarmaState.nearest_hunter(px, py, state, 150.0)
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
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
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
	var px: float = float((a as Dictionary)["x"]) if a != null else float(KarmaState.px(state))
	var py: float = float((a as Dictionary)["y"]) if a != null else float(KarmaState.py(state))
	var t: Dictionary = KarmaState.body_actor(state, a) as Dictionary
	# Spines sting now: the hunter in reach stalls, and the coat stays up for the next bite.
	var h: Variant = KarmaState.nearest_hunter(px, py, state, 60.0)
	if h == null:
		return false
	(h as Dictionary)["restT"] = float(KarmaData.TUNING["restTime"])
	t["bristled"] = true
	KarmaState.add_log(state, a, "Erizas espinas (el depredador se frena)")
	return true


static func groom_tick(state: Dictionary, dt: float) -> void:
	if str(state["speciesKey"]) == "raton" and float(KarmaState.player(state).get("groomCd", 0.0)) <= 0.0:
		if KarmaState.nearest_company(float(KarmaState.px(state)), float(KarmaState.py(state)), state, float(KarmaData.TUNING["groomRange"])) != null:
			KarmaState.player(state)["groomT"] = float(KarmaState.player(state).get("groomT", 0.0)) + dt
			if float(KarmaState.player(state)["groomT"]) >= KarmaData.aged_time(state, float(KarmaData.TUNING["groomTime"])):
				KarmaState.player(state)["groomT"] = 0.0
				KarmaState.player(state)["groomCd"] = KarmaData.aged_time(state, float(KarmaData.TUNING["groomCd"]))
				KarmaState.add_karma(state, null, float(KarmaData.TUNING["groomKarma"]), "Acicalas a un congénere (+karma)")
		else:
			KarmaState.player(state)["groomT"] = 0.0
	else:
		KarmaState.player(state)["groomT"] = 0.0


static func update_agents(state: Dictionary, dt: float, solids: Array = []) -> void:
	var dead: Array = []
	var list: Array = solids if not solids.is_empty() else KarmaUtils.collect_solids(state)
	for a in (state["agents"] as Array).duplicate():
		# A kill earlier in the pass already removed this agent.
		if not (state["agents"] as Array).has(a):
			continue
		step_agent(state, a, dt)
		if float(a.get("hp", 1.0)) > 0.0:
			var p: Vector2 = KarmaUtils.resolve_collisions(state, Vector2(float(a["x"]), float(a["y"])),
				float(KarmaData.SPECIES[str(a.get("speciesKey", "raton"))]["radius"]),
				str(a.get("speciesKey", "")) == "topo",
				KarmaUtils.skips_water(str(a.get("speciesKey", "")), bool(a.get("grounded", false))), list)
			a["x"] = p.x
			a["y"] = p.y
		if float(a.get("hp", 1.0)) <= 0.0:
			dead.append(a)
	for a in dead:
		if not (state["agents"] as Array).has(a):
			continue
		KarmaState.remove_agent(state, a)
		KarmaEat.add_carrion(state, float(a["x"]), float(a["y"]))


static func step_agent(state: Dictionary, a: Dictionary, dt: float) -> void:
	if str(a.get("brain", "")) == "PLAYER":
		KarmaUtils.update_needs(a, KarmaState.eff_max_hp_for(a), dt)
		return
	KarmaAI.ai_step(state, a, dt)
	# Species AI owns the chase; the bite itself is a per-pair contact check.
	KarmaPredators.hunt_player(state, a, dt)


static func wander_mates(state: Dictionary, dt: float, rng: RandomNumberGenerator) -> void:
	var hunters: Array = KarmaState.predator_agents(state)
	for m in KarmaState.company_agents(state):
		if float(m.get("rallyT", 0.0)) > 0.0:
			m["rallyT"] = float(m["rallyT"]) - dt
		var boost: float = 1.5 if float(m.get("rallyT", 0.0)) > 0.0 else 1.0
		var pred: Variant = KarmaUtils.nearest_from(float(m["x"]), float(m["y"]), hunters, 999.0)
		if bool(m.get("saved", false)) and pred != null:
			var d: float = Vector2(float(m["x"]), float(m["y"])).distance_to(Vector2(float((pred as Dictionary)["x"]), float((pred as Dictionary)["y"])))
			if d == 0.0:
				d = 1.0
			m["x"] = float(m["x"]) + (float(m["x"]) - float((pred as Dictionary)["x"])) / d * 90.0 * boost * dt
			m["y"] = float(m["y"]) + (float(m["y"]) - float((pred as Dictionary)["y"])) / d * 90.0 * boost * dt
		else:
			var pd: float = Vector2(float(KarmaState.px(state)), float(KarmaState.py(state))).distance_to(Vector2(float(m["x"]), float(m["y"])))
			if pd > float(KarmaData.TUNING["groomRange"]):
				KarmaGame.move_toward(state, m, float(KarmaState.px(state)), float(KarmaState.py(state)), boost, dt)
			else:
				var poi: Variant = KarmaGame.wander_poi(state, m)
				if poi != null:
					KarmaGame.move_toward(state, m, float((poi as Dictionary)["x"]), float((poi as Dictionary)["y"]), boost, dt)
				else:
					m["x"] = float(m["x"]) + (rng.randf() - 0.5) * 40.0 * boost * dt
					m["y"] = float(m["y"]) + (rng.randf() - 0.5) * 40.0 * boost * dt
