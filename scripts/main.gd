extends Node2D

# Karma MVP — Main scene. Simulation lives in Karma* classes; this node
# owns input, the tick, world rendering (_draw) and a minimal HUD.

# Display-only viewport geometry (must match project.godot window size).
const VIEW_W := 1280.0
const VIEW_H := 800.0
const VIEW_DIAG := sqrt(VIEW_W * VIEW_W + VIEW_H * VIEW_H)
const PANEL_W := 264.0
const PANEL_MARGIN := 8.0
# _pill measures every visible label; font shaping is the expensive part.
# Cache widths once a frame draws enough labels to pay for the lookup, and clear
# on overflow so changing counts cannot grow the map without bound.
const LABEL_CACHE_MIN_CALLS := 12
# FIFO above the cap: evict one oldest entry per miss instead of clearing all
# (a wholesale clear re-shapes every visible pill in one frame — the 100 ms
# _draw spikes behind the "low fps" reports).
const LABEL_CACHE_MAX := 400
# World furniture (backdrop, grid, tufts, waters, rocks, refuges, seedlings,
# flora) renders in the cached _StaticLayer: it re-draws only when the camera
# moved this far or the world content changed — everything animated stays in
# _draw. This is the fix for the render-side frame budget collapse on
# content-dense areas (draw_calls ~1400 / prims ~44k measured at 5 fps).
const LAYER_CAM_REDRAW := 150.0
# Bake-rect edge margin: must cover LAYER_CAM_REDRAW plus slack so the baked
# furniture always extends past the farthest camera drift — no gray edges
# while the player walks into a not-yet-rebaked sector.
const LAYER_EDGE_MARGIN := 210.0
# Drawn rain streaks (replaces the old CPUParticles2D emitter: 160 engine
# particles dragged even a cached-world frame under ~10 fps on this GPU).
# RAIN_STREAKS is the count at 1280 px width; narrower windows scale down
# but never below RAIN_STREAKS_FLOOR so the storm always covers the stage.
const RAIN_STREAKS := 160
const RAIN_STREAKS_FLOOR := 64

var state: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _labels: Dictionary = {}
# Vitals HUD: three drawn bars (vida/hambre/sed) with value overlays.
# _bar_fills holds each bar's fill StyleBoxFlat so a value change re-tints it.
var _bars: Dictionary = {}
var _bar_fills: Dictionary = {}
var _label_sizes: Dictionary = {}
var _label_order: PackedStringArray = PackedStringArray()
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
# Decor textures built once (radial meadow, vignette).
var _bg_tex: Texture2D = null
var _vignette_tex: Texture2D = null
var _motes: CPUParticles2D = null
# Cached static furniture layer (see _build_static_layer).
var _world_layer: SubViewport = null
# Runtime hook: flip true (e.g. from debug tools) to skip the birth modal.
var skip_intro: bool = false
# Display-only player ripple wake: recent stamped positions (in water).
var _wake: Array = []
var _wake_last: Vector2 = Vector2.ZERO
var _wake_has: bool = false
# Bench probes: run with "--bench" (optionally "--seed=N") to print
# per-phase timing aggregates every ~2 s and log frame spikes.
var _bench_on: bool = false
var _bench_usec: Dictionary = {}
var _bench_peak: Dictionary = {}
var _bench_frames: int = 0
var _bench_log_t: float = 0.0
var _bench_shot: bool = false
# Per-species JEV dispatch tables (built once in _ready). Replaces the
# repeated match blocks in _build_jev_body/_build_jev_agent_state/_apply_jev_answer.
var _jev_body_builders: Dictionary = {}
var _jev_state_builders: Dictionary = {}
var _jev_answer_appliers: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	var first: String = KarmaGame.draw_start_form(rng)
	state = KarmaState.new_run(first, 0.0, 0.0, 0, rng)
	state["introDone"] = false
	state["introNext"] = first
	_init_jev_dispatch()
	_build_hud()
	_build_modal()
	_build_motes()
	_build_static_layer()
	var vp := get_viewport()
	if vp != null:
		vp.size_changed.connect(_on_view_resized)
	get_window().min_size = Vector2i(960, 600)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_bench_on = args.has("--bench")
	_bench_shot = args.has("--shot")
	for a in args:
		if a.begins_with("--seed="):
			rng.seed = int(a.get_slice("=", 1))
	if _bench_on and args.has("--skip-intro"):
		# The birth modal freezes the sim; skip it to profile pure gameplay.
		state["introDone"] = true
	_jev_http = HTTPRequest.new()
	_jev_http.timeout = 2.0
	add_child(_jev_http)
	_jev_http.request_completed.connect(_on_jev_done)
	set_process_unhandled_input(true)


func _jev_poll() -> void:
	if _jev_busy:
		if not state.is_empty():
			KarmaJev.poll_note(state, "busy_skip")
		return
	if state.is_empty() or bool(state.get("dead", false)):
		return
	var now: float = float(state.get("time", 0.0))
	var view_diag: float = _view_diag()
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
		for a in due:
			KarmaJev.mark_asked(state, a, _view_diag())
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


func _init_jev_dispatch() -> void:
	for sp: String in ["halcon", "raton", "ardilla", "sapo", "topo", "lobo", "oruga"]:
		_jev_body_builders[sp] = Callable(KarmaJev, "build_%s_http_body_for" % sp)
		_jev_state_builders[sp] = Callable(KarmaJev, "build_%s_state" % sp)
		_jev_answer_appliers[sp] = Callable(KarmaJev, "apply_%s_answer" % sp)


func _build_jev_body(species: String, due: Array) -> Dictionary:
	var builder: Callable = _jev_body_builders.get(species, Callable(KarmaJev, "build_http_body_for"))
	return builder.call(state, due) as Dictionary


func _build_jev_snapshot(species: String, agents: Array) -> Dictionary:
	var snaps: Dictionary = {}
	for i in agents.size():
		snaps[str(i)] = _build_jev_agent_state(species, agents[i])
	return snaps


func _build_jev_agent_state(species: String, a: Dictionary) -> Dictionary:
	var builder: Callable = _jev_state_builders.get(species, Callable(KarmaJev, "build_state"))
	return builder.call(state, a) as Dictionary


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
	var b_p: int = Time.get_ticks_usec() if _bench_on else 0
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null or not (parsed as Dictionary).has("states"):
		push_error(KarmaJev.format_jev_error(code, raw_text))
		if not state.is_empty():
			KarmaJev.poll_note(state, "error")
		_clear_jev_flight()
		return
	var valid: Dictionary = KarmaJev.parse_answers(parsed, _jev_flight.get("menus", {}))
	_apply_flight(valid)
	if _bench_on:
		_bench_note("jev_apply", Time.get_ticks_usec() - b_p)
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
	var applier: Callable = _jev_answer_appliers.get(species, Callable(KarmaJev, "apply_answer"))
	return bool(applier.call(state, a, menu, answer))


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
		for a in _jev_flight.get("agents", []):
			if (state["agents"] as Array).has(a):
				(a as Dictionary)["jev_live"] = false
				KarmaJev.mark_asked(state, a, _view_diag())
	_jev_flight = {}


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 5.0
	sb.content_margin_bottom = 5.0
	return sb


