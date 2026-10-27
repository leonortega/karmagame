class_name KarmaUtils
extends RefCounted

# Port of src/script/utils.js — pure helpers taking an explicit state Dictionary.


static func rng() -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.randomize()
	return r


static func scatter(n: int, rng: RandomNumberGenerator, margin: float = 120.0) -> Array[Dictionary]:
	var pts: Array[Dictionary] = []
	var w: float = KarmaData.WORLD["w"]
	var h: float = KarmaData.WORLD["h"]
	for i in n:
		pts.append({"x": margin + rng.randf() * (w - margin * 2.0), "y": margin + rng.randf() * (h - margin * 2.0)})
	return pts


static func mk_patch(kind: String, x: float, y: float, amount: int, extra: Dictionary = {}) -> Dictionary:
	var p: Dictionary = {"kind": kind, "x": x, "y": y, "amount": amount, "alive": true}
	for k in extra:
		p[k] = extra[k]
	return p


static func area_scale() -> float:
	return float(KarmaData.WORLD["w"]) * float(KarmaData.WORLD["h"]) / float(KarmaData.BASE_AREA)


static func scaled_count(base: int) -> int:
	return maxi(1, roundi(float(base) * area_scale()))


# Squared distance between two points. Use for range comparisons to skip the sqrt.
static func dist2(ax: float, ay: float, bx: float, by: float) -> float:
	var dx: float = ax - bx
	var dy: float = ay - by
	return dx * dx + dy * dy


static func nearest_from(ax: float, ay: float, list: Array, max_d: float) -> Variant:
	var best: Variant = null
	var bd: float = max_d * max_d
	for o in list:
		if o == null:
			continue
		var dx: float = ax - float(o["x"])
		var dy: float = ay - float(o["y"])
		var d: float = dx * dx + dy * dy
		if d < bd:
			bd = d
			best = o
	return best


static func nearest_hunter_in_fears(ax: float, ay: float, list: Array, fears: Array, max_d: float) -> Variant:
	var best: Variant = null
	var bd: float = max_d * max_d
	for o in list:
		if o == null:
			continue
		if not str(o.get("speciesKey", "")) in fears:
			continue
		var dx: float = ax - float(o["x"])
		var dy: float = ay - float(o["y"])
		var d: float = dx * dx + dy * dy
		if d < bd:
			bd = d
			best = o
	return best


static func fmt_time(s: float) -> String:
	var m: int = int(s / 60.0)
	var ss: int = int(s) % 60
	return "%d:%02d" % [m, ss]


static func thirstier(t: Dictionary) -> bool:
	return (100.0 - float(t.get("sed", 100.0))) >= (100.0 - float(t.get("hambre", 100.0)))


static func nearest_water_for(state: Dictionary, ax: float, ay: float, max_d: float) -> Variant:
	var best: Variant = null
	var bd: float = max_d
	for w in state.get("waters", []):
		if float(w.get("level", 1.0)) <= 0.0:
			continue
		var r: float = float(w["r"])
		var lim: float = bd + r
		if lim < 0.0:
			continue
		var dx: float = ax - float(w["x"])
		var dy: float = ay - float(w["y"])
		var d2: float = dx * dx + dy * dy
		if d2 < lim * lim:
			bd = sqrt(d2) - r
			best = w
	return best


static func inside_water(state: Dictionary, x: float, y: float, margin: float = 0.0) -> bool:
	for w in state.get("waters", []):
		var dx: float = x - float(w["x"])
		var dy: float = y - float(w["y"])
		var r: float = float(w["r"]) + margin
		if dx * dx + dy * dy < r * r:
			return true
	return false


static func nudge_dry(state: Dictionary, pt: Dictionary, dry_margin: float = 0.0) -> Dictionary:
	for _pass in 10:
		var moved: bool = false
		for w in state.get("waters", []):
			var dx: float = float(pt["x"]) - float(w["x"])
			var dy: float = float(pt["y"]) - float(w["y"])
			var d: float = Vector2(dx, dy).length()
			var min_d: float = float(w["r"]) + dry_margin + 0.5
			if d < min_d:
				if d == 0.0:
					pt["x"] = float(w["x"]) + min_d
				else:
					pt["x"] = float(w["x"]) + dx / d * min_d
					pt["y"] = float(w["y"]) + dy / d * min_d
				moved = true
		if not moved:
			break
	pt["x"] = clampf(float(pt["x"]), 20.0, float(KarmaData.WORLD["w"]) - 20.0)
	pt["y"] = clampf(float(pt["y"]), 20.0, float(KarmaData.WORLD["h"]) - 20.0)
	return pt


static func scatter_dry(state: Dictionary, n: int, rng: RandomNumberGenerator, dry_margin: float = 0.0) -> Array[Dictionary]:
	var pts: Array[Dictionary] = []
	for i in n:
		var best: Dictionary = scatter(1, rng)[0]
		for t in 12:
			if not inside_water(state, float(best["x"]), float(best["y"]), dry_margin):
				break
			best = scatter(1, rng)[0]
		if inside_water(state, float(best["x"]), float(best["y"]), dry_margin):
			nudge_dry(state, best, dry_margin)
		pts.append(best)
	return pts


