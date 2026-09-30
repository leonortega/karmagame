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
  // Necesidades vitales (también escondido: esconderse no pausa hambre ni sed)
  updateNeeds(state, effMaxHp(), dt);
  warnNeeds(); // aviso de umbral una vez por caída (se rearma al recuperar)
  escortTick(dt); // escolta: karma si el protegido sobrevive al plazo
  for (const k of ['shoutCd','strikeCd','invuln','lureTimer','pounceCd','digCd','landT','senseCd','revealT','trackT','groomCd','curlCd','dietHintT','thermalT'])
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

// Aviso de umbral: solo del jugador, una vez por caída; recuperarse rearma (vitals-water)
function warnNeeds() {
  if (state.hambre <= TUNING.regenHambre && !state.hambreWarned) {
    state.hambreWarned = true;
    log('Hambre bajo el umbral: la vida no regenará hasta comer', 'bad');
  } else if (state.hambre > TUNING.regenHambre) state.hambreWarned = false;
  if (state.sed <= TUNING.regenSed && !state.sedWarned) {
    state.sedWarned = true;
    log('Sed bajo el umbral: la vida no regenará hasta beber (E en el agua)', 'bad');
  } else if (state.sed > TUNING.regenSed) state.sedWarned = false;
}
// Escolta del lobo: si el protegido sigue en el mundo al vencer el plazo, karma;
// si cayó antes, nada (el cuerpo lo dice todo).
function escortTick(dt) {
  if (!(state.escortT > 0)) return;
  state.escortT -= dt;
  const m = state.agents.includes(state.escortTarget) ? state.escortTarget : null;
  if (!m) { state.escortT = 0; state.escortTarget = null; return; }
  if (state.escortT > 0) return;
  state.escortTarget = null;
  addKarma(TUNING.escortKarma, `Escolta cumplida: tu protegido sobrevive (+${TUNING.escortKarma} karma)`, 'good');
}
// Reloj de fruta genérico: toda planta viva o pelada regenera 1 fruta hasta su tope (flora-lifecycle 1)
const FRUIT_CAP = { berries: 3, apples: 3, carrots: 3, mushrooms: 2, nuts: 3 };
// Tope de flora por especie, escalado por área como toda densidad del mundo (flora-lifecycle 2)
const FLORA_BASE = { berries: 7, apples: 3, carrots: 2, mushrooms: 4, leaves: 4, nuts: 2 };
const FLORA_KIND = { berries: 'bushes', apples: 'shrubs', carrots: 'patches', mushrooms: 'clusters', leaves: 'clumps', nuts: 'oaks' };
function floraCap(kind) {
  return scaledCount(FLORA_BASE[kind] || 2);
}
// Insecto nuevo: con probabilidad sesga a la orilla de un lago (vitals-water),
// si no punto uniforme como siempre. Vagar, tope y cadencia intactos.
function spawnInsectPt() {
  const lagos = (state.waters || []).filter((w) => w.kind === 'lago');
  if (lagos.length && Math.random() < TUNING.lakeInsectBias) {
    const l = lagos[(Math.random() * lagos.length) | 0];
    const ang = Math.random() * 7, r = Math.random() * TUNING.lakeShore;
    return { x: clamp(l.x + Math.cos(ang) * r, 20, WORLD.w - 20),
      y: clamp(l.y + Math.sin(ang) * r, 20, WORLD.h - 20) };
  }
  return spawnPt();
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
  // Cobijos temporales (hoja enrollada) caducan
  for (let i = state.refuges.length - 1; i >= 0; i--) {
    const r = state.refuges[i];
    if (r.ttl != null) { r.ttl -= dt; if (r.ttl <= 0) state.refuges.splice(i, 1); }
  }
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
    state.insects.push(spawnInsectPt());
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

// Núcleo compartido jugador/IA (karma-verbs 3.3): mismos VERB_FN, ledger del agente.
// La IA también enfría por slot (verbCds propios): sin esto, verbos como toxina
// se dispararían cada tick (karma infinita + depredador bloqueado para siempre).
function castVerbFor(a, slot) {
  const def = (VERB_DEFS[a.speciesKey] || [])[slot - 1];
  if (!def || !VERB_FN[def.id]) return false;
  a.verbCds = a.verbCds || [0, 0, 0, 0, 0];
  if (a.verbCds[slot - 1] > 0) return false;
  if ((a.pa || 0) < def.costPa) return false; // sin deuda de PA, como el jugador
  const ok = VERB_FN[def.id](a);
  if (!ok) return false;
  a.hp -= def.costHp; a.pa -= def.costPa;
  a.verbCds[slot - 1] = def.cd;
  return true;
}

const VERB_FN = {
  aerate(a) { return a ? digBurrow(a) : digBurrow(); }, // topo 1: delega en E-cavar (una implementación)
  tunneline(a) { // topo 2: refuerza madriguera cavada (+karma de obra)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const r = nearestFrom(px, py, state.refuges.filter(o => o.dug), TUNING.eatRange);
    if (!r) return false;
    r.firm = true; // marca de obra (futura duración la leerá si hace falta)
    if (a) addKarma(TUNING.aerateKarma, `Túnel reforzado (+${TUNING.aerateKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.aerateKarma, `Refuerzas el túnel (+${TUNING.aerateKarma} karma)`, 'good');
      record(`Túnel firme (+${TUNING.aerateKarma} karma)`);
    }
    return true;
  },
  worm(a) { // topo 3: rescata lombriz de tierra fresca (comida + PA)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const r = nearestFrom(px, py, state.refuges.filter(o => o.dug), TUNING.eatRange);
    if (!r) return false; // sin tierra fresca no hay lombriz
    healEater(a, TUNING.wormHp);
    refillHambre(a, TUNING.wormHp);
    if (a) return true; // la IA no cobra PA por comer (como siempre)
    addPa(TUNING.wormPa);
    record(`Lombriz (+${TUNING.wormHp} vida, +${TUNING.wormPa} PA)`);
    log('Rescatas una lombriz (+vida)', 'info');
    return true;
  },
  larder(a) { // topo 4: despensa de lombrices (guarda, come o comparte; capacidad 1)
    const t = a || state;
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const hungryMate = nearestFrom(px, py, companyAgents().filter(o =>
      (a ? o.speciesKey === a.speciesKey : true) && (o.hambre ?? 100) < TUNING.regenHambre), TUNING.groomRange);
    if ((t.larder || 0) > 0 && hungryMate) { // compartir: el hambriento come (+karma)
      t.larder--;
      hungryMate.hp = Math.min(SPECIES[hungryMate.speciesKey].maxHp, hungryMate.hp + TUNING.wormHp);
      hungryMate.hambre = Math.min(100, (hungryMate.hambre ?? 100) + TUNING.wormHp);
      if (a) addKarma(TUNING.shareKarma, `Lombriz compartida (+${TUNING.shareKarma} karma)`, 'good', a);
      else {
        addKarma(TUNING.shareKarma, `Compartes lombriz con un hambriento (+${TUNING.shareKarma} karma)`, 'good');
        record(`Lombriz compartida (+${TUNING.shareKarma} karma)`);
      }
      return true;
    }
    if ((t.larder || 0) > 0 && (t.hambre ?? 100) < TUNING.regenHambre) { // comer lo guardado
      t.larder--;
      healEater(a, TUNING.wormHp);
      refillHambre(a, TUNING.wormHp);
      if (!a) record(`Lombriz de despensa (+${TUNING.wormHp} vida)`);
      return true;
    }
    const ins = nearestFrom(px, py, state.insects, TUNING.eatRange);
    if (!ins || (t.larder || 0) > 0) return false; // guardar: bicho cerca y hueco
    state.insects.splice(state.insects.indexOf(ins), 1);
    t.larder = 1;
    if (!a) log('Guardas una lombriz en la despensa (4 para comerla)', 'info');
    return true;
  },
  nestdig(a) { // topo 5: excava nido (refugio extra sin tope, cuesta vida)
    if (a) return false; // solo jugador: la IA puebla con airear (tope digMax)
    if (state.digCd > 0) return false;
    state.digCd = TUNING.digCd;
    state.refuges.push({ type: 'burrow-M', maxSize: 2, climbOnly: false, x: state.px, y: state.py, dug: true });
    log('Excavas un nido extra (cuesta vida)', 'info');
    record(`Nido extra cavado`);
    return true;
  },
  alarm(a) { // ratón 1: grito de alarma; la IA grita por su núcleo (aiTryShout)
    if (a) return aiTryShout(a);
    tryShout();
    return true;
  },
  pest() { return eatAsSapo(); }, // sapo 2: la lengua y su +3 de siempre
  croak(a) { return VERB_FN.alarm(a); }, // sapo 1: mismo grito (tryShout ya croa al sapo)
  burrowin(a) { // sapo 3: entiérrate en tierra blanda (oculto sin refugio)
    if (a) {
      if (a.hidden) return false;
      a.hidden = true; a.hideRef = null; a.hideT = TUNING.aiHideMax;
      return true;
    }
    if (state.hidden) return false;
    state.hidden = true; state.hideRef = null;
    log('Te entierras en tierra blanda (H para salir)', 'info');
    return true;
  },
  toxin(a) { // sapo 4: rocío tóxico al depredador cercano (corta la cacería)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const p = nearestFrom(px, py, state.agents.filter(o => o.role === 'hunter'), 60);
    if (!p) return false;
    p.restT = TUNING.restTime; // el cazador descansa: caza rota
    if (a) addKarma(TUNING.toxinKarma, `Rocío tóxico (+${TUNING.toxinKarma} karma)`, 'good', a);
    else addKarma(TUNING.toxinKarma, `Rocío tóxico: el depredador retrocede (+${TUNING.toxinKarma} karma)`, 'good');
    return true;
  },
  chorus(a) { // sapo 5: coro con congéneres (más cantores, más karma)
    const sk = a ? a.speciesKey : state.speciesKey;
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const choir = state.agents.filter(o => o !== a && o.speciesKey === sk &&
      (o.role === 'company' || o.role === 'fauna') &&
      Math.hypot(o.x - px, o.y - py) <= TUNING.groomRange);
    if (!choir.length) return false; // coro necesita compañía
    const k = TUNING.chorusKarma * (1 + choir.length);
    if (a) addKarma(k, `Coro de croac con ${1 + choir.length} cantores (+${k} karma)`, 'good', a);
    else addKarma(k, `Coro de croac con ${1 + choir.length} cantores (+${k} karma)`, 'good');
    return true;
  },
  prudent() { return eatAsGrazer(); }, // oruga 1: el mordisco sostenible de siempre
  groom() { // ratón/ardilla: acicalado social instantáneo (+2, distinto del acicalado largo de karma-core)
    const m = nearest(companyAgents(), TUNING.groomRange);
    if (!m) return false;
    addKarma(TUNING.groomSocialKarma, `Acicalas a un congénere (+${TUNING.groomSocialKarma} karma)`, 'good');
    return true;
  },
  seedcache(a) { // ratón 2: entierra semilla de fruta (banco + karma lite, nunca la última)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const sk = a ? a.speciesKey : state.speciesKey;
    const all = [...state.bushes, ...state.shrubs, ...state.patches, ...state.clusters, ...state.oaks];
    let best = null, bd = TUNING.eatRange;
    for (const p of all) {
      if (!p.alive || p.amount <= 1 || !DIET[sk].includes(p.kind)) continue;
      const d = Math.hypot(p.x - px, p.y - py);
      if (d < bd) { bd = d; best = p; }
    }
    if (!best) return false;
    best.amount--;
    dropSeed(best.kind, px, py);
    if (a) addKarma(TUNING.seedCacheKarma, `Cacha de semilla (+${TUNING.seedCacheKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.seedCacheKarma, `Cachas una semilla (+${TUNING.seedCacheKarma} karma)`, 'good');
      record(`Semilla enterrada (+${TUNING.seedCacheKarma} karma)`);
    }
    return true;
  },
  scout(a) { // ratón 4: ojea madrigueras (revela peligro, refugios y agua; solo jugador como el temblor)
    if (a) return false;
    state.revealT = TUNING.revealTime;
    addKarma(TUNING.prudentKarma, `Ojeas madrigueras (+${TUNING.prudentKarma} karma)`, 'good');
    record('Ojeada (peligro, refugios y agua a la vista)');
    return true;
  },
  share(a) { // ratón 5: comparte bocado con hambriento (le llena, te cuesta su valor)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const mates = companyAgents().filter(o => (a ? o.speciesKey === a.speciesKey : true) &&
      (o.hambre ?? 100) < TUNING.regenHambre);
    const m = nearestFrom(px, py, mates, TUNING.groomRange);
    const t = a || state;
    if (!m || t.hp <= TUNING.shareBiteHp) return false; // sin resto no se comparte: sin deuda de vida
    t.hp -= TUNING.shareBiteHp;
    m.hp = Math.min(SPECIES[m.speciesKey].maxHp, m.hp + TUNING.shareBiteHp);
    m.hambre = Math.min(100, (m.hambre ?? 100) + TUNING.shareBiteHp);
    if (a) addKarma(TUNING.shareKarma, `Bocado compartido (+${TUNING.shareKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.shareKarma, `Compartes tu bocado con un hambriento (+${TUNING.shareKarma} karma)`, 'good');
      record(`Bocado compartido (−${TUNING.shareBiteHp} vida, +${TUNING.shareKarma} karma)`);
    }
    return true;
  },
  plantoak(a) { return a ? buryOrCarryNut(a) : carryAction(); }, // ardilla 2: llevar/enterrar de siempre (C)
  tailflick(a) { // ardilla 1: cola al aire (alarma sin cebo: sin señuelo ni PA)
    if (a) {
      addKarma(TUNING.tailflickKarma, `Cola al aire (+${TUNING.tailflickKarma} karma)`, 'good', a);
      companyAgents().forEach(m => m.saved = true);
      return true;
    }
    addKarma(TUNING.tailflickKarma, `Cola al aire: avisas sin exponerte (+${TUNING.tailflickKarma} karma)`, 'good');
    companyAgents().forEach(m => m.saved = true);
    record(`Cola al aire (+${TUNING.tailflickKarma} karma, sin señuelo)`);
    return true;
  },
  falsecache(a) { // ardilla 3: cacha falsa (el cazador cercano pierde el tiempo)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const p = nearestFrom(px, py, state.agents.filter(o => o.role === 'hunter'), 150);
    if (!p) return false;
    p.restT = TUNING.restTime; // cae en el engaño: descansa
    if (a) addKarma(TUNING.falseCacheKarma, `Cacha falsa (+${TUNING.falseCacheKarma} karma)`, 'good', a);
    else addKarma(TUNING.falseCacheKarma, `Cacha falsa: el cazador pica (+${TUNING.falseCacheKarma} karma)`, 'good');
    return true;
  },
  bark(a) { // ardilla 4: cosecha corteza del roble sin comer (+PA, karma menor)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const oak = state.oaks.find(o => o.alive && o.amount > 0 && Math.hypot(o.x - px, o.y - py) <= TUNING.eatRange);
    if (!oak) return false;
    if (a) {
      addPa(TUNING.barkPa, a);
      addKarma(TUNING.barkKarma, `Corteza cosechada (+${TUNING.barkKarma} karma)`, 'good', a);
      return true;
    }
    addPa(TUNING.barkPa);
    addKarma(TUNING.barkKarma, `Cosechas corteza sin comer (+${TUNING.barkPa} PA, +${TUNING.barkKarma} karma)`, 'good');
    record(`Corteza (+${TUNING.barkPa} PA)`);
    return true;
  },
  cede(a) { // zorro 3: cede la carroña cercana (+15, única por carroña)
    if (a) {
      const w = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
      if (!w || w.ceded) return false;
      w.ceded = true;
      addKarma(TUNING.cedeKarma, `Cede la presa a otros (+${TUNING.cedeKarma} karma)`, 'good', a);
      return true;
    }
    const c = nearest(state.carrions, TUNING.eatRange);
    return c && !c.ceded ? cedeCarrion(c) : false;
  },
  pounce() { return eatAsZorro(); }, // zorro 1: zarpazo/lengua/cavar, la ruta de E de cada especie
  howl(a) { // lobo 1: aúlla (la manada se anima; solo jugador, la IA caza al día)
    if (a) return false;
    if (!companyAgents().length) return false; // sin manada no hay coro
    for (const m of companyAgents()) m.rallyT = TUNING.howlTime;
    addKarma(TUNING.howlKarma, `Aúllas: la manada se anima (+${TUNING.howlKarma} karma)`, 'good');
    record(`Aullido (+${TUNING.howlKarma} karma, rally ${TUNING.howlTime}s)`);
    return true;
  },
  regurg(a) { // lobo 2: regurgita al hambriento (le llena, te cuesta su valor)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const mates = companyAgents().filter(o => (a ? o.speciesKey === a.speciesKey : true) &&
      (o.hambre ?? 100) < TUNING.regenHambre);
    const m = nearestFrom(px, py, mates, TUNING.groomRange);
    const cost = TUNING.regurgCost;
    const t = a || state;
    if (!m || t.hp <= cost) return false; // sin resto no se comparte: sin deuda de vida
    t.hp -= cost;
    m.hp = Math.min(SPECIES[m.speciesKey].maxHp, m.hp + cost);
    m.hambre = Math.min(100, (m.hambre ?? 100) + cost);
    if (a) addKarma(TUNING.regurgKarma, `Regurgito (+${TUNING.regurgKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.regurgKarma, `Regurgitas para un hambriento (+${TUNING.regurgKarma} karma)`, 'good');
      record(`Regurgito (−${cost} vida, +${TUNING.regurgKarma} karma)`);
    }
    return true;
  },
  escort(a) { // lobo 4: escolta al congénere amenazado (karma si sobrevive al plazo)
    if (a) return false; // solo jugador: la IA caza en manada sin escoltas
    const threatened = companyAgents().find(m =>
      state.agents.some(o => o.role === 'hunter' && Math.hypot(o.x - m.x, o.y - m.y) <= 150));
    if (!threatened) return false;
    const d = Math.hypot(state.px - threatened.x, state.py - threatened.y) || 1;
    const step = Math.min(50, d); // acude al lado sin pasarse de largo
    state.px = clamp(state.px + (threatened.x - state.px) / d * step, 20, WORLD.w - 20);
    state.py = clamp(state.py + (threatened.y - state.py) / d * step, 20, WORLD.h - 20);
    state.escortT = TUNING.escortTime;
    state.escortTarget = threatened;
    log('Escoltas a un congénere amenazado (sobrevive y hay karma)', 'info');
    return true;
  },
  cull(a) { // lobo 5: caza al más débil (bonus si hp<30%, muerte normal si sano)
    if (a) return false; // solo jugador: cazar al débil es juicio, no instinto
    let sick = null, sickFrac = 2;
    for (const o of state.agents) {
      if (o.role !== 'fauna' || !edibleAgentFor('lobo', o, 1e9)) continue;
      if (Math.hypot(o.x - state.px, o.y - state.py) > TUNING.pounceRange) continue;
      const frac = o.hp / SPECIES[o.speciesKey].maxHp;
      if (frac < sickFrac) { sickFrac = frac; sick = o; }
    }
    if (!sick) return false;
    const weak = sickFrac < 0.3;
    if (!pounceKill(sick)) return false; // muerte con la economía del zarpazo
    if (weak) addKarma(TUNING.cullKarma, `Caza al débil, selección natural (+${TUNING.cullKarma} karma)`, 'good');
    return true;
  },
  cachecarrion(a) { // zorro 2: entierra carroña (despensa propia, bono PA en la próxima; solo jugador)
    if (a) return false; // la IA caza al día
    if ((state.stash || 0) > 0) return false; // despensa llena
    const c = nearest(state.carrions.filter(k => carrionStage(k) !== 'rotten'), TUNING.eatRange);
    if (!c) return false;
    state.carrions.splice(state.carrions.indexOf(c), 1);
    state.stash = 1;
    log('Entierras carroña para después (+PA en la próxima)', 'info');
    record('Carroña en despensa (bono +PA pendiente)');
    return true;
  },
  dendig(a) { // zorro 4: excava guarida (madriguera-M; ojo: el zorro no cabe, es para otros)
    if (a) return false; // solo jugador: la IA no excava guaridas
    state.refuges.push({ type: 'burrow-M', maxSize: 2, climbOnly: false, x: state.px, y: state.py, dug: true });
    log('Excavas una guarida (cuesta vida)', 'info');
    record('Guarida excavada');
    return true;
  },
  dive() { return eatAsHalcon(); }, // halcón 1: picado/ataque/aterrizaje de E
  thermal() { // halcón 2: térmica (ojo de águila breve; solo jugador como el temblor)
    if (state.thermalT > 0) return false;
    state.thermalT = TUNING.thermalTime;
    log('Térmica: ojo de águila (visión extra unos segundos)', 'info');
    return true;
  },
  courtesy() { // halcón 3: carroña compartida (deja la presa a carroñeros; ética de ceder)
    const c = nearest(state.carrions.filter(k => carrionStage(k) === 'fresh'), TUNING.eatRange);
    if (!c || c.ceded) return false;
    c.ceded = true;
    addKarma(TUNING.cedeKarma, `Carroña compartida (+${TUNING.cedeKarma} karma, la dejas)`, 'good');
    return true;
  },
  scare(a) { // halcón 4: ahuyenta sin matar (dispersa fauna pequeña)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const v = nearestFrom(px, py, state.agents.filter(o =>
      o !== a && o.role === 'fauna' && SPECIES[o.speciesKey].size <= 2), 90);
    if (!v) return false;
    const d = Math.hypot(v.x - px, v.y - py) || 1;
    v.x = clamp(v.x + (v.x - px) / d * 60, 20, WORLD.w - 20);
    v.y = clamp(v.y + (v.y - py) / d * 60, 20, WORLD.h - 20);
    if (a) addKarma(TUNING.scareKarma, `Ahuyenta sin matar (+${TUNING.scareKarma} karma)`, 'good', a);
    else addKarma(TUNING.scareKarma, `Ahuyentas sin matar (+${TUNING.scareKarma} karma)`, 'good');
    return true;
  },
  bone(a) { // halcón 5: suelta hueso (resto fresco que alimenta a quien lo halle)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    addCarrion(px, py);
    if (a) addKarma(TUNING.boneKarma, `Hueso suelto (+${TUNING.boneKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.boneKarma, `Sueltas un hueso (+${TUNING.boneKarma} karma, carroña fresca)`, 'good');
      record(`Hueso suelto (+${TUNING.boneKarma} karma)`);
    }
    return true;
  },
  strike(a) { // zorro 5 / lobo 3: ahuyenta al depredador cercano (+5, +20 ante lobo)
    if (a) {
      const p = nearestFrom(a.x, a.y, state.agents.filter(o =>
        o !== a && (o.role === 'hunter' || o.kind === 'hunter')), 60);
      if (!p || (a.strikeCd || 0) > 0) return false;
      aiStrike(a, p); // mismo knockback, karma y PA que el jugador
      return true;
    }
    const p = nearest(allHunters(), 60);
    if (!p || state.strikeCd > 0) return false;
    return strikePredator(p);
  },
  silk(a) { // oruga 2: suelta el hilo y se deja llevar lejos del cazador
    return silkDrop(a || null);
  },
  nectar(a) { // oruga 3: néctar para hormigas (una aliada distrae al cazador)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const p = nearestFrom(px, py, state.agents.filter(o => o.role === 'hunter'), 150);
    if (!p) return false;
    if (state.insects.length < TUNING.insectMax) state.insects.push({ x: px, y: py });
    p.restT = TUNING.restTime; // la aliada distrae: caza rota
    if (a) addKarma(TUNING.nectarKarma, `Néctar para hormigas (+${TUNING.nectarKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.nectarKarma, `Néctar para hormigas: una aliada distrae (+${TUNING.nectarKarma} karma)`, 'good');
      record(`Néctar (${TUNING.nectarKarma} karma, aliada invocada)`);
    }
    return true;
  },
  leafroll(a) { // oruga 4: enrolla hoja (cobijo propio temporal, solo orugas)
    const px = a ? a.x : state.px, py = a ? a.y : state.py;
    const clump = nearestFrom(px, py, state.clumps, TUNING.eatRange);
    if (!clump) return false; // vale mata pelada: cobijo en lo podado, sin gastar hojas
    state.refuges.push({ type: 'leafroll', maxSize: 1, orugaOnly: true, x: px, y: py, dug: false, ttl: TUNING.leafrollTtl });
    if (a) addKarma(TUNING.leafrollKarma, `Hoja enrollada (+${TUNING.leafrollKarma} karma)`, 'good', a);
    else {
      addKarma(TUNING.leafrollKarma, `Enrollas una hoja (+${TUNING.leafrollKarma} karma)`, 'good');
      record('Hoja enrollada (cobijo propio)');
    }
    return true;
  },
  bristle(a) { // oruga 5: eriza espinas (el próximo zarpazo se revierte)
    if (a) return false; // solo jugador: los agentes mueren de un bocado, sin daño que revertir (el rizo los cubre)
    state.bristled = true;
    log('Erizas espinas (el próximo zarpazo se revierte)', 'info');
    return true;
  },
};

// Seda compartida jugador/IA: huida de 40px en la línea de centros
function silkDrop(a) {
  const px = a ? a.x : state.px, py = a ? a.y : state.py;
  const h = nearestFrom(px, py,
    state.agents.filter(o => o.role === 'hunter' || o.kind === 'hunter'), 150);
  if (!h) return false; // sin cazador cerca, no hay escape que pagar
  const d = Math.hypot(px - h.x, py - h.y) || 1;
  const nx = clamp(px + (px - h.x) / d * 40, 20, WORLD.w - 20);
  const ny = clamp(py + (py - h.y) / d * 40, 20, WORLD.h - 20);
  if (a) { a.x = nx; a.y = ny; return true; }
  state.px = nx; state.py = ny;
  return true;
}

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
  // Mates deambulan / huyen (animados van más rápido mientras dura el rally del aullido)
  for (const m of companyAgents()) {
    if ((m.rallyT || 0) > 0) m.rallyT -= dt;
    const boost = (m.rallyT || 0) > 0 ? 1.5 : 1;
    const pred = nearestFrom(m.x, m.y, allHunters(), 999);
    if (m.saved && pred) {
      const d = Math.hypot(m.x-pred.x,m.y-pred.y)||1;
      m.x += (m.x-pred.x)/d*90*boost*dt; m.y += (m.y-pred.y)/d*90*boost*dt;
    } else { m.x += (Math.random()-0.5)*40*boost*dt; m.y += (Math.random()-0.5)*40*boost*dt; }
  }
}

// predators.js: updatePredators

// hud.js (B): updateHud

// utils.js: clamp

showStart();
