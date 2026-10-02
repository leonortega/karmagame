class_name KarmaState
extends RefCounted

# Port of src/script/state.js — world state as a plain Dictionary.
# UI rendering lives in main.gd; this file keeps simulation + ledger rules.

const FLORA_BASE := {"berries": 7, "apples": 3, "carrots": 2, "mushrooms": 4, "leaves": 4, "nuts": 2}
const FLORA_KIND := {"berries": "bushes", "apples": "shrubs", "carrots": "patches", "mushrooms": "clusters", "leaves": "clumps", "nuts": "oaks"}


static func flora_cap(kind: String) -> int:
	return KarmaUtils.scaled_count(int(FLORA_BASE.get(kind, 2)))


static func blank_state(species_key: String, karma: float, pa: float) -> Dictionary:
	var sp: Dictionary = KarmaData.SPECIES[species_key]
	return {
		"speciesKey": species_key, "sp": sp,
		"px": float(KarmaData.WORLD["w"]) / 2.0, "py": float(KarmaData.WORLD["h"]) / 2.0,
		"face": {"x": 1.0, "y": 0.0}, "moved": false,
		"hp": float(sp["maxHp"]), "karma": karma,
		"hambre": 100.0, "sed": 100.0, "edad": 0.0,
		"pa": pa, "saplings": 0,
		"time": 0.0, "dead": false, "paAcc": 0.0,
		"shoutCd": 0.0, "invuln": 0.0, "lureTimer": 0.0, "strikeCd": 0.0,
		"verbCds": [0.0, 0.0, 0.0, 0.0, 0.0],
		"pounceCd": 0.0, "digCd": 0.0, "dug": 0, "senseCd": 0.0, "revealT": 0.0, "trackT": 0.0,
		"groomT": 0.0, "groomCd": 0.0, "stillT": 0.0, "curlCd": 0.0, "dietHintT": 0.0, "thermalT": 0.0,
		"carriedNut": false, "larder": 0, "stash": 0,
		"hidden": false, "hideRef": null, "bristled": false,
		"grounded": false, "landT": 0.0,
		"cam": {"x": 0.0, "y": 0.0},
		"agents": [], "possessed": 0,
		"lifeLog": [], "feed": [], "otherFeed": [],
		"owned": {}, "shopOpen": false,
		"pendingNext": null, "pendingPool": null,
		"mateT": 0.0, "insectT": 0.0, "respawnT": 0.0,
		"hambreWarned": false, "sedWarned": false,
		"escortT": 0.0, "escortTarget": null,
		"bushes": [], "shrubs": [], "patches": [], "clusters": [], "clumps": [], "oaks": [],
		"insects": [], "seedlings": [], "rocks": [], "waters": [], "refuges": [], "carrions": [],
	}


static func new_run(species_key: String, carry_karma := 0.0, carry_pa := 0.0, carry_saplings := 0, rng: RandomNumberGenerator = null) -> Dictionary:
	var r := rng if rng != null else KarmaUtils.rng()
	var state := blank_state(species_key, carry_karma, carry_pa)
	seed_food(state, carry_saplings, r)
	seed_foes(state, state["sp"], r)
	seed_company(state, r)
	state["carrions"] = []
	add_log(state, null, "Naces como %s T%d" % [str(state["sp"]["name"]), int(state["sp"]["tier"])])
	return state


static func seed_waters(state: Dictionary, rng: RandomNumberGenerator) -> void:
	state["waters"] = []
	for pt in KarmaUtils.scatter(KarmaUtils.scaled_count(int(KarmaData.TUNING["charcoCount"])), rng):
		(state["waters"] as Array).append({"kind": "charco", "x": pt["x"], "y": pt["y"], "r": float(KarmaData.TUNING["charcoR"])})
	for pt in KarmaUtils.scatter(KarmaUtils.scaled_count(int(KarmaData.TUNING["lagoCount"])), rng):
		(state["waters"] as Array).append({"kind": "lago", "x": pt["x"], "y": pt["y"], "r": float(KarmaData.TUNING["lagoR"])})


