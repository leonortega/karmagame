class_name KarmaData
extends RefCounted

# Port of src/script/data.js — all species/diet/tuning/shop/verb tables.
# Numbers are behavior; do not rebalance here.

const WORLD := {"w": 3200, "h": 2400}
const BASE_AREA := 1600 * 1200

const POP := {
	"company": 4,
	"faunaFloor": {"oruga": 2, "sapo": 2, "raton": 3, "ardilla": 3, "topo": 2, "halcon": 1, "zorro": 2, "lobo": 1},
}

const SPECIES := {
	"oruga": {"name": "Oruga", "tier": 0, "speed": 80.0, "vision": 130.0, "maxHp": 60.0, "radius": 8.0, "size": 1, "hungerMult": 1.5, "color": "#9ccc65", "desc": "Castigo: lenta, todos te cazan"},
	"sapo": {"name": "Sapo", "tier": 1, "speed": 110.0, "vision": 170.0, "maxHp": 80.0, "radius": 9.0, "size": 1, "hungerMult": 1.25, "color": "#4db6ac", "desc": "Lengua a 90px, cabe en madrigueras-S"},
	"raton": {"name": "Ratón", "tier": 1, "speed": 150.0, "vision": 190.0, "maxHp": 100.0, "radius": 10.0, "size": 2, "hungerMult": 1.0, "color": "#90caf9", "desc": "Base: equilibrado, puede gritar (Q)"},
	"ardilla": {"name": "Ardilla", "tier": 1, "speed": 175.0, "vision": 210.0, "maxHp": 90.0, "radius": 10.0, "size": 2, "hungerMult": 1.0, "climb": true, "color": "#ffcc80", "desc": "Lateral: rápida, trepa al árbol hueco"},
	"topo": {"name": "Topo", "tier": 1, "speed": 135.0, "vision": 150.0, "maxHp": 95.0, "radius": 10.0, "size": 2, "hungerMult": 1.1, "color": "#a1887f", "desc": "Cava madrigueras con E, puede gritar"},
	"halcon": {"name": "Halcón", "tier": 2, "speed": 215.0, "vision": 340.0, "maxHp": 140.0, "radius": 12.0, "size": 3, "hungerMult": 0.8, "color": "#ce93d8", "desc": "Premio: veloz, gran visión, debe aterrizar para comer"},
	"zorro": {"name": "Zorro", "tier": 2, "speed": 185.0, "vision": 260.0, "maxHp": 120.0, "radius": 11.0, "size": 3, "hungerMult": 0.85, "color": "#ff8a65", "desc": "Depredador jugable: Zarpazo (E), sin grito"},
	"lobo": {"name": "Lobo", "tier": 2, "speed": 165.0, "vision": 300.0, "maxHp": 160.0, "radius": 14.0, "size": 4, "hungerMult": 0.7, "color": "#4a3b52", "desc": "Ápice jugable: caza T2 y zorros, nadie lo caza"},
}

const DIET := {
	"oruga": ["leaves"], "sapo": ["insects"],
	"raton": ["berries", "apples", "carrots", "mushrooms", "nuts"],
	"ardilla": ["berries", "apples", "mushrooms", "nuts"],
	"topo": ["carrots", "insects", "nuts"],
	"halcon": ["carrion", "mates"], "zorro": ["carrion", "mates"], "lobo": ["carrion", "mates"],
}
const WATER_ENTER := {"sapo": true}
const DIET_HINT := {"oruga": "hojas", "sapo": "insectos", "raton": "bayas, manzanas, zanahorias, setas o nueces",
	"ardilla": "bayas, manzanas, setas o nueces", "topo": "zanahorias, insectos o nueces",
	"halcon": "carroña o presas", "zorro": "carroña o presas", "lobo": "carroña o presas"}
const FOODDEF := {
	"berries": {"hp": 15.0, "pa": 5.0}, "apples": {"hp": 22.0, "pa": 8.0}, "carrots": {"hp": 18.0, "pa": 5.0},
	"mushrooms": {"hp": 10.0, "pa": 0.0}, "leaves": {"hp": 12.0, "pa": 3.0}, "nuts": {"hp": 18.0, "pa": 5.0},
	"insects": {"hp": 10.0, "pa": 3.0},
}