func _apply_modal_button_theme(primary: Button, close: Button) -> void:
	primary.add_theme_stylebox_override("normal", _button_style(Color("#2b2411"), Color("#ffd54f")))
	primary.add_theme_stylebox_override("hover", _button_style(Color("#3d3215"), Color("#ffd54f")))
	primary.add_theme_stylebox_override("pressed", _button_style(Color("#1f190a"), Color("#b8962f")))
	primary.add_theme_color_override("font_color", Color("#ffd54f"))
	primary.add_theme_color_override("font_hover_color", Color("#fff3c4"))
	primary.add_theme_color_override("font_pressed_color", Color("#c9a227"))
	close.add_theme_stylebox_override("normal", _button_style(Color("#20271f"), Color("#5a6b57")))
	close.add_theme_stylebox_override("hover", _button_style(Color("#2c352a"), Color("#7c8f7a")))
	close.add_theme_stylebox_override("pressed", _button_style(Color("#171d17"), Color("#44513f")))
	close.add_theme_color_override("font_color", Color("#dcedc8"))
	close.add_theme_color_override("font_hover_color", Color("#f1f7e6"))
	close.add_theme_color_override("font_pressed_color", Color("#a9bb9e"))


func _vp_size() -> Vector2:
	var vp := get_viewport()
	return Vector2(VIEW_W, VIEW_H) if vp == null else vp.get_visible_rect().size


func _view_diag() -> float:
	var vp := get_viewport()
	return VIEW_DIAG if vp == null else float(vp.get_visible_rect().size.length())


func _on_view_resized() -> void:
	_layout_screen_fx()


func _build_static_layer() -> void:
	var l := _StaticLayer.new()
	l.main = self
	l.cam_redraw = LAYER_CAM_REDRAW
	l.edge_margin = LAYER_EDGE_MARGIN
	l.render_target_update_mode = SubViewport.UPDATE_ONCE
	l.disable_3d = true
	var p := _StaticPainter.new()
	p.main = self
	p.baked = true
	l.add_child(p)
	l.painter = p
	add_child(l)
	_world_layer = l


func _make_mote_texture() -> Texture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 10
	tex.height = 10
	return tex


func _build_motes() -> void:
	_motes = CPUParticles2D.new()
	_motes.name = "Motes"
	_motes.emitting = true
	_motes.amount = 26
	_motes.lifetime = 7.0
	_motes.preprocess = 7.0
	_motes.texture = _make_mote_texture()
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.direction = Vector2(0, -1)
	_motes.spread = 25.0
	_motes.gravity = Vector2(0, -3)
	_motes.initial_velocity_min = 6.0
	_motes.initial_velocity_max = 14.0
	_motes.scale_amount_min = 0.35
	_motes.scale_amount_max = 0.7
	_motes.color = Color(1.0, 0.93, 0.62, 0.16)
	add_child(_motes)


func _layout_screen_fx() -> void:
	if _motes == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var size: Vector2 = vp.get_visible_rect().size
	_motes.position = Vector2(size.x * 0.5, size.y * 0.5)
	_motes.emission_rect_extents = Vector2(size.x * 0.55, size.y * 0.4)


func _build_decor_textures() -> void:
	if _bg_tex != null and _vignette_tex != null:
		return
	var bg := Gradient.new()
	bg.offsets = PackedFloat32Array([0.0, 1.0])
	bg.colors = PackedColorArray([Color("#2b3831"), KarmaDraw.MEADOW_B])
	var bg_tex := GradientTexture2D.new()
	bg_tex.gradient = bg
	bg_tex.fill = GradientTexture2D.FILL_RADIAL
	bg_tex.fill_from = Vector2(0.5, 0.5)
	bg_tex.fill_to = Vector2(0.5, 0.0)
	bg_tex.width = 256
	bg_tex.height = 256
	_bg_tex = bg_tex
	var vg := Gradient.new()
	vg.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	vg.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.42)])
	var vg_tex := GradientTexture2D.new()
	vg_tex.gradient = vg
	vg_tex.fill = GradientTexture2D.FILL_RADIAL
	vg_tex.fill_from = Vector2(0.5, 0.5)
	vg_tex.fill_to = Vector2(0.5, 0.0)
	vg_tex.width = 256
	vg_tex.height = 256
	_vignette_tex = vg_tex


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
	sb.shadow_color = Color(0, 0, 0, 0.40)
	sb.shadow_size = 8.0
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _make_side_panel(layer: CanvasLayer, panel_name: String, right_edge: bool, width: float) -> VBoxContainer:
	var frame: PanelContainer = PanelContainer.new()
	frame.name = panel_name
	# Anchor the frame to its viewport edge so a window resize keeps it
	# pinned: the right panel uses anchor 1 with negative offsets.
	frame.anchor_top = 0.0
	frame.anchor_bottom = 0.0
	frame.offset_top = PANEL_MARGIN
	frame.offset_bottom = PANEL_MARGIN
	if right_edge:
		frame.anchor_left = 1.0
		frame.anchor_right = 1.0
		frame.offset_left = -(width + PANEL_MARGIN)
		frame.offset_right = -PANEL_MARGIN
		frame.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	else:
		frame.offset_left = PANEL_MARGIN
		frame.offset_right = PANEL_MARGIN + width
		frame.grow_horizontal = Control.GROW_DIRECTION_END
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


