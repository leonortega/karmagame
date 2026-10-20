extends Node2D

# Karma MVP — Main scene. Simulation lives in Karma* classes; this node
# owns input, the tick, world rendering (_draw) and a minimal HUD.

# Display-only viewport geometry (must match project.godot window size).
const VIEW_W := 1280.0
const VIEW_H := 800.0
const PANEL_W := 264.0
const PANEL_MARGIN := 8.0
# _pill measures every visible label; font shaping is the expensive part.
# Cache widths once a frame draws enough labels to pay for the lookup, and clear
# on overflow so changing counts cannot grow the map without bound.
const LABEL_CACHE_MIN_CALLS := 24
const LABEL_CACHE_MAX := 200

var state: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _labels: Dictionary = {}
var _label_sizes: Dictionary = {}
var _label_font: Font = null
var _pill_calls: int = 0
var _jev_http: HTTPRequest
var _jev_busy: bool = false
# Single in-flight record: {species, agents, menus, snaps}. Only one species is
# ever in flight at a time; the record replaces the eight field groups so send,
# apply, and timeout all read the same shape.
var _jev_flight: Dictionary = {}
var _jev_flushed: Dictionary = {"zorro": 0, "halcon": 0, "raton": 0, "ardilla": 0, "sapo": 0, "topo": 0, "lobo": 0, "oruga": 0}
var _jev_last_species: String = "halcon"
var _jev_flush_t: float = 0.0
# HUD text changes slowly (cooldowns tick in whole seconds); rebuilding a dozen
# Label strings + forcing container re-layout every physics tick tanks FPS.
# Refresh at ~7Hz and skip labels whose text did not change.
var _hud_t: float = 0.0
var _hud_cache: Dictionary = {}
var _modal_dim: ColorRect
var _modal_panel: PanelContainer
var _birth_t: float = 0.0
var _judge_t: float = 0.0
var _last_modal: String = ""


func _ready() -> void:
	rng.randomize()
	var first: String = KarmaGame.draw_start_form(rng)
	state = KarmaState.new_run(first, 0.0, 0.0, 0, rng)
	state["introDone"] = false
	state["introNext"] = first
	_build_hud()
	_build_modal()
	_jev_http = HTTPRequest.new()
	_jev_http.timeout = 2.0
	add_child(_jev_http)
	_jev_http.request_completed.connect(_on_jev_done)
	set_process_unhandled_input(true)


func _jev_view_diag() -> float:
	return Vector2(VIEW_W, VIEW_H).length()


func _jev_poll() -> void:
	if _jev_busy:
		if not state.is_empty():
			KarmaJev.poll_note(state, "busy_skip")
		return
	if state.is_empty() or bool(state.get("dead", false)):
		return
	var now: float = float(state.get("time", 0.0))
	var view_diag: float = _jev_view_diag()
	var due: Array = _due_jev_agents(KarmaJev.all_jev_zorros(state) if KarmaJev.USE_JEV else [], now, view_diag)
	var h_due: Array = _due_jev_agents(KarmaJev.all_jev_halcons(state) if KarmaJev.USE_JEV_HALCON else [], now, view_diag)
	var r_due: Array = _due_jev_agents(KarmaJev.all_jev_ratons(state) if KarmaJev.USE_JEV_RATON else [], now, view_diag)
	var a_due: Array = _due_jev_agents(KarmaJev.all_jev_ardillas(state) if KarmaJev.USE_JEV_ARDILLA else [], now, view_diag)
	var s_due: Array = _due_jev_agents(KarmaJev.all_jev_sapos(state) if KarmaJev.USE_JEV_SAPO else [], now, view_diag)
	var t_due: Array = _due_jev_agents(KarmaJev.all_jev_topos(state) if KarmaJev.USE_JEV_TOPO else [], now, view_diag)
	var l_due: Array = _due_jev_agents(KarmaJev.all_jev_lobos(state) if KarmaJev.USE_JEV_LOBO else [], now, view_diag)
	var o_due: Array = _due_jev_agents(KarmaJev.all_jev_orugas(state) if KarmaJev.USE_JEV_ORUGA else [], now, view_diag)
	var due_by_species: Dictionary = {
		"zorro": due,
		"halcon": h_due,
		"raton": r_due,
		"ardilla": a_due,
		"sapo": s_due,
		"topo": t_due,
		"lobo": l_due,
		"oruga": o_due,
	}
	var species: String = KarmaJev.pick_batch_species_8(not due.is_empty(), not h_due.is_empty(), not r_due.is_empty(), not a_due.is_empty(), not s_due.is_empty(), not t_due.is_empty(), not l_due.is_empty(), not o_due.is_empty(), _jev_last_species, state.get("jev_last_served", {}))
	if species != "":
		_send_batch(species, due_by_species[species])


func _due_jev_agents(agents: Array, now: float, view_diag: float) -> Array:
	var due: Array = []
	for a in agents:
		if KarmaJev.should_ask(state, a, now, view_diag):
			due.append(a)
	return due


func _send_batch(species: String, due: Array) -> void:
	var body: Dictionary = _build_jev_body(species, due)
	if (body["states"] as Array).is_empty():
		var view_diag: float = _jev_view_diag()
		for a in due:
			KarmaJev.mark_asked(state, a, view_diag)
		return
	var agents: Array = body["agents"]
	_jev_flight = {
		"species": species,
		"agents": agents,
		"menus": body["menus"],
		"snaps": _build_jev_snapshot(species, agents),
	}
	for a in due:
		(a as Dictionary)["jev_live"] = true
	_jev_busy = true
	_jev_last_species = species
	KarmaJev.poll_note(state, "sent", species)
	KarmaJev.mark_served(state, species)
	_jev_http.request(KarmaJev.JEV_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"states": body["states"]}))


