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
