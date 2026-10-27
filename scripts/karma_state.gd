class_name KarmaState
extends RefCounted

# Port of src/script/state.js — world state as a plain Dictionary.
# UI rendering lives in main.gd; this file keeps simulation + ledger rules.

const FLORA_BASE := {"berries": 7, "apples": 3, "carrots": 2, "mushrooms": 4, "leaves": 4, "nuts": 2}
const FLORA_KIND := {"berries": "bushes", "apples": "shrubs", "carrots": "patches", "mushrooms": "clusters", "leaves": "clumps", "nuts": "oaks"}
const FLORA_KEYS := ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks"]


static func flora_cap(kind: String) -> int:
	return KarmaUtils.scaled_count(int(FLORA_BASE.get(kind, 2)))


static func blank_state(species_key: String, karma: float, pa: float) -> Dictionary:
	var sp: Dictionary = KarmaData.SPECIES[species_key]
	return {
		"speciesKey": species_key, "sp": sp,
		"karma": karma, "pa": pa, "saplings": 0,
		"time": 0.0, "dead": false, "paAcc": 0.0,
		"dug": 0,
		"agents": [],
		"lifeLog": [], "feed": [], "otherFeed": [],
		"owned": {}, "shopOpen": false, "paused": false,
		"introDone": true, "introNext": null,
		"pendingNext": null, "pendingPool": null, "judgeReason": "",
		"mateT": 0.0, "insectT": 0.0, "respawnT": 0.0,
		"weather": {"raining": false, "t": float(KarmaData.TUNING["rainDryMin"])},
		"hambreWarned": false, "sedWarned": false,
		"escortT": 0.0, "escortTarget": null,
		"bushes": [], "shrubs": [], "patches": [], "clusters": [], "clumps": [], "oaks": [],
		"insects": [], "seedlings": [], "rocks": [], "waters": [], "refuges": [], "carrions": [],
	}


static func new_run(species_key: String, carry_karma: float = 0.0, carry_pa: float = 0.0, carry_saplings: int = 0, rng: RandomNumberGenerator = null) -> Dictionary:
	var r: RandomNumberGenerator = rng if rng != null else KarmaUtils.rng()
	var state: Dictionary = blank_state(species_key, carry_karma, carry_pa)
	var roll: Dictionary = KarmaCensus.roll(r, species_key)
	state["census"] = roll
	seed_food(state, carry_saplings, r)
	seed_fauna(state, r)
	possess_member(state)
	seed_refuges(state, r)
	state["carrions"] = []
	add_log(state, null, "Naces como %s T%d" % [str(state["sp"]["name"]), int(state["sp"]["tier"])])
	add_log(state, null, "Año %s" % _year_name(str(roll["theme"])))
	return state


static func _year_name(theme: String) -> String:
	return {"bloom": "de la proliferación de orugas", "rodent": "de roedores",
		"wet": "húmedo", "lean": "escaso"}.get(theme, "equilibrado")


static func seed_waters(state: Dictionary, rng: RandomNumberGenerator) -> void:
	state["waters"] = []
	for pt in KarmaUtils.scatter(KarmaUtils.scaled_count(int(KarmaData.TUNING["charcoCount"])), rng):
		var ccap: float = water_cap_for("charco")
		(state["waters"] as Array).append({"kind": "charco", "x": pt["x"], "y": pt["y"], "r": float(KarmaData.TUNING["charcoR"]), "level": ccap, "cap": ccap})
	for pt in KarmaUtils.scatter(KarmaUtils.scaled_count(int(KarmaData.TUNING["lagoCount"])), rng):
		var lcap: float = water_cap_for("lago")
		(state["waters"] as Array).append({"kind": "lago", "x": pt["x"], "y": pt["y"], "r": float(KarmaData.TUNING["lagoR"]), "level": lcap, "cap": lcap})


static func water_cap_for(kind: String) -> float:
	var r: float = float(KarmaData.TUNING["lagoR"]) if kind == "lago" else float(KarmaData.TUNING["charcoR"])
	var ratio: float = r / float(KarmaData.TUNING["charcoR"])
	return float(KarmaData.TUNING["waterCapCharco"]) * ratio * ratio


