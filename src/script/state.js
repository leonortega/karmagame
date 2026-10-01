// state.js - estado, stats efectivos, dieta, visibilidad, refugio, karma/PA (extraido de game.js, sin cambios)
// Depende de globales: WORLD, SPECIES, DIET, DIET_HINT, TUNING, REFUGES, TIER_SPAWNS + utils.js + shop.js (hideJudgment, hideShop).
let state;

// utils.js: scatter, mkPatch

function blankState(speciesKey, sp, karma, pa) {
  return {
    speciesKey, sp,
    px: WORLD.w/2, py: WORLD.h/2, face:{x:1,y:0}, moved:false,
    hp: sp.maxHp, karma,
    hambre: 100, sed: 100, edad: 0, // necesidades vitales: stocks llenos, edad cero (vitals-water)
    pa, saplings: 0,
    time: 0, dead:false, paAcc:0,
    shoutCd:0, invuln:0, lureTimer:0, strikeCd:0,
    verbCds: [0, 0, 0, 0, 0], // barra de verbos 1-5 (karma-verbs)
    pounceCd:0, digCd:0, dug:0, senseCd:0, revealT:0, trackT:0,
    groomT:0, groomCd:0, stillT:0, curlCd:0, dietHintT:0,
    carriedNut:false, larder:0, // despensa de lombrices del topo (verbo 4)
    stash:0, // despensa de carroña del zorro (verbo 2; la IA no la usa)
    hidden:false, hideRef:null, bristled:false, // erizo de oruga: un zarpazo se revierte
    grounded:false, landT:0,
    cam:{x:0,y:0},
    agents: [], possessed: 0, // roster unificado: el poseído es state
    lifeLog: [], // causa-efecto de esta vida para el juicio
    owned: {},   // adaptaciones compradas (se pierden al morir)
    shopOpen: false,
    pendingNext: null, pendingPool: null,
    mateT:0, insectT:0, respawnT:0,
  };
}

function newRun(speciesKey, carryKarma = 0, carryPa = 0, carrySaplings = 0) {
  const sp = SPECIES[speciesKey];
  state = blankState(speciesKey, sp, carryKarma, carryPa);
  seedFood(carrySaplings);
  seedFoes(sp);
  seedCompany();
  state.carrions = [];
  hideJudgment();
  hideShop();
  log(`Naces como <b>${sp.name}</b> T${sp.tier} — ${sp.desc}`, 'info');
}

function seedFood(carrySaplings) {
  // Mundo fresco cada vida; densidades = floraCap (una sola fuente: FLORA_BASE en game.js)
  // El agua va primero: todo lo demas nace seco (water-terrain-entry)
  seedWaters();
  const extraBushes = Math.min(carrySaplings, TUNING.saplingCap);
  state.bushes = [];
  scatterDry(floraCap('berries') + extraBushes).forEach((pt,i) => state.bushes.push(mkPatch('berries', pt.x, pt.y, 3, {
    mimic: (i % 3 === 2), mimicEaten: false, // ponzoñoso en cada 3er arbusto
  })));
  if (extraBushes > 0) record(`Tus nueces plantadas brotaron (+${extraBushes} arbustos)`);
  state.shrubs = scatterDry(floraCap('apples')).map(pt => mkPatch('apples', pt.x, pt.y, 2));
  state.patches = scatterDry(floraCap('carrots')).map(pt => mkPatch('carrots', pt.x, pt.y, 3));
  state.clusters = scatterDry(floraCap('mushrooms')).map(pt => mkPatch('mushrooms', pt.x, pt.y, 2, {
    toxicLeft: Math.random() < 0.5 ? 1 : 0, toxicEaten: false, // ~1 de cada 4 tóxica
  }));
  state.clumps = scatterDry(floraCap('leaves')).map(pt => mkPatch('leaves', pt.x, pt.y, 3, { regrowT: 0 }));
  state.oaks = scatterDry(floraCap('nuts')).map(pt => mkPatch('nuts', pt.x, pt.y, 3));
  state.insects = [];
  for (let i = 0; i < scaledCount(6); i++) state.insects.push(spawnInsectPt());
  state.seedlings = []; // banco de brotes del bosque vivo (flora-lifecycle)
  state.rocks = scatterDry(scaledCount(TUNING.rockCount)).map(pt => ({ x: pt.x, y: pt.y })); // terreno sólido
}

