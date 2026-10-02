class_name KarmaDraw
extends RefCounted

# Port of src/script/draw.js pure lookups (no canvas calls; main.gd draws).

const SPECIES_ICON := {"oruga": "🐛", "sapo": "🐸", "raton": "🐭", "ardilla": "🐿️", "topo": "🦔", "halcon": "🦅", "zorro": "🦊", "lobo": "🐺"}
const FOOD_ICON := {"berries": "🍒", "apples": "🍎", "carrots": "🥕", "mushrooms": "🍄", "nuts": "🌰", "leaves": "🍃", "insects": "🦗", "carrion": "🍖"}
const FOOD_LABEL := {"berries": "bayas", "apples": "manzana", "carrots": "zanahoria", "mushrooms": "setas", "nuts": "nuez", "leaves": "hojas", "insects": "insectos", "carrion": "carroña"}
const CARRION_ICON := {"fresh": "🍖", "stale": "🍗", "rotten": "🤢"}
const REFUGE_ICON := {"burrow-S": "🕳️", "burrow-M": "🕳️", "hollow-tree": "🪵", "thorn-bush": "🌵", "old-oak": "🌳", "leafroll": "🍂"}
const WATER_ICON := {"charco": "💧", "lago": "🌊"}
const WATER_LABEL := {"charco": "charco", "lago": "lago"}
const REFUGE_LABEL := {"burrow-S": "madriguera S", "burrow-M": "madriguera M", "hollow-tree": "tronco hueco", "thorn-bush": "zarza", "old-oak": "roble viejo", "leafroll": "hoja enrollada"}

const EMOJI_SIZE := {"animal": 28.0, "food": 18.0, "terrain": 15.0, "decor": 10.0}
const ANIMAL_SIZE_DELTA := {"oruga": -4.0, "sapo": -2.0, "raton": 0.0, "ardilla": 0.0, "topo": 0.0, "halcon": 4.0, "zorro": 4.0, "lobo": 6.0}
const REFUGE_SIZE := {"old-oak": 34.0, "hollow-tree": 26.0, "thorn-bush": 20.0, "burrow-S": 15.0, "burrow-M": 15.0}

const LEGEND_LINES := ["🐛oruga 🐸sapo 🐭ratón 🐿️ardilla", "🦔topo 🦅halcón 🦊zorro 🐺lobo", "🍒bayas 🍎manzana 🥕zanahoria", "🍄setas 🌰nuez 🍃hojas 🦗bicho", "🍖carroña 🕳️madriguera 🪵tronco", "🌵zarza 🌳roble 🪨roca 🌱brote"]

# Visual palette (display-only; gameplay numbers stay in KarmaData.TUNING).
const MEADOW_B := Color("#1c2620")
const GRID_LINE := Color(1, 1, 1, 0.045)
const SHADOW := Color(0, 0, 0, 0.30)
const RIM := Color(0, 0, 0, 0.35)
const PILL_BG := Color(0, 0, 0, 0.62)
const SHORE := Color("#8d9b6a")
const ROCK_BODY := Color("#607d8b")
const ROCK_TOP := Color("#90a4ae")
const INSECT_MEDAL := Color("#5d4037")

const FOOD_MEDAL := {
	"berries": Color("#c62828"), "apples": Color("#d81b60"), "carrots": Color("#ef6c00"),
	"mushrooms": Color("#795548"), "nuts": Color("#6d4c41"), "leaves": Color("#2e7d32"),
	"insects": Color("#f9a825"), "carrion": Color("#4e342e"),
}
const REFUGE_MEDAL := {
	"burrow-S": Color("#4e342e"), "burrow-M": Color("#5d4037"), "hollow-tree": Color("#6d4c41"),
	"thorn-bush": Color("#33691e"), "old-oak": Color("#1b5e20"), "leafroll": Color("#7cb342"),
}
const HP_GOOD := Color("#66bb6a")
const HP_MID := Color("#ffca28")
const HP_LOW := Color("#ef5350")

# Display-only world dressing step (gameplay counts stay in TUNING).
const GRID_STEP := 160.0


static func species_icon(form: String) -> String:
	return str(SPECIES_ICON.get(form, "❓"))


static func food_icon(kind: String) -> String:
	return str(FOOD_ICON.get(kind, "❓"))


static func refuge_icon(type: String) -> String:
	return str(REFUGE_ICON.get(type, "⛺"))


static func carrion_icon(stage: String) -> String:
	return str(CARRION_ICON.get(stage, "🍖"))


static func water_icon(kind: String) -> String:
	return str(WATER_ICON.get(kind, "💧"))


static func animal_emoji_size(form: String) -> float:
	return float(EMOJI_SIZE["animal"]) + float(ANIMAL_SIZE_DELTA.get(form, 0.0))


static func refuge_emoji_size(type: String) -> float:
	return float(REFUGE_SIZE.get(type, EMOJI_SIZE["terrain"]))


static func carrion_look(stage: String) -> Dictionary:
	if stage == "fresh":
		return {"meat": Color("#b03939"), "bone": Color("#efebe9"), "label": "carroña fresca"}
	if stage == "stale":
		return {"meat": Color("#795548"), "bone": Color("#d7ccc8"), "label": "carroña pasada"}
	return {"meat": Color("#33691e"), "bone": Color("#9e9e9e"), "label": "¡podrida: -25!"}


static func water_disc(w: Dictionary) -> Dictionary:
	return {"r": float(w["r"]), "color": Color("#1565c0") if str(w.get("kind", "")) == "lago" else Color("#42a5f5")}


static func species_medal(form: String) -> Color:
	return Color(str(KarmaData.SPECIES.get(form, {"color": "#ffffff"})["color"]))


static func food_medal(kind: String) -> Color:
	return FOOD_MEDAL.get(kind, Color("#757575"))


static func refuge_medal(type: String) -> Color:
	return REFUGE_MEDAL.get(type, Color("#546e7a"))


static func hp_frac(hp: float, max_hp: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


static func hp_color(frac: float) -> Color:
	if frac >= 0.55:
		return HP_GOOD
	if frac >= 0.25:
		return HP_MID
	return HP_LOW