func _build_jev_body(species: String, due: Array) -> Dictionary:
	match species:
		"halcon":
			return KarmaJev.build_halcon_http_body_for(state, due)
		"raton":
			return KarmaJev.build_raton_http_body_for(state, due)
		"ardilla":
			return KarmaJev.build_ardilla_http_body_for(state, due)
		"sapo":
			return KarmaJev.build_sapo_http_body_for(state, due)
		"topo":
			return KarmaJev.build_topo_http_body_for(state, due)
		"lobo":
			return KarmaJev.build_lobo_http_body_for(state, due)
		"oruga":
			return KarmaJev.build_oruga_http_body_for(state, due)
		_:
			return KarmaJev.build_http_body_for(state, due)


func _build_jev_snapshot(species: String, agents: Array) -> Dictionary:
	var snaps: Dictionary = {}
	for i in agents.size():
		snaps[str(i)] = _build_jev_agent_state(species, agents[i])
	return snaps


func _build_jev_agent_state(species: String, a: Dictionary) -> Dictionary:
	match species:
		"halcon":
			return KarmaJev.build_halcon_state(state, a)
		"raton":
			return KarmaJev.build_raton_state(state, a)
		"ardilla":
			return KarmaJev.build_ardilla_state(state, a)
		"sapo":
			return KarmaJev.build_sapo_state(state, a)
		"topo":
			return KarmaJev.build_topo_state(state, a)
		"lobo":
			return KarmaJev.build_lobo_state(state, a)
		"oruga":
			return KarmaJev.build_oruga_state(state, a)
		_:
			return KarmaJev.build_state(state, a)


func _on_jev_done(result: int, code: int, _headers: PackedStringArray, raw: PackedByteArray) -> void:
	_jev_busy = false
	var raw_text: String = raw.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_error(KarmaJev.format_jev_error(code, raw_text))
		if not state.is_empty():
			state["jev_last_error"] = {"code": code, "body": raw_text.left(300)}
			KarmaJev.poll_note(state, "error")
		_clear_jev_flight()
		return
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null or not (parsed as Dictionary).has("states"):
		push_error(KarmaJev.format_jev_error(code, raw_text))
		if not state.is_empty():
			KarmaJev.poll_note(state, "error")
		_clear_jev_flight()
		return
	var valid: Dictionary = KarmaJev.parse_answers(parsed, _jev_flight.get("menus", {}))
	_apply_flight(valid)
	_clear_jev_flight()


func _apply_flight(valid: Dictionary) -> void:
	var species: String = _jev_flight.get("species", "zorro")
	var agents: Array = _jev_flight.get("agents", [])
	var menus: Dictionary = _jev_flight.get("menus", {})
	var snaps: Dictionary = _jev_flight.get("snaps", {})
	for rid in valid:
		var answer: Dictionary = valid[rid]
		if not rid.is_valid_int():
			continue
		var idx: int = rid.to_int()
		if idx < 0 or idx >= agents.size():
			continue
		var a: Dictionary = agents[idx]
		if not (state["agents"] as Array).has(a):
			continue
		var menu: Array = menus.get(rid, [])
		var snapshot: Dictionary = snaps.get(rid, _build_jev_agent_state(species, a))
		var applied: bool = _apply_jev_answer(species, a, menu, answer)
		KarmaJev.log_decision(state, snapshot, menu, answer, applied, species, _jev_log_agent_id(species, a))


func _apply_jev_answer(species: String, a: Dictionary, menu: Array, answer: Dictionary) -> bool:
	match species:
		"halcon":
			return KarmaJev.apply_halcon_answer(state, a, menu, answer)
		"raton":
			return KarmaJev.apply_raton_answer(state, a, menu, answer)
		"ardilla":
			return KarmaJev.apply_ardilla_answer(state, a, menu, answer)
		"sapo":
			return KarmaJev.apply_sapo_answer(state, a, menu, answer)
		"topo":
			return KarmaJev.apply_topo_answer(state, a, menu, answer)
		"lobo":
			return KarmaJev.apply_lobo_answer(state, a, menu, answer)
		"oruga":
			return KarmaJev.apply_oruga_answer(state, a, menu, answer)
		_:
			return KarmaJev.apply_answer(state, a, menu, answer)


func _jev_log_agent_id(species: String, a: Dictionary) -> String:
	if species in ["ardilla", "sapo", "topo", "lobo", "oruga"]:
		return "%s#%d" % [species, (state["agents"] as Array).find(a)]
	return ""


func _jev_flush_log() -> void:
	if state.is_empty():
		return
	for species in ["zorro", "halcon", "raton", "ardilla", "sapo", "topo", "lobo", "oruga"]:
		if not KarmaJev.log_enabled(species):
			continue
		var key: String = KarmaJev.log_key_for(species)
		var entries: Array = state.get(key, []) as Array
		var flushed: int = int(_jev_flushed.get(species, 0))
		if flushed >= entries.size():
			continue
		var path: String = KarmaJev.jev_log_path_for(species)
		if not KarmaJev.ensure_log_ready(path):
			push_error("JEV log open failed: " + path)
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
		if file == null:
			push_error("JEV log open failed: " + path)
			continue
		file.seek_end()
		while flushed < entries.size():
			file.store_line(JSON.stringify(entries[flushed]))
			flushed += 1
		_jev_flushed[species] = flushed
		file.close()
	if state.has("jev_poll"):
		var pf: FileAccess = FileAccess.open(KarmaJev.JEV_POLL_PATH, FileAccess.WRITE)
		if pf != null:
			pf.store_line(JSON.stringify({"t": float(state.get("time", 0.0)), "poll": state["jev_poll"], "census": KarmaJev.census(state), "red_flags": state.get("jev_red_flags", {})}))
			pf.close()


