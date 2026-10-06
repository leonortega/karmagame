class_name KarmaJev
extends RefCounted

# Facade: shared JEV plumbing + delegates to per-species bridges.
# Zorro logic lives in KarmaJevZorro, halcon in KarmaJevHalcon,
# raton in KarmaJevRaton. This file keeps the old API stable.

const SCHEMA_VERSION := "jev-zorro/v1"
const QUESTION := "Que hace el zorro ahora? Elige un candidato."
const HALCON_QUESTION := "Que hace el halcon ahora? Elige un candidato."
const USE_JEV := true
const USE_JEV_HALCON := true
const USE_JEV_RATON := true
const USE_JEV_ARDILLA := true
static var LOG_JEV_ZORRO := false
static var LOG_JEV_HALCON := false
static var LOG_JEV_RATON := false
static var LOG_JEV_ARDILLA := true
const JEV_URL := "http://192.168.100.80:8766/api/evaluate"
const JEV_LOG_CAP := 200
const JEV_LOG_PATH := "user://logs/jev_zorro.log"
const MACRO_EVERY := 1.0
const MACRO_EVERY_FAR := 3.0


static func schema_for(species: String) -> String:
	return "jev-%s/v1" % species


static func jev_log_path_for(species: String) -> String:
	return "user://logs/jev_%s.log" % species


static func log_enabled(species: String) -> bool:
	match species:
		"zorro":
			return LOG_JEV_ZORRO
		"halcon":
			return LOG_JEV_HALCON
		"raton":
			return LOG_JEV_RATON
		"ardilla":
			return LOG_JEV_ARDILLA
	return false


static func log_key_for(species: String) -> String:
	return "jev_log_%s" % species


const JEV_POLL_PATH := "user://logs/jev_poll.json"


static func poll_note(state: Dictionary, event: String, species: String = "") -> void:
	if not state.has("jev_poll"):
		state["jev_poll"] = {"busy_skip": 0, "sent": {}, "error": 0}
	var p := state["jev_poll"] as Dictionary
	match event:
		"busy_skip":
			p["busy_skip"] = int(p["busy_skip"]) + 1
		"sent":
			(p["sent"] as Dictionary)[species] = int((p["sent"] as Dictionary).get(species, 0)) + 1
		"error":
			p["error"] = int(p["error"]) + 1


static func mark_served(state: Dictionary, species: String) -> void:
	if not state.has("jev_last_served"):
		state["jev_last_served"] = {}
	(state["jev_last_served"] as Dictionary)[species] = float(state.get("time", 0.0))


static func appraise_emocion(snapshot: Dictionary, kind: String) -> String:
	if bool(snapshot.get("threatened", false)):
		return "Miedo"
	if kind in ["bury_nut", "carry_nut"] or bool(snapshot.get("carriedNut", false)):
		return "Esperanza"
	if bool(snapshot.get("hungry", false)):
		return "Hambre"
	return ""


static func intent_tick(a: Dictionary, dt: float) -> void:
	if not a.has("jev_intent"):
		return
	(a["jev_intent"] as Dictionary)["ttl"] = float((a["jev_intent"] as Dictionary).get("ttl", 0.0)) - dt


static func format_jev_error(code: int, body_text: String) -> String:
	var snippet := body_text.strip_edges().left(300)
	return "JEV request failed code=%d body=%s" % [code, snippet]


