const WORLD = { w: 3200, h: 2400 };
const BASE_AREA = 1600 * 1200; // area de referencia: la densidad reproduce las constantes en 1x

// Composición por densidad: pisos de fauna por especie (agentes IA de toda clase)
const POP = {
  company: 4, // grupo social de la misma especie (fijo, no escala)
  faunaFloor: { oruga:2, sapo:2, raton:3, ardilla:3, topo:2, halcon:1, zorro:2, lobo:1 },
};

const SPECIES = {
  oruga:   { name:'Oruga',   tier:0, speed:80,  vision:130, maxHp:60,  radius:8,  size:1, hungerMult:1.5, color:'#9ccc65', desc:'Castigo: lenta, todos te cazan' },
  sapo:    { name:'Sapo',    tier:1, speed:110, vision:170, maxHp:80,  radius:9,  size:1, hungerMult:1.25, color:'#4db6ac', desc:'Lengua a 90px, cabe en madrigueras-S' },
  raton:   { name:'Ratón',   tier:1, speed:150, vision:190, maxHp:100, radius:10, size:2, hungerMult:1.0, color:'#90caf9', desc:'Base: equilibrado, puede gritar (Q)' },
  ardilla: { name:'Ardilla', tier:1, speed:175, vision:210, maxHp:90,  radius:10, size:2, hungerMult:1.0, climb:true, color:'#ffcc80', desc:'Lateral: rápida, trepa al árbol hueco' },
  topo:    { name:'Topo',    tier:1, speed:135, vision:150, maxHp:95,  radius:10, size:2, hungerMult:1.1, color:'#a1887f', desc:'Cava madrigueras con E, puede gritar' },
  halcon:  { name:'Halcón',  tier:2, speed:215, vision:340, maxHp:140, radius:12, size:3, hungerMult:0.8, color:'#ce93d8', desc:'Premio: veloz, gran visión, debe aterrizar para comer' },
  zorro:   { name:'Zorro',   tier:2, speed:185, vision:260, maxHp:120, radius:11, size:3, hungerMult:0.85, color:'#ff8a65', desc:'Depredador jugable: Zarpazo (E), sin grito' },
  lobo:    { name:'Lobo',    tier:2, speed:165, vision:300, maxHp:160, radius:14, size:4, hungerMult:0.7, color:'#4a3b52', desc:'Ápice jugable: caza T2 y zorros, nadie lo caza' },
};

// Dieta dura: cada forma come solo sus entradas
const DIET = {
  oruga: ['leaves'], sapo: ['insects'],
  raton: ['berries','apples','carrots','mushrooms','nuts'],
  ardilla: ['berries','apples','mushrooms','nuts'],
  topo: ['carrots','insects','nuts'],
  halcon: ['carrion','mates'], zorro: ['carrion','mates'], lobo: ['carrion','mates'],
};
// Quien nada: solo anfibios/agua (el pato futuro entra aqui como una fila)
const WATER_ENTER = { sapo: true };
const DIET_HINT = { oruga:'hojas', sapo:'insectos', raton:'bayas, manzanas, zanahorias, setas o nueces',
  ardilla:'bayas, manzanas, setas o nueces', topo:'zanahorias, insectos o nueces',
  halcon:'carroña o presas', zorro:'carroña o presas', lobo:'carroña o presas' };
// Pagos [vida, PA] por comida
const FOODDEF = {
  berries: { hp:15, pa:5 }, apples: { hp:22, pa:8 }, carrots: { hp:18, pa:5 },
  mushrooms: { hp:10, pa:0 }, leaves: { hp:12, pa:3 }, nuts: { hp:18, pa:5 },
  insects: { hp:10, pa:3 },
};

// Cadena trófica como datos: cazar/huir por tabla, no por código
const PRED = {
  zorro: { name:'Zorro', speed:100, perception:230, damage:28, body:26, size:3,
           huntsTiers:[0,1], huntsMates:true, huntsZorro:false, fears:['lobo'], color:'#c8532a' },
  lobo:  { name:'Lobo',  speed:150, perception:280, damage:35, body:32, size:4,
           huntsTiers:[2], huntsMates:false, huntsZorro:true, fears:[], color:'#4a3b52' },
  saponpc: { name:'Sapo', speed:70, perception:150, damage:10, body:14, size:1,
           huntsForms:['oruga'], huntsMates:false, huntsZorro:false, fears:['zorro','lobo'], color:'#4db6ac' },
};
const TIER_SPAWNS = { 0:['zorro','saponpc'], 1:['zorro','zorro'], 2:['zorro','lobo'] };
const T1POOL = ['raton','ardilla','topo','sapo'];
const T2POOL = ['halcon','zorro','lobo']; // azar-birth: el lobo ya no es especial, sortea como T2