func _clear_jev_flight() -> void:
	if not state.is_empty():
		var view_diag: float = _jev_view_diag()
		for a in _jev_flight.get("agents", []):
			if (state["agents"] as Array).has(a):
				(a as Dictionary)["jev_live"] = false
				KarmaJev.mark_asked(state, a, view_diag)
	_jev_flight = {}


func _panel_style(accent: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.09, 0.92)
	sb.border_color = accent
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _make_side_panel(layer: CanvasLayer, panel_name: String, pos: Vector2, width: float) -> VBoxContainer:
	var frame: PanelContainer = PanelContainer.new()
	frame.name = panel_name
	# TOP_LEFT + absolute position keeps the panel inside the viewport
	# (VIEW_W x VIEW_H). (PRESET_TOP_RIGHT + positive x pushes it off-screen.)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = pos
	frame.custom_minimum_size = Vector2(width, 0)
	frame.add_theme_stylebox_override("panel", _panel_style(Color("#c9a227")))
	layer.add_child(frame)
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(width - 16, 0)
	box.add_theme_constant_override("separation", 4)
	frame.add_child(box)
	return box


func _add_hud_label(box: VBoxContainer, key: String, width: float, min_h: float) -> void:
	var l: Label = Label.new()
	l.name = key
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width - 16, min_h)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("#e8ede9"))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(l)
	_labels[key] = l


func _style_hud_label(key: String, size: int, color: Color) -> void:
	var l: Label = _labels[key] as Label
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)


func _build_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	# Left: other-animals feed. Right: status + controls + verbs + shop + log.
	# Center (~280..1000) stays clear so the world stays visible.
	var left: VBoxContainer = _make_side_panel(layer, "LeftPanel", Vector2(PANEL_MARGIN, PANEL_MARGIN), PANEL_W)
	_add_hud_label(left, "others_title", PANEL_W, 20.0)
	_add_hud_label(left, "others", PANEL_W, 120.0)
	var right: VBoxContainer = _make_side_panel(layer, "RightPanel", Vector2(VIEW_W - PANEL_W - PANEL_MARGIN, PANEL_MARGIN), PANEL_W)
	for key in ["species", "vitals", "karma", "edad", "weather", "prompt"]:
		_add_hud_label(right, key, PANEL_W, 20.0)
	_add_hud_label(right, "controls", PANEL_W, 110.0)
	_add_hud_label(right, "verbs", PANEL_W, 90.0)
	_add_hud_label(right, "shop", PANEL_W, 60.0)
	_add_hud_label(right, "log", PANEL_W, 60.0)
	_style_hud_label("species", 14, Color("#ffd54f"))
	_style_hud_label("karma", 13, Color("#ffd54f"))
	_style_hud_label("vitals", 12, Color("#ffffff"))
	_style_hud_label("edad", 11, Color("#b0bec5"))
	_style_hud_label("weather", 12, Color("#81d4fa"))
	_style_hud_label("prompt", 12, Color("#80deea"))
	_style_hud_label("controls", 12, Color("#dcedc8"))
	_style_hud_label("verbs", 12, Color("#dcedc8"))
	_style_hud_label("shop", 12, Color("#ffe0b2"))
	_style_hud_label("log", 11, Color("#b0bec5"))
	_style_hud_label("others_title", 13, Color("#ffd54f"))
	_style_hud_label("others", 11, Color("#cfd8dc"))


func _build_modal() -> void:
	var layer: CanvasLayer = get_node("HUD") as CanvasLayer
	_modal_dim = ColorRect.new()
	_modal_dim.name = "ModalDim"
	_modal_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dim.color = Color(0, 0, 0, 0.55)
	_modal_dim.visible = false
	layer.add_child(_modal_dim)
	_modal_panel = PanelContainer.new()
	_modal_panel.name = "ModalPanel"
	_modal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_modal_panel.custom_minimum_size = Vector2(460, 0)
	_modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffd54f")))
	_modal_panel.visible = false
	layer.add_child(_modal_panel)
	var modal_box: VBoxContainer = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 6)
	_modal_panel.add_child(modal_box)
	for key in ["modal_title", "modal_body", "modal_blocks", "modal_hint"]:
		var l: Label = Label.new()
		l.name = key
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(428, 0)
		l.add_theme_font_size_override("font_size", 13 if key != "modal_title" else 16)
		l.add_theme_color_override("font_color", Color("#ffd54f") if key == "modal_title" else Color("#e8ede9"))
		modal_box.add_child(l)
		_labels[key] = l
	var primary: Button = Button.new()
	primary.name = "modal_primary"
	primary.custom_minimum_size = Vector2(428, 28)
	modal_box.add_child(primary)
	_labels["modal_primary"] = primary
	primary.pressed.connect(_on_modal_primary)
	var close_b: Button = Button.new()
	close_b.name = "modal_close"
	close_b.text = "Cerrar (B/Esc)"
	close_b.custom_minimum_size = Vector2(428, 24)
	modal_box.add_child(close_b)
	_labels["modal_close"] = close_b
	close_b.pressed.connect(_on_modal_close)


