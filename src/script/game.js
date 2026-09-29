// Karma MVP - prototipo gris 2D top-down, sin dependencias
const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');

// state.js (A): state, newRun

// predators.js: mkPredator

// Stats efectivos con adaptaciones de la tienda
// state.js (B): effSpeed, effVision, effMaxHp, effSize, canEat, dietHint, mimicsVisible, toxicsVisible, trackedCarrion

const keys = {};
addEventListener('keydown', e => {
  const k = e.key.toLowerCase();
  keys[k] = true;
  if (k==='e') tryEat();
  if (k==='q') tryShout();
  if (k==='b' && !state?.dead) toggleShop();
  if (k==='h' && !state?.dead && !state?.shopOpen) toggleHide();
  if (k==='v' && !state?.dead) sensePulse();
  if (k==='c' && !state?.dead) carryAction();
  if (k==='escape') hideShop();
  if (['1','2','3','4','5'].includes(k) && state && !state.shopOpen && !state.dead) castVerb(+k);
  if (['1','2','3','4'].includes(k) && state?.shopOpen && !state?.dead) {
    const item = SHOP.find(s=>s.key===k);
    if (item) buyItem(item.id);
  }
  if (k==='r' && state?.dead) reincarnate();
});
addEventListener('keyup', e => keys[e.key.toLowerCase()] = false);
document.getElementById('btnReencarnar').onclick = () => { if (state) reincarnate(); };
document.getElementById('btnChooseRaton').onclick = () => chooseForm('raton');
document.getElementById('btnChooseArdilla').onclick = () => chooseForm('ardilla');
document.getElementById('btnChooseTopo').onclick = () => chooseForm('topo');
document.getElementById('btnChooseSapo').onclick = () => chooseForm('sapo');
document.getElementById('btnT2Halcon').onclick = () => pickT2('halcon');
document.getElementById('btnT2Zorro').onclick = () => pickT2('zorro');
for (const k of ['oruga','sapo','raton','ardilla','topo','halcon','zorro','lobo']) {
  const btn = document.getElementById('btnStart' + k[0].toUpperCase() + k.slice(1));
  if (btn) btn.onclick = () => startRun(k);
}

// Primera vida libre: el jugador elige cualquier especie antes de nacer
function showStart() {
  document.getElementById('start').classList.remove('hidden');
}
function startRun(speciesKey) {
  if (!SPECIES[speciesKey]) return false;
  document.getElementById('start').classList.add('hidden');
  newRun(speciesKey, 0, 0, 0);
  requestAnimationFrame(frame);
  return true;
}

// state.js (C): reincarnate, refugeFits, toggleHide, tryShout, addKarma, addPa, record

// hud.js (A): log

function frame(now) {
  const dt = Math.min(0.05, (now-last)/1000); last = now;
  if (!state.dead) update(dt);
  render();
  updateHud();
  requestAnimationFrame(frame);
}

// Forrajeo óptimo: dif talla ≥2 se ignora salvo snap por contacto
// predators.js: playerEdibleFor, camouflaged, curled

function update(dt) {
  state.time += dt;
  // PA por sobrevivir
  state.paAcc += dt * TUNING.paPerSec;
  if (state.paAcc >= 1) { state.pa += Math.floor(state.paAcc); state.paAcc %= 1; }
  // Hambre (también escondido: esconderse no pausa el hambre)
  state.hp -= TUNING.hungerPerSec * dt;
  for (const k of ['shoutCd','strikeCd','invuln','lureTimer','pounceCd','digCd','landT','senseCd','revealT','trackT','groomCd','curlCd','dietHintT'])
    if (state[k]>0) state[k]-=dt;
  for (let i = 0; i < state.verbCds.length; i++) if (state.verbCds[i] > 0) state.verbCds[i] -= dt; // cds de verbos (karma-verbs)
  ageWorld(dt);
  movePlayer(dt);
  groomTick(dt);
  updatePredators(dt);
  updateAgents(dt);
  wanderMates(dt);
  if (state.hp <= 0) { state.hp = 0; state.dead = true; showJudgment(); }
  // Cámara
  state.cam.x = clamp(state.px - canvas.width/2, 0, WORLD.w-canvas.width);
  state.cam.y = clamp(state.py - canvas.height/2, 0, WORLD.h-canvas.height);
}

