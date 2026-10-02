extends Node2D

# Karma MVP — Main scene. Simulation lives in Karma* classes; this node
# owns input, the tick, world rendering (_draw) and a minimal HUD.

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _labels := {}
# HUD text changes slowly (cooldowns tick in whole seconds); rebuilding a dozen
# Label strings + forcing container re-layout every physics tick tanks FPS.
# Refresh at ~7Hz and skip labels whose text did not change.
var _hud_t := 0.0
var _hud_cache := {}


func _ready() -> void:
	rng.randomize()
	state = KarmaState.new_run(KarmaGame.draw_start_form(rng), 0.0, 0.0, 0, rng)
	_build_hud()
	set_process_unhandled_input(true)


func _make_side_panel(layer: CanvasLayer, panel_name: String, pos: Vector2, width: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.name = panel_name
	# TOP_LEFT + absolute position keeps the panel inside the fixed 960x600
	# viewport. (PRESET_TOP_RIGHT + positive x pushes it off-screen.)
	frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	frame.position = pos
	frame.custom_minimum_size = Vector2(width, 0)
	layer.add_child(frame)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.custom_minimum_size = Vector2(width - 16, 0)
	frame.add_child(box)
	return box


func _add_hud_label(box: VBoxContainer, key: String, width: float, min_h: float) -> void:
	var l := Label.new()
	l.name = key
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width - 16, min_h)
	l.add_theme_font_size_override("font_size", 12)
	box.add_child(l)
	_labels[key] = l


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	# Left: other-animals feed. Right: status + controls + verbs + shop + log.
	# Center (~280..680) stays clear so the world stays visible.
	var left := _make_side_panel(layer, "LeftPanel", Vector2(8, 8), 264.0)
	_add_hud_label(left, "others_title", 264.0, 20.0)
	_add_hud_label(left, "others", 264.0, 120.0)
	var right := _make_side_panel(layer, "RightPanel", Vector2(688, 8), 264.0)
	for key in ["species", "vitals", "karma", "edad", "prompt"]:
		_add_hud_label(right, key, 264.0, 20.0)
	_add_hud_label(right, "controls", 264.0, 110.0)
	_add_hud_label(right, "verbs", 264.0, 90.0)
	_add_hud_label(right, "shop", 264.0, 60.0)
	_add_hud_label(right, "log", 264.0, 60.0)


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
		state["cam"] = {"x": clampf(float(state["px"]) - 480.0, 0.0, float(KarmaData.WORLD["w"]) - 960.0),
			"y": clampf(float(state["py"]) - 300.0, 0.0, float(KarmaData.WORLD["h"]) - 600.0)}
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
	_set_text("species", "%s T%d · %s" % [str(state["sp"]["name"]), int(state["sp"]["tier"]), KarmaUtils.fmt_time(float(state.get("time", 0.0)))])
	_set_text("vitals", "Vida %d/%d · Hambre %d · Sed %d · PA %d" % [int(ceil(float(state.get("hp", 0.0)))), int(KarmaState.eff_max_hp(state)), int(state.get("hambre", 0.0)), int(state.get("sed", 0.0)), int(state.get("pa", 0.0))])
	_set_text("karma", "Karma %d%s" % [int(state.get("karma", 0.0)), " · MUERTO (R reencarnar)" if bool(state.get("dead", false)) else ""])
	_set_text("edad", KarmaHud.edad_line(state))
	_set_text("prompt", KarmaHud.prompt_line(state))
	_set_text("others_title", "Otros animales")
	_set_text("others", "\n".join(KarmaHud.other_panel_lines(state)))
	var crows: Array = []
	for c in KarmaHud.control_rows(state):
		crows.append("%s %s%s" % [str(c["key"]), str(c["label"]), (" (%ds)" % int(ceil(float(c["cd"])))) if float(c["cd"]) > 0.0 else ""])
	_set_text("controls", "\n".join(crows))
	var feed: Array = state.get("feed", [])
	_set_text("log", "\n".join(feed.slice(maxi(0, feed.size() - 4))))
	var rows: Array = []
	for v in KarmaHud.verb_rows(state):
		rows.append("[%d] %s%s" % [int(v["slot"]), str(v["name"]), (" (%ds)" % int(ceil(float(v["cd"])))) if float(v["cd"]) > 0.0 else ""])
	_set_text("verbs", "Verbos:\n" + "\n".join(rows))
	if bool(state.get("shopOpen", false)):
		var srows: Array = []
		for it in KarmaShop.catalog_for(str(state["speciesKey"])):
			srows.append("[%s] %s (%d PA)" % [str(it["key"]), str(it["name"]), int(it["cost"])])
		_set_text("shop", "Tienda (B cerrar):\n" + "\n".join(srows))
	else:
		_set_text("shop", "")