func _modal_pool_for(state: Dictionary, modal: String) -> Array:
	if modal == "birth":
		return KarmaData.SPECIES.keys()
	if modal == "judgment":
		var p: Array = state.get("pendingPool", [])
		if p.is_empty():
			p = KarmaShop.pool_for(float(state.get("karma", 0.0)))
		return p
	return []


func _modal_next_for(state: Dictionary, modal: String) -> String:
	if modal == "birth":
		return str(state.get("introNext", state.get("speciesKey", "raton")))
	if modal == "judgment":
		return str(state.get("pendingNext", "raton"))
	return ""


func _refresh_modal() -> void:
	if _modal_dim == null or _modal_panel == null:
		return
	var modal: String = KarmaModals.active_modal(state)
	if modal != _last_modal:
		if modal == "birth":
			_birth_t = 0.0
		if modal == "judgment":
			_judge_t = 0.0
		_last_modal = modal
	var open: bool = modal != ""
	_modal_dim.visible = open
	_modal_panel.visible = open
	if not open:
		return
	var primary: Button = _labels["modal_primary"] as Button
	var close_b: Button = _labels["modal_close"] as Button
	if modal == "shop":
		_set_text("modal_title", "TIENDA — %s (PA %d)" % [str(state["sp"]["name"]), int(state.get("pa", 0.0))])
		_set_text("modal_body", "\n".join(KarmaHud.shop_modal_rows(state)))
		_set_text("modal_blocks", "")
		_set_text("modal_hint", "1-3 comprar · B/Esc cerrar")
		primary.text = "Cerrar (B)"
		close_b.visible = true
	elif modal == "birth":
		var pool: Array = _modal_pool_for(state, modal)
		var nxt: String = _modal_next_for(state, modal)
		var hl: String = KarmaModals.roulette_pick(pool, nxt, _birth_t)
		_set_text("modal_title", "KARMA")
		_set_text("modal_body", "los dioses han elegido que nazcas como:")
		_set_text("modal_blocks", "\n".join(KarmaHud.birth_blocks(pool, hl)))
		if _birth_t >= KarmaModals.SETTLE_AFTER:
			var sp: Dictionary = KarmaData.SPECIES.get(nxt, {"name": nxt, "tier": 1})
			_set_text("modal_hint", "Eres %s T%d · Espacio/Enter para empezar" % [str(sp["name"]), int(sp["tier"])])
		else:
			_set_text("modal_hint", "··· los dioses deciden ···")
		primary.text = "Empezar (Espacio)"
		close_b.visible = false
	elif modal == "judgment":
		var pool: Array = _modal_pool_for(state, modal)
		var nxt: String = _modal_next_for(state, modal)
		var hl: String = KarmaModals.roulette_pick(pool, nxt, _judge_t)
		_set_text("modal_title", "JUICIO")
		_set_text("modal_body", "los dioses han elegido que reencarnes como:\n" + KarmaHud.judgment_summary(state))
		_set_text("modal_blocks", "\n".join(KarmaHud.birth_blocks(pool, hl)))
		if _judge_t >= KarmaModals.SETTLE_AFTER or pool.size() <= 1:
			var sp: Dictionary = KarmaData.SPECIES.get(nxt, {"name": nxt, "tier": 1})
			_set_text("modal_hint", "Reencarnas en %s T%d · R para reencarnar" % [str(sp["name"]), int(sp["tier"])])
		else:
			_set_text("modal_hint", "··· los dioses deciden ···")
		primary.text = "Reincarnar (R)"
		close_b.visible = false
	elif modal == "pause":
		_set_text("modal_title", "PAUSA")
		_set_text("modal_body", "◆ %s T%d · PA %d · Karma %d" % [str(state["sp"]["name"]), int(state["sp"]["tier"]), int(state.get("pa", 0.0)), int(state.get("karma", 0.0))])
		_set_text("modal_blocks", "")
		_set_text("modal_hint", "WASD moverse · E comer · Q gritar · H esconderse · B tienda · 1-5 verbos · P/Esc seguir")
		primary.text = "Seguir (P/Esc)"
		close_b.visible = true


func _on_modal_primary() -> void:
	if state.is_empty():
		return
	var modal: String = KarmaModals.active_modal(state)
	if modal == "birth":
		state["introDone"] = true
	elif modal == "judgment":
		state = KarmaState.reincarnate(state, rng)
		_judge_t = 0.0
		_last_modal = KarmaModals.active_modal(state)
	elif modal == "pause":
		state["paused"] = false
	elif modal == "shop":
		state["shopOpen"] = false


func _on_modal_close() -> void:
	if state.is_empty():
		return
	var modal: String = KarmaModals.active_modal(state)
	if modal == "shop":
		state["shopOpen"] = false
	elif modal == "pause":
		state["paused"] = false