static func seed_food(state: Dictionary, carry_saplings: int, rng: RandomNumberGenerator) -> void:
	seed_waters(state, rng)
	var extra: int = mini(carry_saplings, int(KarmaData.TUNING["saplingCap"]))
	# Leave headroom below each flora cap so seedlings can mature into new
	# plants during play; a world seeded exactly at cap could never grow.
	# Draws keep the old counts so the rng stream (and every downstream
	# spawn) is unchanged; only the kept prefix shrinks.
	var headroom: int = int(KarmaData.TUNING.get("floraHeadroom", 2))
	state["bushes"] = []
	var i: int = 0
	var bush_pts: Array[Dictionary] = KarmaUtils.scatter_dry(state, flora_cap("berries") + extra, rng)
	for pt in bush_pts.slice(0, maxi(1, flora_cap("berries") - headroom) + extra):
		(state["bushes"] as Array).append(KarmaUtils.mk_patch("berries", pt["x"], pt["y"], 3, {"mimic": i % 3 == 2, "mimicEaten": false}))
		i += 1
	state["shrubs"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("apples"), rng).slice(0, maxi(1, flora_cap("apples") - headroom)):
		(state["shrubs"] as Array).append(KarmaUtils.mk_patch("apples", pt["x"], pt["y"], 2))
	state["patches"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("carrots"), rng).slice(0, maxi(1, flora_cap("carrots") - headroom)):
		(state["patches"] as Array).append(KarmaUtils.mk_patch("carrots", pt["x"], pt["y"], 3))
	state["clusters"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("mushrooms"), rng).slice(0, maxi(1, flora_cap("mushrooms") - headroom)):
		(state["clusters"] as Array).append(KarmaUtils.mk_patch("mushrooms", pt["x"], pt["y"], 2, {"toxicLeft": 1 if rng.randf() < 0.5 else 0, "toxicEaten": false}))
	state["clumps"] = []
	for pt in KarmaUtils.scatter_dry(state, maxi(1, flora_cap("leaves") - headroom), rng):
		(state["clumps"] as Array).append(KarmaUtils.mk_patch("leaves", pt["x"], pt["y"], 3, {"regrowT": 0.0}))
	state["oaks"] = []
	for pt in KarmaUtils.scatter_dry(state, maxi(1, flora_cap("nuts") - headroom), rng):
		(state["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", pt["x"], pt["y"], 3))
	state["insects"] = []
	KarmaGame.seed_insect_minimums(state, rng)
	state["seedlings"] = []
	state["rocks"] = []
	for pt in KarmaUtils.scatter_dry(state, KarmaUtils.scaled_count(int(KarmaData.TUNING["rockCount"])), rng):
		(state["rocks"] as Array).append({"x": pt["x"], "y": pt["y"]})


static func mk_agent(a: Dictionary) -> Dictionary:
	var base: Dictionary = {"brain": "AI", "x": 0.0, "y": 0.0, "face": {"x": 1.0, "y": 0.0}, "moved": false,
		"hp": 60.0, "hambre": 100.0, "sed": 100.0, "edad": 0.0, "invuln": 0.0,
		"shoutCd": 0.0, "strikeCd": 0.0, "pounceCd": 0.0, "digCd": 0.0, "senseCd": 0.0,
		"revealT": 0.0, "trackT": 0.0, "groomCd": 0.0, "curlCd": 0.0, "dietHintT": 0.0,
		"thermalT": 0.0, "lureTimer": 0.0, "verbCds": [0.0, 0.0, 0.0, 0.0, 0.0],
		"hidden": false, "hideRef": null, "bristled": false, "grounded": false, "landT": 0.0,
		"cam": {"x": 0.0, "y": 0.0}, "carriedNut": false, "larder": 0, "stash": 0,
		"stillT": 0.0, "groomT": 0.0, "karma": 0.0, "pa": 0.0, "owned": {}, "lifeLog": []}
	for k in a:
		base[k] = a[k]
	if not base.has("caution_food"):
		base["caution_food"] = randf()
	if not base.has("caution_water"):
		base["caution_water"] = randf()
	return base


# The possessed body: the one agent with brain PLAYER. Until every scene
# possesses a member, blank states keep their body at top level.
static func player(state: Dictionary) -> Variant:
	for a in state["agents"] as Array:
		if a != null and str((a as Dictionary).get("brain", "")) == "PLAYER":
			return a
	return null


static func body_actor(state: Dictionary, a: Variant) -> Variant:
	if a != null:
		return a
	var p: Variant = player(state)
	if p != null:
		return p
	return state


static func px(state: Dictionary) -> float:
	var p: Variant = player(state)
	if p == null:
		return 0.0
	return float((p as Dictionary).get("x", 0.0))