const PRED := {
	"zorro": {"name": "Zorro", "speed": 100.0, "perception": 230.0, "damage": 28.0, "body": 26.0, "size": 3,
		"huntsTiers": [0, 1], "huntsMates": true, "huntsZorro": false, "fears": ["lobo"], "color": "#c8532a"},
	"lobo": {"name": "Lobo", "speed": 150.0, "perception": 280.0, "damage": 35.0, "body": 32.0, "size": 4,
		"huntsTiers": [2], "huntsMates": false, "huntsZorro": true, "fears": [], "color": "#4a3b52"},
	"saponpc": {"name": "Sapo", "speed": 70.0, "perception": 150.0, "damage": 10.0, "body": 14.0, "size": 1,
		"huntsForms": ["oruga"], "huntsMates": false, "huntsZorro": false, "fears": ["zorro", "lobo"], "color": "#4db6ac"},
}
const PRED_FALLBACK := {"name": "Depredador", "speed": 150.0, "perception": 250.0, "damage": 20.0,
	"body": 22.0, "size": 3, "huntsTiers": [], "huntsMates": false, "huntsZorro": false, "fears": ["lobo"]}
const TIER_SPAWNS := {0: ["zorro", "saponpc"], 1: ["zorro", "zorro"], 2: ["zorro", "lobo"]}
const T1POOL := ["raton", "ardilla", "topo", "sapo"]
const T2POOL := ["halcon", "zorro", "lobo"]

static var TUNING := _build_tuning()

static func _build_tuning() -> Dictionary:
	var hunger := 160.0 / (30.0 * 60.0 * 0.7)
	return {
		"hungerPerSec": hunger,
		"vidaRegenPerSec": hunger * 2.0,
		"paPerSec": 1.0 / 3.0,
		"lastFruitHp": 20.0, "lastFruitKarma": -15.0,
		"shoutKarma": 30.0, "shoutPa": 50.0, "shoutCooldown": 10.0, "shoutLureRange": 450.0,
		"predatorDamage": 28.0, "predatorInvuln": 1.0,
		"tierUpKarma": 50.0, "tierDownKarma": -50.0,
		"chaseMult": 1.35, "loboChaseMult": 1.3, "chaseMax": 6.0, "restTime": 2.0, "fleeHysteresis": 1.5,
		"snapRange": 25.0,
		"pounceCd": 6.0, "pounceRange": 70.0, "pounceHp": 25.0, "pouncePa": 10.0,
		"digCd": 20.0, "digMax": 3, "tongueRange": 90.0, "eatRange": 46.0,
		"campTime": 3.0, "hideRange": 40.0,
		"carrionFreshHp": 20.0, "carrionStaleHp": 8.0, "carrionRottenHp": -25.0,
		"carrionFreshT": 30.0, "carrionRottenT": 60.0, "carrionCap": 5, "carrionFreshPa": 5.0,
		"aiBuyEvery": 10.0, "aiKarmaGood": 30.0, "aiKarmaBad": -30.0, "aiPredPerceptMod": 0.2, "aiShoutLureTime": 5.0,
		"mimicHp": -20.0, "satedTime": 25.0,
		"wastefulHpFrac": 0.8, "wastefulKarma": -10.0, "strikeCd": 4.0,
		"mateRespawn": 45.0, "mateMax": 4,
		"respawnTime": 20.0,
		"landTime": 1.0,
		"leafRegrow": 60.0, "insectRespawn": 20.0, "insectMax": 6,
		"dietHintCd": 5.0, "groomRange": 30.0, "groomTime": 3.0, "groomCd": 30.0, "groomKarma": 5.0,
		"pestKarma": 3.0, "prudentKarma": 2.0, "aerateKarma": 3.0, "plantKarma": 10.0,
		"toxinKarma": 5.0, "chorusKarma": 5.0,
		"nectarKarma": 8.0, "leafrollKarma": 5.0, "leafrollTtl": 60.0,
		"seedCacheKarma": 5.0, "shareBiteHp": 15.0, "shareKarma": 8.0,
		"tailflickKarma": 10.0, "falseCacheKarma": 5.0, "barkPa": 5.0, "barkKarma": 2.0,
		"wormHp": 12.0, "wormPa": 5.0,
		"thermalTime": 8.0, "thermalVision": 150.0, "scareKarma": 5.0, "boneKarma": 5.0,
		"howlKarma": 10.0, "howlTime": 10.0, "regurgKarma": 15.0, "regurgCost": 8.0,
		"escortKarma": 12.0, "escortTime": 10.0, "cullKarma": 10.0,
		"loboStrikeKarma": 20.0, "strikeKarma": 5.0, "strikePa": 10.0, "strikeHp": 10.0,
		"cedeKarma": 15.0, "divePa": 10.0,
		"senseTremorCd": 25.0, "senseTrackCd": 30.0, "revealTime": 3.0, "trackTime": 5.0,
		"curlCd": 20.0, "saplingCap": 3,
		"fruitRegrow": 45.0, "seedSproutChance": 0.35, "seedlingMaturity": 75.0,
		"seedlingMax": 10, "seedScatter": 60.0, "oakTreeCap": 6,
		"rockCount": 8, "solidRefuge": 16.0, "solidPlant": 12.0, "solidRock": 14.0, "losSamples": 10,
		"regenHambre": 30.0, "regenSed": 30.0, "thirstMult": 2.0, "deficitMax": 2.0,
		"sipSed": 35.0, "sipHp": 5.0, "drinkRange": 46.0,
		"charcoCount": 6, "lagoCount": 2, "charcoR": 20.0, "lagoR": 95.0,
		"lakeInsectBias": 0.6, "lakeShore": 120.0,
		"forageRangeMult": 0.5, "hungerPriority": 0.4, "aiHideMax": 5.0, "aiCoverRange": 250.0, "lowHpPercept": 1.4,
		"aiFearRange": 200.0,
		"hopImpulse": 0.5, "hopRest": 0.6, "wormStretch": 1.3, "wormBurst": 0.35, "tunnelSpeed": 0.8,
		"groomSocialKarma": 2.0,
	}

