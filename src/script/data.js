const WORLD = { w: 3200, h: 2400 };
const BASE_AREA = 1600 * 1200; // area de referencia: la densidad reproduce las constantes en 1x

// Composición por densidad: pisos de fauna por especie (agentes IA de toda clase)
const POP = {
  company: 4, // grupo social de la misma especie (fijo, no escala)
  faunaFloor: { oruga:2, sapo:2, raton:3, ardilla:3, topo:2, halcon:1, zorro:2, lobo:1 },
};

const SPECIES = {
  oruga:   { name:'Oruga',   tier:0, speed:80,  vision:130, maxHp:60,  radius:8,  size:1, color:'#9ccc65', desc:'Castigo: lenta, todos te cazan' },
  sapo:    { name:'Sapo',    tier:1, speed:110, vision:170, maxHp:80,  radius:9,  size:1, color:'#4db6ac', desc:'Lengua a 90px, cabe en madrigueras-S' },
  raton:   { name:'Ratón',   tier:1, speed:150, vision:190, maxHp:100, radius:10, size:2, color:'#90caf9', desc:'Base: equilibrado, puede gritar (Q)' },
  ardilla: { name:'Ardilla', tier:1, speed:175, vision:210, maxHp:90,  radius:10, size:2, climb:true, color:'#ffcc80', desc:'Lateral: rápida, trepa al árbol hueco' },
  topo:    { name:'Topo',    tier:1, speed:135, vision:150, maxHp:95,  radius:10, size:2, color:'#a1887f', desc:'Cava madrigueras con E, puede gritar' },
  halcon:  { name:'Halcón',  tier:2, speed:215, vision:340, maxHp:140, radius:12, size:3, color:'#ce93d8', desc:'Premio: veloz, gran visión, debe aterrizar para comer' },
  zorro:   { name:'Zorro',   tier:2, speed:185, vision:260, maxHp:120, radius:11, size:3, color:'#ff8a65', desc:'Depredador jugable: Zarpazo (E), sin grito' },
  lobo:    { name:'Lobo',    tier:2, speed:165, vision:300, maxHp:160, radius:14, size:4, color:'#4a3b52', desc:'Ápice jugable: caza T2 y zorros, nadie lo caza' },
};

// Dieta dura: cada forma come solo sus entradas
const DIET = {
  oruga: ['leaves'], sapo: ['insects'],
  raton: ['berries','apples','carrots','mushrooms','nuts'],
  ardilla: ['berries','apples','mushrooms','nuts'],
  topo: ['carrots','insects','nuts'],
  halcon: ['carrion','mates'], zorro: ['carrion','mates'], lobo: ['carrion','mates'],
};
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

const TUNING = {
  hungerPerSec: 1.6,
  paPerSec: 1 / 3, // ~20 PA/min por sobrevivir
  lastFruitHp: 20, lastFruitKarma: -15,
  shoutKarma: 30, shoutPa: 50, shoutCooldown: 10, shoutLureRange: 450,
  predatorDamage: 28, predatorInvuln: 1.0,
  tierUpKarma: 50, tierUpPa: 100,
  tierDownKarma: -50, sapoHopKarma: 20,
  chooseFormCost: 15,
  // cadena y verbos
  chaseMult: 1.35, loboChaseMult: 1.3, chaseMax: 6, restTime: 2, fleeHysteresis: 1.5,
  snapRange: 25, // forrajeo óptimo: snap por contacto aunque difiera talla
  pounceCd: 6, pounceRange: 70, pounceHp: 25, pouncePa: 10,
  digCd: 20, digMax: 3, tongueRange: 90, eatRange: 46,
  campTime: 3, hideRange: 40,
  carrionFreshHp: 20, carrionStaleHp: 8, carrionRottenHp: -25,
  carrionFreshT: 30, carrionRottenT: 60, carrionCap: 5, carrionFreshPa: 5,
  mimicHp: -20, satedTime: 25,
  wastefulHpFrac: 0.8, wastefulKarma: -10, strikeCd: 4,
  mateRespawn: 45, mateMax: 4,
  respawnTime: 20, // la fauna bajo el piso repuebla lejos
  landTime: 1.0,
  // mesa salvaje
  leafRegrow: 60, insectRespawn: 20, insectMax: 6,
  dietHintCd: 5, groomRange: 30, groomTime: 3, groomCd: 30, groomKarma: 5,
  pestKarma: 3, prudentKarma: 2, aerateKarma: 3, plantKarma: 10,
  loboStrikeKarma: 20, strikeKarma: 5, strikePa: 10, strikeHp: 10,
  cedeKarma: 15, divePa: 10,
  senseTremorCd: 25, senseTrackCd: 30, revealTime: 3, trackTime: 5,
  curlCd: 20, saplingCap: 3,
};

// Tienda mid-life: adaptaciones per-life, una compra por stat, sin apilado
const SHOP = [
  { id:'swift',   key:'1', name:'Zarpas veloces',  cost:50, desc:'+15% velocidad (esta vida)' },
  { id:'stomach', key:'2', name:'Estómago grande', cost:30, desc:'+25 Vida máx y cura +25' },
  { id:'nose',    key:'3', name:'Olfato agudo',    cost:25, desc:'+50 visión y revela ponzoña' },
  { id:'voice',   key:'4', name:'Voz suave',       cost:35, desc:'próximo grito atrae 2s en vez de 5s' },
];

const REFUGES = [
  { type:'burrow-S',    maxSize:1, count:3 },
  { type:'burrow-M',    maxSize:2, count:3 },
  { type:'hollow-tree', maxSize:2, climbOnly:true, count:2 },
  { type:'thorn-bush',  maxSize:2, count:2 },
];