const TUNING = {
  hungerPerSec: SPECIES.lobo.maxHp / (30 * 60 * SPECIES.lobo.hungerMult), // base anclada: el lobo vive 30 min sin comer; el resto escala por su hungerMult
  paPerSec: 1 / 3, // ~20 PA/min por sobrevivir
  lastFruitHp: 20, lastFruitKarma: -15,
  shoutKarma: 30, shoutPa: 50, shoutCooldown: 10, shoutLureRange: 450,
  predatorDamage: 28, predatorInvuln: 1.0,
  tierUpKarma: 50,
  tierDownKarma: -50,
  // cadena y verbos
  chaseMult: 1.35, loboChaseMult: 1.3, chaseMax: 6, restTime: 2, fleeHysteresis: 1.5,
  snapRange: 25, // forrajeo óptimo: snap por contacto aunque difiera talla
  pounceCd: 6, pounceRange: 70, pounceHp: 25, pouncePa: 10,
  digCd: 20, digMax: 3, tongueRange: 90, eatRange: 46,
  campTime: 3, hideRange: 40,
  carrionFreshHp: 20, carrionStaleHp: 8, carrionRottenHp: -25,
  carrionFreshT: 30, carrionRottenT: 60, carrionCap: 5, carrionFreshPa: 5,
  aiBuyEvery: 10, aiKarmaGood: 30, aiKarmaBad: -30, aiPredPerceptMod: 0.2, aiShoutLureTime: 5,
  mimicHp: -20, satedTime: 25,
  wastefulHpFrac: 0.8, wastefulKarma: -10, strikeCd: 4,
  mateRespawn: 45, mateMax: 4,
  respawnTime: 20, // la fauna bajo el piso repuebla lejos
  landTime: 1.0,
  // mesa salvaje
  leafRegrow: 60, insectRespawn: 20, insectMax: 6,
  dietHintCd: 5, groomRange: 30, groomTime: 3, groomCd: 30, groomKarma: 5,
  pestKarma: 3, prudentKarma: 2, aerateKarma: 3, plantKarma: 10,
  toxinKarma: 5, chorusKarma: 5, // sapo 4-5: defensa química y coro por cantor
  nectarKarma: 8, leafrollKarma: 5, leafrollTtl: 60, // oruga 3-4: mutualismo y cobijo temporal
  seedCacheKarma: 5, shareBiteHp: 15, shareKarma: 8, // ratón 2+5: banco lite y bocado (hambre manda)
  tailflickKarma: 10, falseCacheKarma: 5, barkPa: 5, barkKarma: 2, // ardilla 1+3+4: alarma sin cebo, engaño y corteza
  wormHp: 12, wormPa: 5, // topo 3-4: lombriz (come, guarda o comparte; la nuez ajena no)
  thermalTime: 8, thermalVision: 150, scareKarma: 5, boneKarma: 5, // halcón 2+4+5: ojo, espanto y hueso
  howlKarma: 10, howlTime: 10, regurgKarma: 15, regurgCost: 8, // lobo 1-2: rally y regurgito
  escortKarma: 12, escortTime: 10, cullKarma: 10, // lobo 4-5: escolta que sobrevive y caza al débil
  loboStrikeKarma: 20, strikeKarma: 5, strikePa: 10, strikeHp: 10,
  cedeKarma: 15, divePa: 10,
  senseTremorCd: 25, senseTrackCd: 30, revealTime: 3, trackTime: 5,
  curlCd: 20, saplingCap: 3,
  // bosque vivo (forest-flora-lifecycle)
  fruitRegrow: 45, seedSproutChance: 0.35, seedlingMaturity: 75,
  seedlingMax: 10, seedScatter: 60, oakTreeCap: 6,
  // terreno sólido (readable-forest-solid-terrain)
  rockCount: 8, solidRefuge: 16, solidPlant: 12, solidRock: 14, losSamples: 10,
  // necesidades vitales (vitals-water): stocks 100 = lleno, umbrales de regen, sed 2x hambre
  regenHambre: 30, regenSed: 30, thirstMult: 2, deficitMax: 2,
  sipSed: 35, sipHp: 5, drinkRange: 46,
  // agua infinita: charcos chicos dispersos, lagos grandes escasos (densidades por área)
  charcoCount: 6, lagoCount: 2, charcoR: 20, lagoR: 95,
  // insectos anclados al lago: sesgo de aparición en la orilla
  lakeInsectBias: 0.6, lakeShore: 120,
  // supervivencia IA (foraging-survival-ai)
  forageRangeMult: 0.5, hungerPriority: 0.4, aiHideMax: 5, aiCoverRange: 250, lowHpPercept: 1.4,
  aiFearRange: 200,
  // marchas (species-locomotion-verbs)
  hopImpulse: 0.5, hopRest: 0.6, wormStretch: 1.3, wormBurst: 0.35, tunnelSpeed: 0.8,
  // verbos (karma-verbs)
  groomSocialKarma: 2, // acicala social instantánea (el acicalado de 3s de karma-core queda intacto)
};
// regen por debajo del peor drenaje con tope: quieto y necesitado siempre pierde vida (vitals-water)
TUNING.vidaRegenPerSec = TUNING.hungerPerSec * 2;