const SHOP_BY_SPECIES := {
	"oruga": [
		{"id": "oruga_panza", "key": "1", "name": "Panza grande", "cost": 60.0, "desc": "+25 Vida máx y cura +25 (esta vida)", "effect": "stomach"},
		{"id": "oruga_seda", "key": "2", "name": "Seda gruesa", "cost": 60.0, "desc": "escape de seda más lejos (80px)", "effect": "silkPlus"},
		{"id": "oruga_hoja", "key": "3", "name": "Hoja maestra", "cost": 55.0, "desc": "hoja enrollada dura el doble", "effect": "leafrollPlus"},
	],
	"sapo": [
		{"id": "sapo_lengua", "key": "1", "name": "Lengua larga", "cost": 70.0, "desc": "lengua a 130px", "effect": "tonguePlus"},
		{"id": "sapo_toxina", "key": "2", "name": "Toxina potente", "cost": 60.0, "desc": "rocío con doble karma", "effect": "toxinPlus"},
		{"id": "sapo_coro", "key": "3", "name": "Coro mayor", "cost": 55.0, "desc": "coro con doble karma", "effect": "chorusPlus"},
	],
	"raton": [
		{"id": "raton_zarpas", "key": "1", "name": "Zarpas veloces", "cost": 60.0, "desc": "+15% velocidad (esta vida)", "effect": "swift"},
		{"id": "raton_ojeada", "key": "2", "name": "Ojeada experta", "cost": 65.0, "desc": "ojea el doble de tiempo", "effect": "scoutPlus"},
		{"id": "raton_bocado", "key": "3", "name": "Bocado generoso", "cost": 55.0, "desc": "compartir da doble karma", "effect": "sharePlus"},
	],
	"ardilla": [
		{"id": "ardilla_olfato", "key": "1", "name": "Olfato agudo", "cost": 60.0, "desc": "+50 visión y revela ponzoña", "effect": "nose"},
		{"id": "ardilla_corteza", "key": "2", "name": "Corteza dulce", "cost": 55.0, "desc": "doble PA y karma por corteza", "effect": "barkPlus"},
		{"id": "ardilla_engano", "key": "3", "name": "Cacha maestra", "cost": 60.0, "desc": "cacha falsa a mayor distancia", "effect": "cachePlus"},
	],
	"topo": [
		{"id": "topo_panza", "key": "1", "name": "Panza grande", "cost": 60.0, "desc": "+25 Vida máx y cura +25 (esta vida)", "effect": "stomach"},
		{"id": "topo_lombriz", "key": "2", "name": "Lombriz gorda", "cost": 55.0, "desc": "más vida por lombriz (+8)", "effect": "wormPlus"},
		{"id": "topo_tunel", "key": "3", "name": "Túnel maestro", "cost": 70.0, "desc": "+1 madriguera por vida", "effect": "digPlus"},
	],
	"halcon": [
		{"id": "halcon_ojo", "key": "1", "name": "Ojo de águila", "cost": 65.0, "desc": "+50 visión y revela ponzoña", "effect": "nose"},
		{"id": "halcon_termica", "key": "2", "name": "Térmica alta", "cost": 70.0, "desc": "ojo de águila más duradero", "effect": "thermalPlus"},
		{"id": "halcon_sombra", "key": "3", "name": "Sombra temible", "cost": 55.0, "desc": "ahuyentar da doble karma", "effect": "scarePlus"},
	],
	"zorro": [
		{"id": "zorro_zarpas", "key": "1", "name": "Zarpas veloces", "cost": 60.0, "desc": "+15% velocidad (esta vida)", "effect": "swift"},
		{"id": "zorro_reparto", "key": "2", "name": "Reparto noble", "cost": 55.0, "desc": "ceder da doble karma", "effect": "cedePlus"},
		{"id": "zorro_alarde", "key": "3", "name": "Alarde feroz", "cost": 60.0, "desc": "ahuyentar da doble karma", "effect": "strikePlus"},
	],
	"lobo": [
		{"id": "lobo_piel", "key": "1", "name": "Piel gruesa", "cost": 65.0, "desc": "+25 Vida máx y cura +25 (esta vida)", "effect": "stomach"},
		{"id": "lobo_aullido", "key": "2", "name": "Aullido profundo", "cost": 60.0, "desc": "rally de manada más duradero", "effect": "howlPlus"},
		{"id": "lobo_seleccion", "key": "3", "name": "Selección natural", "cost": 70.0, "desc": "caza al menos débil (50% vida)", "effect": "cullPlus"},
	],
}

