extends Node2D

# Karma MVP — Main scene. Simulation lives in Karma* classes; this node
# owns input, the tick, world rendering (_draw) and a minimal HUD.

# Display-only viewport geometry (must match project.godot window size).
const VIEW_W := 1280.0
const VIEW_H := 800.0
const PANEL_W := 264.0
const PANEL_MARGIN := 8.0

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _labels := {}
var _jev_http: HTTPRequest
var _jev_busy := false
var _jev_agents: Array = []
var _jev_menus := {}
var _jev_snaps := {}
var _jev_h_agents: Array = []
var _jev_h_menus := {}
var _jev_h_snaps := {}
var _jev_flushed := {"zorro": 0, "halcon": 0}
var _jev_last_species := "halcon"
var _jev_flush_t := 0.0
# HUD text changes slowly (cooldowns tick in whole seconds); rebuilding a dozen
# Label strings + forcing container re-layout every physics tick tanks FPS.
# Refresh at ~7Hz and skip labels whose text did not change.
var _hud_t := 0.0
var _hud_cache := {}


func _ready() -> void:
	rng.randomize()
	state = KarmaState.new_run(KarmaGame.draw_start_form(rng), 0.0, 0.0, 0, rng)
	_build_hud()
	_jev_http = HTTPRequest.new()
	_jev_http.timeout = 2.0
	add_child(_jev_http)
	_jev_http.request_completed.connect(_on_jev_done)
	set_process_unhandled_input(true)


func _jev_view_diag() -> float:
	return Vector2(VIEW_W, VIEW_H).length()


func _jev_poll() -> void:
	if _jev_busy or state.is_empty() or bool(state.get("dead", false)):
		return
	var now := float(state.get("time", 0.0))
	var due: Array = []
	if KarmaJev.USE_JEV:
		for a in KarmaJev.all_jev_zorros(state):
			if KarmaJev.should_ask(state, a, now, _jev_view_diag()):
				due.append(a)
	var h_due: Array = []
	if KarmaJev.USE_JEV_HALCON:
		for a in KarmaJev.all_jev_halcons(state):
			if KarmaJev.should_ask(state, a, now, _jev_view_diag()):
				h_due.append(a)
	match KarmaJev.pick_batch_species(not due.is_empty(), not h_due.is_empty(), _jev_last_species):
		"zorro":
			_send_zorro_batch(due)
		"halcon":
			_send_halcon_batch(h_due)


func _send_zorro_batch(due: Array) -> void:
	var body := KarmaJev.build_http_body_for(state, due)
	if (body["states"] as Array).is_empty():
		return
	_jev_agents = body["agents"]
	_jev_menus = body["menus"]
	_jev_snaps = {}
	for i in _jev_agents.size():
		_jev_snaps[str(i)] = KarmaJev.build_state(state, _jev_agents[i])
	for a in due:
		(a as Dictionary)["jev_live"] = true
	_jev_busy = true
	_jev_last_species = "zorro"
	_jev_http.request(KarmaJev.JEV_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"states": body["states"]}))


func _send_halcon_batch(h_due: Array) -> void:
	var h_body := KarmaJev.build_halcon_http_body_for(state, h_due)
	if (h_body["states"] as Array).is_empty():
		return
	_jev_h_agents = h_body["agents"]
	_jev_h_menus = h_body["menus"]
	_jev_h_snaps = {}
	for i in _jev_h_agents.size():
		_jev_h_snaps[str(i)] = KarmaJev.build_halcon_state(state, _jev_h_agents[i])
	for a in h_due:
		(a as Dictionary)["jev_live"] = true
	_jev_busy = true
	_jev_last_species = "halcon"
	_jev_http.request(KarmaJev.JEV_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"states": h_body["states"]}))