func _unhandled_input(event: InputEvent) -> void:
	if state.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ev: InputEventKey = event as InputEventKey
		var k: int = ev.physical_keycode
		if k == 0:
			k = ev.keycode
		var ch: String = String.chr(k).to_lower() if k >= 32 and k < 128 else ""
		# Number keys: Godot keycodes KEY_1..KEY_5.
		var num: int = -1
		if k >= KEY_1 and k <= KEY_5:
			num = int(k - KEY_0)
		var is_esc: bool = ev.keycode == KEY_ESCAPE or ev.physical_keycode == KEY_ESCAPE
		var is_enter: bool = ev.keycode == KEY_ENTER or ev.keycode == KEY_KP_ENTER or ev.physical_keycode == KEY_ENTER
		var is_space: bool = k == KEY_SPACE
		var modal: String = KarmaModals.active_modal(state)
		if modal == "judgment":
			if ch == "r":
				_on_modal_primary()
			return
		if modal == "birth":
			if is_space or is_enter:
				_on_modal_primary()
			return
		if modal == "pause":
			if ch == "p" or is_esc:
				state["paused"] = false
			return
		if modal == "shop":
			if ch == "b" or is_esc:
				state["shopOpen"] = false
				return
			if ch == "p":
				state["shopOpen"] = false
				state["paused"] = true
				return
			if num >= 1 and num <= 3:
				for it in KarmaShop.catalog_for(str(state["speciesKey"])):
					if str(it["key"]) == str(num):
						KarmaShop.buy_item(state, state, str(it["id"]))
			return
		match ch:
			"e":
				KarmaEat.try_eat(state)
			"q":
				KarmaState.try_shout(state)
			"h":
				KarmaState.toggle_hide(state)
			"v":
				KarmaEat.sense_pulse(state)
			"c":
				KarmaEat.carry_action(state)
			"b":
				state["shopOpen"] = true
			"p":
				state["paused"] = true
			"r":
				if bool(state.get("dead", false)):
					state = KarmaState.reincarnate(state, rng)
		if is_esc and not bool(state.get("dead", false)) and not bool(state.get("shopOpen", false)):
			state["paused"] = true
		if num >= 1 and num <= 5:
			KarmaGame.cast_verb(state, num)


func _physics_process(delta: float) -> void:
	if state.is_empty():
		return
	var dt: float = minf(delta, 0.05)
	var frozen: String = KarmaModals.active_modal(state)
	if frozen != "":
		if frozen == "birth":
			_birth_t += dt
		if frozen == "judgment":
			_judge_t += dt
		queue_redraw()
		_hud_t += dt
		if _hud_t >= 0.15:
			_hud_t = 0.0
			_refresh_hud()
		return
	if not bool(state.get("dead", false)):
		var axes: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# One solids snapshot per tick shared by movement + sim (see KarmaGame).
		var solids: Array = KarmaUtils.collect_solids(state)
		KarmaGame.move_player(state, axes.x, axes.y, dt, solids)
		KarmaGame.update(state, dt, rng, solids)
		_jev_poll()
		_jev_flush_t += dt
		if _jev_flush_t >= 0.5:
			_jev_flush_t = 0.0
			_jev_flush_log()
		state["cam"] = {"x": clampf(float(state["px"]) - VIEW_W / 2.0, 0.0, float(KarmaData.WORLD["w"]) - VIEW_W),
			"y": clampf(float(state["py"]) - VIEW_H / 2.0, 0.0, float(KarmaData.WORLD["h"]) - VIEW_H)}
	queue_redraw()
	# Movement + sim stay every physics tick (smooth 60fps motion); HUD is
	# text-only and refreshed on a timer instead.
	_hud_t += dt
	if _hud_t >= 0.15:
		_hud_t = 0.0
		_refresh_hud()


func _set_text(key: String, txt: String) -> void:
	if str(_hud_cache.get(key, "")) == txt:
		return
	_hud_cache[key] = txt
	(_labels[key] as Label).text = txt


func _refresh_hud() -> void:
	if _labels.is_empty():
		return
	_set_text("species", "◆ %s T%d · ⏱ %s" % [str(state["sp"]["name"]), int(state["sp"]["tier"]), KarmaUtils.fmt_time(float(state.get("time", 0.0)))])
	_set_text("vitals", "Vida %s %d/%d\nHambre %s %d\nSed %s %d" % [
		KarmaHud.bar(KarmaHud.hp_frac(state), 10), int(ceil(float(state.get("hp", 0.0)))), int(KarmaState.eff_max_hp(state)),
		KarmaHud.bar(KarmaHud.hunger_frac(state), 10), int(state.get("hambre", 0.0)),
		KarmaHud.bar(KarmaHud.thirst_frac(state), 10), int(state.get("sed", 0.0))])
	_set_text("karma", "◈ PA %d · Karma %d%s" % [int(state.get("pa", 0.0)), int(state.get("karma", 0.0)), " · MUERTO (R reencarnar)" if bool(state.get("dead", false)) else ""])
	_set_text("edad", KarmaHud.edad_line(state))
	_set_text("weather", KarmaHud.weather_line(state))
	_set_text("prompt", KarmaHud.prompt_line(state))
	_set_text("others_title", "▼ OTROS ANIMALES")
	_set_text("others", "\n".join(KarmaHud.other_panel_lines(state)))
	var crows: Array = []
	for c in KarmaHud.control_rows(state):
		var mark: String = "✓ " if float(c["cd"]) <= 0.0 else "⏳ "
		crows.append("%s%s %s%s" % [mark, str(c["key"]), str(c["label"]), (" (%ds)" % int(ceil(float(c["cd"])))) if float(c["cd"]) > 0.0 else ""])
	_set_text("controls", "\n".join(crows))
	var feed: Array = state.get("feed", [])
	_set_text("log", "\n".join(feed.slice(maxi(0, feed.size() - 4))))
	var rows: Array = []
	for v in KarmaHud.verb_rows(state):
		var mark: String = "✓ " if float(v["cd"]) <= 0.0 and not bool(v["poor"]) else ("⏳ " if float(v["cd"]) > 0.0 else "∅ ")
		rows.append("%s[%d] %s%s%s" % [mark, int(v["slot"]), str(v["name"]), (" (%ds)" % int(ceil(float(v["cd"])))) if float(v["cd"]) > 0.0 else "", " (sin PA)" if bool(v["poor"]) else ""])
	_set_text("verbs", "VERBOS:\n" + "\n".join(rows))
	if bool(state.get("shopOpen", false)):
		var srows: Array = []
		for it in KarmaShop.catalog_for(str(state["speciesKey"])):
			var owned: bool = KarmaShop.has_adapt(state, str(it["effect"]))
			var afford: bool = float(state.get("pa", 0.0)) >= float(it["cost"])
			var mark: String = "✔ " if owned else ("✓ " if afford else "🔒 ")
			srows.append("%s[%s] %s (%d PA)" % [mark, str(it["key"]), str(it["name"]), int(it["cost"])])
		_set_text("shop", "TIENDA (B cerrar):\n" + "\n".join(srows))
	else:
		_set_text("shop", "")
	_refresh_modal()