static func py(state: Dictionary) -> float:
	var p: Variant = player(state)
	if p == null:
		return 0.0
	return float((p as Dictionary).get("y", 0.0))


static func company_agents(state: Dictionary) -> Array:
	var out: Array = []
	for a in state["agents"] as Array:
		if a == null or str(a.get("brain", "")) == "PLAYER":
			continue
		if str(a.get("speciesKey", "")) == str(state["speciesKey"]):
			out.append(a)
	return out


# Nearest company agent within max_d, or null. Scans agents in place (no temp array).
# exclude skips one agent (the asker) without scanning the list twice.
static func nearest_company(ax: float, ay: float, state: Dictionary, max_d: float, exclude: Variant = null) -> Variant:
	var best: Variant = null
	var bd: float = max_d * max_d
	for o in state["agents"] as Array:
		if o == null or o == exclude or str(o.get("brain", "")) == "PLAYER":
			continue
		if str(o.get("speciesKey", "")) != str(state["speciesKey"]):
			continue
		var dx: float = ax - float(o["x"])
		var dy: float = ay - float(o["y"])
		var d: float = dx * dx + dy * dy
		if d < bd:
			bd = d
			best = o
	return best


static func predator_agents(state: Dictionary) -> Array:
	var out: Array = []
	for a in state["agents"] as Array:
		if a == null or str(a.get("brain", "")) == "PLAYER":
			continue
		if KarmaData.PRED.has(str(a.get("speciesKey", ""))):
			out.append(a)
	return out


# Nearest animal predator within max_d, or null. Scans agents in place.
# exclude skips one agent (the asker) without scanning the list twice.
static func nearest_hunter(ax: float, ay: float, state: Dictionary, max_d: float, exclude: Variant = null) -> Variant:
	var best: Variant = null
	var bd: float = max_d * max_d
	for o in state["agents"] as Array:
		if o == null or o == exclude:
			continue
		if not KarmaData.PRED.has(str(o.get("speciesKey", ""))):
			continue
		var dx: float = ax - float(o["x"])
		var dy: float = ay - float(o["y"])
		var d: float = dx * dx + dy * dy
		if d < bd:
			bd = d
			best = o
	return best


static func remove_agent(state: Dictionary, a: Dictionary) -> void:
	(state["agents"] as Array).erase(a)


static func possess_member(state: Dictionary) -> void:
	# The census member is taken over in place: no erase, no duplicate body.
	for a in (state["agents"] as Array):
		if str(a.get("speciesKey", "")) == str(state["speciesKey"]) and str(a.get("brain", "")) != "PLAYER":
			a["brain"] = "PLAYER"
			return


static func seed_refuges(state: Dictionary, rng: RandomNumberGenerator) -> void:
	state["refuges"] = []
	for r in KarmaData.REFUGES:
		for pt in KarmaUtils.scatter_dry(state, KarmaUtils.scaled_count(int(r["count"])), rng):
			(state["refuges"] as Array).append({"type": r["type"], "maxSize": r["maxSize"],
				"climbOnly": bool(r.get("climbOnly", false)), "x": pt["x"], "y": pt["y"], "dug": false})


static func fauna_count(k: String) -> int:
	return maxi(1, roundi(float((KarmaData.POP["faunaFloor"] as Dictionary).get(k, 0)) * KarmaUtils.area_scale() / 4.0))


static func spawn_fauna(state: Dictionary, k: String, x: float, y: float) -> Dictionary:
	var a: Dictionary = mk_agent({"speciesKey": k, "hp": float(KarmaData.SPECIES[k]["maxHp"]), "x": x, "y": y,
		"face": {"x": 1.0, "y": 0.0}})
	if KarmaData.PRED.has(k):
		a["speed"] = float(KarmaData.SPECIES[k]["speed"])
		a["mode"] = "wander"
		a["wx"] = x
		a["wy"] = y
		a["huntT"] = 0.0
		a["restT"] = 0.0
		a["satedT"] = 0.0
		a["fleeLatch"] = false
		a["huntingPlayer"] = false
	(state["agents"] as Array).append(a)
	return a