static func seed_food(state: Dictionary, carry_saplings: int, rng: RandomNumberGenerator) -> void:
	seed_waters(state, rng)
	var extra: int = mini(carry_saplings, int(KarmaData.TUNING["saplingCap"]))
	state["bushes"] = []
	var i := 0
	for pt in KarmaUtils.scatter_dry(state, flora_cap("berries") + extra, rng):
		(state["bushes"] as Array).append(KarmaUtils.mk_patch("berries", pt["x"], pt["y"], 3, {"mimic": i % 3 == 2, "mimicEaten": false}))
		i += 1
	state["shrubs"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("apples"), rng):
		(state["shrubs"] as Array).append(KarmaUtils.mk_patch("apples", pt["x"], pt["y"], 2))
	state["patches"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("carrots"), rng):
		(state["patches"] as Array).append(KarmaUtils.mk_patch("carrots", pt["x"], pt["y"], 3))
	state["clusters"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("mushrooms"), rng):
		(state["clusters"] as Array).append(KarmaUtils.mk_patch("mushrooms", pt["x"], pt["y"], 2, {"toxicLeft": 1 if rng.randf() < 0.5 else 0, "toxicEaten": false}))
	state["clumps"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("leaves"), rng):
		(state["clumps"] as Array).append(KarmaUtils.mk_patch("leaves", pt["x"], pt["y"], 3, {"regrowT": 0.0}))
	state["oaks"] = []
	for pt in KarmaUtils.scatter_dry(state, flora_cap("nuts"), rng):
		(state["oaks"] as Array).append(KarmaUtils.mk_patch("nuts", pt["x"], pt["y"], 3))
	state["insects"] = []
	for k in KarmaUtils.scaled_count(6):
		(state["insects"] as Array).append(KarmaGame.spawn_insect_pt(state, rng))
	state["seedlings"] = []
	state["rocks"] = []
	for pt in KarmaUtils.scatter_dry(state, KarmaUtils.scaled_count(int(KarmaData.TUNING["rockCount"])), rng):
		(state["rocks"] as Array).append({"x": pt["x"], "y": pt["y"]})


static func seed_foes(state: Dictionary, sp: Dictionary, rng: RandomNumberGenerator) -> void:
	var table: Array = (KarmaData.TIER_SPAWNS.get(int(sp["tier"]), KarmaData.TIER_SPAWNS[1]) as Array).duplicate()
	var reps: int = maxi(1, roundi(KarmaUtils.area_scale()))
	for r in reps:
		for t in table:
			var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
			(state["agents"] as Array).append(mk_agent(KarmaPredators.mk_predator(state, str(t), float(pt["x"]), float(pt["y"]), int(sp["tier"]))))


static func mk_agent(a: Dictionary) -> Dictionary:
	var base := {"brain": "AI", "kind": "grazer", "hp": 60.0, "hambre": 100.0, "sed": 100.0, "edad": 0.0,
		"larder": 0, "karma": 0.0, "pa": 0.0, "owned": {}, "lifeLog": [], "verbCds": [0.0, 0.0, 0.0, 0.0, 0.0]}
	for k in a:
		base[k] = a[k]
	return base


static func company_agents(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("role", "")) == "company")


static func hunter_agents(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("role", "")) == "hunter")


static func fauna_agents(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("role", "")) == "fauna")


static func all_hunters(state: Dictionary) -> Array:
	return (state["agents"] as Array).filter(func(a): return str(a.get("kind", "")) == "hunter")


static func remove_agent(state: Dictionary, a: Dictionary) -> void:
	(state["agents"] as Array).erase(a)


static func player_agent(state: Dictionary) -> Dictionary:
	return {"id": state.get("possessed", 0), "speciesKey": state["speciesKey"], "x": state["px"], "y": state["py"],
		"hp": state["hp"], "brain": "PLAYER"}