func _on_jev_done(result: int, code: int, _headers: PackedStringArray, raw: PackedByteArray) -> void:
	_jev_busy = false
	var raw_text := raw.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_error(KarmaJev.format_jev_error(code, raw_text))
		if not state.is_empty():
			state["jev_last_error"] = {"code": code, "body": raw_text.left(300)}
		_clear_jev_flight()
		return
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null or not (parsed as Dictionary).has("states"):
		push_error(KarmaJev.format_jev_error(code, raw_text))
		_clear_jev_flight()
		return
	var valid := KarmaJev.parse_answers(parsed, _jev_menus if not _jev_agents.is_empty() else _jev_h_menus)
	var is_halcon := _jev_agents.is_empty() and not _jev_h_agents.is_empty()
	var flight_agents := _jev_h_agents if is_halcon else _jev_agents
	for rid in valid:
		var answer: Dictionary = valid[rid]
		if not rid.is_valid_int():
			continue
		var idx: int = rid.to_int()
		if idx < 0 or idx >= flight_agents.size():
			continue
		var a: Dictionary = flight_agents[idx]
		if not (state["agents"] as Array).has(a):
			continue
		if is_halcon:
			var h_menu: Array = _jev_h_menus.get(rid, [])
			var h_snapshot: Dictionary = _jev_h_snaps.get(rid, KarmaJev.build_halcon_state(state, a))
			var h_applied := KarmaJev.apply_halcon_answer(state, a, h_menu, answer)
			KarmaJev.log_decision(state, h_snapshot, h_menu, answer, h_applied, "halcon")
		else:
			var menu: Array = _jev_menus.get(rid, [])
			var snapshot: Dictionary = _jev_snaps.get(rid, KarmaJev.build_state(state, a))
			var applied := KarmaJev.apply_answer(state, a, menu, answer)
			KarmaJev.log_decision(state, snapshot, menu, answer, applied)
		KarmaJev.mark_asked(state, a, _jev_view_diag())
		a["jev_live"] = false
	_jev_agents = []
	_jev_menus = {}
	_jev_snaps = {}
	_jev_h_agents = []
	_jev_h_menus = {}
	_jev_h_snaps = {}


func _jev_flush_log() -> void:
	if state.is_empty():
		return
	for species in ["zorro", "halcon"]:
		if not KarmaJev.log_enabled(species):
			continue
		var key := KarmaJev.log_key_for(species)
		var entries: Array = state.get(key, []) as Array
		var flushed := int(_jev_flushed.get(species, 0))
		if flushed >= entries.size():
			continue
		var path := KarmaJev.jev_log_path_for(species)
		if not KarmaJev.ensure_log_ready(path):
			push_error("JEV log open failed: " + path)
			continue
		var file := FileAccess.open(path, FileAccess.READ_WRITE)
		if file == null:
			push_error("JEV log open failed: " + path)
			continue
		file.seek_end()
		while flushed < entries.size():
			file.store_line(JSON.stringify(entries[flushed]))
			flushed += 1
		_jev_flushed[species] = flushed
		file.close()


func _clear_jev_flight() -> void:
	if not state.is_empty():
		for a in _jev_agents + _jev_h_agents:
			if (state["agents"] as Array).has(a):
				(a as Dictionary)["jev_live"] = false
				KarmaJev.mark_asked(state, a, _jev_view_diag())
	_jev_agents = []
	_jev_menus = {}
	_jev_snaps = {}
	_jev_h_agents = []
	_jev_h_menus = {}
	_jev_h_snaps = {}


