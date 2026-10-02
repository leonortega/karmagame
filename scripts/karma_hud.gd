class_name KarmaHud
extends RefCounted

# Port of src/script/hud.js data builders (DOM writes live in main.gd).


static func other_panel_lines(state: Dictionary) -> Array:
	var lines: Array = []
	for a in (state.get("agents", []) as Array).slice(0, 8):
		var sp: Variant = KarmaData.SPECIES.get(str(a.get("speciesKey", "")), null)
		if sp == null:
			lines.append("")
			continue
		var last: String = str((a.get("lifeLog", []) as Array).slice(-1)[0]) if not (a.get("lifeLog", []) as Array).is_empty() else ""
		lines.append("%s %s k:%d hp:%d%s" % [KarmaDraw.species_icon(str(a.get("speciesKey", ""))), str((sp as Dictionary)["name"]),
			int(round(float(a.get("karma", 0.0)))), int(ceil(float(a.get("hp", 0.0)))),
			(" · " + last) if not last.is_empty() else ""])
	return lines


static func control_rows(state: Dictionary) -> Array:
	var sk := str(state["speciesKey"])
	var rows: Array = [{"key": "WASD/Flechas", "label": "moverse", "cd": 0.0}]
	var e_cd := 0.0
	var e_extra := ""
	if sk == "zorro" and float(state.get("pounceCd", 0.0)) > 0.0:
		e_cd = float(state["pounceCd"])
	if sk == "topo":
		if float(state.get("digCd", 0.0)) > 0.0:
			e_cd = float(state["digCd"])
		e_extra = " (%d/%d)" % [int(state.get("dug", 0)), int(KarmaData.TUNING["digMax"])]
	rows.append({"key": "E", "label": str(KarmaData.CONTROLS_E.get(sk, "comer/cazar")) + e_extra, "cd": e_cd})
	if sk in KarmaData.CONTROLS_Q:
		rows.append({"key": "Q", "label": "gritar", "cd": float(state.get("shoutCd", 0.0))})
	if KarmaData.CONTROLS_V.has(sk):
		rows.append({"key": "V", "label": str(KarmaData.CONTROLS_V[sk]), "cd": float(state.get("senseCd", 0.0))})
	if sk in KarmaData.CONTROLS_C:
		var nut := " (nuez en lomo: C enterrar)" if bool(state.get("carriedNut", false)) else ""
		rows.append({"key": "C", "label": "llevar/enterrar" + nut, "cd": 0.0})
	rows.append({"key": "H", "label": "salir (hambre y sed siguen)" if bool(state.get("hidden", false)) else "esconderse", "cd": 0.0})
	rows.append({"key": "B", "label": "tienda (1-3 comprar)", "cd": 0.0})
	return rows


static func verb_rows(state: Dictionary) -> Array:
	var defs: Array = KarmaData.VERB_DEFS.get(str(state["speciesKey"]), [])
	var out: Array = []
	for i in defs.size():
		var v: Dictionary = defs[i]
		out.append({"slot": v["slot"], "name": v["name"], "desc": v["desc"],
			"cd": float((state["verbCds"] as Array)[i]), "poor": float(state.get("pa", 0.0)) < float(v["costPa"])})
	return out


static func edad_line(state: Dictionary) -> String:
	return "Edad %ds (~%.1f años)" % [int(state.get("edad", 0.0)), KarmaData.animal_years(str(state["speciesKey"]), float(state.get("edad", 0.0)))]


static func bar(frac: float, width := 10) -> String:
	var fill := int(round(clampf(frac, 0.0, 1.0) * float(width)))
	return "■".repeat(fill) + "□".repeat(maxi(0, width - fill))


static func hp_frac(state: Dictionary) -> float:
	return KarmaDraw.hp_frac(float(state.get("hp", 0.0)), KarmaState.eff_max_hp(state))


static func hunger_frac(state: Dictionary) -> float:
	return clampf(float(state.get("hambre", 0.0)) / 100.0, 0.0, 1.0)


static func thirst_frac(state: Dictionary) -> float:
	return clampf(float(state.get("sed", 0.0)) / 100.0, 0.0, 1.0)


static func prompt_line(state: Dictionary) -> String:
	if bool(state.get("hidden", false)):
		return "Oculto — H salir · hambre y sed siguen drenando"
	var near := (state.get("refuges", []) as Array).filter(func(r): return Vector2(float(r["x"]), float(r["y"])).distance_to(Vector2(float(state["px"]), float(state["py"]))) <= float(KarmaData.TUNING["hideRange"]))
	var fit: Variant = null
	for r in near:
		if KarmaState.refuge_fits(state, r):
			fit = r
			break
	if fit != null:
		return "H esconderse (%s)" % str((fit as Dictionary)["type"])
	if not near.is_empty():
		return "No cabes aquí (tamaño %d)" % KarmaState.eff_size(state)
	return ""