// Tienda mid-life por especie (azar-birth): 3 adaptaciones únicas cada una (1 stat + 1 verbo + 1 firma),
// per-life, sin apilado, 50-80 PA (una vida típica ~60-100 PA da para ~1). `effect` es la mecánica que resuelve hasAdapt.
const SHOP_BY_SPECIES = {
  oruga: [
    { id:'oruga_panza', key:'1', name:'Panza grande',  cost:60, desc:'+25 Vida máx y cura +25 (esta vida)', effect:'stomach' },
    { id:'oruga_seda',  key:'2', name:'Seda gruesa',   cost:60, desc:'escape de seda más lejos (80px)', effect:'silkPlus' },
    { id:'oruga_hoja',  key:'3', name:'Hoja maestra',  cost:55, desc:'hoja enrollada dura el doble', effect:'leafrollPlus' },
  ],
  sapo: [
    { id:'sapo_lengua', key:'1', name:'Lengua larga',   cost:70, desc:'lengua a 130px', effect:'tonguePlus' },
    { id:'sapo_toxina', key:'2', name:'Toxina potente', cost:60, desc:'rocío con doble karma', effect:'toxinPlus' },
    { id:'sapo_coro',   key:'3', name:'Coro mayor',     cost:55, desc:'coro con doble karma', effect:'chorusPlus' },
  ],
  raton: [
    { id:'raton_zarpas', key:'1', name:'Zarpas veloces',  cost:60, desc:'+15% velocidad (esta vida)', effect:'swift' },
    { id:'raton_ojeada', key:'2', name:'Ojeada experta',  cost:65, desc:'ojea el doble de tiempo', effect:'scoutPlus' },
    { id:'raton_bocado', key:'3', name:'Bocado generoso', cost:55, desc:'compartir da doble karma', effect:'sharePlus' },
  ],
  ardilla: [
    { id:'ardilla_olfato',  key:'1', name:'Olfato agudo',   cost:60, desc:'+50 visión y revela ponzoña', effect:'nose' },
    { id:'ardilla_corteza', key:'2', name:'Corteza dulce',  cost:55, desc:'doble PA y karma por corteza', effect:'barkPlus' },
    { id:'ardilla_engano',  key:'3', name:'Cacha maestra',  cost:60, desc:'cacha falsa a mayor distancia', effect:'cachePlus' },
  ],
  topo: [
    { id:'topo_panza',   key:'1', name:'Panza grande',   cost:60, desc:'+25 Vida máx y cura +25 (esta vida)', effect:'stomach' },
    { id:'topo_lombriz', key:'2', name:'Lombriz gorda',  cost:55, desc:'más vida por lombriz (+8)', effect:'wormPlus' },
    { id:'topo_tunel',   key:'3', name:'Túnel maestro',  cost:70, desc:'+1 madriguera por vida', effect:'digPlus' },
  ],
  halcon: [
    { id:'halcon_ojo',     key:'1', name:'Ojo de águila',  cost:65, desc:'+50 visión y revela ponzoña', effect:'nose' },
    { id:'halcon_termica', key:'2', name:'Térmica alta',   cost:70, desc:'ojo de águila más duradero', effect:'thermalPlus' },
    { id:'halcon_sombra',  key:'3', name:'Sombra temible', cost:55, desc:'ahuyentar da doble karma', effect:'scarePlus' },
  ],
  zorro: [
    { id:'zorro_zarpas',  key:'1', name:'Zarpas veloces', cost:60, desc:'+15% velocidad (esta vida)', effect:'swift' },
    { id:'zorro_reparto', key:'2', name:'Reparto noble',  cost:55, desc:'ceder da doble karma', effect:'cedePlus' },
    { id:'zorro_alarde',  key:'3', name:'Alarde feroz',   cost:60, desc:'ahuyentar da doble karma', effect:'strikePlus' },
  ],
  lobo: [
    { id:'lobo_piel',      key:'1', name:'Piel gruesa',       cost:65, desc:'+25 Vida máx y cura +25 (esta vida)', effect:'stomach' },
    { id:'lobo_aullido',   key:'2', name:'Aullido profundo',  cost:60, desc:'rally de manada más duradero', effect:'howlPlus' },
    { id:'lobo_seleccion', key:'3', name:'Selección natural', cost:70, desc:'caza al menos débil (50% vida)', effect:'cullPlus' },
  ],
};