// Agua infinita como terreno (posición + radio, sin cantidad ni agotamiento)
function seedWaters() {
  state.waters = [];
  scatter(scaledCount(TUNING.charcoCount)).forEach(pt => state.waters.push({ kind: 'charco', x: pt.x, y: pt.y, r: TUNING.charcoR }));
  scatter(scaledCount(TUNING.lagoCount)).forEach(pt => state.waters.push({ kind: 'lago', x: pt.x, y: pt.y, r: TUNING.lagoR }));
}

function seedFoes(sp) {
  const table = TIER_SPAWNS[sp.tier] || TIER_SPAWNS[1];
  const reps = Math.max(1, Math.round(areaScale()));
  for (let r = 0; r < reps; r++) table.forEach(t => {
    const pt = dryPt();
    state.agents.push(mkAgent({ role:'hunter', ...mkPredator(t, pt.x, pt.y, sp.tier) }));
  });
}

function mkAgent(a) {
  return { brain: 'AI', kind: 'grazer', hp: 60, hambre: 100, sed: 100, edad: 0, larder: 0,
    karma: 0, pa: 0, owned: {}, lifeLog: [], ...a };
}
function companyAgents() { return state.agents.filter(a => a.role === 'company'); }
function hunterAgents() { return state.agents.filter(a => a.role === 'hunter'); }
function faunaAgents() { return state.agents.filter(a => a.role === 'fauna'); }
function allHunters() { return state.agents.filter(a => a.kind === 'hunter'); }
function removeAgent(a) { const i = state.agents.indexOf(a); if (i >= 0) state.agents.splice(i, 1); }
// Vista del poseído como un agente más (para caza, render y roster)
function playerAgent() {
  return { id: state.possessed, speciesKey: state.speciesKey, x: state.px, y: state.py,
    hp: state.hp, brain: 'PLAYER' };
}
function roster() { return [playerAgent(), ...state.agents]; }

function seedCompany() {
  for (let i=0;i<POP.company;i++) {
    const pt = nudgeDry({ x: state.px+(Math.random()*200-100), y: state.py+(Math.random()*200-100) });
    state.agents.push(mkAgent({
      role:'company', speciesKey: state.speciesKey, hp: state.sp.maxHp,
      x: pt.x, y: pt.y, saved:false,
    }));
  }
  seedFauna();
  state.refuges = [];
  REFUGES.forEach(r => scatterDry(scaledCount(r.count)).forEach(pt => state.refuges.push({
    type:r.type, maxSize:r.maxSize, climbOnly:!!r.climbOnly, x:pt.x, y:pt.y, dug:false,
  })));
}

function faunaCount(k) {
  return Math.max(1, Math.round((POP.faunaFloor[k] || 0) * areaScale() / 4));
}

function spawnFauna(k, x, y) {
  const carnivore = DIET[k].includes('mates');
  const a = mkAgent({
    role:'fauna', speciesKey: k, hp: SPECIES[k].maxHp, x, y,
    face: { x: 1, y: 0 }, kind: carnivore ? 'hunter' : 'grazer',
    ...(carnivore ? { type: k, speed: SPECIES[k].speed, mode: 'wander',
      wx: x, wy: y, huntT: 0, restT: 0, satedT: 0, fleeLatch: false,
      huntingPlayer: false } : {}),
  });
  state.agents.push(a);
  return a;
}

function seedFauna() {
  for (const k of Object.keys(POP.faunaFloor)) {
    for (let i=0;i<faunaCount(k);i++) {
      const pt = dryPt();
      spawnFauna(k, pt.x, pt.y);
    }
  }
}