func _medal(pos: Vector2, radius: float, fill: Color, glyph: String, glyph_size: float, font: Font, outline: Color = Color(0, 0, 0, 0), ring_width: float = 0.0) -> void:
	draw_circle(pos + Vector2(2, 3), radius, KarmaDraw.SHADOW)
	draw_circle(pos, radius, fill)
	draw_arc(pos, radius - 1.0, 0, TAU, 32, KarmaDraw.RIM, 2.0)
	if ring_width > 0.0:
		draw_arc(pos, radius + 2.0, 0, TAU, 32, outline, ring_width)
	var w: float = maxf(radius * 2.0, 40.0) + 16.0
	draw_string(font, pos + Vector2(-w / 2.0, glyph_size * 0.35), glyph, HORIZONTAL_ALIGNMENT_CENTER, w, glyph_size, Color.WHITE)


func _sync_label_font(font: Font) -> void:
	if font == _label_font:
		return
	_label_font = font
	_label_sizes.clear()


func _uses_label_cache() -> bool:
	return _pill_calls > LABEL_CACHE_MIN_CALLS


func _measure_label(font: Font, text: String, fs: int, use_cache: bool) -> Vector2:
	if not use_cache:
		return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var key: String = "%s|%d" % [text, fs]
	if _label_sizes.has(key):
		return _label_sizes[key] as Vector2
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	if _label_sizes.size() >= LABEL_CACHE_MAX:
		_label_sizes.clear()
	_label_sizes[key] = size
	return size


func _pill(pos: Vector2, text: String, font: Font, fs: int, text_color: Color = Color("#ffffff")) -> void:
	_pill_calls += 1
	var size: Vector2 = _measure_label(font, text, fs, _uses_label_cache())
	var rect: Rect2 = Rect2(pos - Vector2(size.x / 2.0 + 5.0, 0), Vector2(size.x + 10.0, fs + 9.0))
	draw_rect(rect, KarmaDraw.PILL_BG)
	draw_rect(rect, Color(1, 1, 1, 0.18), false, 1.0)
	draw_string(font, rect.position + Vector2(5, fs + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)


func _hp_bar(pos: Vector2, w: float, frac: float) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(w / 2.0, 0), Vector2(w, 4.0))
	draw_rect(rect, KarmaDraw.PILL_BG)
	var f: float = clampf(frac, 0.0, 1.0)
	if f > 0.0:
		draw_rect(Rect2(rect.position, Vector2(w * f, 4.0)), KarmaDraw.hp_color(f))
	draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)