static func seed_company(state: Dictionary, rng: RandomNumberGenerator) -> void:
	for i in int(KarmaData.POP["company"]):
		var pt := {"x": float(state["px"]) + (rng.randf() * 200.0 - 100.0), "y": float(state["py"]) + (rng.randf() * 200.0 - 100.0)}
		KarmaUtils.nudge_dry(state, pt)
		(state["agents"] as Array).append(mk_agent({"role": "company", "speciesKey": state["speciesKey"],
			"hp": float(state["sp"]["maxHp"]), "x": pt["x"], "y": pt["y"], "saved": false}))
	seed_fauna(state, rng)
	state["refuges"] = []
	for r in KarmaData.REFUGES:
		for pt in KarmaUtils.scatter_dry(state, KarmaUtils.scaled_count(int(r["count"])), rng):
			(state["refuges"] as Array).append({"type": r["type"], "maxSize": r["maxSize"],
				"climbOnly": bool(r.get("climbOnly", false)), "x": pt["x"], "y": pt["y"], "dug": false})


static func fauna_count(k: String) -> int:
	return maxi(1, roundi(float((KarmaData.POP["faunaFloor"] as Dictionary).get(k, 0)) * KarmaUtils.area_scale() / 4.0))


static func spawn_fauna(state: Dictionary, k: String, x: float, y: float) -> Dictionary:
	var carnivore: bool = (KarmaData.DIET[k] as Array).has("mates")
	var a := mk_agent({"role": "fauna", "speciesKey": k, "hp": float(KarmaData.SPECIES[k]["maxHp"]), "x": x, "y": y,
		"face": {"x": 1.0, "y": 0.0}, "kind": "hunter" if carnivore else "grazer"})
	if carnivore:
		a["type"] = k
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
	for k in (KarmaData.POP["faunaFloor"] as Dictionary):
		for i in fauna_count(str(k)):
			var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
			spawn_fauna(state, str(k), float(pt["x"]), float(pt["y"]))