func _panel_style(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
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
	var frame := PanelContainer.new()
	frame.name = panel_name
	# TOP_LEFT + absolute position keeps the panel inside the viewport
	# (VIEW_W x VIEW_H). (PRESET_TOP_RIGHT + positive x pushes it off-screen.)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = pos
	frame.custom_minimum_size = Vector2(width, 0)
	frame.add_theme_stylebox_override("panel", _panel_style(Color("#c9a227")))
	layer.add_child(frame)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(width - 16, 0)
	box.add_theme_constant_override("separation", 4)
	frame.add_child(box)
	return box


func _add_hud_label(box: VBoxContainer, key: String, width: float, min_h: float) -> void:
	var l := Label.new()
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
	var l := _labels[key] as Label
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	# Left: other-animals feed. Right: status + controls + verbs + shop + log.
	# Center (~280..1000) stays clear so the world stays visible.
	var left := _make_side_panel(layer, "LeftPanel", Vector2(PANEL_MARGIN, PANEL_MARGIN), PANEL_W)
	_add_hud_label(left, "others_title", PANEL_W, 20.0)
	_add_hud_label(left, "others", PANEL_W, 120.0)
	var right := _make_side_panel(layer, "RightPanel", Vector2(VIEW_W - PANEL_W - PANEL_MARGIN, PANEL_MARGIN), PANEL_W)
	for key in ["species", "vitals", "karma", "edad", "prompt"]:
		_add_hud_label(right, key, PANEL_W, 20.0)
	_add_hud_label(right, "controls", PANEL_W, 110.0)
	_add_hud_label(right, "verbs", PANEL_W, 90.0)
	_add_hud_label(right, "shop", PANEL_W, 60.0)
	_add_hud_label(right, "log", PANEL_W, 60.0)
	_style_hud_label("species", 14, Color("#ffd54f"))
	_style_hud_label("karma", 13, Color("#ffd54f"))
	_style_hud_label("vitals", 12, Color("#ffffff"))
	_style_hud_label("edad", 11, Color("#b0bec5"))
	_style_hud_label("prompt", 12, Color("#80deea"))
	_style_hud_label("controls", 12, Color("#dcedc8"))
	_style_hud_label("verbs", 12, Color("#dcedc8"))
	_style_hud_label("shop", 12, Color("#ffe0b2"))
	_style_hud_label("log", 11, Color("#b0bec5"))
	_style_hud_label("others_title", 13, Color("#ffd54f"))
	_style_hud_label("others", 11, Color("#cfd8dc"))


func _unhandled_input(event: InputEvent) -> void:
	if state.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == 0:
			k = (event as InputEventKey).keycode
		var ch := String.chr(k).to_lower() if k >= 32 and k < 128 else ""
		# Number keys: Godot keycodes KEY_1..KEY_5.
		var num := -1
		if k >= KEY_1 and k <= KEY_5:
			num = int(k - KEY_0)
		if state.get("dead", false):
			if ch == "r":
				state = KarmaState.reincarnate(state, rng)
			return
		match ch:
			"e":
				KarmaEat.try_eat(state)
			"q":
				KarmaState.try_shout(state)
			"h":
				if not bool(state.get("shopOpen", false)):
					KarmaState.toggle_hide(state)
			"v":
				KarmaEat.sense_pulse(state)
			"c":
				KarmaEat.carry_action(state)
			"b":
				state["shopOpen"] = not bool(state.get("shopOpen", false))
		if ch == "" and event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
			state["shopOpen"] = false
		if num >= 1 and num <= 5 and not bool(state.get("shopOpen", false)):
			KarmaGame.cast_verb(state, num)
		elif num >= 1 and num <= 3 and bool(state.get("shopOpen", false)):
			for it in KarmaShop.catalog_for(str(state["speciesKey"])):
				if str(it["key"]) == str(num):
					KarmaShop.buy_item(state, state, str(it["id"]))


func _physics_process(delta: float) -> void:
	if state.is_empty():
		return
	var dt := minf(delta, 0.05)
	if not bool(state.get("dead", false)):
		var ix := (1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0)
		var iy := (1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
		# One solids snapshot per tick shared by movement + sim (see KarmaGame).
		var solids := KarmaUtils.collect_solids(state)
		KarmaGame.move_player(state, ix, iy, dt, solids)
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
	_set_text("prompt", KarmaHud.prompt_line(state))
	_set_text("others_title", "▼ OTROS ANIMALES")
	_set_text("others", "\n".join(KarmaHud.other_panel_lines(state)))
	var crows: Array = []
	for c in KarmaHud.control_rows(state):
		var mark := "✓ " if float(c["cd"]) <= 0.0 else "⏳ "
		crows.append("%s%s %s%s" % [mark, str(c["key"]), str(c["label"]), (" (%ds)" % int(ceil(float(c["cd"])))) if float(c["cd"]) > 0.0 else ""])
	_set_text("controls", "\n".join(crows))
	var feed: Array = state.get("feed", [])
	_set_text("log", "\n".join(feed.slice(maxi(0, feed.size() - 4))))
	var rows: Array = []
	for v in KarmaHud.verb_rows(state):
		var mark := "✓ " if float(v["cd"]) <= 0.0 and not bool(v["poor"]) else ("⏳ " if float(v["cd"]) > 0.0 else "∅ ")
		rows.append("%s[%d] %s%s%s" % [mark, int(v["slot"]), str(v["name"]), (" (%ds)" % int(ceil(float(v["cd"])))) if float(v["cd"]) > 0.0 else "", " (sin PA)" if bool(v["poor"]) else ""])
	_set_text("verbs", "VERBOS:\n" + "\n".join(rows))
	if bool(state.get("shopOpen", false)):
		var srows: Array = []
		for it in KarmaShop.catalog_for(str(state["speciesKey"])):
			var owned := KarmaShop.has_adapt(state, str(it["effect"]))
			var afford := float(state.get("pa", 0.0)) >= float(it["cost"])
			var mark := "✔ " if owned else ("✓ " if afford else "🔒 ")
			srows.append("%s[%s] %s (%d PA)" % [mark, str(it["key"]), str(it["name"]), int(it["cost"])])
		_set_text("shop", "TIENDA (B cerrar):\n" + "\n".join(srows))
	else:
		_set_text("shop", "")


func _medal(pos: Vector2, radius: float, fill: Color, glyph: String, glyph_size: float, font: Font, outline := Color(0, 0, 0, 0), ring_width := 0.0) -> void:
	draw_circle(pos + Vector2(2, 3), radius, KarmaDraw.SHADOW)
	draw_circle(pos, radius, fill)
	draw_arc(pos, radius - 1.0, 0, TAU, 32, KarmaDraw.RIM, 2.0)
	if ring_width > 0.0:
		draw_arc(pos, radius + 2.0, 0, TAU, 32, outline, ring_width)
	var w := maxf(radius * 2.0, 40.0) + 16.0
	draw_string(font, pos + Vector2(-w / 2.0, glyph_size * 0.35), glyph, HORIZONTAL_ALIGNMENT_CENTER, w, glyph_size, Color.WHITE)


func _pill(pos: Vector2, text: String, font: Font, fs: int, text_color := Color("#ffffff")) -> void:
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var rect := Rect2(pos - Vector2(size.x / 2.0 + 5.0, 0), Vector2(size.x + 10.0, fs + 9.0))
	draw_rect(rect, KarmaDraw.PILL_BG)
	draw_rect(rect, Color(1, 1, 1, 0.18), false, 1.0)
	draw_string(font, rect.position + Vector2(5, fs + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)


func _hp_bar(pos: Vector2, w: float, frac: float) -> void:
	var rect := Rect2(pos - Vector2(w / 2.0, 0), Vector2(w, 4.0))
	draw_rect(rect, KarmaDraw.PILL_BG)
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		draw_rect(Rect2(rect.position, Vector2(w * f, 4.0)), KarmaDraw.hp_color(f))
	draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)


func _draw() -> void:
	if state.is_empty():
		return
	var cam := Vector2(float((state.get("cam", {"x": 0}) as Dictionary).get("x", 0.0)), float((state.get("cam", {"y": 0}) as Dictionary).get("y", 0.0)))
	var font := ThemeDB.fallback_font
	var t := float(state.get("time", 0.0))
	# Screen-space visible rect + margin: the world is 3200x2400 but the
	# viewport shows VIEW_W x VIEW_H. Skipping off-screen circles AND their
	# draw_string labels (font shaping is the expensive part) is the main
	# _draw win.
	var view := Rect2(Vector2(-48, -48), Vector2(VIEW_W + 96.0, VIEW_H + 96.0))
	# Meadow background + grid + vignette (screen-space: no Camera2D, the
	# world is manually shifted by -cam, so the backdrop sits at origin).
	draw_rect(Rect2(Vector2.ZERO, Vector2(VIEW_W, VIEW_H)), KarmaDraw.MEADOW_B)
	var step := KarmaDraw.GRID_STEP
	var gx := floorf(cam.x / step) * step
	while gx <= cam.x + VIEW_W:
		draw_line(Vector2(gx - cam.x, 0), Vector2(gx - cam.x, VIEW_H), KarmaDraw.GRID_LINE, 1.0)
		gx += step
	var gy := floorf(cam.y / step) * step
	while gy <= cam.y + VIEW_H:
		draw_line(Vector2(0, gy - cam.y), Vector2(VIEW_W, gy - cam.y), KarmaDraw.GRID_LINE, 1.0)
		gy += step
	for w in state.get("waters", []):
		var wpos := Vector2(float(w["x"]), float(w["y"])) - cam
		if not view.has_point(wpos):
			continue
		var body := KarmaDraw.water_disc(w)
		var wr: float = float(body["r"])
		draw_circle(wpos, wr + 5.0, KarmaDraw.SHORE)
		draw_circle(wpos, wr, body["color"])
		draw_arc(wpos, wr - 3.0, PI * 0.9, PI * 1.7, 24, Color(1, 1, 1, 0.25), 2.0)
		_medal(wpos, 11.0, Color(0, 0, 0, 0.25), KarmaDraw.water_icon(str(w.get("kind", ""))), 13.0, font)
		_pill(wpos + Vector2(0, wr + 16.0), str(KarmaDraw.WATER_LABEL.get(str(w.get("kind", "")), "agua")), font, 11)
	for k in state.get("rocks", []):
		var kpos := Vector2(float(k["x"]), float(k["y"])) - cam
		if not view.has_point(kpos):
			continue
		draw_circle(kpos + Vector2(2, 3), 9.0, KarmaDraw.SHADOW)
		draw_circle(kpos, 9.0, KarmaDraw.ROCK_BODY)
		draw_circle(kpos + Vector2(-2, -2), 5.0, KarmaDraw.ROCK_TOP)
		_medal(kpos, 7.0, Color(0, 0, 0, 0.2), "🪨", 10.0, font)
	for r in state.get("refuges", []):
		var rpos := Vector2(float(r["x"]), float(r["y"])) - cam
		if not view.has_point(rpos):
			continue
		var rtype := str(r["type"])
		var rmedal := KarmaDraw.refuge_medal(rtype)
		var rr := KarmaDraw.refuge_emoji_size(rtype) * 0.62 + 6.0
		_medal(rpos, rr, rmedal, KarmaDraw.refuge_icon(rtype), KarmaDraw.refuge_emoji_size(rtype), font)
		if rtype.begins_with("burrow"):
			draw_circle(rpos, rr * 0.55, Color(0, 0, 0, 0.55))
		if bool(state.get("hidden", false)) and state.get("hideRef") is Dictionary and Vector2(float((state["hideRef"] as Dictionary).get("x", -9999.0)), float((state["hideRef"] as Dictionary).get("y", -9999.0))).distance_to(Vector2(float(r["x"]), float(r["y"]))) < 1.0:
			draw_arc(rpos, rr + 3.0, 0, TAU, 32, Color("#80deea"), 2.0)
		_pill(rpos + Vector2(0, rr + 16.0), str(KarmaDraw.REFUGE_LABEL.get(rtype, rtype)), font, 11)
	for s in state.get("seedlings", []):
		var spos := Vector2(float(s["x"]), float(s["y"])) - cam
		if not view.has_point(spos):
			continue
		_medal(spos, 8.0, KarmaDraw.food_medal("leaves"), "🌱", 12.0, font)
	var mimics := KarmaState.mimics_visible(state)
	var toxics := KarmaState.toxics_visible(state)
	for key in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		for p in state.get(key, []):
			var kind := str(p.get("kind", key))
			var ppos := Vector2(float(p["x"]), float(p["y"])) - cam
			if not view.has_point(ppos):
				continue
			if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 0:
				_medal(ppos, 8.0, Color("#616161"), "✕", 12.0, font)
				_pill(ppos + Vector2(0, 24.0), "↻ recuperando", font, 11, Color("#b0bec5"))
				continue
			var trapped := (bool(p.get("mimic", false)) and not bool(p.get("mimicEaten", false))) or int(p.get("toxicLeft", 0)) > 0
			var ring := Color(0, 0, 0, 0)
			var ring_w := 0.0
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
		var ipos := Vector2(float(ins["x"]), float(ins["y"])) - cam
		if not view.has_point(ipos):
			continue
		ipos.y += sin(t * 4.0 + float(ins["x"]) * 0.13) * 1.5
		_medal(ipos, 7.0, KarmaDraw.INSECT_MEDAL, KarmaDraw.food_icon("insects"), 12.0, font)
	for c in state.get("carrions", []):
		var cpos := Vector2(float(c["x"]), float(c["y"])) - cam
		if not view.has_point(cpos):
			continue
		var stage := KarmaEat.carrion_stage(c)
		var look := KarmaDraw.carrion_look(stage)
		_medal(cpos, 10.0, look["meat"], KarmaDraw.carrion_icon(stage), 16.0, font)
		_pill(cpos + Vector2(0, 26.0), str(look["label"]), font, 11)
		if stage == "rotten":
			var wob := Vector2(sin(t * 6.0 + float(c["x"])), cos(t * 5.0 + float(c["y"]))) * 2.0
			draw_circle(cpos + Vector2(-6, -12) + wob, 1.5, Color("#212121"))
			draw_circle(cpos + Vector2(6, -10) - wob, 1.5, Color("#212121"))
	# Vision ring + agents + player.
	var pcenter := Vector2(float(state["px"]), float(state["py"])) - cam
	draw_arc(pcenter, KarmaState.eff_vision(state), 0, TAU, 64, Color(1, 1, 1, 0.22), 1.0)
	if float(state.get("thermalT", 0.0)) > 0.0:
		draw_arc(pcenter, KarmaState.eff_vision(state) + 6.0, 0, TAU, 64, Color("#ffd54f"), 1.5)
	if float(state.get("revealT", 0.0)) > 0.0:
		draw_arc(pcenter, KarmaState.eff_vision(state) * 0.5, 0, TAU, 48, Color("#80deea"), 1.5)
	var tracked: Variant = KarmaState.tracked_carrion(state)
	if tracked is Dictionary:
		var tpos := Vector2(float((tracked as Dictionary)["x"]), float((tracked as Dictionary)["y"])) - cam
		draw_line(pcenter, tpos, Color(1, 0.84, 0.31, 0.5), 1.5)
		draw_arc(tpos, 14.0, 0, TAU, 24, Color("#ffd54f"), 2.0)
	for a in state.get("agents", []):
		var sp: Dictionary = KarmaData.SPECIES.get(str(a.get("speciesKey", "raton")), KarmaData.SPECIES["raton"])
		var col := KarmaDraw.species_medal(str(a.get("speciesKey", "raton")))
		if str(a.get("role", "")) == "company":
			col = col.darkened(0.2)
		var pos := Vector2(float(a["x"]), float(a["y"])) - cam
		if pos.x < -40 or pos.y < -40 or pos.x > VIEW_W + 40.0 or pos.y > VIEW_H + 40.0:
			continue
		var ar := float(sp["radius"]) * 0.7 + 5.0
		var ring := Color(0, 0, 0, 0)
		var ring_w := 0.0
		if str(a.get("kind", "")) == "hunter":
			ring = Color("#ef5350")
			ring_w = 2.5
		_medal(pos, ar, col, KarmaDraw.species_icon(str(a.get("speciesKey", ""))), KarmaDraw.animal_emoji_size(str(a.get("speciesKey", ""))), font, ring, ring_w)
		var kc := Color("#ffd54f") if float(a.get("karma", 0.0)) > 0.0 else (Color("#ef5350") if float(a.get("karma", 0.0)) < 0.0 else Color("#ffffff"))
		_pill(pos + Vector2(0, -ar - 22.0), "%s %d" % [KarmaDraw.species_icon(str(a.get("speciesKey", ""))), int(a.get("karma", 0.0))], font, 11, kc)
		_hp_bar(pos + Vector2(0, ar + 4.0), ar * 2.0, KarmaDraw.hp_frac(float(a.get("hp", 60.0)), float(sp.get("maxHp", 100.0))))
	var pp := Vector2(float(state["px"]), float(state["py"])) - cam
	var psp: Dictionary = state["sp"]
	var pr := float(psp["radius"]) + 4.0
	_medal(pp, pr, KarmaDraw.species_medal(str(state["speciesKey"])), KarmaDraw.species_icon(str(state["speciesKey"])), KarmaDraw.animal_emoji_size(str(state["speciesKey"])), font, Color("#ffffff"), 2.0)
	var face := Vector2(float((state.get("face", {"x": 1.0}) as Dictionary).get("x", 1.0)), float((state.get("face", {"y": 0.0}) as Dictionary).get("y", 0.0)))
	if face.length() > 0.01:
		face = face.normalized()
		var nose := pp + face * (pr + 9.0)
		var side := face.rotated(PI / 2.0) * 5.0
		draw_colored_polygon([nose, pp + face * (pr + 1.0) + side, pp + face * (pr + 1.0) - side], Color("#ffffff"))
	draw_arc(pp, pr + 3.0, 0, TAU, 32, Color("#1565c0"), 2.0)
	_pill(pp + Vector2(0, pr + 18.0), "TU %s" % str(psp["name"]), font, 12)
	_hp_bar(pp + Vector2(0, pr + 38.0), pr * 2.0 + 12.0, KarmaHud.hp_frac(state))
	var badge_y := 30.0
	var badge_x := VIEW_W - PANEL_W - PANEL_MARGIN - 240.0
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