static func ensure_log_ready(path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if FileAccess.file_exists(path):
		return true
	var seed := FileAccess.open(path, FileAccess.WRITE)
	if seed == null:
		return false
	seed.close()
	return true


static func lod_interval(state: Dictionary, a: Dictionary, view_diag: float) -> float:
	var d := Vector2(float(a["x"]), float(a["y"])).distance_to(Vector2(float(state["px"]), float(state["py"])))
	return MACRO_EVERY_FAR if d > view_diag * 0.5 else MACRO_EVERY


static func should_ask(state: Dictionary, a: Dictionary, now: float, view_diag: float) -> bool:
	if not a.has("jev_intent") or (a.get("jev_intent", {}) as Dictionary).is_empty():
		return true
	if not _reask_ready(a, now):
		return now >= float(a.get("jev_next", 0.0))
	if KarmaAI.is_hungry(a) and not bool(a.get("jev_was_hungry", false)) and str((a.get("jev_intent", {}) as Dictionary).get("kind", "")) in ["wander", ""]:
		return true
	if KarmaAI.is_hunted(state, a) and str((a.get("jev_intent", {}) as Dictionary).get("kind", "")) != "flee":
		return true
	if (state["carrions"] as Array).size() > int(a.get("jev_carrion_n", 0)):
		return true
	return now >= float(a.get("jev_next", 0.0))


static func _reask_ready(a: Dictionary, now: float) -> bool:
	return now - float(a.get("jev_last_asked", -1e9)) >= float(KarmaData.TUNING["jevReaskBackoff"])


static func mark_asked(state: Dictionary, a: Dictionary, view_diag: float) -> void:
	var now := float(state.get("time", 0.0))
	var stagger := fmod(abs(float(a.get("x", 0.0)) + float(a.get("y", 0.0))), 0.5)
	a["jev_next"] = now + lod_interval(state, a, view_diag) + stagger
	a["jev_carrion_n"] = (state["carrions"] as Array).size()
	a["jev_was_hungry"] = KarmaAI.is_hungry(a)
	a["jev_last_asked"] = now


static func pick_batch_species(zorro_due: bool, halcon_due: bool, last: String) -> String:
	if zorro_due and halcon_due:
		return "halcon" if last == "zorro" else "zorro"
	if zorro_due:
		return "zorro"
	if halcon_due:
		return "halcon"
	return ""


static func pick_batch_species_3(zorro_due: bool, halcon_due: bool, raton_due: bool, last: String) -> String:
	var order := ["zorro", "halcon", "raton"]
	var due := {"zorro": zorro_due, "halcon": halcon_due, "raton": raton_due}
	var start := (order.find(last) + 1) % order.size() if order.has(last) else 0
	for i in order.size():
		var species: String = order[(start + i) % order.size()]
		if bool(due[species]):
			return species
	return ""


static func pick_batch_species_4(zorro_due: bool, halcon_due: bool, raton_due: bool, ardilla_due: bool, last: String, served: Dictionary = {}) -> String:
	var order := ["zorro", "halcon", "raton", "ardilla"]
	var due := {"zorro": zorro_due, "halcon": halcon_due, "raton": raton_due, "ardilla": ardilla_due}
	var start := (order.find(last) + 1) % order.size() if order.has(last) else 0
	var best := ""
	var best_t := 1e18
	for i in order.size():
		var species: String = order[(start + i) % order.size()]
		if bool(due[species]) and float(served.get(species, -1e9)) < best_t:
			best = species
			best_t = float(served.get(species, -1e9))
	return best


static func log_decision(state: Dictionary, snapshot: Dictionary, menu: Array, answer: Dictionary, applied: bool, species: String = "zorro", agent_id: String = "") -> void:
	if not log_enabled(species):
		return
	var key := log_key_for(species)
	if not state.has(key):
		state[key] = []
	var kinds: Array = menu.map(func(c): return str((c as Dictionary).get("kind", c)))
	var labels: Array = menu.map(func(c): return str((c as Dictionary).get("label", "")))
	var idx := int(answer.get("choice", -1))
	var picked := str(kinds[idx]) if idx >= 0 and idx < kinds.size() else "?"
	var entry := {
		"schema": schema_for(species),
		"t": float(snapshot.get("t", state.get("time", 0.0))),
		"summary": "%s chose %s from [%s] hp=%.2f applied=%s" % [species, picked, ",".join(kinds), float(snapshot.get("hp_frac", 0.0)), str(applied)],
		"snapshot": snapshot,
		"menu": kinds,
		"labels": labels,
		"choice": idx,
		"probs": answer.get("probs", []),
		"emocion": str(answer.get("emocion", "")),
		"emocion_source": str(answer.get("emocion_source", "")),
		"intent_keys": answer.get("intent_keys", []),
		"applied": applied,
		"agent": agent_id,
	}
	(state[key] as Array).append(entry)
	while (state[key] as Array).size() > JEV_LOG_CAP:
		(state[key] as Array).remove_at(0)
	if species == "zorro":
		if not state.has("jev_log"):
			state["jev_log"] = []
		(state["jev_log"] as Array).append(entry)
		while (state["jev_log"] as Array).size() > JEV_LOG_CAP:
			(state["jev_log"] as Array).remove_at(0)


static func parse_answers(response: Dictionary, menus: Dictionary) -> Dictionary:
	var out := {}
	for st in response.get("states", []):
		var req_id := str((st as Dictionary).get("id", ""))
		if not menus.has(req_id):
			continue
		var menu: Array = menus[req_id] as Array
		var kinds := candidate_ids(menu)
		var wander := maxi(0, menu.size() - 1)
		var intent: Dictionary = ((st as Dictionary).get("answers", {}) as Dictionary).get("intent", {})
		var pick := str(intent.get("choice", "wander"))
		var choice := kinds.find(pick)
		if choice < 0:
			choice = wander
		out[req_id] = {"choice": choice, "kind": pick, "probs": intent.get("probabilities", {}), "emocion": str(intent.get("emocion", intent.get("emotion", ""))), "intent_keys": intent.keys(), "emocion_source": "ranker" if intent.has("emocion") or intent.has("emotion") else "local"}
	return out


# --- Zorro delegates (stable API) ---

static func zorro_definition() -> Dictionary:
	return KarmaJevZorro.zorro_definition()


static func build_menu(state: Dictionary, a: Dictionary) -> Array:
	return KarmaJevZorro.build_menu(state, a)


static func build_state(state: Dictionary, a: Dictionary) -> Dictionary:
	return KarmaJevZorro.build_state(state, a)


static func build_batch(state: Dictionary) -> Array:
	return KarmaJevZorro.build_batch(state)


static func mock_choice(menu: Array) -> int:
	return KarmaJevZorro.mock_choice(menu)


static func mock_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevZorro.mock_macro(state, a)


static func apply_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	return KarmaJevZorro.apply_answer(state, a, menu, answer)


static func all_jev_zorros(state: Dictionary) -> Array:
	return KarmaJevZorro.all_jev_zorros(state)


static func candidate_ids(menu: Array) -> Array:
	return KarmaJevZorro.candidate_ids(menu)


static func state_text(state: Dictionary, a: Dictionary) -> String:
	return KarmaJevZorro.state_text(state, a)


static func build_http_body(state: Dictionary) -> Dictionary:
	return KarmaJevZorro.build_http_body(state)


static func build_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevZorro.build_http_body_for(state, agents)


# --- Halcon delegates (stable API) ---

static func halcon_definition() -> Dictionary:
	return KarmaJevHalcon.halcon_definition()


static func build_halcon_menu(state: Dictionary, a: Dictionary) -> Array:
	return KarmaJevHalcon.build_halcon_menu(state, a)


static func build_halcon_state(state: Dictionary, a: Dictionary) -> Dictionary:
	return KarmaJevHalcon.build_halcon_state(state, a)


static func all_jev_halcons(state: Dictionary) -> Array:
	return KarmaJevHalcon.all_jev_halcons(state)


static func halcon_state_text(state: Dictionary, a: Dictionary) -> String:
	return KarmaJevHalcon.halcon_state_text(state, a)


static func build_halcon_http_body(state: Dictionary) -> Dictionary:
	return KarmaJevHalcon.build_halcon_http_body(state)


static func build_halcon_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevHalcon.build_halcon_http_body_for(state, agents)


static func halcon_mock_choice(menu: Array) -> int:
	return KarmaJevHalcon.halcon_mock_choice(menu)


static func mock_halcon_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevHalcon.mock_halcon_macro(state, a)


static func apply_halcon_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	return KarmaJevHalcon.apply_halcon_answer(state, a, menu, answer)


# --- Raton delegates ---

static func raton_definition() -> Dictionary:
	return KarmaJevRaton.raton_definition()


static func build_raton_menu(state: Dictionary, a: Dictionary) -> Array:
	return KarmaJevRaton.build_menu(state, a)


static func build_raton_state(state: Dictionary, a: Dictionary) -> Dictionary:
	return KarmaJevRaton.build_state(state, a)


static func all_jev_ratons(state: Dictionary) -> Array:
	return KarmaJevRaton.all_jev_ratons(state)


static func raton_state_text(state: Dictionary, a: Dictionary) -> String:
	return KarmaJevRaton.state_text(state, a)


static func build_raton_http_body(state: Dictionary) -> Dictionary:
	return KarmaJevRaton.build_http_body(state)


static func build_raton_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevRaton.build_http_body_for(state, agents)


static func raton_mock_choice(menu: Array) -> int:
	return KarmaJevRaton.mock_choice(menu)


static func mock_raton_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevRaton.mock_macro(state, a)


static func apply_raton_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	return KarmaJevRaton.apply_answer(state, a, menu, answer)


# --- Ardilla delegates ---

static func ardilla_definition() -> Dictionary:
	return KarmaJevArdilla.ardilla_definition()


static func build_ardilla_menu(state: Dictionary, a: Dictionary) -> Array:
	return KarmaJevArdilla.build_menu(state, a)


static func build_ardilla_state(state: Dictionary, a: Dictionary) -> Dictionary:
	return KarmaJevArdilla.build_state(state, a)


static func all_jev_ardillas(state: Dictionary) -> Array:
	return KarmaJevArdilla.all_jev_ardillas(state)


static func ardilla_state_text(state: Dictionary, a: Dictionary) -> String:
	return KarmaJevArdilla.state_text(state, a)


static func build_ardilla_http_body(state: Dictionary) -> Dictionary:
	return KarmaJevArdilla.build_http_body(state)


static func build_ardilla_http_body_for(state: Dictionary, agents: Array) -> Dictionary:
	return KarmaJevArdilla.build_http_body_for(state, agents)


static func ardilla_mock_choice(menu: Array) -> int:
	return KarmaJevArdilla.mock_choice(menu)


static func mock_ardilla_macro(state: Dictionary, a: Dictionary) -> bool:
	return KarmaJevArdilla.mock_macro(state, a)


static func apply_ardilla_answer(state: Dictionary, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	return KarmaJevArdilla.apply_answer(state, a, menu, answer)