# A videogame-style vital: icon+name, then a rounded ProgressBar whose fill
# tint follows the value (green→yellow→red) with the number drawn on top of
# the track. Registered as: _bars[key], _bar_fills[key], _labels[key+"_val"].
func _make_vital_bar(box: VBoxContainer, key: String, icon_txt: String, name_txt: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = key + "_row"
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var name_l: Label = Label.new()
	name_l.name = key + "_name"
	name_l.text = icon_txt + " " + name_txt
	name_l.custom_minimum_size = Vector2(72, 16)
	name_l.add_theme_font_size_override("font_size", 11)
	name_l.add_theme_color_override("font_color", Color("#e8ede9"))
	name_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_l.add_theme_constant_override("shadow_offset_x", 1)
	name_l.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(name_l)
	var bar: ProgressBar = ProgressBar.new()
	bar.name = key
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 0.5
	bar.value = 0.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(120, 16)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = KarmaDraw.HP_GOOD
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var val: Label = Label.new()
	val.name = key + "_val"
	val.set_anchors_preset(Control.PRESET_FULL_RECT)
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", 10)
	val.add_theme_color_override("font_color", Color("#ffffff"))
	val.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	val.add_theme_constant_override("shadow_offset_x", 1)
	val.add_theme_constant_override("shadow_offset_y", 1)
	bar.add_child(val)
	_bars[key] = bar
	_bar_fills[key] = fill
	_labels[key + "_val"] = val


# Value + numeric overlay + fill tint in one call; frac is 0..1.
func _set_bar(key: String, frac: float, txt: String) -> void:
	if not _bars.has(key):
		return
	var bar: ProgressBar = _bars[key] as ProgressBar
	bar.value = clampf(frac, 0.0, 1.0) * 100.0
	(_bar_fills[key] as StyleBoxFlat).bg_color = KarmaDraw.hp_color(frac)
	_set_text(key + "_val", txt)


func _build_hud() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	# Left: other-animals feed. Right: status + controls + verbs + shop + log.
	# Center (~280..1000) stays clear so the world stays visible.
	var left: VBoxContainer = _make_side_panel(layer, "LeftPanel", false, PANEL_W)
	_add_hud_label(left, "others_title", PANEL_W, 20.0)
	_add_hud_label(left, "others", PANEL_W, 40.0)
	var right: VBoxContainer = _make_side_panel(layer, "RightPanel", true, PANEL_W)
	_add_hud_label(right, "species", PANEL_W, 20.0)
	for bar_def in [["vida", "❤", "Vida"], ["hambre", "🍖", "Hambre"], ["sed", "💧", "Sed"]]:
		_make_vital_bar(right, str(bar_def[0]), str(bar_def[1]), str(bar_def[2]))
	for key in ["karma", "edad", "weather", "prompt"]:
		_add_hud_label(right, key, PANEL_W, 20.0)
	_add_hud_label(right, "diet", PANEL_W, 20.0)
	_add_hud_label(right, "controls_title", PANEL_W, 16.0)
	_add_hud_label(right, "controls", PANEL_W, 110.0)
	_add_hud_label(right, "verbs", PANEL_W, 90.0)
	_add_hud_label(right, "shop", PANEL_W, 60.0)
	_add_hud_label(right, "log_title", PANEL_W, 16.0)
	_add_hud_label(right, "log", PANEL_W, 84.0)
	_style_hud_label("species", 14, Color("#ffd54f"))
	_style_hud_label("karma", 13, Color("#ffd54f"))
	_style_hud_label("edad", 11, Color("#b0bec5"))
	_style_hud_label("weather", 12, Color("#81d4fa"))
	_style_hud_label("prompt", 12, Color("#80deea"))
	_style_hud_label("diet", 11, Color("#a5d6a7"))
	_style_hud_label("controls", 12, Color("#dcedc8"))
	_style_hud_label("verbs", 12, Color("#dcedc8"))
	_style_hud_label("shop", 12, Color("#ffe0b2"))
	_style_hud_label("log", 11, Color("#b0bec5"))
	_style_hud_label("others_title", 13, Color("#ffd54f"))
	_style_hud_label("others", 11, Color("#a5d6a7"))
	_style_hud_label("controls_title", 12, Color("#ffd54f"))
	_style_hud_label("log_title", 12, Color("#ffd54f"))


func _build_modal() -> void:
	var layer: CanvasLayer = get_node("HUD") as CanvasLayer
	_modal_dim = ColorRect.new()
	_modal_dim.name = "ModalDim"
	_modal_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dim.color = Color(0, 0, 0, 0.55)
	_modal_dim.visible = false
	layer.add_child(_modal_dim)
	# Full-rect CenterContainer: the dialog stays exactly centered no
	# matter how its content grows (roulette rows resize it every frame).
	var center: CenterContainer = CenterContainer.new()
	center.name = "ModalCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.visible = false
	layer.add_child(center)
	_modal_panel = PanelContainer.new()
	_modal_panel.name = "ModalPanel"
	_modal_panel.custom_minimum_size = Vector2(460, 0)
	_modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffd54f")))
	_modal_panel.visible = false
	center.add_child(_modal_panel)
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
	_apply_modal_button_theme(primary, close_b)


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
	var center := _modal_panel.get_parent()
	if center is Control:
		(center as Control).visible = open
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
	var b_t0: int = Time.get_ticks_usec() if _bench_on else 0
	var dt: float = minf(delta, 0.05)
	var frozen: String = KarmaModals.active_modal(state)
	if frozen != "":
		if frozen == "birth":
			_birth_t += dt
			if _bench_on and _birth_t > KarmaModals.SETTLE_AFTER + 1.0:
				_on_modal_primary()
				_birth_t = 0.0
		if frozen == "judgment":
			_judge_t += dt
		queue_redraw()
		_hud_t += dt
		if _hud_t >= 0.15:
			_hud_t = 0.0
			_refresh_hud()
		if _bench_on:
			_bench_frames += 1
			_bench_note("tick_modal", Time.get_ticks_usec() - b_t0)
			if _bench_log_t >= 2.0:
				_bench_report()
	if _bench_on and _bench_shot and float(state.get("time", 0.0)) > 2.5:
		_bench_shot = false
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("res://reports/bench_shot.png")
		return
	if not bool(state.get("dead", false)):
		var axes: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# One solids snapshot per tick shared by movement + sim (see KarmaGame).
		var solids: Array = KarmaUtils.collect_solids(state)
		KarmaGame.move_player(state, axes.x, axes.y, dt, solids)
		KarmaGame.update(state, dt, rng, solids)
		var plp: Vector2 = Vector2(float(KarmaState.px(state)), float(KarmaState.py(state)))
		if axes.length() > 0.05 and not bool((KarmaState.player(state) as Dictionary).get("hidden", false)):
			if not _wake_has or KarmaUtils.dist2(_wake_last.x, _wake_last.y, plp.x, plp.y) > 196.0:
				for w: Dictionary in state.get("waters", []):
					if KarmaUtils.dist2(float(w["x"]), float(w["y"]), plp.x, plp.y) < float(w["r"]) * float(w["r"]):
						_wake.append({"x": plp.x, "y": plp.y, "t": float(state.get("time", 0.0))})
						if _wake.size() > 24:
							_wake.pop_front()
						break
				_wake_last = plp
				_wake_has = true
		if _bench_on:
			_bench_note("sim", Time.get_ticks_usec() - b_t0)
		var b_j: int = Time.get_ticks_usec() if _bench_on else 0
		_jev_poll()
		if _bench_on:
			_bench_note("jev", Time.get_ticks_usec() - b_j)
		_jev_flush_t += dt
		if _jev_flush_t >= 0.5:
			_jev_flush_t = 0.0
			var b_f: int = Time.get_ticks_usec() if _bench_on else 0
			_jev_flush_log()
			if _bench_on:
				_bench_note("flush", Time.get_ticks_usec() - b_f)
		var cam_d: Dictionary = KarmaState.player(state)["cam"]
		var vp := _vp_size()
		cam_d["x"] = clampf(float(KarmaState.px(state)) - vp.x / 2.0, 0.0, float(KarmaData.WORLD["w"]) - vp.x)
		cam_d["y"] = clampf(float(KarmaState.py(state)) - vp.y / 2.0, 0.0, float(KarmaData.WORLD["h"]) - vp.y)
	queue_redraw()
	# Movement + sim stay every physics tick (smooth 60fps motion); HUD is
	# text-only and refreshed on a timer instead.
	_hud_t += dt
	if _hud_t >= 0.15:
		_hud_t = 0.0
		_refresh_hud()
	if _bench_on:
		_bench_frames += 1
		_bench_log_t += dt
		if _bench_log_t >= 2.0:
			_bench_report()


func _set_text(key: String, txt: String) -> void:
	if str(_hud_cache.get(key, "")) == txt:
		return
	_hud_cache[key] = txt
	(_labels[key] as Label).text = txt


func _refresh_hud() -> void:
	var b_h: int = Time.get_ticks_usec() if _bench_on else 0
	if _labels.is_empty():
		return
	var pl: Variant = KarmaState.player(state)
	_set_text("species", "◆ %s T%d · ⏱ %s" % [str(state["sp"]["name"]), int(state["sp"]["tier"]), KarmaUtils.fmt_time(float(state.get("time", 0.0)))])
	_set_bar("vida", KarmaHud.hp_frac(state), "%d/%d" % [int(ceil(float(pl.get("hp", 0.0)))), int(KarmaState.eff_max_hp_for(state))])
	_set_bar("hambre", KarmaHud.hunger_frac(state), "%d" % int(pl.get("hambre", 0.0)))
	_set_bar("sed", KarmaHud.thirst_frac(state), "%d" % int(pl.get("sed", 0.0)))
	_set_text("karma", "◈ PA %d · Karma %d%s" % [int(state.get("pa", 0.0)), int(state.get("karma", 0.0)), " · MUERTO (R reencarnar)" if bool(state.get("dead", false)) else ""])
	_set_text("edad", KarmaHud.edad_line(state))
	_set_text("weather", KarmaHud.weather_line(state))
	_set_text("prompt", KarmaHud.prompt_line(state))
	_set_text("diet", "Comen: %s" % KarmaState.diet_list_for(str(state["speciesKey"])))
	_set_text("controls_title", "CONTROLES ▼")
	_set_text("log_title", "REGISTRO ▼ (tu historia)")
	_set_text("others_title", "▼ OTROS ANIMALES (log CPU)")
	_set_text("others", "\n".join(KarmaHud.other_feed_lines(state)))
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
	if _bench_on:
		_bench_note("hud", Time.get_ticks_usec() - b_h)


func _process(delta: float) -> void:
	if skip_intro and not state.is_empty():
		state["introDone"] = true
	if _bench_on and delta > 0.03:
		print("BENCH SPIKE %.1fms t=%.0fs %s unreported=%s" % [delta * 1000.0, float(state.get("time", 0.0)), str(_bench_counts()), str(_bench_usec)])


func _bench_note(phase: String, usec: int) -> void:
	_bench_usec[phase] = int(_bench_usec.get(phase, 0)) + usec
	_bench_peak[phase] = maxi(int(_bench_peak.get(phase, 0)), usec)


func _bench_counts() -> Dictionary:
	var foods := 0
	for key in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps", "waters", "rocks", "refuges", "seedlings"]:
		foods += (state.get(key, []) as Array).size()
	return {
		"agents": (state.get("agents", []) as Array).size(),
		"insects": (state.get("insects", []) as Array).size(),
		"carrions": (state.get("carrions", []) as Array).size(),
		"food": foods,
		"rain": bool((state.get("weather", {}) as Dictionary).get("raining", false)),
		"modal": KarmaModals.active_modal(state),
		"labels": _label_sizes.size(),
		"view": _vp_size(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"prims": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"obj": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
	}


func _bench_report() -> void:
	var phases := PackedStringArray()
	for phase: String in _bench_usec:
		phases.append("%s avg=%.2fms peak=%.2fms" % [phase, int(_bench_usec[phase]) / 1000.0 / float(_bench_frames), int(_bench_peak[phase]) / 1000.0])
	print("BENCH t=%.0fs fps=%.0f frames=%d %s | %s" % [float(state.get("time", 0.0)), Performance.get_monitor(Performance.TIME_FPS), _bench_frames, str(_bench_counts()), " ".join(phases)])
	_bench_usec.clear()
	_bench_peak.clear()
	_bench_frames = 0
	_bench_log_t = 0.0


func _medal(pos: Vector2, radius: float, fill: Color, glyph: String, glyph_size: float, font: Font, outline: Color = Color(0, 0, 0, 0), ring_width: float = 0.0) -> void:
	# MSAA 4x covers edge smoothness; per-primitive antialiasing inside the
	# heavy furniture loop doubles its primitive count for no visible gain.
	draw_circle(pos + Vector2(2, 3), radius, KarmaDraw.SHADOW)
	draw_circle(pos, radius, fill)
	var segs: int = maxi(8, int(radius))
	draw_arc(pos, radius - 1.0, 0, TAU, segs, KarmaDraw.RIM, 2.0)
	if ring_width > 0.0:
		draw_arc(pos, radius + 2.0, 0, TAU, segs, outline, ring_width)
	var w: float = maxf(radius * 2.0, 40.0) + 16.0
	draw_string(font, pos + Vector2(-w / 2.0, glyph_size * 0.35), glyph, HORIZONTAL_ALIGNMENT_CENTER, w, glyph_size, Color.WHITE)


func _sync_label_font(font: Font) -> void:
	if font == _label_font:
		return
	_label_font = font
	_label_sizes.clear()
	_label_order.clear()


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
		_label_sizes.erase(_label_order[0])
		_label_order.remove_at(0)
	_label_sizes[key] = size
	_label_order.append(key)
	return size


func _pill(pos: Vector2, text: String, font: Font, fs: int, text_color: Color = Color("#ffffff")) -> void:
	_pill_calls += 1
	var size: Vector2 = _measure_label(font, text, fs, _uses_label_cache())
	var cap: float = (fs + 9.0) * 0.5
	var rect: Rect2 = Rect2(pos - Vector2(size.x / 2.0 + cap, 0), Vector2(size.x + cap * 2.0, fs + 9.0))
	# Soft capsule: body + rounded caps + faded rim (no hard rectangle).
	draw_rect(rect, KarmaDraw.PILL_BG)
	draw_circle(Vector2(rect.position.x + cap, rect.position.y + cap), cap, KarmaDraw.PILL_BG)
	draw_circle(Vector2(rect.end.x - cap, rect.position.y + cap), cap, KarmaDraw.PILL_BG)
	draw_line(Vector2(rect.position.x + cap, rect.position.y + 0.5), Vector2(rect.end.x - cap, rect.position.y + 0.5), KarmaDraw.PILL_RIM, 1.0)
	draw_line(Vector2(rect.position.x + cap, rect.end.y - 0.5), Vector2(rect.end.x - cap, rect.end.y - 0.5), KarmaDraw.PILL_RIM, 1.0)
	draw_arc(Vector2(rect.position.x + cap, rect.position.y + cap), cap - 0.5, PI * 0.5, PI * 1.5, 12, KarmaDraw.PILL_RIM, 1.0, true)
	draw_arc(Vector2(rect.end.x - cap, rect.position.y + cap), cap - 0.5, -PI * 0.5, PI * 0.5, 12, KarmaDraw.PILL_RIM, 1.0, true)
	draw_string(font, rect.position + Vector2(cap, fs + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)


func _hp_bar(pos: Vector2, w: float, frac: float) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(w / 2.0, 0), Vector2(w, 4.0))
	draw_rect(rect, KarmaDraw.PILL_BG)
	draw_circle(Vector2(rect.position.x + 2.0, rect.position.y + 2.0), 2.0, KarmaDraw.PILL_BG)
	draw_circle(Vector2(rect.end.x - 2.0, rect.position.y + 2.0), 2.0, KarmaDraw.PILL_BG)
	var f: float = clampf(frac, 0.0, 1.0)
	if f > 0.0:
		var fill_w: float = w * f
		draw_rect(Rect2(rect.position, Vector2(fill_w, 4.0)), KarmaDraw.hp_color(f))
		if fill_w > 2.0:
			draw_circle(Vector2(rect.position.x + fill_w - 2.0, rect.position.y + 2.0), 2.0, KarmaDraw.hp_color(f))
	draw_arc(Vector2(rect.position.x + 2.0, rect.position.y + 2.0), 1.8, PI * 0.5, PI * 1.5, 8, Color(1, 1, 1, 0.25), 1.0, true)
	draw_arc(Vector2(rect.end.x - 2.0, rect.position.y + 2.0), 1.8, -PI * 0.5, PI * 0.5, 8, Color(1, 1, 1, 0.25), 1.0, true)
	draw_line(Vector2(rect.position.x + 2.0, rect.position.y + 0.4), Vector2(rect.end.x - 2.0, rect.position.y + 0.4), Color(1, 1, 1, 0.25), 1.0)
	draw_line(Vector2(rect.position.x + 2.0, rect.end.y - 0.4), Vector2(rect.end.x - 2.0, rect.end.y - 0.4), Color(1, 1, 1, 0.25), 1.0)


func _draw() -> void:
	if state.is_empty():
		return
	var b_d: int = Time.get_ticks_usec() if _bench_on else 0
	var pl: Variant = KarmaState.player(state)
	var cam_dict: Dictionary = pl.get("cam", {})
	var cam: Vector2 = Vector2(float(cam_dict.get("x", 0.0)), float(cam_dict.get("y", 0.0)))
	var font: Font = ThemeDB.fallback_font
	_sync_label_font(font)
	_pill_calls = 0
	var t: float = float(state.get("time", 0.0))
	# Screen-space visible rect + margin: skipping off-screen circles AND
	# their draw_string labels (font shaping is the expensive part) is the
	# main _draw win. Everything reads the live viewport size so a window
	# resize just widens the view.
	var vp: Vector2 = _vp_size()
	var view: Rect2 = Rect2(Vector2(-48, -48), vp + Vector2(96.0, 96.0))
	if _vignette_tex == null:
		_build_decor_textures()
	# Baked static furniture: blit the SubViewport texture as ONE quad so the
	# per-frame scene stays small with or without rain. Fallback: plain meadow
	# color for the first frame(s), before the bake has rasterized.
	var bake_tex: Texture2D = null
	var b_origin: Vector2 = Vector2.ZERO
	var b_area: Vector2 = Vector2.ZERO
	if _world_layer != null:
		bake_tex = (_world_layer as SubViewport).get_texture()
		var lz: Variant = _world_layer
		b_origin = lz.blit_origin
		b_area = lz.blit_area
	if bake_tex != null and b_area != Vector2.ZERO:
		draw_texture_rect(bake_tex, Rect2(b_origin - cam, b_area), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, vp), KarmaDraw.MEADOW_B)
	var raining: bool = bool((state.get("weather", {}) as Dictionary).get("raining", false))
	for w: Dictionary in state.get("waters", []):
		var wpos: Vector2 = Vector2(float(w["x"]), float(w["y"])) - cam
		if not view.has_point(wpos):
			continue
		var body: Dictionary = KarmaDraw.water_disc(w)
		var wr: float = float(body["r"])
		# Waters live on the per-frame overlay: levels refill continuously
		# during rain, so baking them would rebake every tick.
		draw_circle(wpos, wr + 5.0, KarmaDraw.SHORE)
		draw_circle(wpos, wr, KarmaDraw.DRY_BASIN)
		if not bool(body["dry"]):
			draw_circle(wpos, float(body["fill"]), body["color"], true, -1.0, true)
			draw_arc(wpos, wr - 3.0, PI * 0.9, PI * 1.7, 12, Color(1, 1, 1, 0.25), 2.0)
			# Display-only ripple: an expanding ring that fades out.
			var rt: float = fposmod(t * 0.45, 1.0)
			draw_arc(wpos, wr * (0.15 + 0.8 * rt), 0.0, TAU, 16, Color(1, 1, 1, 0.16 * (1.0 - rt)), 1.5)
			if raining:
				# Two deterministic glints dancing on the surface (rain).
				var ph: float = fposmod(float(w["x"]) * 0.37 + float(w["y"]) * 0.71, 1.0)
				for gi in 2:
					var gl: float = fposmod(t * 1.3 + ph + float(gi) * 0.5, 1.0)
					var ga: float = TAU * fposmod(ph * 7.0 + float(gi) * 0.31, 1.0)
					var gpos: Vector2 = wpos + Vector2(cos(ga), sin(ga)) * wr * 0.4 * gl
					draw_circle(gpos, 1.5, Color(0.88, 0.96, 1.0, 0.45 * (1.0 - gl)))
		_medal(wpos, 11.0, Color(0, 0, 0, 0.25), KarmaDraw.water_icon(str(w.get("kind", ""))), 13.0, font)
		var wlabel: String = "seco" if bool(body["dry"]) else str(KarmaDraw.WATER_LABEL.get(str(w.get("kind", "")), "agua"))
		_pill(wpos + Vector2(0, wr + 16.0), wlabel, font, 11)
	# Player ripple wake (display-only): fading rings where the player swam.
	var wake_alive: Array = []
	for w: Dictionary in _wake:
		var age: float = t - float(w["t"])
		if age > 1.0:
			continue
		wake_alive.append(w)
		var wpos2: Vector2 = Vector2(float(w["x"]), float(w["y"])) - cam
		if view.has_point(wpos2):
			draw_arc(wpos2, 3.0 + age * 14.0, 0.0, TAU, 12, Color(0.78, 0.88, 1.0, 0.25 * (1.0 - age)), 1.2)
	_wake = wake_alive
	# Hidden-refuge ring (player-only state, so it stays on the overlay).
	if bool(pl.get("hidden", false)) and pl.get("hideRef") is Dictionary:
		var hr: Dictionary = pl["hideRef"]
		var hpos: Vector2 = Vector2(float(hr["x"]), float(hr["y"])) - cam
		if view.has_point(hpos):
			draw_arc(hpos, 18.0, 0, TAU, 16, Color("#80deea"), 2.0)
	var nose_adapt: bool = KarmaShop.has_adapt(state, "nose")
	var px: float = float(KarmaState.px(state))
	var py: float = float(KarmaState.py(state))
	var vis: float = KarmaState.eff_vision(state)
	var vis2: float = vis * vis
	# Flagged (nose) highlight only: the flora medals/pills live in _world_layer.
	if nose_adapt:
		for key: String in ["bushes", "clusters"]:
			for p: Dictionary in state.get(key, []):
				var fpos: Vector2 = Vector2(float(p["x"]), float(p["y"])) - cam
				if not view.has_point(fpos):
					continue
				var trapped: bool = (bool(p.get("mimic", false)) and not bool(p.get("mimicEaten", false))) or int(p.get("toxicLeft", 0)) > 0
				if not trapped:
					continue
				var fdx: float = float(p["x"]) - px
				var fdy: float = float(p["y"]) - py
				if fdx * fdx + fdy * fdy > vis2:
					continue
				draw_arc(fpos, 12.0, 0, TAU, 16, Color("#ffd54f"), 2.0)
	var insects: Array = state.get("insects", [])
	for i in insects.size():
		var ins: Dictionary = insects[i]
		var ipos: Vector2 = Vector2(float(ins["x"]), float(ins["y"])) - cam
		if not view.has_point(ipos):
			continue
		ipos.y += sin(t * 4.0 + float(ins["x"]) * 0.13) * 1.5
		_medal(ipos, 7.0, KarmaDraw.INSECT_MEDAL, KarmaDraw.food_icon("insects"), 12.0, font)
	for c: Dictionary in state.get("carrions", []):
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
	var pcenter: Vector2 = Vector2(px, py) - cam
	# Rotating dashed vision ring (display-only).
	var dash_count := 24
	var dash_a: float = t * 0.5
	for i in dash_count:
		var a0: float = TAU * float(i) / float(dash_count) + dash_a
		draw_arc(pcenter, vis, a0, a0 + TAU / float(dash_count) * 0.5, 6, Color(1, 1, 1, 0.30), 1.5)
	if float(pl.get("thermalT", 0.0)) > 0.0:
		draw_arc(pcenter, vis + 6.0, 0, TAU, 32, Color("#ffd54f"), 1.5)
	if float(pl.get("revealT", 0.0)) > 0.0:
		draw_arc(pcenter, vis * 0.5, 0, TAU, 24, Color("#80deea"), 1.5)
	var tracked: Variant = KarmaState.tracked_carrion(state)
	if tracked is Dictionary:
		var tpos: Vector2 = Vector2(float((tracked as Dictionary)["x"]), float((tracked as Dictionary)["y"])) - cam
		draw_line(pcenter, tpos, Color(1, 0.84, 0.31, 0.5), 1.5)
		draw_arc(tpos, 14.0, 0, TAU, 12, Color("#ffd54f"), 2.0)
	var _agents_arr: Array = state.get("agents", [])
	var _player_species: String = str(state.get("speciesKey", ""))
	for a: Dictionary in _agents_arr:
		var pos: Vector2 = Vector2(float(a["x"]), float(a["y"])) - cam
		if pos.x < -40 or pos.y < -40 or pos.x > VIEW_W + 40.0 or pos.y > VIEW_H + 40.0:
			continue
		var a_species: String = str(a.get("speciesKey", "raton"))
		var sp: Dictionary = KarmaData.SPECIES.get(a_species, KarmaData.SPECIES["raton"])
		var col: Color = KarmaDraw.species_medal(a_species)
		if str(a.get("brain", "")) != "PLAYER" and a_species == _player_species:
			col = col.darkened(0.2)
		var ar: float = float(sp["radius"]) * 0.7 + 5.0
		var ring: Color = Color(0, 0, 0, 0)
		var ring_w: float = 0.0
		if KarmaData.PRED.has(str(a.get("speciesKey", ""))):
			ring = Color("#ef5350")
			ring_w = 2.5
		_medal(pos, ar, col, KarmaDraw.species_icon(str(a.get("speciesKey", ""))), KarmaDraw.animal_emoji_size(str(a.get("speciesKey", ""))), font, ring, ring_w)
		var kc: Color = Color("#ffd54f") if float(a.get("karma", 0.0)) > 0.0 else (Color("#ef5350") if float(a.get("karma", 0.0)) < 0.0 else Color("#ffffff"))
		# Karma pill: the species emoji already lives in the medallion,
		# so show only the karma number here (no duplicate image).
		_pill(pos + Vector2(0, -ar - 22.0), "\u25c8 %d" % int(a.get("karma", 0.0)), font, 11, kc)
		_hp_bar(pos + Vector2(0, ar + 4.0), ar * 2.0, KarmaDraw.hp_frac_for_agent(a))
	var pp: Vector2 = Vector2(float(KarmaState.px(state)), float(KarmaState.py(state))) - cam
	var psp: Dictionary = state["sp"]
	var pr: float = float(psp["radius"]) + 4.0
	# Display-only soft aura under the player.
	draw_circle(pp, pr + 7.0, Color(0.20, 0.55, 1.0, 0.10))
	_medal(pp, pr, KarmaDraw.species_medal(str(state["speciesKey"])), KarmaDraw.species_icon(str(state["speciesKey"])), KarmaDraw.animal_emoji_size(str(state["speciesKey"])), font, Color("#ffffff"), 2.0)
	var face: Vector2 = Vector2(float((pl.get("face", {"x": 1.0}) as Dictionary).get("x", 1.0)), float((pl.get("face", {"y": 0.0}) as Dictionary).get("y", 0.0)))
	if face.length() > 0.01:
		face = face.normalized()
		var nose: Vector2 = pp + face * (pr + 9.0)
		var side: Vector2 = face.rotated(PI / 2.0) * 5.0
		draw_colored_polygon([nose, pp + face * (pr + 1.0) + side, pp + face * (pr + 1.0) - side], Color("#ffffff"))
	draw_arc(pp, pr + 3.0, 0, TAU, 16, Color("#1565c0"), 2.0)
	_pill(pp + Vector2(0, pr + 18.0), "TU %s" % str(psp["name"]), font, 12)
	_hp_bar(pp + Vector2(0, pr + 38.0), pr * 2.0 + 12.0, KarmaHud.hp_frac(state))
	if raining:
		# Streaks come from the Rain CPUParticles2D; here just the wash.
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.25, 0.45, 0.7, 0.10))
	var badge_y: float = 30.0
	var badge_x: float = vp.x - PANEL_W - PANEL_MARGIN - 240.0
	if bool(pl.get("hidden", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🙈 OCULTO", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#80deea"))
		badge_y += 18.0
	if bool(pl.get("grounded", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🛬 EN TIERRA", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#ffe0b2"))
		badge_y += 18.0
	if bool(pl.get("bristled", false)):
		draw_string(font, Vector2(badge_x, badge_y), "🦔 ERIZADO", HORIZONTAL_ALIGNMENT_RIGHT, 240, 13, Color("#ef5350"))
	# Vignette (radial gradient texture).
	draw_texture_rect(_vignette_tex, Rect2(Vector2.ZERO, vp), false)
	if raining:
		# Deterministic drawn rain: one draw_multiline_colors call (one color
		# per streak pair), streak speed/length/drift hashed per index.
		var pts: PackedVector2Array = PackedVector2Array()
		var cols: PackedColorArray = PackedColorArray()
		for i in _rain_streak_count(vp):
			var h: float = fposmod(sin(float(i) * 91.17) * 87791.5453, 1.0)
			var h2: float = fposmod(sin(h * 999.13) * 31221.7, 1.0)
			var speed: float = vp.y + 60.0 + 80.0 * h
			var phase: float = fposmod(t * speed / (vp.y + 40.0) + h2, 1.0)
			var x: float = fposmod(h * (vp.x + 24.0) + t * (-52.0 - 30.0 * h), vp.x + 24.0)
			var y: float = phase * (vp.y + 40.0) - 40.0
			var ln: float = 22.0 + 22.0 * (1.0 - h)
			var c := Color(0.78, 0.87, 1.0, 0.55 * sin(PI * phase))
			pts.append(Vector2(x, y))
			pts.append(Vector2(x - 0.08 * ln, y + ln))
			cols.append(c)
		draw_multiline_colors(pts, cols, 2.0)
	if _bench_on:
		_bench_note("draw", Time.get_ticks_usec() - b_d)