# Needs tick shared player/AI: stocks always drain; hp regens only above both
# thresholds, otherwise drains with capped deficit. Damage is applied elsewhere.
static func update_needs(t: Dictionary, max_hp: float, dt: float) -> void:
	t["hambre"] = clampf(float(t.get("hambre", 100.0)) - KarmaData.hunger_rate_for(str(t.get("speciesKey", "raton"))) * dt, 0.0, 100.0)
	t["sed"] = clampf(float(t.get("sed", 100.0)) - KarmaData.thirst_rate_for(str(t.get("speciesKey", "raton"))) * dt, 0.0, 100.0)
	t["edad"] = float(t.get("edad", 0.0)) + dt
	if KarmaData.is_natural_death(str(t.get("speciesKey", "raton")), float(t["edad"])):
		t["hp"] = 0.0
		return
	if float(t["hambre"]) > float(KarmaData.TUNING["regenHambre"]) and float(t["sed"]) > float(KarmaData.TUNING["regenSed"]):
		var regen: float = float(KarmaData.TUNING["vidaRegenPerSec"]) * KarmaData.regen_mult_for(str(t.get("speciesKey", "raton")), float(t.get("edad", 0.0)))
		t["hp"] = minf(max_hp, float(t.get("hp", max_hp)) + regen * dt)
		return
	var deficit: float = minf((100.0 - float(t["hambre"])) / 100.0 + (100.0 - float(t["sed"])) / 100.0, float(KarmaData.TUNING["deficitMax"]))
	t["hp"] = float(t.get("hp", max_hp)) - KarmaData.hunger_rate_for(str(t.get("speciesKey", "raton"))) * (1.0 + deficit) * dt


static func tick_cooldowns(t: Dictionary, keys: Array, dt: float) -> void:
	for k in keys:
		if float(t.get(k, 0.0)) > 0.0:
			t[k] = float(t[k]) - dt


static func tick_verb_cds(t: Dictionary, dt: float) -> void:
	if not t.has("verbCds"):
		return
	var cds: Array = t["verbCds"]
	for i in cds.size():
		if float(cds[i]) > 0.0:
			cds[i] = float(cds[i]) - dt


static func solid_radius(refuge_type: String) -> float:
	if refuge_type == "old-oak" or refuge_type == "hollow-tree":
		return float(KarmaData.TUNING["solidRefuge"]) + 4.0
	return float(KarmaData.TUNING["solidRefuge"])


static func collect_solids(state: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in state.get("refuges", []):
		# Scent marks, threads, shadows, and wallows warn or snare; they never block.
		if str(r.get("type", "")) in ["scent-post", "silk-thread", "shadow-disc", "wallow", "foam-ring"]:
			continue
		out.append({"x": r["x"], "y": r["y"], "r": solid_radius(str(r["type"]))})
	for key in KarmaState.FLORA_KEYS:
		if key == "clumps":
			continue
		var extra: float = 2.0 if key == "oaks" else 0.0
		for p in state.get(key, []):
			if bool(p.get("alive", false)) and int(p.get("amount", 0)) > 0:
				out.append({"x": p["x"], "y": p["y"], "r": float(KarmaData.TUNING["solidPlant"]) + extra})
	for k in state.get("rocks", []):
		out.append({"x": k["x"], "y": k["y"], "r": float(KarmaData.TUNING["solidRock"]), "rock": true})
	for w in state.get("waters", []):
		out.append({"x": w["x"], "y": w["y"], "r": float(w["r"]), "water": true})
	return out


static func skips_water(species_key: String, grounded: bool) -> bool:
	if bool(KarmaData.WATER_ENTER.get(species_key, false)):
		return true
	return species_key == "halcon" and not grounded


# agent: {x, y, r, skipRock, skipWater} + set_pos Callable(pos: Vector2) or Dictionary ref.
static func resolve_collisions(state: Dictionary, pos: Vector2, radius: float, skip_rock: bool, skip_water: bool, solids: Array = []) -> Vector2:
	var list: Array = solids if not solids.is_empty() else collect_solids(state)
	var p: Vector2 = pos
	for s in list:
		if skip_rock and bool(s.get("rock", false)):
			continue
		if skip_water and bool(s.get("water", false)):
			continue
		var dx: float = p.x - float(s["x"])
		var dy: float = p.y - float(s["y"])
		var d2: float = dx * dx + dy * dy
		var min_d: float = float(s["r"]) + radius
		if d2 >= min_d * min_d or d2 == 0.0:
			continue
		var dir: Vector2 = (p - Vector2(float(s["x"]), float(s["y"]))) / sqrt(d2)
		p = Vector2(float(s["x"]), float(s["y"])) + dir * min_d
	return p


static func los_blocked(state: Dictionary, fx: float, fy: float, tx: float, ty: float, flying: bool, solids: Array = []) -> bool:
	if flying:
		return false
	var list: Array = solids if not solids.is_empty() else collect_solids(state)
	for s in list:
		if bool(s.get("water", false)):
			continue
		if float(s["r"]) < float(KarmaData.TUNING["solidRefuge"]):
			continue
		for i in range(1, int(KarmaData.TUNING["losSamples"])):
			var t: float = float(i) / float(KarmaData.TUNING["losSamples"])
			var px: float = fx + (tx - fx) * t
			var py: float = fy + (ty - fy) * t
			var dx: float = px - float(s["x"])
			var dy: float = py - float(s["y"])
			if dx * dx + dy * dy < float(s["r"]) * float(s["r"]):
				return true
	return false
