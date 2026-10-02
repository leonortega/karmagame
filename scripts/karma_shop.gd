class_name KarmaShop
extends RefCounted

# Port of shop.js logic (DOM-free). Rendering lives in main.gd.


static func pool_for(karma: float) -> Array:
	if karma <= float(KarmaData.TUNING["tierDownKarma"]):
		return ["oruga"]
	if karma >= float(KarmaData.TUNING["tierUpKarma"]):
		return KarmaData.T1POOL + KarmaData.T2POOL
	return KarmaData.T1POOL.duplicate()


static func draw_from(pool: Array, rng: RandomNumberGenerator) -> String:
	if pool.is_empty():
		return "raton"
	return str(pool[rng.randi() % pool.size()])


static func judge(state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var karma := float(state.get("karma", 0.0))
	var pool := pool_for(karma)
	var next := draw_from(pool, rng)
	var names: Array = []
	for k in pool:
		names.append(str(KarmaData.SPECIES[k]["name"]))
	var reason := ""
	if karma <= float(KarmaData.TUNING["tierDownKarma"]):
		reason = "Karma %d ≤ -50 → involución: los dioses te devuelven como Oruga." % int(karma)
	elif karma >= float(KarmaData.TUNING["tierUpKarma"]):
		reason = "Karma %d ≥ +50 → los dioses te abren el pool T1+T2 (%s)." % [int(karma), ", ".join(names)]
	else:
		reason = "Karma neutral (%d) → pool T1 (%s)." % [int(karma), ", ".join(names)]
	return {"pool": pool, "next": next, "reason": reason}


static func catalog_for(species_key: String) -> Array:
	return (KarmaData.SHOP_BY_SPECIES.get(species_key, []) as Array).duplicate()


static func adapt_effect(item_id: String) -> String:
	for k in KarmaData.SHOP_BY_SPECIES:
		for it in (KarmaData.SHOP_BY_SPECIES[k] as Array):
			if str(it["id"]) == item_id:
				return str(it["effect"])
	return item_id


static func has_adapt(t: Dictionary, effect: String) -> bool:
	var owned: Dictionary = t.get("owned", {})
	if not owned is Dictionary:
		return false
	if bool(owned.get(effect, false)):
		return true
	for id in owned:
		if bool(owned[id]) and adapt_effect(str(id)) == effect:
			return true
	return false


# Returns bought item or {} — mutates target ledger (player state or agent).
static func buy_item(state: Dictionary, target: Dictionary, item_id: String) -> Dictionary:
	if bool(state.get("dead", false)):
		return {}
	var item := {}
	for it in catalog_for(str(target.get("speciesKey", state.get("speciesKey", "raton")))):
		if str(it["id"]) == item_id:
			item = it
			break
	if item.is_empty():
		return {}
	var owned: Dictionary = target.get("owned", {})
	if bool(owned.get(item_id, false)):
		return {}
	if float(target.get("pa", 0.0)) < float(item["cost"]):
		return {}
	target["pa"] = float(target["pa"]) - float(item["cost"])
	owned[item_id] = true
	target["owned"] = owned
	if str(item["effect"]) == "stomach":
		target["hp"] = minf(KarmaState.eff_max_hp_for(target), float(target.get("hp", 0.0)) + 25.0)
	return item
