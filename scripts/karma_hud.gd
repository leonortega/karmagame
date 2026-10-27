class_name KarmaHud
extends RefCounted

# Port of src/script/hud.js data builders (DOM writes live in main.gd).

const STAGE_LABEL := {"prime": "joven", "worn": "maduro", "frail": "frágil"}


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
	var sk: String = str(state["speciesKey"])
	var rows: Array = [{"key": "WASD/Flechas", "label": "moverse", "cd": 0.0}]
	var e_cd: float = 0.0
	var e_extra: String = ""
	if sk == "zorro" and float(KarmaState.player(state).get("pounceCd", 0.0)) > 0.0:
		e_cd = float(KarmaState.player(state)["pounceCd"])
	if sk == "topo":
		if float(KarmaState.player(state).get("digCd", 0.0)) > 0.0:
			e_cd = float(KarmaState.player(state)["digCd"])
		e_extra = " (%d/%d)" % [int(state.get("dug", 0)), int(KarmaData.TUNING["digMax"])]
	rows.append({"key": "E", "label": str(KarmaData.CONTROLS_E.get(sk, "comer/cazar")) + e_extra, "cd": e_cd})
	if sk in KarmaData.CONTROLS_Q:
		rows.append({"key": "Q", "label": "gritar", "cd": float(KarmaState.player(state).get("shoutCd", 0.0))})
	if KarmaData.CONTROLS_V.has(sk):
		rows.append({"key": "V", "label": str(KarmaData.CONTROLS_V[sk]), "cd": float(KarmaState.player(state).get("senseCd", 0.0))})
	if sk in KarmaData.CONTROLS_C:
		var nut: String = " (nuez en lomo: C enterrar)" if bool(KarmaState.player(state).get("carriedNut", false)) else ""
		rows.append({"key": "C", "label": "llevar/enterrar" + nut, "cd": 0.0})
	rows.append({"key": "H", "label": "salir (hambre y sed siguen)" if bool(KarmaState.player(state).get("hidden", false)) else "esconderse", "cd": 0.0})
	rows.append({"key": "B", "label": "tienda (1-3 comprar)", "cd": 0.0})
	return rows


static func verb_rows(state: Dictionary) -> Array:
	var defs: Array = KarmaData.VERB_DEFS.get(str(state["speciesKey"]), [])
	var out: Array = []
	for i in defs.size():
		var v: Dictionary = defs[i]
		out.append({"slot": v["slot"], "name": v["name"], "desc": v["desc"],
			"cd": float((KarmaState.player(state)["verbCds"] as Array)[i]), "poor": float(state.get("pa", 0.0)) < float(v["costPa"])})
	return out


static func shop_modal_rows(state: Dictionary) -> Array:
	var out: Array = []
	for it in KarmaShop.catalog_for(str(state.get("speciesKey", "raton"))):
		var owned: bool = KarmaShop.has_adapt(state, str(it["effect"]))
		var afford: bool = float(state.get("pa", 0.0)) >= float(it["cost"])
		var mark: String = "✔ " if owned else ("✓ " if afford else "🔒 ")
		out.append("%s[%s] %s (%d PA) — %s" % [mark, str(it["key"]), str(it["name"]), int(it["cost"]), str(it["desc"])])
	return out


static func birth_blocks(pool: Array, highlight_key: String) -> Array:
	var out: Array = []
	for k in pool:
		var kk: String = str(k)
		var mark: String = "▶ " if kk == highlight_key else "· "
		out.append("%s%s %s" % [mark, KarmaDraw.species_icon(kk), str(KarmaData.SPECIES.get(kk, {"name": kk})["name"])])
	return out


static func judgment_summary(state: Dictionary) -> String:
	var feed: Array = state.get("lifeLog", [])
	var tail: Array = feed.slice(maxi(0, feed.size() - 4))
	var lines: Array = []
	lines.append("Karma %d · %ss · %s" % [int(state.get("karma", 0.0)), KarmaUtils.fmt_time(float(state.get("time", 0.0))), str(state.get("judgeReason", ""))])
	lines.append("Ultimos: %s" % (" | ".join(tail) if not tail.is_empty() else "—"))
	return "\n".join(lines)


static func edad_line(state: Dictionary) -> String:
	var secs: float = float(KarmaState.player(state).get("edad", 0.0))
	var sk: String = str(state["speciesKey"])
	var line: String = "Edad %ds (~%.1f años)" % [int(secs), KarmaData.animal_years(sk, secs)]
	return line + " · %s" % str(STAGE_LABEL.get(KarmaData.age_stage(sk, secs), "joven"))


static func bar(frac: float, width: int = 10) -> String:
	var fill: int = int(round(clampf(frac, 0.0, 1.0) * float(width)))
	return "■".repeat(fill) + "□".repeat(maxi(0, width - fill))


static func hp_frac(state: Dictionary) -> float:
	return KarmaDraw.hp_frac(float(KarmaState.player(state).get("hp", 0.0)), KarmaState.eff_max_hp_for(state))


static func hunger_frac(state: Dictionary) -> float:
	return clampf(float(KarmaState.player(state).get("hambre", 0.0)) / 100.0, 0.0, 1.0)


static func thirst_frac(state: Dictionary) -> float:
	return clampf(float(KarmaState.player(state).get("sed", 0.0)) / 100.0, 0.0, 1.0)


static func weather_line(state: Dictionary) -> String:
	var w: Dictionary = state.get("weather", {})
	return "🌧️ Lluvia" if bool(w.get("raining", false)) else ""


static func prompt_line(state: Dictionary) -> String:
	if bool(KarmaState.player(state).get("hidden", false)):
		return "Oculto — H salir · hambre y sed siguen drenando"
	var px: float = float(KarmaState.px(state))
	var py: float = float(KarmaState.py(state))
	var hide_range: float = float(KarmaData.TUNING["hideRange"])
	var near: Array = []
	for r in state.get("refuges", []):
		if KarmaUtils.dist2(float(r["x"]), float(r["y"]), px, py) <= hide_range * hide_range:
			near.append(r)
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