// Reloj de fruta genérico: toda planta viva o pelada regenera 1 fruta hasta su tope (flora-lifecycle 1)
const FRUIT_CAP = { berries: 3, apples: 3, carrots: 3, mushrooms: 2, nuts: 3 };
// Tope de flora por especie, escalado por área como toda densidad del mundo (flora-lifecycle 2)
const FLORA_BASE = { berries: 7, apples: 3, carrots: 2, mushrooms: 4, leaves: 4, nuts: 2 };
const FLORA_KIND = { berries: 'bushes', apples: 'shrubs', carrots: 'patches', mushrooms: 'clusters', leaves: 'clumps', nuts: 'oaks' };
function floraCap(kind) {
  return scaledCount(FLORA_BASE[kind] || 2);
}
// Semilla al suelo: kind 'oak-tree' = plantado deliberado (sin azar); resto = azar de fruta comida
function dropSeed(kind, x, y) {
  if (kind !== 'oak-tree' && Math.random() >= TUNING.seedSproutChance) return;
  if (state.seedlings.length >= TUNING.seedlingMax) return; // banco de brotes lleno
  const ang = Math.random() * 7, r = Math.random() * TUNING.seedScatter;
  state.seedlings.push({ kind, x: clamp(x + Math.cos(ang) * r, 20, WORLD.w - 20),
    y: clamp(y + Math.sin(ang) * r, 20, WORLD.h - 20), age: 0 });
}
// Maduración: brote → planta nueva (con estado ponzoñoso propio); espera si el tope de su especie está lleno
function matureSeedlings(dt) {
  for (let i = state.seedlings.length - 1; i >= 0; i--) {
    const s = state.seedlings[i];
    s.age += dt;
    if (s.age < TUNING.seedlingMaturity) continue;
    if (s.kind === 'oak-tree') { // linaje de roble: madura en roble joven cargado
      if (state.oaks.length < floraCap('nuts') + TUNING.oakTreeCap) {
        state.oaks.push(mkPatch('nuts', s.x, s.y, 3));
        state.seedlings.splice(i, 1);
      }
      continue;
    }
    const list = state[FLORA_KIND[s.kind]];
    if (!list || list.length >= floraCap(s.kind)) continue; // sin hueco: reintenta el próximo tick
    const patch = mkPatch(s.kind, s.x, s.y, FRUIT_CAP[s.kind] || 1); // nace con toda la fruta (foraging-survival-ai 4.1)
    if (s.kind === 'berries') { patch.mimic = Math.random() < 1 / 3; patch.mimicEaten = false; } // tira ponzoña propia
    if (s.kind === 'mushrooms') { patch.toxicLeft = Math.random() < 0.5 ? 1 : 0; patch.toxicEaten = false; }
    list.push(patch);
    state.seedlings.splice(i, 1);
  }
}
function regrowFruit(list, cap, dt, rate) {
  const cycle = rate || TUNING.fruitRegrow;
  for (const p of list) {
    if (p.amount >= cap) { p.regrowT = 0; continue; }
    p.regrowT = (p.regrowT || 0) + dt;
    if (p.regrowT >= cycle) {
      p.amount++; p.alive = true; p.regrowT = 0;
    }
  }
}

function ageWorld(dt) {
  // Carroña envejece
  for (const c of state.carrions) c.age += dt;
  // Fruta: un solo mecanismo para todo (hojas = rate rápido propio)
  regrowFruit(state.bushes, FRUIT_CAP.berries, dt);
  regrowFruit(state.shrubs, FRUIT_CAP.apples, dt);
  regrowFruit(state.patches, FRUIT_CAP.carrots, dt);
  regrowFruit(state.clusters, FRUIT_CAP.mushrooms, dt);
  regrowFruit(state.oaks, FRUIT_CAP.nuts, dt);
  regrowFruit(state.clumps, 3, dt, TUNING.leafRegrow);
  matureSeedlings(dt);
  // Insectos: deambulan y reaparecen
  for (const i of state.insects) { i.x += (Math.random()-0.5)*60*dt; i.y += (Math.random()-0.5)*60*dt; }
  state.insectT += dt;
  if (state.insectT >= TUNING.insectRespawn && state.insects.length < TUNING.insectMax) {
    state.insectT = 0;
    const pt = spawnPt();
    state.insects.push({ x:pt.x, y:pt.y });
  }
  // Congéneres: reaparecen lento (1 por 45s, máx 4)
  state.mateT += dt;
  if (state.mateT >= TUNING.mateRespawn && companyAgents().length < TUNING.mateMax) {
    state.mateT = 0;
    const pt = spawnPt();
    state.agents.push(mkAgent({ role:'company', speciesKey: state.speciesKey,
      hp: state.sp.maxHp, x:pt.x, y:pt.y, saved:false }));
  }
  // Fauna bajo el piso: repuebla una por especie cada respawnTime
  state.respawnT += dt;
  if (state.respawnT >= TUNING.respawnTime) {
    state.respawnT = 0;
    respawnMissing();
  }
}