static func distant_pt(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var best: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
	var bd := -1.0
	for i in 5:
		var pt: Dictionary = KarmaUtils.scatter_dry(state, 1, rng)[0]
		var d := Vector2(float(pt["x"]), float(pt["y"])).distance_to(Vector2(float(state["px"]), float(state["py"])))
		for h in all_hunters(state):
			d = minf(d, Vector2(float(pt["x"]), float(pt["y"])).distance_to(Vector2(float(h["x"]), float(h["y"]))))
		if d > bd:
			bd = d
			best = pt
	return best


static func respawn_missing(state: Dictionary, rng: RandomNumberGenerator) -> void:
	for k in (KarmaData.POP["faunaFloor"] as Dictionary):
		var n := (state["agents"] as Array).filter(func(a): return str(a.get("speciesKey", "")) == str(k)).size()
		if str(state["speciesKey"]) == str(k):
			n += 1
		if n < fauna_count(str(k)):
			var pt := distant_pt(state, rng)
			spawn_fauna(state, str(k), float(pt["x"]), float(pt["y"]))


static func eff_speed(state: Dictionary) -> float:
	return float(state["sp"]["speed"]) * (1.15 if KarmaShop.has_adapt(state, "swift") else 1.0)


static func eff_vision(state: Dictionary) -> float:
	return float(state["sp"]["vision"]) + (50.0 if KarmaShop.has_adapt(state, "nose") else 0.0) + (float(KarmaData.TUNING["thermalVision"]) if float(state.get("thermalT", 0.0)) > 0.0 else 0.0)


static func eff_max_hp(state: Dictionary) -> float:
	return eff_max_hp_for(state)


static func eff_max_hp_for(target: Dictionary) -> float:
	var base: float = KarmaData.SPECIES.get(str(target.get("speciesKey", "raton")), {}).get("maxHp", 100.0)
	return base + (25.0 if KarmaShop.has_adapt(target, "stomach") else 0.0)


static func eff_size(state: Dictionary) -> int:
	if str(state["speciesKey"]) == "raton":
		return 1
	return int(state["sp"]["size"])


static func diet_hint(state: Dictionary) -> void:
	if float(state.get("dietHintT", 0.0)) > 0.0:
		return
	state["dietHintT"] = float(KarmaData.TUNING["dietHintCd"])
	add_log(state, null, "Los %ss comen %s" % [str(state["sp"]["name"]).to_lower(), str(KarmaData.DIET_HINT[state["speciesKey"]])])


static func mimics_visible(state: Dictionary) -> Array:
	if not KarmaShop.has_adapt(state, "nose"):
		return []
	return (state["bushes"] as Array).filter(func(b):
		return bool(b.get("alive", false)) and bool(b.get("mimic", false)) and not bool(b.get("mimicEaten", false)) and Vector2(float(b["x"]), float(b["y"])).distance_to(Vector2(float(state["px"]), float(state["py"]))) <= eff_vision(state)
	)


static func toxics_visible(state: Dictionary) -> Array:
	if not KarmaShop.has_adapt(state, "nose"):
		return []
	return (state["clusters"] as Array).filter(func(c):
		return bool(c.get("alive", false)) and int(c.get("toxicLeft", 0)) > 0 and Vector2(float(c["x"]), float(c["y"])).distance_to(Vector2(float(state["px"]), float(state["py"]))) <= eff_vision(state)
	)


static func tracked_carrion(state: Dictionary) -> Variant:
	if float(state.get("trackT", 0.0)) <= 0.0:
		return null
	return KarmaUtils.nearest_from(float(state["px"]), float(state["py"]), state.get("carrions", []), 9999.0)


static func reincarnate(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not bool(state.get("dead", false)):
		return state
	var next := str(state.get("pendingNext", "raton"))
	var carry_karma := roundf(float(state.get("karma", 0.0)) * 0.2)
	var carry_pa := float(state.get("pa", 0.0))
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
	var keep := ["bushes", "shrubs", "patches", "clusters", "clumps", "oaks", "insects",
		"refuges", "carrions", "agents", "seedlings", "rocks", "waters"]
	var fresh := blank_state(next, carry_karma, carry_pa)
	for k in keep:
		fresh[k] = state[k]
	fresh["px"] = float(at["x"])
	fresh["py"] = float(at["y"])
	fresh["saplings"] = 0
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
	if bool(state.get("hidden", false)):
		state["hidden"] = false
		state["hideRef"] = null
		add_log(state, null, "Sales del escondite")
		return true
	var near := (state["refuges"] as Array).filter(func(r): return Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(float(state["px"]), float(state["py"]))) <= float(KarmaData.TUNING["hideRange"]))
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
	state["hidden"] = true
	state["hideRef"] = fit
	add_log(state, null, "Te escondes (%s)" % str((fit as Dictionary)["type"]))
	return true


static func try_shout(state: Dictionary) -> bool:
	if bool(state.get("dead", false)) or float(state.get("shoutCd", 0.0)) > 0.0:
		return false
	if str(state["speciesKey"]) in ["oruga", "halcon", "zorro"]:
		add_log(state, null, "Esta forma no avisa a nadie.")
		return false
	if bool(state.get("hidden", false)):
		state["hidden"] = false
		state["hideRef"] = null
	state["shoutCd"] = float(KarmaData.TUNING["shoutCooldown"])
	state["lureTimer"] = 5.0
	add_karma(state, null, float(KarmaData.TUNING["shoutKarma"]), "Alerta a tu especie (+karma, atrae 5s)")
	add_pa(state, null, float(KarmaData.TUNING["shoutPa"]))
	for m in company_agents(state):
		m["saved"] = true
	return true


static func add_karma(state: Dictionary, agent: Variant, n: float, msg := "") -> void:
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
	var label := str(KarmaData.SPECIES.get(str(agent.get("speciesKey", "")), {}).get("name", agent.get("speciesKey", "")))
	add_karma(state, agent, float(KarmaData.TUNING["shoutKarma"]), "Grito de %s (+karma)" % label.to_lower())
	add_pa(state, agent, float(KarmaData.TUNING["shoutPa"]))
	for m in company_agents(state):
		m["saved"] = true
	return true