# One streak per 8 viewport px (at 1280: RAIN_STREAKS), floored so narrow
# windows still get a full-stage storm.
func _rain_streak_count(vp: Vector2) -> int:
	return maxi(RAIN_STREAKS_FLOOR, int(float(RAIN_STREAKS) * vp.x / 1280.0))


# Cached static furniture, baked once into a SubViewport texture:
# - _StaticPainter draws backdrop, grid, tufts, rocks, refuges, seedlings and
#   flora into the bake rect [origin, origin+area] in LOCAL coords
#   (world - origin); waters and everything animated render per frame on the
#   overlay instead (levels move continuously during rain).
# - _StaticLayer (SubViewport) triggers a rebake when the camera drifts past
#   half the edge margin or the world content signature changes, then re-arms
#   UPDATE_ONCE so the texture is rasterized exactly once per change.
# - Main._draw blits the baked texture every frame as a single quad, so the
#   per-frame scene stays small (no gray edges: the bake rect is view + edge
#   margin larger than the camera drift threshold).
class _StaticPainter extends Node2D:
	var main: Variant = null
	var baked: bool = false
	var edge_margin: float = LAYER_EDGE_MARGIN
	var origin: Vector2 = Vector2.ZERO
	var area: Vector2 = Vector2.ZERO
	var _sig: int = -2147483648

	# Cheap fold over every mutable field the painter paints (~250 dict probes,
	# well under a tenth of a millisecond) so content changes rebake within
	# one frame without instrumenting every mutation site. Waters are NOT
	# included: their fill animates on the overlay per frame.
	func _content_sig() -> int:
		var st: Dictionary = main.state as Dictionary
		var s: int = 0
		s = s * 31 + (st.get("seedlings", []) as Array).size()
		for key: String in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
			var arr: Array = st.get(key, [])
			s = s * 31 + arr.size()
			for p: Dictionary in arr:
				s = s * 7 + int(p["amount"])
				if bool(p.get("alive", false)):
					s += 1
				if int(p.get("toxicLeft", 0)) > 0:
					s += 7
				if bool(p.get("mimic", false)):
					s += 13
				if bool(p.get("mimicEaten", false)):
					s += 29
		return s

	func _draw() -> void:
		if main == null or (main.state as Dictionary).is_empty():
			return
		var st: Dictionary = main.state as Dictionary
		var b_l: int = Time.get_ticks_usec() if main._bench_on else 0
		if main._bg_tex == null or main._vignette_tex == null:
			main._build_decor_textures()
		var font: Font = ThemeDB.fallback_font
		main._sync_label_font(font)
		var t: float = float(st.get("time", 0.0))
		# Local coords: everything subtracts origin once here; the bake rect
		# [origin, origin+area] is blitted to the screen as one texture quad.
		draw_rect(Rect2(Vector2.ZERO, area), KarmaDraw.MEADOW_B)
		draw_texture_rect(main._bg_tex, Rect2(Vector2.ZERO, area), false)
		var grid: PackedVector2Array = PackedVector2Array()
		var step: float = KarmaDraw.GRID_STEP
		var gx: float = floorf(origin.x / step) * step
		while gx <= origin.x + area.x:
			grid.append(Vector2(gx - origin.x, 0.0))
			grid.append(Vector2(gx - origin.x, area.y))
			gx += step
		var gy: float = floorf(origin.y / step) * step
		while gy <= origin.y + area.y:
			grid.append(Vector2(0.0, gy - origin.y))
			grid.append(Vector2(area.x, gy - origin.y))
			gy += step
		draw_multiline(grid, KarmaDraw.GRID_LINE, 1.0)
		# Deterministic grass tufts (display-only): hashed per world cell. The
		# sway is sampled at bake time, so it settles between rebakes.
		var cell := 96.0
		var tufts: PackedVector2Array = PackedVector2Array()
		var cell_x0: int = int(floorf(origin.x / cell))
		var cell_y0: int = int(floorf(origin.y / cell))
		for ix in int(ceilf(area.x / cell)) + 1:
			for iy in int(ceilf(area.y / cell)) + 1:
				var h: float = sin(float(cell_x0 + ix) * 91.17 + float(cell_y0 + iy) * 37.91) * 43758.5453
				h -= floorf(h)
				if h < 0.80:
					continue
				var bx: float = float(cell_x0 + ix) * cell + (h - 0.5) * cell
				var h2: float = sin(h * 999.13) * 31221.7
				h2 -= floorf(h2)
				var by: float = float(cell_y0 + iy) * cell + h2 * cell
				var sway: float = sin(t * 1.6 + h * TAU) * 2.0
				tufts.append(Vector2(bx - origin.x, by - origin.y))
				tufts.append(Vector2(bx - origin.x + sway * 0.5, by - origin.y - 6.0))
				tufts.append(Vector2(bx + 4.0 - origin.x, by - origin.y))
				tufts.append(Vector2(bx + 4.0 - origin.x + sway, by - origin.y - 9.0))
				tufts.append(Vector2(bx - 4.0 - origin.x, by - origin.y))
				tufts.append(Vector2(bx - 4.0 - origin.x + sway * 0.6, by - origin.y - 5.0))
		if not tufts.is_empty():
			draw_multiline(tufts, Color(0.62, 0.78, 0.50, 0.16), 1.5)
		for k: Dictionary in st.get("rocks", []):
			var kpos: Vector2 = Vector2(float(k["x"]), float(k["y"])) - origin
			if kpos.x < -32.0 or kpos.y < -32.0 or kpos.x > area.x + 32.0 or kpos.y > area.y + 32.0:
				continue
			draw_circle(kpos + Vector2(2, 3), 9.0, KarmaDraw.SHADOW)
			draw_circle(kpos, 9.0, KarmaDraw.ROCK_BODY)
			draw_circle(kpos + Vector2(-2, -2), 5.0, KarmaDraw.ROCK_TOP)
			_l_medal(kpos, 7.0, Color(0, 0, 0, 0.2), "🪨", 10.0, font)
		for r: Dictionary in st.get("refuges", []):
			var rpos: Vector2 = Vector2(float(r["x"]), float(r["y"])) - origin
			if rpos.x < -40.0 or rpos.y < -40.0 or rpos.x > area.x + 40.0 or rpos.y > area.y + 40.0:
				continue
			var rtype: String = str(r["type"])
			var rmedal: Color = KarmaDraw.refuge_medal(rtype)
			var rr: float = KarmaDraw.refuge_emoji_size(rtype) * 0.62 + 6.0
			_l_medal(rpos, rr, rmedal, KarmaDraw.refuge_icon(rtype), KarmaDraw.refuge_emoji_size(rtype), font)
			if rtype.begins_with("burrow"):
				draw_circle(rpos, rr * 0.55, Color(0, 0, 0, 0.55))
			_l_pill(rpos + Vector2(0, rr + 16.0), str(KarmaDraw.REFUGE_LABEL.get(rtype, rtype)), font, 11)
		for s: Dictionary in st.get("seedlings", []):
			var spos: Vector2 = Vector2(float(s["x"]), float(s["y"])) - origin
			if spos.x < -20.0 or spos.y < -20.0 or spos.x > area.x + 20.0 or spos.y > area.y + 20.0:
				continue
			_l_medal(spos, 8.0, KarmaDraw.food_medal("leaves"), "🌱", 12.0, font)
		for key: String in ["bushes", "shrubs", "patches", "clusters", "oaks", "clumps"]:
			for p: Dictionary in st.get(key, []):
				var ppos: Vector2 = Vector2(float(p["x"]), float(p["y"])) - origin
				if ppos.x < -40.0 or ppos.y < -40.0 or ppos.x > area.x + 40.0 or ppos.y > area.y + 40.0:
					continue
				var kind: String = str(p.get("kind", key))
				if not bool(p.get("alive", false)) or int(p.get("amount", 0)) <= 0:
					_l_medal(ppos, 8.0, Color("#616161"), "✕", 12.0, font)
					_l_pill(ppos + Vector2(0, 24.0), "↻ recuperando", font, 11, Color("#b0bec5"))
					continue
				var trapped: bool = (bool(p.get("mimic", false)) and not bool(p.get("mimicEaten", false))) or int(p.get("toxicLeft", 0)) > 0
				var ring: Color = Color(0, 0, 0, 0)
				var ring_w: float = 0.0
				if trapped:
					ring = KarmaDraw.RIM
					ring_w = 2.0
				_l_medal(ppos, 10.0, KarmaDraw.food_medal(kind), KarmaDraw.food_icon(kind), 18.0, font, ring, ring_w)
				_l_pill(ppos + Vector2(0, 26.0), "%s x%d" % [str(KarmaDraw.FOOD_LABEL.get(kind, kind)), int(p["amount"])], font, 11)
		if main._bench_on:
			main._bench_note("layer", Time.get_ticks_usec() - b_l)

	func _l_medal(pos: Vector2, radius: float, fill: Color, glyph: String, glyph_size: float, font: Font, outline: Color = Color(0, 0, 0, 0), ring_width: float = 0.0) -> void:
		draw_circle(pos + Vector2(2, 3), radius, KarmaDraw.SHADOW)
		draw_circle(pos, radius, fill)
		var segs: int = maxi(8, int(radius))
		draw_arc(pos, radius - 1.0, 0, TAU, segs, KarmaDraw.RIM, 2.0)
		if ring_width > 0.0:
			draw_arc(pos, radius + 2.0, 0, TAU, segs, outline, ring_width)
		var w: float = maxf(radius * 2.0, 40.0) + 16.0
		draw_string(font, pos + Vector2(-w / 2.0, glyph_size * 0.35), glyph, HORIZONTAL_ALIGNMENT_CENTER, w, glyph_size, Color.WHITE)

	func _l_pill(pos: Vector2, text: String, font: Font, fs: int, text_color: Color = Color("#ffffff")) -> void:
		var size: Vector2 = main._measure_label(font, text, fs, true)
		var cap: float = (fs + 9.0) * 0.5
		var rect: Rect2 = Rect2(pos - Vector2(size.x / 2.0 + cap, 0), Vector2(size.x + cap * 2.0, fs + 9.0))
		draw_rect(rect, KarmaDraw.PILL_BG)
		draw_circle(Vector2(rect.position.x + cap, rect.position.y + cap), cap, KarmaDraw.PILL_BG)
		draw_circle(Vector2(rect.end.x - cap, rect.position.y + cap), cap, KarmaDraw.PILL_BG)
		draw_line(Vector2(rect.position.x + cap, rect.position.y + 0.5), Vector2(rect.end.x - cap, rect.position.y + 0.5), KarmaDraw.PILL_RIM, 1.0)
		draw_line(Vector2(rect.position.x + cap, rect.end.y - 0.5), Vector2(rect.end.x - cap, rect.end.y - 0.5), KarmaDraw.PILL_RIM, 1.0)
		draw_arc(Vector2(rect.position.x + cap, rect.position.y + cap), cap - 0.5, PI * 0.5, PI * 1.5, 12, KarmaDraw.PILL_RIM, 1.0, true)
		draw_arc(Vector2(rect.end.x - cap, rect.position.y + cap), cap - 0.5, -PI * 0.5, PI * 0.5, 12, KarmaDraw.PILL_RIM, 1.0, true)
		draw_string(font, rect.position + Vector2(cap, fs + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)


class _StaticLayer extends SubViewport:
	var main: Variant = null
	var painter: Node2D = null
	var edge_margin: float = LAYER_EDGE_MARGIN
	var cam_redraw: float = LAYER_CAM_REDRAW
	# The blit rect Main._draw pairs with get_texture(). On a drift rebake the
	# painter origin MOVES on this frame but UPDATE_ONCE rasterizes at frame's
	# end — committing the new rect next _process keeps the old texture paired
	# with its own rect for exactly one frame (no glitch while moving).
	var blit_origin: Vector2 = Vector2.ZERO
	var blit_area: Vector2 = Vector2.ZERO
	var _pending_origin: Vector2 = Vector2.ZERO
	var _pending_area: Vector2 = Vector2.ZERO
	var _pending: bool = false
	# Frames to wait before committing a pending bake rect, so the SubViewport
	# texture has actually rasterized before we pair the new rect with it.
	var _pending_frames: int = 0
	var _just_committed: bool = false
	var _has_bake: bool = false
	var _last_sig: int = -2147483648

	func _content_sig() -> int:
		return int(painter.call("_content_sig"))

	func _process(_delta: float) -> void:
		if main == null or (main.state as Dictionary).is_empty() or painter == null:
			return
		var world_w: float = float(KarmaData.WORLD["w"])
		var world_h: float = float(KarmaData.WORLD["h"])
		var area: Vector2 = Vector2(world_w, world_h)
		var area_i: Vector2i = Vector2i(area)
		if not _has_bake:
			# Bake the whole world once: a single full-world texture avoids any
			# camera-drift rebake, so the drawn rect never jumps while walking.
			if size != area_i:
				size = area_i
			(painter as Variant).origin = Vector2.ZERO
			(painter as Variant).area = area
			painter.queue_redraw()
			render_target_update_mode = SubViewport.UPDATE_ONCE
			blit_origin = Vector2.ZERO
			blit_area = area
			_has_bake = true
			_last_sig = int((painter as Variant).call("_content_sig"))
			return
		# Re-bake only when world content changes.
		var sig: int = int((painter as Variant).call("_content_sig"))
		if sig != _last_sig:
			_last_sig = sig
			if size != area_i:
				size = area_i
			(painter as Variant).origin = Vector2.ZERO
			(painter as Variant).area = area
			painter.queue_redraw()
			render_target_update_mode = SubViewport.UPDATE_ONCE