// Punto lejano al jugador y a los cazadores para repoblar sin emboscadas
function distantPt() {
  let best = dryPt(), bd = -1;
  for (let i=0;i<5;i++) {
    const pt = dryPt();
    let d = Math.hypot(pt.x-state.px, pt.y-state.py);
    for (const h of allHunters()) d = Math.min(d, Math.hypot(pt.x-h.x, pt.y-h.y));
    if (d > bd) { bd = d; best = pt; }
  }
  return best;
}

function respawnMissing() {
  for (const k of Object.keys(POP.faunaFloor)) {
    const n = state.agents.filter(a => a.speciesKey === k).length +
      (state.speciesKey === k ? 1 : 0); // el poseído cuenta para su especie
    if (n < faunaCount(k)) {
      const pt = distantPt();
      spawnFauna(k, pt.x, pt.y);
    }
  }
}

function effSpeed(){
  return state.sp.speed * (hasAdapt(state, 'swift') ? 1.15 : 1); // la media velocidad del halcón en tierra va en la marcha (locoMult)
}
function effVision(){ return state.sp.vision + (hasAdapt(state, 'nose') ? 50 : 0) + (state.thermalT > 0 ? TUNING.thermalVision : 0); }
function effMaxHp(){ return state.sp.maxHp + (hasAdapt(state, 'stomach') ? 25 : 0); }
function effSize(){ return state.speciesKey==='raton' ? 1 : state.sp.size; } // Squeeze: el ratón cabe en S

function dietHint() {
  if (state.dietHintT > 0) return;
  state.dietHintT = TUNING.dietHintCd;
  log(`Los ${state.sp.name.toLowerCase()}s comen ${DIET_HINT[state.speciesKey]}`, 'info');
}

// Ponzoña visible con olfato dentro de visión
function mimicsVisible() {
  if (!hasAdapt(state, 'nose')) return [];
  return state.bushes.filter(b => b.alive && b.mimic && !b.mimicEaten &&
    Math.hypot(b.x-state.px, b.y-state.py) <= effVision());
}
function toxicsVisible() {
  if (!hasAdapt(state, 'nose')) return [];
  return state.clusters.filter(c => c.alive && c.toxicLeft > 0 &&
    Math.hypot(c.x-state.px, c.y-state.py) <= effVision());
}
function trackedCarrion() {
  if (state.trackT <= 0) return null;
  return nearest(state.carrions, 9999);
}

// Juicio azar (karma -> pool -> sorteo, sin PA ni elección)
// shop.js (A): poolFor, drawFrom, judge, showJudgment, hideJudgment, renderFateBlocks, animateFateBlocks

function reincarnate() {
  if (!state.dead) return;
  const next = state.pendingNext || 'raton';
  const carryKarma = Math.round(state.karma * 0.2); // 20% arrastre: redención suave
  const carryPa = state.pa; // saldo restante persiste (lo gastado no vuelve)
  possessOrSpawn(next, carryKarma, carryPa, state.saplings);
}

// Reencarnar en el MISMO mundo: la comida comida sigue comida, la carroña
// envejece y los supervivientes persisten. Solo se reinicia la vida.
function possessOrSpawn(next, carryKarma, carryPa, carrySaplings) {
  const sp = SPECIES[next];
  const host = state.agents.find(a => a.speciesKey === next && a.brain !== 'PLAYER');
  const at = host || dryPt();
  if (host) removeAgent(host); // posees su cuerpo: aparece donde vivía
  else if (!skipsWater(next, false)) nudgeDry(at); // no-nadador nunca nace dentro del agua
  const keep = { bushes: state.bushes, shrubs: state.shrubs, patches: state.patches,
    clusters: state.clusters, clumps: state.clumps, oaks: state.oaks, insects: state.insects,
    refuges: state.refuges, carrions: state.carrions, agents: state.agents, seedlings: state.seedlings,
    rocks: state.rocks, waters: state.waters };
  state = { ...blankState(next, sp, carryKarma, carryPa), ...keep, px: at.x, py: at.y, saplings: 0 };
  const extra = Math.min(carrySaplings, TUNING.saplingCap);
  scatterDry(extra).forEach(pt => state.bushes.push(mkPatch('berries', pt.x, pt.y, 3)));
  if (extra > 0) record(`Tus nueces plantadas brotaron (+${extra} arbustos)`);
  hideJudgment();
  hideShop();
  log(`Naces como <b>${sp.name}</b> T${sp.tier} — ${sp.desc}`, 'info');
}