const REFUGES = [
  { type:'burrow-S',    maxSize:1, count:3 },
  { type:'burrow-M',    maxSize:2, count:3 },
  { type:'hollow-tree', maxSize:2, climbOnly:true, count:2 },
  { type:'thorn-bush',  maxSize:2, count:2 },
  { type:'old-oak',     maxSize:3, count:2 }, // copa anti-terrestres, sin fruta (flora-lifecycle)
];

// Barra de verbos 1-5 por especie (karma-verbs): cada animal tiene su propio rol ecológico.
// slot = tecla · cd en s · costHp/costPa = coste real · el karma lo paga el efecto según contexto.
const VERB_DEFS = {
  sapo: [
    { slot:1, id:'croak',    name:'Croa alerta',   desc:'avisa a los cercanos (+30)', cd:10, costHp:0,  costPa:0 },
    { slot:2, id:'pest',     name:'Come plagas',   desc:'un insecto de más (+3)',     cd:8,  costHp:0,  costPa:0 },
    { slot:3, id:'burrowin', name:'Entiérrate',    desc:'refugio express en tierra blanda', cd:12, costHp:0, costPa:0 },
    { slot:4, id:'toxin',    name:'Rocío tóxico',  desc:'rechaza al depredador (−10 vida)', cd:15, costHp:10, costPa:0 },
    { slot:5, id:'chorus',   name:'Coro de croac', desc:'coro con congéneres: más sapos, más karma', cd:30, costHp:0, costPa:0 },
  ],
  oruga: [
    { slot:1, id:'prudent',  name:'Mordisco prudente', desc:'hoja sostenible (+2)',       cd:6,  costHp:0,  costPa:0 },
    { slot:2, id:'silk',     name:'Seda-cuerda',       desc:'hilo de escape (−8 vida)',   cd:20, costHp:8,  costPa:0 },
    { slot:3, id:'nectar',   name:'Néctar para hormigas', desc:'aliadas que distraen (−5 vida, −10 PA)', cd:25, costHp:5, costPa:10 },
    { slot:4, id:'leafroll', name:'Enrolla hoja',      desc:'cobijo propio (+karma)',     cd:30, costHp:0,  costPa:0 },
    { slot:5, id:'bristle',  name:'Eriza espinas',     desc:'el próximo zarpazo se revierte (−6 vida)', cd:25, costHp:6, costPa:0 },
  ],
  raton: [
    { slot:1, id:'alarm',    name:'¡Alerta!',      desc:'grito de alarma (+30)',      cd:10, costHp:0,  costPa:0 },
    { slot:2, id:'seedcache',name:'Cacha semilla', desc:'entierra una semilla (+karma)', cd:15, costHp:0, costPa:0 },
    { slot:3, id:'groom',    name:'Acicala',       desc:'acicalado social (+2)',      cd:30, costHp:0,  costPa:0 },
    { slot:4, id:'scout',    name:'Ojea madrigueras', desc:'revela peligro cercano (−10 PA)', cd:25, costHp:0, costPa:10 },
    { slot:5, id:'share',    name:'Comparte bocado',   desc:'alimenta a un hambriento (+karma)', cd:20, costHp:0, costPa:0 },
  ],
  ardilla: [
    { slot:1, id:'tailflick',name:'Cola al aire',  desc:'alarma sin cebo (+10)',      cd:8,  costHp:0,  costPa:0 },
    { slot:2, id:'plantoak', name:'Planta roble',  desc:'bosque futuro (+10)',        cd:5,  costHp:0,  costPa:0 },
    { slot:3, id:'falsecache',name:'Cacha falsa', desc:'engaña a ladrones (+karma)', cd:25, costHp:0,  costPa:0 },
    { slot:4, id:'bark',     name:'Cosecha corteza',   desc:'PA del roble (+karma)', cd:20, costHp:0,  costPa:0 },
    { slot:5, id:'groom',    name:'Acicala',       desc:'acicalado social (+2)',      cd:30, costHp:0,  costPa:0 },
  ],
  topo: [
    { slot:1, id:'aerate',   name:'Airea la tierra',   desc:'+3 karma, madriguera', cd:20, costHp:0, costPa:0 },
    { slot:2, id:'tunneline',name:'Reforza túnel',     desc:'madriguera firme (+karma)', cd:25, costHp:0, costPa:0 },
    { slot:3, id:'worm',     name:'Rescata lombriz',   desc:'comida y PA',           cd:15, costHp:0, costPa:0 },
    { slot:4, id:'larder',   name:'Despensa',      desc:'guarda lombriz para compartir', cd:25, costHp:0, costPa:0 },
    { slot:5, id:'nestdig',  name:'Excava nido',   desc:'otro refugio (−10 vida)',    cd:30, costHp:10, costPa:0 },
  ],
  halcon: [
    { slot:1, id:'dive',     name:'Picado',        desc:'embestida defensiva (+karma)', cd:4, costHp:0, costPa:0 },
    { slot:2, id:'thermal',  name:'Térmica',       desc:'ojo de águila (−15 PA)',     cd:30, costHp:0,  costPa:15 },
    { slot:3, id:'courtesy', name:'Carroña compartida', desc:'deja la presa a carroñeros (+karma)', cd:40, costHp:0, costPa:0 },
    { slot:4, id:'scare',    name:'Ahuyenta',      desc:'espanta sin matar (+karma)', cd:20, costHp:0,  costPa:0 },
    { slot:5, id:'bone',     name:'Suelta hueso',  desc:'alimenta del suelo (+karma)', cd:30, costHp:0, costPa:0 },
  ],
  zorro: [
    { slot:1, id:'pounce',   name:'Salto de caza', desc:'embiste a la presa cercana', cd:6,  costHp:0,  costPa:0 },
    { slot:2, id:'cachecarrion',name:'Entierra carroña', desc:'para después (+PA)',  cd:30, costHp:0,  costPa:0 },
    { slot:3, id:'cede',     name:'Cede la presa', desc:'a otros (+15)',              cd:12, costHp:0,  costPa:0 },
    { slot:4, id:'dendig',   name:'Excava guarida',    desc:'refugio nuevo (−12 vida)', cd:40, costHp:12, costPa:0 },
    { slot:5, id:'strike',   name:'Ahuyenta',      desc:'hazaña (+5)',                cd:4,  costHp:0,  costPa:0 },
  ],
  lobo: [
    { slot:1, id:'howl',     name:'Aúlla',         desc:'la manada se anima (+karma)', cd:35, costHp:0, costPa:0 },
    { slot:2, id:'regurg',   name:'Regurgita',     desc:'alimenta (−8 vida, +karma)', cd:30, costHp:0, costPa:0 },
    { slot:3, id:'strike',   name:'Ahuyenta',      desc:'hazaña (+20)',               cd:4,  costHp:0,  costPa:0 },
    { slot:4, id:'escort',   name:'Escolta',       desc:'protege a un congénere (+karma)', cd:25, costHp:0, costPa:0 },
    { slot:5, id:'cull',     name:'Caza al débil', desc:'selección natural (+karma)', cd:12, costHp:0,  costPa:0 },
  ],
};

// Marchas por especie (species-locomotion-verbs): la forma de moverse es dato, no código.
// hop = impulso+pausa (el sapo salta, no camina) · inchworm = estira-congela-impulsa (oruga)
// continuous = deslizamiento continuo (lo que ya hacía el juego)
const LOCO = {
  sapo:    { mode:'hop', cadence:1.1 },
  oruga:   { mode:'inchworm', cadence:1.65 },
  raton:   { mode:'continuous' },
  ardilla: { mode:'continuous' },
  topo:    { mode:'continuous' },
  halcon:  { mode:'continuous' },
  zorro:   { mode:'continuous' },
  lobo:    { mode:'continuous' },
};