// Marcha compartida jugador/IA (species-locomotion-verbs): 1 = plena, 0 = en pausa de la marcha.
// clock = reloj de fase (state.time para el jugador; locoT propio por agente IA).
// El halcón en tierra chapotea a media velocidad (igual que hoy); el topo tunela a tunnelSpeed.
function locoMult(speciesKey, grounded, clock) {
  const loco = LOCO[speciesKey] || {};
  if (grounded && speciesKey === 'halcon') return 0.5; // chapoteo: era el ×0.5 de effSpeed
  switch (loco.mode) {
    case 'hop': {
      const t = (clock + speciesKey.length) % (TUNING.hopImpulse + TUNING.hopRest);
      return t < TUNING.hopImpulse ? 1 : 0;
    }
    case 'inchworm': {
      const t = (clock + speciesKey.length * 2) % (TUNING.wormStretch + TUNING.wormBurst);
      return t < TUNING.wormBurst ? 1 : 0;
    }
    case 'tunnel':
      return TUNING.tunnelSpeed;
    default:
      return 1;
  }
}

function movePlayer(dt) {
  // Movimiento (congelado si escondido; despegar si halcón en tierra se mueve)
  state.moved = false;
  if (!state.hidden) {
    let ix = (keys['d']||keys['arrowright']?1:0)-(keys['a']||keys['arrowleft']?1:0);
    let iy = (keys['s']||keys['arrowdown']?1:0)-(keys['w']||keys['arrowup']?1:0);
    if ((ix||iy)) {
      state.moved = true;
      state.face = { x: ix/(Math.hypot(ix,iy)||1), y: iy/(Math.hypot(ix,iy)||1) };
      if (state.grounded) state.grounded = false; // despega
    }
    const l = Math.hypot(ix,iy)||1;
    const envelope = locoMult(state.speciesKey, state.grounded, state.time);
    const skipRock = state.speciesKey === 'topo'; // tunel: bajo las piedras
    state.px = clamp(state.px + ix/l*effSpeed()*envelope*dt, 20, WORLD.w-20);
    state.py = clamp(state.py + iy/l*effSpeed()*envelope*dt, 20, WORLD.h-20);
    resolveCollisions({ r: state.sp.radius, skipRock, get: () => ({ x: state.px, y: state.py }),
      set: (k, v) => { if (k === 'x') state.px = v; else state.py = v; } });
  }
  // Quietud: camuflaje y rizo
  if (!state.moved) state.stillT += dt; else state.stillT = 0;
}

// --- Barra de verbos 1-5 (karma-verbs): el rol ecológico de cada animal, hecho teclas ---
// Coste real: el PA no entra en deuda, pero la vida SÍ puede llegar a 0 (juicio normal).
// Si el efecto contextual es imposible, no se cobra ni enfría nada.
function castVerb(slot) {
  const def = (VERB_DEFS[state.speciesKey] || [])[slot - 1];
  if (!def || state.verbCds[slot - 1] > 0) return false;
  if (state.pa < def.costPa) return false; // sin deuda de PA; la vida sí puede agotarse
  const ok = VERB_FN[def.id] ? VERB_FN[def.id]() : false;
  if (!ok) return false;
  state.hp -= def.costHp; state.pa -= def.costPa; // el coste se cobra solo si el verbo ocurre
  state.verbCds[slot - 1] = def.cd;
  return true;
}