func _draw() -> void:
	if state.is_empty():
		return
	var cam: Vector2 = Vector2(float((state.get("cam", {"x": 0}) as Dictionary).get("x", 0.0)), float((state.get("cam", {"y": 0}) as Dictionary).get("y", 0.0)))
	var font: Font = ThemeDB.fallback_font
	_sync_label_font(font)
	_pill_calls = 0
	var t: float = float(state.get("time", 0.0))
	# Screen-space visible rect + margin: the world is 3200x2400 but the
	# viewport shows VIEW_W x VIEW_H. Skipping off-screen circles AND their
	# draw_string labels (font shaping is the expensive part) is the main
	# _draw win.
	var view: Rect2 = Rect2(Vector2(-48, -48), Vector2(VIEW_W + 96.0, VIEW_H + 96.0))
	# Meadow background + grid + vignette (screen-space: no Camera2D, the
	# world is manually shifted by -cam, so the backdrop sits at origin).
	draw_rect(Rect2(Vector2.ZERO, Vector2(VIEW_W, VIEW_H)), KarmaDraw.MEADOW_B)
	var step: float = KarmaDraw.GRID_STEP
	var gx: float = floorf(cam.x / step) * step
	while gx <= cam.x + VIEW_W:
		draw_line(Vector2(gx - cam.x, 0), Vector2(gx - cam.x, VIEW_H), KarmaDraw.GRID_LINE, 1.0)
		gx += step
	var gy: float = floorf(cam.y / step) * step
	while gy <= cam.y + VIEW_H:
		draw_line(Vector2(0, gy - cam.y), Vector2(VIEW_W, gy - cam.y), KarmaDraw.GRID_LINE, 1.0)
		gy += step
	for w in state.get("waters", []):
		var wpos: Vector2 = Vector2(float(w["x"]), float(w["y"])) - cam
		if not view.has_point(wpos):
			continue
		var body: Dictionary = KarmaDraw.water_disc(w)
		var wr: float = float(body["r"])
		draw_circle(wpos, wr + 5.0, KarmaDraw.SHORE)
		draw_circle(wpos, wr, KarmaDraw.DRY_BASIN)
		if not bool(body["dry"]):
			draw_circle(wpos, float(body["fill"]), body["color"])
			draw_arc(wpos, wr - 3.0, PI * 0.9, PI * 1.7, 24, Color(1, 1, 1, 0.25), 2.0)
		_medal(wpos, 11.0, Color(0, 0, 0, 0.25), KarmaDraw.water_icon(str(w.get("kind", ""))), 13.0, font)
		var wlabel: String = "seco" if bool(body["dry"]) else str(KarmaDraw.WATER_LABEL.get(str(w.get("kind", "")), "agua"))
		_pill(wpos + Vector2(0, wr + 16.0), wlabel, font, 11)
	for k in state.get("rocks", []):
		var kpos: Vector2 = Vector2(float(k["x"]), float(k["y"])) - cam
		if not view.has_point(kpos):
			continue
		draw_circle(kpos + Vector2(2, 3), 9.0, KarmaDraw.SHADOW)
		draw_circle(kpos, 9.0, KarmaDraw.ROCK_BODY)
		draw_circle(kpos + Vector2(-2, -2), 5.0, KarmaDraw.ROCK_TOP)
		_medal(kpos, 7.0, Color(0, 0, 0, 0.2), "🪨", 10.0, font)
	for r in state.get("refuges", []):
		var rpos: Vector2 = Vector2(float(r["x"]), float(r["y"])) - cam
		if not view.has_point(rpos):
			continue
		var rtype: String = str(r["type"])
		var rmedal: Color = KarmaDraw.refuge_medal(rtype)
		var rr: float = KarmaDraw.refuge_emoji_size(rtype) * 0.62 + 6.0
		_medal(rpos, rr, rmedal, KarmaDraw.refuge_icon(rtype), KarmaDraw.refuge_emoji_size(rtype), font)
		if rtype.begins_with("burrow"):
			draw_circle(rpos, rr * 0.55, Color(0, 0, 0, 0.55))
		if bool(state.get("hidden", false)) and state.get("hideRef") is Dictionary and Vector2(float((state["hideRef"] as Dictionary).get("x", -9999.0)), float((state["hideRef"] as Dictionary).get("y", -9999.0))).distance_to(Vector2(float(r["x"]), float(r["y"]))) < 1.0:
			draw_arc(rpos, rr + 3.0, 0, TAU, 32, Color("#80deea"), 2.0)
		_pill(rpos + Vector2(0, rr + 16.0), str(KarmaDraw.REFUGE_LABEL.get(rtype, rtype)), font, 11)
	for s in state.get("seedlings", []):
		var spos: Vector2 = Vector2(float(s["x"]), float(s["y"])) - cam
		if not view.has_point(spos):
			continue
		_medal(spos, 8.0, KarmaDraw.food_medal("leaves"), "🌱", 12.0, font)
	var mimics: Array = KarmaState.mimics_visible(state)
	var toxics: Array = KarmaState.toxics_visible(state)
	for key in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		for p in state.get(key, []):
			var kind: String = str(p.get("kind", key))
			var ppos: Vector2 = Vector2(float(p["x"]), float(p["y"])) - cam
			if not view.has_point(ppos):
				continue
			if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 0:
				_medal(ppos, 8.0, Color("#616161"), "✕", 12.0, font)
				_pill(ppos + Vector2(0, 24.0), "↻ recuperando", font, 11, Color("#b0bec5"))
				continue
			var trapped: bool = (bool(p.get("mimic", false)) and not bool(p.get("mimicEaten", false))) or int(p.get("toxicLeft", 0)) > 0
			var ring: Color = Color(0, 0, 0, 0)
			var ring_w: float = 0.0
			if mimics.has(p) or toxics.has(p):
				ring = Color("#ffd54f")
				ring_w = 2.0
			elif trapped:
				ring = KarmaDraw.RIM
				ring_w = 2.0
			_medal(ppos, 10.0, KarmaDraw.food_medal(kind), KarmaDraw.food_icon(kind), 18.0, font, ring, ring_w)
			_pill(ppos + Vector2(0, 26.0), "%s x%d" % [str(KarmaDraw.FOOD_LABEL.get(kind, kind)), int(p["amount"])], font, 11)
	var insects: Array = state.get("insects", [])
	for i in insects.size():
		var ins: Dictionary = insects[i]
		var ipos: Vector2 = Vector2(float(ins["x"]), float(ins["y"])) - cam
		if not view.has_point(ipos):
			continue
		ipos.y += sin(t * 4.0 + float(ins["x"]) * 0.13) * 1.5
		_medal(ipos, 7.0, KarmaDraw.INSECT_MEDAL, KarmaDraw.food_icon("insects"), 12.0, font)
	for c in state.get("carrions", []):
		var cpos: Vector2 = Vector2(float(c["x"]), float(c["y"])) - cam
		if not view.has_point(cpos):
			continue
		var stage: String = KarmaEat.carrion_stage(c)
		var look: Dictionary = KarmaDraw.carrion_look(stage)
		_medal(cpos, 10.0, look["meat"], KarmaDraw.carrion_icon(stage), 16.0, font)
		_pill(cpos + Vector2(0, 26.0), str(look["label"]), font, 11)
		if stage == "rotten":
			var wob: Vector2 = Vector2(sin(t * 6.0 + float(c["x"])), cos(t * 5.0 + float(c["y"]))) * 2.0
			draw_circle(cpos + Vector2(-6, -12) + wob, 1.5, Color("#212121"))
			draw_circle(cpos + Vector2(6, -10) - wob, 1.5, Color("#212121"))
	# Vision ring + agents + player.
	var pcenter: Vector2 = Vector2(float(state["px"]), float(state["py"])) - cam
	draw_arc(pcenter, KarmaState.eff_vision(state), 0, TAU, 64, Color(1, 1, 1, 0.22), 1.0)
	if float(state.get("thermalT", 0.0)) > 0.0:
		draw_arc(pcenter, KarmaState.eff_vision(state) + 6.0, 0, TAU, 64, Color("#ffd54f"), 1.5)
	if float(state.get("revealT", 0.0)) > 0.0:
		draw_arc(pcenter, KarmaState.eff_vision(state) * 0.5, 0, TAU, 48, Color("#80deea"), 1.5)
	var tracked: Variant = KarmaState.tracked_carrion(state)
	if tracked is Dictionary:
		var tpos: Vector2 = Vector2(float((tracked as Dictionary)["x"]), float((tracked as Dictionary)["y"])) - cam
		draw_line(pcenter, tpos, Color(1, 0.84, 0.31, 0.5), 1.5)
		draw_arc(tpos, 14.0, 0, TAU, 24, Color("#ffd54f"), 2.0)
	for a in state.get("agents", []):
		var sp: Dictionary = KarmaData.SPECIES.get(str(a.get("speciesKey", "raton")), KarmaData.SPECIES["raton"])
		var col: Color = KarmaDraw.species_medal(str(a.get("speciesKey", "raton")))
		if str(a.get("role", "")) == "company":
			col = col.darkened(0.2)
		var pos: Vector2 = Vector2(float(a["x"]), float(a["y"])) - cam
		if pos.x < -40 or pos.y < -40 or pos.x > VIEW_W + 40.0 or pos.y > VIEW_H + 40.0:
			continue
		var ar: float = float(sp["radius"]) * 0.7 + 5.0
		var ring: Color = Color(0, 0, 0, 0)
		var ring_w: float = 0.0
		if str(a.get("kind", "")) == "hunter":
			ring = Color("#ef5350")
			ring_w = 2.5
		_medal(pos, ar, col, KarmaDraw.species_icon(str(a.get("speciesKey", ""))), KarmaDraw.animal_emoji_size(str(a.get("speciesKey", ""))), font, ring, ring_w)
		var kc: Color = Color("#ffd54f") if float(a.get("karma", 0.0)) > 0.0 else (Color("#ef5350") if float(a.get("karma", 0.0)) < 0.0 else Color("#ffffff"))
		_pill(pos + Vector2(0, -ar - 22.0), "%s %d" % [KarmaDraw.species_icon(str(a.get("speciesKey", ""))), int(a.get("karma", 0.0))], font, 11, kc)
		_hp_bar(pos + Vector2(0, ar + 4.0), ar * 2.0, KarmaDraw.hp_frac(float(a.get("hp", 60.0)), float(sp.get("maxHp", 100.0))))
	var pp: Vector2 = Vector2(float(state["px"]), float(state["py"])) - cam
	var psp: Dictionary = state["sp"]
	var pr: float = float(psp["radius"]) + 4.0
	_medal(pp, pr, KarmaDraw.species_medal(str(state["speciesKey"])), KarmaDraw.species_icon(str(state["speciesKey"])), KarmaDraw.animal_emoji_size(str(state["speciesKey"])), font, Color("#ffffff"), 2.0)
	var face: Vector2 = Vector2(float((state.get("face", {"x": 1.0}) as Dictionary).get("x", 1.0)), float((state.get("face", {"y": 0.0}) as Dictionary).get("y", 0.0)))
	if face.length() > 0.01:
		face = face.normalized()
		var nose: Vector2 = pp + face * (pr + 9.0)
		var side: Vector2 = face.rotated(PI / 2.0) * 5.0
		draw_colored_polygon([nose, pp + face * (pr + 1.0) + side, pp + face * (pr + 1.0) - side], Color("#ffffff"))
	draw_arc(pp, pr + 3.0, 0, TAU, 32, Color("#1565c0"), 2.0)
	_pill(pp + Vector2(0, pr + 18.0), "TU %s" % str(psp["name"]), font, 12)
	_hp_bar(pp + Vector2(0, pr + 38.0), pr * 2.0 + 12.0, KarmaHud.hp_frac(state))
	if bool((state.get("weather", {}) as Dictionary).get("raining", false)):
		var rain_t: float = float(state.get("time", 0.0))
		draw_rect(Rect2(Vector2.ZERO, Vector2(VIEW_W, VIEW_H)), Color(0.25, 0.45, 0.7, 0.16))
		for i in 40:
			var rx: float = fmod(float(i) * 97.3 + rain_t * 220.0, VIEW_W)
			var ry: float = fmod(float(i) * 151.7 + rain_t * 620.0, VIEW_H)
			draw_line(Vector2(rx, ry), Vector2(rx - 4.0, ry + 14.0), Color(0.8, 0.9, 1.0, 0.5), 1.5)
	var badge_y: float = 30.0
	var badge_x: float = VIEW_W - PANEL_W - PANEL_MARGIN - 240.0
	if bool(state.get("hidden", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🙈 OCULTO", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#80deea"))
		badge_y += 18.0
	if bool(state.get("grounded", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🛬 EN TIERRA", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#ffe0b2"))
		badge_y += 18.0
	if bool(state.get("bristled", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🦔 ERIZADO", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#ef5350"))
	# Vignette edges.
	draw_rect(Rect2(0, 0, VIEW_W, 18), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0, VIEW_H - 18.0, VIEW_W, 18), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0, 0, 18, VIEW_H), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(VIEW_W - 18.0, 0, 18, VIEW_H), Color(0, 0, 0, 0.18))