const REFUGES := [
	{"type": "burrow-S", "maxSize": 1, "count": 3},
	{"type": "burrow-M", "maxSize": 2, "count": 3},
	{"type": "hollow-tree", "maxSize": 2, "climbOnly": true, "count": 2},
	{"type": "thorn-bush", "maxSize": 2, "count": 2},
	{"type": "old-oak", "maxSize": 3, "count": 2},
]

const VERB_DEFS := {
	"sapo": [
		{"slot": 1, "id": "croak", "name": "Croa alerta", "desc": "avisa a los cercanos (+30)", "cd": 10.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "pest", "name": "Come plagas", "desc": "un insecto de más (+3)", "cd": 8.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "burrowin", "name": "Entiérrate", "desc": "refugio express en tierra blanda", "cd": 12.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "toxin", "name": "Rocío tóxico", "desc": "rechaza al depredador (−10 vida)", "cd": 15.0, "costHp": 10.0, "costPa": 0.0},
		{"slot": 5, "id": "chorus", "name": "Coro de croac", "desc": "coro con congéneres: más sapos, más karma", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
	],
	"oruga": [
		{"slot": 1, "id": "prudent", "name": "Mordisco prudente", "desc": "hoja sostenible (+2)", "cd": 6.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "silk", "name": "Seda-cuerda", "desc": "hilo de escape (−8 vida)", "cd": 20.0, "costHp": 8.0, "costPa": 0.0},
		{"slot": 3, "id": "nectar", "name": "Néctar para hormigas", "desc": "aliadas que distraen (−5 vida, −10 PA)", "cd": 25.0, "costHp": 5.0, "costPa": 10.0},
		{"slot": 4, "id": "leafroll", "name": "Enrolla hoja", "desc": "cobijo propio (+karma)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 5, "id": "bristle", "name": "Eriza espinas", "desc": "el próximo zarpazo se revierte (−6 vida)", "cd": 25.0, "costHp": 6.0, "costPa": 0.0},
	],
	"raton": [
		{"slot": 1, "id": "alarm", "name": "¡Alerta!", "desc": "grito de alarma (+30)", "cd": 10.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "seedcache", "name": "Cacha semilla", "desc": "entierra una semilla (+karma)", "cd": 15.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "groom", "name": "Acicala", "desc": "acicalado social (+2)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "scout", "name": "Ojea madrigueras", "desc": "revela peligro cercano (−10 PA)", "cd": 25.0, "costHp": 0.0, "costPa": 10.0},
		{"slot": 5, "id": "share", "name": "Comparte bocado", "desc": "alimenta a un hambriento (+karma)", "cd": 20.0, "costHp": 0.0, "costPa": 0.0},
	],
	"ardilla": [
		{"slot": 1, "id": "tailflick", "name": "Cola al aire", "desc": "alarma sin cebo (+10)", "cd": 8.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "plantoak", "name": "Planta roble", "desc": "bosque futuro (+10)", "cd": 5.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "falsecache", "name": "Cacha falsa", "desc": "engaña a ladrones (+karma)", "cd": 25.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "bark", "name": "Cosecha corteza", "desc": "PA del roble (+karma)", "cd": 20.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 5, "id": "groom", "name": "Acicala", "desc": "acicalado social (+2)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
	],
	"topo": [
		{"slot": 1, "id": "aerate", "name": "Airea la tierra", "desc": "+3 karma, madriguera", "cd": 20.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "tunneline", "name": "Reforza túnel", "desc": "madriguera firme (+karma)", "cd": 25.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "worm", "name": "Rescata lombriz", "desc": "comida y PA", "cd": 15.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "larder", "name": "Despensa", "desc": "guarda lombriz para compartir", "cd": 25.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 5, "id": "nestdig", "name": "Excava nido", "desc": "otro refugio (−10 vida)", "cd": 30.0, "costHp": 10.0, "costPa": 0.0},
	],
	"halcon": [
		{"slot": 1, "id": "dive", "name": "Picado", "desc": "embestida defensiva (+karma)", "cd": 4.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "thermal", "name": "Térmica", "desc": "ojo de águila (−15 PA)", "cd": 30.0, "costHp": 0.0, "costPa": 15.0},
		{"slot": 3, "id": "courtesy", "name": "Carroña compartida", "desc": "deja la presa a carroñeros (+karma)", "cd": 40.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "scare", "name": "Ahuyenta", "desc": "espanta sin matar (+karma)", "cd": 20.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 5, "id": "bone", "name": "Suelta hueso", "desc": "alimenta del suelo (+karma)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
	],
	"zorro": [
		{"slot": 1, "id": "pounce", "name": "Salto de caza", "desc": "embiste a la presa cercana", "cd": 6.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "cachecarrion", "name": "Entierra carroña", "desc": "para después (+PA)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "cede", "name": "Cede la presa", "desc": "a otros (+15)", "cd": 12.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "dendig", "name": "Excava guarida", "desc": "refugio nuevo (−12 vida)", "cd": 40.0, "costHp": 12.0, "costPa": 0.0},
		{"slot": 5, "id": "strike", "name": "Ahuyenta", "desc": "hazaña (+5)", "cd": 4.0, "costHp": 0.0, "costPa": 0.0},
	],
	"lobo": [
		{"slot": 1, "id": "howl", "name": "Aúlla", "desc": "la manada se anima (+karma)", "cd": 35.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 2, "id": "regurg", "name": "Regurgita", "desc": "alimenta (−8 vida, +karma)", "cd": 30.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 3, "id": "strike", "name": "Ahuyenta", "desc": "hazaña (+20)", "cd": 4.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 4, "id": "escort", "name": "Escolta", "desc": "protege a un congénere (+karma)", "cd": 25.0, "costHp": 0.0, "costPa": 0.0},
		{"slot": 5, "id": "cull", "name": "Caza al débil", "desc": "selección natural (+karma)", "cd": 12.0, "costHp": 0.0, "costPa": 0.0},
	],
}

const LOCO := {
	"sapo": {"mode": "hop", "cadence": 1.1},
	"oruga": {"mode": "inchworm", "cadence": 1.65},
	"raton": {"mode": "continuous"},
	"ardilla": {"mode": "continuous"},
	"topo": {"mode": "continuous"},
	"halcon": {"mode": "continuous"},
	"zorro": {"mode": "continuous"},
	"lobo": {"mode": "continuous"},
}

const CONTROLS_BASE := [
	{"key": "WASD/Flechas", "label": "moverse"},
	{"key": "H", "label": "esconderse"},
	{"key": "B", "label": "tienda (1-3 comprar)"},
]
const CONTROLS_E := {
	"oruga": "comer hojas", "sapo": "lengua", "raton": "comer", "ardilla": "comer/llevar",
	"topo": "cavar/comer", "halcon": "picado/aterrizar", "zorro": "zarpazo", "lobo": "cazar",
}
const CONTROLS_Q := ["raton", "ardilla", "topo", "sapo", "lobo"]
const CONTROLS_V := {"topo": "temblor", "zorro": "rastro"}
const CONTROLS_C := ["ardilla"]

const SEC_PER_YEAR := {
	"oruga": 15.0, "sapo": 15.0, "raton": 20.0, "ardilla": 20.0, "topo": 20.0, "halcon": 30.0, "zorro": 30.0, "lobo": 30.0,
}

static func animal_years(species_key: String, secs: float) -> float:
	var per: float = SEC_PER_YEAR.get(species_key, 20.0)
	return secs / per


static func hunger_rate_for(species_key: String) -> float:
	var mult: float = SPECIES.get(species_key, {}).get("hungerMult", 1.0)
	return float(TUNING["hungerPerSec"]) * mult


static func thirst_rate_for(species_key: String) -> float:
	return hunger_rate_for(species_key) * float(TUNING["thirstMult"])