const VERB_FN = {
  aerate() { return digBurrow(); }, // topo 1: delega en E-cavar (una implementación)
  alarm() { return tryShout(), true; }, // ratón 1: delega en Q-gritar (karma + PA intactos)
  pest() { return eatAsSapo(); }, // sapo 2: la lengua y su +3 de siempre
  prudent() { return eatAsGrazer(); }, // oruga 1: el mordisco sostenible de siempre
  groom() { // ratón/ardilla: acicalado social instantáneo (+2, distinto del acicalado largo de karma-core)
    const m = nearest(companyAgents(), TUNING.groomRange);
    if (!m) return false;
    addKarma(TUNING.groomSocialKarma, `Acicalas a un congénere (+${TUNING.groomSocialKarma} karma)`, 'good');
    return true;
  },
  plantoak() { return carryAction(); }, // ardilla 2: llevar/enterrar de siempre (C)
  cede() { // zorro 3: cede la carroña cercana (+15, única por carroña)
    const c = nearest(state.carrions, TUNING.eatRange);
    return c && !c.ceded ? cedeCarrion(c) : false;
  },
  pounce() { return eatAsZorro(); }, // zorro 1: zarpazo/lengua/cavar, la ruta de E de cada especie
  dive() { return eatAsHalcon(); }, // halcón 1: picado/ataque/aterrizaje de E
  silk() { // oruga 2: suelta el hilo y se deja llevar lejos del cazador
    const h = nearestFrom(state.px, state.py,
      state.agents.filter(o => o.role === 'hunter' || o.kind === 'hunter'), 150);
    if (!h) return false; // sin cazador cerca, no hay escape que pagar
    const d = Math.hypot(state.px - h.x, state.py - h.y) || 1;
    state.px = clamp(state.px + (state.px - h.x) / d * 40, 20, WORLD.w - 20);
    state.py = clamp(state.py + (state.py - h.y) / d * 40, 20, WORLD.h - 20);
    return true;
  },
};

function groomTick(dt) {
  // Groom: ratón 3s junto a congénere
  if (state.speciesKey === 'raton' && state.groomCd <= 0) {
    if (nearest(companyAgents(), TUNING.groomRange)) {
      state.groomT += dt;
      if (state.groomT >= TUNING.groomTime) {
        state.groomT = 0; state.groomCd = TUNING.groomCd;
        addKarma(TUNING.groomKarma, `Acicalas a un congénere (+${TUNING.groomKarma} karma)`, 'good');
      }
    } else state.groomT = 0;
  } else state.groomT = 0;
}

// Desplazamiento IA hacia un punto pasando por la misma marcha que el jugador (paridad)
function moveToward(a, tx, ty, mult, dt) {
  const d = Math.hypot(tx - a.x, ty - a.y) || 1;
  a.locoT = (a.locoT || 0) + dt; // reloj de fase propio: cada agente salta a su ritmo
  const envelope = locoMult(a.speciesKey, a.grounded, a.locoT);
  const step = SPECIES[a.speciesKey].speed * mult * envelope * dt;
  a.x += (tx - a.x) / d * step;
  a.y += (ty - a.y) / d * step;
  // la resolución de sólidos es del bucle (updateAgents: una pasada por tick)
}

// Bucle compartido: cada agente ejecuta su IA de especie (ai.js); muere a 0 y deja carroña
function updateAgents(dt) {
  const dead = [];
  const solids = collectSolids(); // una pasada por tick: los sólidos no cambian dentro del frame
  for (const a of state.agents) {
    aiStep(a, dt);
    if (a.hp > 0) resolveCollisions({ r: SPECIES[a.speciesKey].radius, skipRock: a.speciesKey === 'topo',
      get: () => ({ x: a.x, y: a.y }), set: (k, v) => { if (k === 'x') a.x = v; else a.y = v; } }, solids);
    if (a.hp <= 0) dead.push(a);
  }
  for (const a of dead) { removeAgent(a); addCarrion(a.x, a.y); }
}

function wanderMates(dt) {
  // Mates deambulan / huyen
  for (const m of companyAgents()) {
    const pred = nearestFrom(m.x, m.y, allHunters(), 999);
    if (m.saved && pred) {
      const d = Math.hypot(m.x-pred.x,m.y-pred.y)||1;
      m.x += (m.x-pred.x)/d*90*dt; m.y += (m.y-pred.y)/d*90*dt;
    } else { m.x += (Math.random()-0.5)*40*dt; m.y += (Math.random()-0.5)*40*dt; }
  }
}

// predators.js: updatePredators

// hud.js (B): updateHud

// utils.js: clamp

showStart();
