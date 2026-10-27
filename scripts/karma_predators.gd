class_name KarmaPredators
extends RefCounted

# Port of src/script/predators.js — trophic chain + hunter stepping.


static func mk_predator(state: Dictionary, species_key: String, x: float, y: float, player_tier: int) -> Dictionary:
	var t: Dictionary = KarmaData.PRED.get(species_key, KarmaData.PRED_FALLBACK)
	var speed: float = float(t["speed"]) + (25.0 if player_tier == 0 and species_key == "zorro" else 0.0)
	return {"speciesKey": species_key, "brain": "AI",
		"hp": float(KarmaData.SPECIES[species_key]["maxHp"]), "hambre": 100.0, "sed": 100.0, "edad": 0.0,
		"x": x, "y": y, "wx": x, "wy": y, "speed": speed,
		"mode": "wander", "campT": 0.0, "huntT": 0.0, "restT": 0.0, "satedT": 0.0,
		"fleeLatch": false, "huntingPlayer": false, "karma": 0.0, "pa": 0.0, "owned": {}, "lifeLog": [],
		"caution_food": randf(), "caution_water": randf()}


static func eff_speed(p: Dictionary) -> float:
	# Old legs slower, same gait mode: hunter displacement scales with age.
	return float(p.get("speed", 100.0)) * KarmaData.speed_mult_for(str(p.get("speciesKey", "raton")), float(p.get("edad", 0.0)))


static func can_eat(actor_species: String, target_species: String, dist: float) -> bool:
	var t: Variant = KarmaData.PRED.get(actor_species, null)
	var v: Variant = KarmaData.SPECIES.get(target_species, null)
	if t == null or v == null:
		return false
	var same: bool = actor_species == target_species
	if same and not bool((t as Dictionary).get("preyMates", false)):
		return false
	if not same:
		if (t as Dictionary).has("preyTiers"):
			if not ((t as Dictionary)["preyTiers"] as Array).has(int(v["tier"])):
				return false
		elif (t as Dictionary).has("preySizes"):
			if not ((t as Dictionary)["preySizes"] as Array).has(int(v["size"])):
				return false
		else:
			return false
	# Optimal foraging: a size gap of 2+ only pays off at touching range, and
	# only for species whose row says so (zorro snap). Halcon keeps its reach.
	if bool((t as Dictionary).get("snapOnly", false)) and float((t as Dictionary)["size"]) - float(v["size"]) >= 2.0 and dist > float(KarmaData.TUNING["snapRange"]):
		return false
	return true


static func can_eat_agent(actor: Dictionary, target: Dictionary) -> bool:
	if actor == target:
		return false
	var d: float = Vector2(float(actor["x"]), float(actor["y"])).distance_to(Vector2(float(target["x"]), float(target["y"])))
	return can_eat(str(actor.get("speciesKey", "")), str(target.get("speciesKey", "")), d)


static func threatens_mate(actor: Dictionary, mate: Dictionary) -> bool:
	# Escort threat: a different species that hunts animals is near the packmate.
	if actor == mate:
		return false
	if str(actor.get("speciesKey", "")) == str(mate.get("speciesKey", "")):
		return false
	return KarmaData.PRED.has(str(actor.get("speciesKey", "")))


static func player_edible_for(state: Dictionary, p: Dictionary, dist: float) -> bool:
	return can_eat(str(p.get("speciesKey", "")), str(state["speciesKey"]), dist)


static func camouflaged_state(state: Dictionary) -> bool:
	return str(state["speciesKey"]) == "sapo" and float(KarmaState.player(state).get("stillT", 0.0)) >= 2.0


static func canopy_blind(state: Dictionary, pred: Dictionary) -> bool:
	if not bool(KarmaState.player(state).get("hidden", false)):
		return false
	if str((KarmaState.player(state).get("hideRef", {}) as Dictionary).get("type", "")) == "old-oak" and str(pred.get("speciesKey", "")) == "halcon":
		return false
	return true