static func seed_fauna(state: Dictionary, rng: RandomNumberGenerator) -> void:
	if not state.has("census"):
		for k in (KarmaData.POP["faunaFloor"] as Dictionary):
			for i in fauna_count(str(k)):
				var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
				spawn_fauna(state, str(k), float(pt["x"]), float(pt["y"]))
		return
	var counts: Dictionary = (state["census"] as Dictionary)["counts"]
	for k in counts:
		var n: int = int(counts[k])
		if KarmaData.PRED.has(str(k)):
			for i in n:
				var far: Dictionary = distant_pt(state, rng)
				spawn_fauna(state, str(k), float(far["x"]), float(far["y"]))
			continue
		var anchor: Dictionary = community_anchor(state, str(k), rng)
		for i in n:
			var mp: Dictionary = member_pt(state, anchor, i, rng)
			if str(k) == str(state["speciesKey"]):
				spawn_company(state, float(mp["x"]), float(mp["y"]))
			else:
				spawn_fauna(state, str(k), float(mp["x"]), float(mp["y"]))


static func community_anchor(state: Dictionary, species_key: String, rng: RandomNumberGenerator) -> Dictionary:
	var spots: Array = []
	match species_key:
		"oruga":
			spots = state.get("clumps", [])
		"sapo":
			# Anchor on the water itself: nudge_dry slides members onto the shore ring.
			spots = state.get("waters", [])
		"raton", "ardilla":
			spots = (state.get("bushes", []) as Array) + (state.get("shrubs", []) as Array) + (state.get("oaks", []) as Array)
		"topo":
			spots = state.get("patches", [])
	if (spots as Array).is_empty():
		return KarmaUtils.scatter_dry(state, 1, rng)[0]
	var s: Dictionary = (spots as Array)[rng.randi() % (spots as Array).size()]
	return {"x": float(s["x"]), "y": float(s["y"])}


static func member_pt(state: Dictionary, anchor: Dictionary, i: int, rng: RandomNumberGenerator) -> Dictionary:
	var pt: Dictionary = {"x": float(anchor["x"]), "y": float(anchor["y"])}
	if i == 1:
		# Hearth pair: guarantees two congeners start within social-verb range.
		var ang: float = rng.randf() * TAU
		pt = {"x": float(anchor["x"]) + cos(ang) * 20.0, "y": float(anchor["y"]) + sin(ang) * 20.0}
	elif i > 1:
		pt = {"x": float(anchor["x"]) + rng.randf() * 500.0 - 250.0,
			"y": float(anchor["y"]) + rng.randf() * 500.0 - 250.0}
	return KarmaUtils.nudge_dry(state, pt)


static func spawn_company(state: Dictionary, x: float, y: float) -> void:
	(state["agents"] as Array).append(mk_agent({"speciesKey": state["speciesKey"],
		"hp": float(state["sp"]["maxHp"]), "x": x, "y": y, "saved": false}))