// eat.js: eatRange, tryEat, dietHintIfNear, nearestEdiblePatch, pounceKill, diveKill, digBurrow, eatPatch, eatInsect, carrionStage, addCarrion, eatCarrion, carryAction, sensePulse

function refugeFits(r) {
  if (effSize() > r.maxSize) return false;
  if (r.climbOnly && !state.sp.climb) return false;
  if (r.orugaOnly && state.speciesKey !== 'oruga') return false;
  return true;
}
function toggleHide() {
  if (state.dead) return false;
  if (state.hidden) {
    state.hidden = false; state.hideRef = null;
    log('Sales del escondite', 'info');
    return true;
  }
  const near = state.refuges.filter(r => Math.hypot(r.x-state.px, r.y-state.py) <= TUNING.hideRange);
  if (!near.length) return false;
  const fit = near.find(r => refugeFits(r));
  if (!fit) { log(`No cabes aquí (tamaño ${effSize()})`, 'info'); return false; }
  state.hidden = true; state.hideRef = fit;
  log(`Te escondes (${fit.type})`, 'info');
  return true;
}

function tryShout() {
  if (state.dead || state.shoutCd > 0) return;
  if (state.speciesKey === 'oruga' || state.speciesKey === 'halcon' || state.speciesKey === 'zorro') {
    log('Esta forma no avisa a nadie.', 'info'); return;
  }
  if (state.hidden) { state.hidden = false; state.hideRef = null; } // gritar te delata
  state.shoutCd = TUNING.shoutCooldown;
  const lure = 5; // gritar te delata 5s (la voz suave murió con la tienda global)
  state.lureTimer = lure;
  const verb = state.speciesKey === 'sapo' ? 'Croas' : 'Alerta';
  addKarma(TUNING.shoutKarma, `${verb} a tu especie: te expones (${TUNING.shoutKarma} karma, +${TUNING.shoutPa} PA, atrae ${lure}s)`, 'good');
  addPa(TUNING.shoutPa);
  // Mates huyen
  companyAgents().forEach(m => m.saved = true);
}

// --- Tienda mid-life (wallet de PA) ---
// shop.js (B): toggleShop, hideShop, renderShop, buyItem

function addKarma(n, msg, cls='info', agent) {
  const t = agent || state; // IA escribe a su ledger; omitir agente = jugador (api sin cambios)
  t.karma = Math.max(-100, Math.min(100, t.karma + n));
  if (!msg) return;
  record(msg, agent);
  if (agent) {
    const icon = (agent.speciesKey && typeof speciesIcon === 'function') ? speciesIcon(agent.speciesKey) + ' ' : '';
    logOther(icon + msg, n>0?'good':n<0?'bad':'info'); // panel izquierdo: emoji + texto
  }
  else log(msg, n>0?'good':n<0?'bad':'info'); // panel derecho: jugador
}
function addPa(n, agent){ (agent || state).pa += n; }
function record(msg, agent){ (agent || state).lifeLog.push(msg); }

// Grito IA: mismas reglas que tryShout pero escribe al ledger del agente y usa cd propio
function aiTryShout(agent) {
  if (agent.shoutCd > 0) return false;
  if (agent.speciesKey === 'oruga' || agent.speciesKey === 'halcon' || agent.speciesKey === 'zorro') return false;
  agent.shoutCd = TUNING.shoutCooldown;
  agent.lureTimer = TUNING.aiShoutLureTime; // señuelo compartido: los pred cazan al gritón
  const label = (SPECIES[agent.speciesKey] || {}).name || agent.speciesKey;
  addKarma(TUNING.shoutKarma, `Grito de ${String(label).toLowerCase()} (+${TUNING.shoutKarma} karma)`, 'good', agent);
  addPa(TUNING.shoutPa, agent);
  companyAgents().forEach(m => m.saved = true);
  return true;
}

// utils.js: nearest, nearestPredOf