static func curled_state(state: Dictionary) -> bool:
	return str(state["speciesKey"]) == "oruga" and float(KarmaState.player(state).get("stillT", 0.0)) >= 0.01 and float(KarmaState.player(state).get("curlCd", 0.0)) <= 0.0 and not bool(KarmaState.player(state).get("moved", false))


static func nearest_rival(state: Dictionary, a: Dictionary, rnge: float) -> Variant:
	# Another species that hunts animals: a rival to scare, never a packmate.
	var own: String = str(a.get("speciesKey", ""))
	var out: Array = []
	for o in state["agents"] as Array:
		if o == null or o == a or str((o as Dictionary).get("speciesKey", "")) == own:
			continue
		if KarmaData.PRED.has(str((o as Dictionary).get("speciesKey", ""))):
			out.append(o)
	return KarmaUtils.nearest_from(float(a["x"]), float(a["y"]), out, rnge)


static func hunt_player(state: Dictionary, p: Dictionary, dt: float) -> void:
	# A predator bites the possessed body on contact; the species AI owns the chase.
	if not KarmaData.PRED.has(str(p.get("speciesKey", ""))):
		return
	var t: Dictionary = KarmaData.PRED.get(str(p.get("speciesKey", "")), KarmaData.PRED_FALLBACK)
	if camp_step(state, p, dt):
		return
	var victim: Dictionary = KarmaState.player(state)
	var dp: float = Vector2(KarmaState.px(state), KarmaState.py(state)).distance_to(Vector2(float(p["x"]), float(p["y"])))
	if camouflaged_state(KarmaState.player(state)) and str(p.get("speciesKey", "")) == "zorro":
		return
	if not player_edible_for(state, p, dp):
		return
	strike_contact(state, p, t, dp)


static func camp_step(state: Dictionary, p: Dictionary, dt: float) -> bool:
	var victim: Dictionary = KarmaState.player(state)
	if str(p.get("mode", "")) == "camp":
		p["campT"] = float(p.get("campT", 0.0)) - dt
		if float(p["campT"]) <= 0.0:
			p["mode"] = "wander"
		elif victim.get("hideRef", null) != null:
			var hr: Dictionary = victim["hideRef"]
			var dx: float = float(hr["x"]) - float(p["x"])
			var dy: float = float(hr["y"]) - float(p["y"])
			var dd: float = Vector2(dx, dy).length()
			if dd == 0.0:
				dd = 1.0
			if dd > 30.0:
				p["x"] = float(p["x"]) + dx / dd * eff_speed(p) * dt
				p["y"] = float(p["y"]) + dy / dd * eff_speed(p) * dt
		return true
	if bool(victim.get("hidden", false)) and bool(p.get("huntingPlayer", false)):
		if not canopy_blind(victim, p):
			return false
		p["mode"] = "camp"
		p["campT"] = float(KarmaData.TUNING["campTime"])
		p["huntingPlayer"] = false
		return true
	return false


static func strike_contact(state: Dictionary, p: Dictionary, t: Dictionary, dp: float) -> void:
	var victim: Dictionary = KarmaState.player(state)
	if bool(victim.get("hidden", false)) or dp >= float(state["sp"]["radius"]) + float(t["body"]) / 2.0 or float(victim.get("invuln", 0.0)) > 0.0:
		return
	var dmg: float = KarmaData.scaled_damage(float(t["damage"]), p, victim)
	if bool(victim.get("bristled", false)):
		victim["bristled"] = false
		p["hp"] = float(p.get("hp", 60.0)) - dmg
		victim["invuln"] = float(KarmaData.TUNING["predatorInvuln"])
		KarmaState.add_log(state, null, "¡Espinas! El zarpazo se revierte")
		return
	if curled_state(victim):
		dmg = ceil(dmg / 2.0)
		victim["curlCd"] = float(KarmaData.TUNING["curlCd"])
	victim["hp"] = float(victim["hp"]) - dmg
	victim["invuln"] = float(KarmaData.TUNING["predatorInvuln"])
	KarmaState.add_log(state, null, "%s te muerde (−%d vida)" % [str(t["name"]), int(dmg)])