static func distant_pt(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var best: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
	var bd: float = -1.0
	var ptx: float = float(KarmaState.px(state))
	var pty: float = float(KarmaState.py(state))
	var hunters: Array = predator_agents(state)
	for i in 5:
		var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
		var px: float = float(pt["x"])
		var py: float = float(pt["y"])
		var d: float = Vector2(px, py).distance_to(Vector2(ptx, pty))
		for h in hunters:
			d = minf(d, Vector2(px, py).distance_to(Vector2(float(h["x"]), float(h["y"]))))
		if d > bd:
			bd = d
			best = pt
	return best


static func respawn_missing(state: Dictionary, rng: RandomNumberGenerator) -> void:
	var targets: Dictionary = {}
	if state.has("census"):
		targets = ((state["census"] as Dictionary)["counts"] as Dictionary).duplicate()
	else:
		for fk in (KarmaData.POP["faunaFloor"] as Dictionary):
			targets[str(fk)] = fauna_count(str(fk))
	var player_sk: String = str(state["speciesKey"])
	var counts: Dictionary = {}
	for a in state["agents"] as Array:
		var sk: String = str(a.get("speciesKey", ""))
		counts[sk] = int(counts.get(sk, 0)) + 1
	for k in targets:
		var n: int = int(counts.get(str(k), 0))
		if n < int(targets[k]):
			var pt: Dictionary = distant_pt(state, rng)
			spawn_fauna(state, str(k), float(pt["x"]), float(pt["y"]))


static func eff_speed(state: Dictionary) -> float:
	var swift: float = 1.15 if KarmaShop.has_adapt(state, "swift") else 1.0
	var _edad: float = 0.0
	var _p: Variant = player(state)
	if _p != null:
		_edad = float((_p as Dictionary).get("edad", 0.0))
	else:
		_edad = float(state.get("edad", 0.0))
	return float(state["sp"]["speed"]) * swift * KarmaData.speed_mult_for(str(state.get("speciesKey", "raton")), _edad)


static func eff_vision(state: Dictionary) -> float:
	var _thermal: float = 0.0
	var _vp: Variant = player(state)
	if _vp != null:
		_thermal = float((_vp as Dictionary).get("thermalT", 0.0))
	else:
		_thermal = float(state.get("thermalT", 0.0))
	return float(state["sp"]["vision"]) + (50.0 if KarmaShop.has_adapt(state, "nose") else 0.0) + (float(KarmaData.TUNING["thermalVision"]) if _thermal > 0.0 else 0.0)


static func eff_max_hp_for(target: Dictionary) -> float:
	var base: float = KarmaData.SPECIES.get(str(target.get("speciesKey", "raton")), {}).get("maxHp", 100.0)
	return base + (25.0 if KarmaShop.has_adapt(target, "stomach") else 0.0)


static func eff_size(state: Dictionary) -> int:
	if str(state["speciesKey"]) == "raton":
		return 1
	return int(state["sp"]["size"])


static func diet_hint(state: Dictionary) -> void:
	if float(KarmaState.player(state).get("dietHintT", 0.0)) > 0.0:
		return
	KarmaState.player(state)["dietHintT"] = float(KarmaData.TUNING["dietHintCd"])
	add_log(state, null, "Los %ss comen %s" % [str(state["sp"]["name"]).to_lower(), str(KarmaData.DIET_HINT[state["speciesKey"]])])


static func tracked_carrion(state: Dictionary) -> Variant:
	if float(KarmaState.player(state).get("trackT", 0.0)) <= 0.0:
		return null
	return KarmaUtils.nearest_from(float(KarmaState.px(state)), float(KarmaState.py(state)), state.get("carrions", []), 9999.0)


static func reincarnate(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not bool(state.get("dead", false)):
		return state
	var next: String = str(state.get("pendingNext", "raton"))
	var carry_karma: float = roundf(float(state.get("karma", 0.0)) * 0.2)
	var carry_pa: float = float(state.get("pa", 0.0))
	return possess_or_spawn(state, next, carry_karma, carry_pa, int(state.get("saplings", 0)), rng)


static func possess_or_spawn(state: Dictionary, next: String, carry_karma: float, carry_pa: float, carry_saplings: int, rng: RandomNumberGenerator) -> Dictionary:
	var sp: Dictionary = KarmaData.SPECIES[next]
	var host: Variant = null
	for a in (state["agents"] as Array):
		if str(a.get("speciesKey", "")) == next and str(a.get("brain", "")) != "PLAYER":
			host = a
			break
	var at: Dictionary
	if host != null:
		at = {"x": (host as Dictionary)["x"], "y": (host as Dictionary)["y"]}
		(state["agents"] as Array).erase(host)
	else:
		at = KarmaUtils.scatter_dry(state, 1, rng)[0]
		if not KarmaUtils.skips_water(next, false):
			KarmaUtils.nudge_dry(state, at)
	var keep: Array[String] = ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks", "insects",
		"refuges", "carrions", "agents", "seedlings", "rocks", "waters"]
	var fresh: Dictionary = blank_state(next, carry_karma, carry_pa)
	for k in keep:
		fresh[k] = state[k]
	if state.has("census"):
		fresh["census"] = state["census"]
	fresh["saplings"] = 0
	# Ensure a same-species agent exists to possess; spawn one if the world has none.
	var has_host: bool = false
	for a in (fresh["agents"] as Array):
		if str(a.get("speciesKey", "")) == next and str(a.get("brain", "")) != "PLAYER":
			has_host = true
			break
	if not has_host:
		(fresh["agents"] as Array).append(mk_agent({"speciesKey": next, "brain": "AI",
			"hp": float(sp["maxHp"]), "x": float(at["x"]), "y": float(at["y"])}))
	possess_member(fresh)
	var pp: Variant = player(fresh)
	if pp != null:
		(pp as Dictionary)["x"] = float(at["x"])
		(pp as Dictionary)["y"] = float(at["y"])
	var extra: int = mini(carry_saplings, int(KarmaData.TUNING["saplingCap"]))
	for pt in KarmaUtils.scatter_dry(fresh, extra, rng):
		(fresh["bushes"] as Array).append(KarmaUtils.mk_patch("berries", pt["x"], pt["y"], 3))
	return fresh


static func refuge_fits(state: Dictionary, r: Dictionary) -> bool:
	if eff_size(state) > int(r["maxSize"]):
		return false
	if bool(r.get("climbOnly", false)) and not bool(state["sp"].get("climb", false)):
		return false
	if bool(r.get("orugaOnly", false)) and str(state["speciesKey"]) != "oruga":
		return false
	return true


static func toggle_hide(state: Dictionary) -> bool:
	if bool(state.get("dead", false)):
		return false
	if bool(KarmaState.player(state).get("hidden", false)):
		KarmaState.player(state)["hidden"] = false
		KarmaState.player(state)["hideRef"] = null
		add_log(state, null, "Sales del escondite")
		return true
	var hr: float = float(KarmaData.TUNING["hideRange"])
	var hr2: float = hr * hr
	var ptx: float = float(KarmaState.px(state))
	var pty: float = float(KarmaState.py(state))
	var near: Array = []
	for r in state["refuges"] as Array:
		var dx: float = float(r["x"]) - ptx
		var dy: float = float(r["y"]) - pty
		if dx * dx + dy * dy <= hr2:
			near.append(r)
	if near.is_empty():
		return false
	var fit: Variant = null
	for r in near:
		if refuge_fits(state, r):
			fit = r
			break
	if fit == null:
		add_log(state, null, "No cabes aquí (tamaño %d)" % eff_size(state))
		return false
	KarmaState.player(state)["hidden"] = true
	KarmaState.player(state)["hideRef"] = fit
	add_log(state, null, "Te escondes (%s)" % str((fit as Dictionary)["type"]))
	return true


static func try_shout(state: Dictionary) -> bool:
	if bool(state.get("dead", false)) or float(KarmaState.player(state).get("shoutCd", 0.0)) > 0.0:
		return false
	if str(state["speciesKey"]) in ["oruga", "halcon", "zorro"]:
		add_log(state, null, "Esta forma no avisa a nadie.")
		return false
	if bool(KarmaState.player(state).get("hidden", false)):
		KarmaState.player(state)["hidden"] = false
		KarmaState.player(state)["hideRef"] = null
	KarmaState.player(state)["shoutCd"] = float(KarmaData.TUNING["shoutCooldown"])
	KarmaState.player(state)["lureTimer"] = 5.0
	add_karma(state, null, float(KarmaData.TUNING["shoutKarma"]), "Alerta a tu especie (+karma, atrae 5s)")
	add_pa(state, null, float(KarmaData.TUNING["shoutPa"]))
	for m in company_agents(state):
		m["saved"] = true
	return true


static func add_karma(state: Dictionary, agent: Variant, n: float, msg: String = "") -> void:
	var t: Dictionary = agent if agent != null else state
	t["karma"] = clampf(float(t.get("karma", 0.0)) + n, -100.0, 100.0)
	if msg.is_empty():
		return
	(t.get("lifeLog", []) as Array).append(msg)
	if agent != null:
		(state.get("otherFeed", []) as Array).append(msg)
	else:
		(state.get("feed", []) as Array).append(msg)


static func add_pa(state: Dictionary, agent: Variant, n: float) -> void:
	var t: Dictionary = agent if agent != null else state
	t["pa"] = float(t.get("pa", 0.0)) + n


static func add_log(state: Dictionary, agent: Variant, msg: String) -> void:
	if agent != null:
		((agent as Dictionary).get("lifeLog", []) as Array).append(msg)
		(state.get("otherFeed", []) as Array).append(msg)
	else:
		(state.get("lifeLog", []) as Array).append(msg)
		(state.get("feed", []) as Array).append(msg)


static func ai_try_shout(state: Dictionary, agent: Dictionary) -> bool:
	if float(agent.get("shoutCd", 0.0)) > 0.0:
		return false
	if str(agent.get("speciesKey", "")) in ["oruga", "halcon", "zorro"]:
		return false
	agent["shoutCd"] = float(KarmaData.TUNING["shoutCooldown"])
	agent["lureTimer"] = float(KarmaData.TUNING["aiShoutLureTime"])
	var label: String = str(KarmaData.SPECIES.get(str(agent.get("speciesKey", "")), {}).get("name", agent.get("speciesKey", "")))
	add_karma(state, agent, float(KarmaData.TUNING["shoutKarma"]), "Grito de %s (+karma)" % label.to_lower())
	add_pa(state, agent, float(KarmaData.TUNING["shoutPa"]))
	for m in company_agents(state):
		m["saved"] = true
	return true