func _draw() -> void:
	if state.is_empty():
		return
	var cam := Vector2(float((state.get("cam", {"x": 0}) as Dictionary).get("x", 0.0)), float((state.get("cam", {"y": 0}) as Dictionary).get("y", 0.0)))
	var font := ThemeDB.fallback_font
	# Screen-space visible rect + margin: the world is 3200x2400 but the
	# viewport shows 960x600. Skipping off-screen circles AND their
	# draw_string labels (font shaping is the expensive part) is the main
	# _draw win.
	var view := Rect2(Vector2(-48, -48), Vector2(1056, 696))
	# Meadow background.
	draw_rect(Rect2(-cam, Vector2(960, 600)), Color("#1c2620"))
	for w in state.get("waters", []):
		var wpos := Vector2(float(w["x"]), float(w["y"])) - cam
		if not view.has_point(wpos):
			continue
		var body := KarmaDraw.water_disc(w)
		draw_circle(wpos, float(body["r"]), body["color"])
	for k in state.get("rocks", []):
		var kpos := Vector2(float(k["x"]), float(k["y"])) - cam
		if not view.has_point(kpos):
			continue
		draw_circle(kpos, 8.0, Color("#546e7a"))
	for r in state.get("refuges", []):
		var rpos := Vector2(float(r["x"]), float(r["y"])) - cam
		if not view.has_point(rpos):
			continue
		var rc := Color("#6d4c41") if str(r["type"]).begins_with("burrow") else Color("#2e7d32")
		draw_circle(rpos, 10.0, rc)
		draw_string(font, rpos + Vector2(-24, 22), str(r["type"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#fff8"))
	for key in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
		for p in state.get(key, []):
			if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 0:
				continue
			var ppos := Vector2(float(p["x"]), float(p["y"])) - cam
			if not view.has_point(ppos):
				continue
			draw_circle(ppos, 7.0, Color("#2e7d32"))
			draw_string(font, ppos + Vector2(-20, 20), "%s x%d" % [str(p["kind"]), int(p["amount"])], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#fff8"))
	for ins in state.get("insects", []):
		var ipos := Vector2(float(ins["x"]), float(ins["y"])) - cam
		if not view.has_point(ipos):
			continue
		draw_circle(ipos, 3.0, Color("#ffca28"))
	for c in state.get("carrions", []):
		var cpos := Vector2(float(c["x"]), float(c["y"])) - cam
		if not view.has_point(cpos):
			continue
		var look := KarmaDraw.carrion_look(KarmaEat.carrion_stage(c))
		draw_circle(cpos, 8.0, look["meat"])
		draw_string(font, cpos + Vector2(-30, 22), str(look["label"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color("#fff8"))
	# Vision ring + agents + player.
	draw_arc(Vector2(float(state["px"]), float(state["py"])) - cam, KarmaState.eff_vision(state), 0, TAU, 48, Color(1, 1, 1, 0.35), 1.0)
	for a in state.get("agents", []):
		var sp: Dictionary = KarmaData.SPECIES.get(str(a.get("speciesKey", "raton")), KarmaData.SPECIES["raton"])
		var col := Color(str(sp.get("color", "#ffffff")))
		var pos := Vector2(float(a["x"]), float(a["y"])) - cam
		if pos.x < -40 or pos.y < -40 or pos.x > 1000 or pos.y > 640:
			continue
		draw_circle(pos, float(sp["radius"]) * 0.7, col.darkened(0.2) if str(a.get("role", "")) == "company" else col)
		draw_string(font, pos + Vector2(-20, -12), "%s %d" % [KarmaDraw.species_icon(str(a.get("speciesKey", ""))), int(a.get("karma", 0.0))], HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
	var pp := Vector2(float(state["px"]), float(state["py"])) - cam
	var psp: Dictionary = state["sp"]
	draw_circle(pp, float(psp["radius"]), Color(str(psp.get("color", "#ffffff"))))
	draw_arc(pp, float(psp["radius"]) + 3.0, 0, TAU, 24, Color("#1565c0"), 2.0)
	draw_string(font, pp + Vector2(-30, float(psp["radius"]) + 18), "TU %s" % str(psp["name"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
