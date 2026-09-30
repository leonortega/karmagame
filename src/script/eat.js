// eat.js - comer, cazar y acciones de especie (extraido de game.js, sin cambios)
// Depende de globales: state, DIET, FOODDEF, TUNING + utils.js + game.js (canEat, dietHint, effMaxHp, addKarma, addPa, record, log).
function eatRange() {
  return state.speciesKey === 'sapo' ? TUNING.tongueRange : TUNING.eatRange;
}

// Agua del jugador desde la orilla (utils.js: nearestWaterFor)
function nearestWater(maxD) {
  return nearestWaterFor(state.px, state.py, maxD);
}
// Comer llena el tanque además de curar: el pago de vida es también saciedad (vitals-water)
function refillHambre(forAgent, n) {
  if (forAgent) forAgent.hambre = Math.min(100, (forAgent.hambre ?? 100) + n);
  else state.hambre = Math.min(100, state.hambre + n);
}
// Beber: recarga sed + sorbo de vida, sin karma ni PA; el agua es infinita
function drinkWater(w, forAgent) {
  if (!w) return false;
  if (forAgent) {
    forAgent.sed = Math.min(100, (forAgent.sed ?? 100) + TUNING.sipSed);
    healEater(forAgent, TUNING.sipHp);
    return true;
  }
  state.sed = Math.min(100, state.sed + TUNING.sipSed);
  state.hp = Math.min(effMaxHp(), state.hp + TUNING.sipHp);
  record(`Bebes agua (+${TUNING.sipSed} sed, +${TUNING.sipHp} vida)`);
  log('Bebes agua (+sed, +vida)', 'info');
  return true;
}
function tryDrink() {
  return drinkWater(nearestWater(TUNING.drinkRange), null);
}

function tryEat() {
  if (state.dead || state.hidden) return;
  const sp = state.speciesKey;
  if (sp === 'zorro') return eatAsZorro();
  if (sp === 'halcon') return eatAsHalcon();
  if (sp === 'topo') return eatAsTopo();
  if (sp === 'sapo') return eatAsSapo();
  return eatAsGrazer();
}

function eatAsZorro() {
  // Zarpazo a presa, si no necesidad: sediento bebe, hambriento carroña; sin fruta
  if (state.pounceCd <= 0) {
    const m = nearest(companyAgents(), TUNING.pounceRange);
    if (m) return pounceKill(m);
  }
  if (thirstier()) { if (tryDrink()) return true; }
  const c = nearest(state.carrions, TUNING.eatRange);
  if (c) {
    if (state.hp >= TUNING.wastefulHpFrac * effMaxHp() && !c.ceded) return cedeCarrion(c);
    return eatCarrion(c);
  }
  if (tryDrink()) return true;
  return dietHintIfNear();
}

// Ceder carroña: la dejas para otros (+15, única por carroña). Una sola implementación
// para la rama de E del zorro y su verbo 3 (karma-verbs).
function cedeCarrion(c) {
  c.ceded = true;
  addKarma(TUNING.cedeKarma, `Cedes la presa a otros (+${TUNING.cedeKarma} karma, la dejas)`, 'good');
  return true;
}

function eatAsHalcon() {
  // Picado defensivo, Dive a presa, si no aterriza para carroña o agua por necesidad
  const p = nearest(allHunters(), 60);
  if (p && state.strikeCd <= 0) return strikePredator(p);
  const m = nearest(companyAgents(), 60);
  if (m) return diveKill(m);
  return landForMeal();
}

function strikePredator(p, forAgent) {
  const ox = forAgent ? forAgent.x : state.px, oy = forAgent ? forAgent.y : state.py;
  if (!forAgent) state.strikeCd = TUNING.strikeCd;
  const lobo = p.type === 'lobo';
  p.x += (p.x-ox)*0.6; p.y += (p.y-oy)*0.6; // picado: lo aleja
  p.hitCd = 2;
  if (forAgent) return true; // golpe IA: mismo knockback, sin karma
  const k = lobo ? TUNING.loboStrikeKarma : TUNING.strikeKarma;
  addKarma(k, lobo ? `¡Ahuyentas un Lobo! Hazaña (+${k} karma)` : 'Caza necesaria: ahuyentas depredador (+5 karma)', k>5?'good':'info');
  addPa(TUNING.strikePa);
  state.hp = Math.min(effMaxHp(), state.hp+TUNING.strikeHp);
  return true; // el verbo 1 del halcón lee el resultado (karma-verbs)
}

// Aterriza 1s vulnerable y resuelve carroña o agua por necesidad (antes solo carroña)
function landForMeal() {
  const c = nearest(state.carrions, TUNING.eatRange);
  const w = nearestWater(TUNING.drinkRange);
  if (!c && !w) return dietHintIfNear();
  if (!state.grounded) {
    state.grounded = true; state.landT = TUNING.landTime;
    log('Aterrizas para comer (vulnerable 1s)…', 'info');
    return;
  }
  if (state.landT > 0) return; // aún posándose
  if (thirstier()) return tryDrink() || (c && eatCarrion(c));
  return (c && eatCarrion(c)) || tryDrink();
}

function eatAsTopo() {
  if (thirstier()) { if (tryDrink()) return true; }
  if (eatCarrion(nearest(state.carrions, TUNING.eatRange))) return true;
  if (eatInsect(nearest(state.insects, TUNING.eatRange))) return true;
  if (eatPatch(nearestEdiblePatch(TUNING.eatRange))) return true;
  if (tryDrink()) return true;
  return digBurrow();
}

function eatAsSapo() {
  if (thirstier()) { if (tryDrink()) return true; }
  if (eatInsect(nearest(state.insects, eatRange()))) return true;
  if (tryDrink()) return true;
  return dietHintIfNear();
}

function eatAsGrazer() {
  // Roedores y oruga: sediento bebe primero, si no parche comestible cercano
  if (thirstier()) { if (tryDrink()) return true; }
  if (eatCarrion(nearest(state.carrions, TUNING.eatRange))) return true;
  if (eatPatch(nearestEdiblePatch(TUNING.eatRange))) return true;
  if (tryDrink()) return true;
  return dietHintIfNear();
}

// Núcleo con agente: forAgent nulo = jugador (karma/PA/log); agente = IA (solo vida)
function dietKey(forAgent) { return forAgent ? forAgent.speciesKey : state.speciesKey; }
function healEater(forAgent, n) {
  if (forAgent) forAgent.hp = Math.min(SPECIES[forAgent.speciesKey].maxHp, forAgent.hp + n);
  else state.hp = Math.min(effMaxHp(), state.hp + n);
}
function hurtEater(forAgent, n) {
  if (forAgent) forAgent.hp += n;
  else state.hp += n;
}
function dietHintIfNear() {
  const all = [...state.bushes, ...state.shrubs, ...state.patches, ...state.clusters, ...state.clumps, ...state.oaks];
  const anyFood = nearest(all.filter(p => p.alive && p.amount > 0), 60) ||
    nearest(state.insects, 60) || nearest(state.carrions, 60);
  if (anyFood) dietHint();
  return false;
}

function nearestEdiblePatch(maxD) {
  return nearestEdiblePatchFor({ speciesKey: state.speciesKey, x: state.px, y: state.py }, maxD);
}

function nearestEdiblePatchFor(a, maxD) {
  const all = [...state.bushes, ...state.shrubs, ...state.patches, ...state.clusters, ...state.clumps, ...state.oaks];
  let best = null, bd = maxD;
  for (const p of all) {
    if (!p.alive || p.amount <= 0 || !DIET[a.speciesKey].includes(p.kind)) continue;
    const d = Math.hypot(p.x-a.x, p.y-a.y);
    if (d < bd) { bd = d; best = p; }
  }
  return best;
}

function pounceKill(m, forAgent) {
  addCarrion(m.x, m.y);
  if (forAgent) { // caza IA: misma carroña y valores, sin karma ni PA
    forAgent.pounceCd = TUNING.pounceCd;
    healEater(forAgent, TUNING.pounceHp);
    return true;
  }
  state.pounceCd = TUNING.pounceCd;
  removeAgent(m);
  addPa(TUNING.pouncePa);
  if (state.hp >= TUNING.wastefulHpFrac * effMaxHp()) {
    addKarma(TUNING.wastefulKarma, `Mataste por deporte (vida al ${Math.round(100*state.hp/effMaxHp())}%): ${TUNING.wastefulKarma} karma`, 'bad');
  } else {
    state.hp = Math.min(effMaxHp(), state.hp + TUNING.pounceHp);
    record(`Zarpazo necesario (+${TUNING.pounceHp} vida, +${TUNING.pouncePa} PA)`);
    log(`Cazas por necesidad (+${TUNING.pounceHp} vida)`, 'info');
  }
  return true; // el verbo 1 del zorro lee el resultado (karma-verbs)
}

function diveKill(m, forAgent) {
  addCarrion(m.x, m.y);
  if (forAgent) { // picado IA: cae sobre la presa y se alimenta, sin karma
    forAgent.x = m.x; forAgent.y = m.y;
    healEater(forAgent, TUNING.pounceHp);
    return true;
  }
  state.px = m.x; state.py = m.y; // picado: cae sobre la presa
  removeAgent(m);
  addPa(TUNING.divePa);
  state.grounded = true; // termina en tierra
  if (state.hp >= TUNING.wastefulHpFrac * effMaxHp()) {
    addKarma(TUNING.wastefulKarma, `Cazaste por deporte desde el cielo (${TUNING.wastefulKarma} karma)`, 'bad');
  } else {
    state.hp = Math.min(effMaxHp(), state.hp + TUNING.pounceHp);
    record(`Picado necesario (+${TUNING.pounceHp} vida)`);
    log(`Cazas en picado (+vida, en tierra)`, 'info');
  }
  return true; // el verbo 1 del halcón lee el resultado (karma-verbs)
}

function digBurrow(forAgent) {
  const t = forAgent || state;
  if ((t.digCd || 0) > 0 || (t.dug || 0) >= TUNING.digMax) return false;
  t.digCd = TUNING.digCd; t.dug = (t.dug || 0) + 1;
  const px = forAgent ? forAgent.x : state.px, py = forAgent ? forAgent.y : state.py;
  state.refuges.push({ type:'burrow-M', maxSize:2, climbOnly:false, x:px, y:py, dug:true });
  if (forAgent) {
    addKarma(TUNING.aerateKarma, `Airea la tierra (+${TUNING.aerateKarma} karma)`, 'good', forAgent);
    return true;
  }
  addKarma(TUNING.aerateKarma, `Aireas la tierra (+${TUNING.aerateKarma} karma)`);
  record(`Cavaste madriguera (${state.dug}/${TUNING.digMax})`);
  log(`Cavas una madriguera (H para esconderte)`, 'info');
  return true;
}

function eatPatch(p, forAgent) {
  if (!p || !DIET[dietKey(forAgent)].includes(p.kind)) return false;
  // Ponzoña primero: mímico de baya, seta tóxica
  if (p.kind === 'berries' && p.mimic && !p.mimicEaten) return eatMimic(p, forAgent);
  if (p.kind === 'mushrooms' && p.toxicLeft > 0) return eatToxicShroom(p, forAgent);
  p.amount--;
  if (p.kind !== 'leaves') dropSeed(p.kind, p.x, p.y); // fruta comida siembra el bosque (flora-lifecycle)
  if (p.amount <= 0 && p.kind !== 'leaves') return eatLastFruit(p, forAgent);
  return eatSustainable(p, FOODDEF[p.kind], forAgent);
}

function eatMimic(p, forAgent) {
  p.mimicEaten = true; p.amount--;
  if (p.amount <= 0) p.alive = false;
  hurtEater(forAgent, TUNING.mimicHp);
  if (!forAgent) {
    record('Fruto ponzoñoso (−20 vida, sin karma)');
    log('¡Era un mímico! Fruto ponzoñoso (−20 vida)', 'bad');
  }
  return true;
}

function eatToxicShroom(p, forAgent) {
  p.toxicLeft--; p.amount--;
  if (p.amount <= 0) p.alive = false;
  hurtEater(forAgent, TUNING.mimicHp);
  if (!forAgent) {
    record('Seta tóxica (−20 vida, sin karma)');
    log('¡Seta tóxica! (−20 vida)', 'bad');
  }
  return true;
}

function eatLastFruit(p, forAgent) {
  p.alive = false;
  healEater(forAgent, TUNING.lastFruitHp);
  refillHambre(forAgent, TUNING.lastFruitHp);
  if (!forAgent) addKarma(TUNING.lastFruitKarma, `Último ${p.kind}: se seca para siempre (${TUNING.lastFruitKarma} karma, +${TUNING.lastFruitHp} vida)`, 'bad');
  return true;
}

function eatSustainable(p, pay, forAgent) {
  if (p.amount <= 0) { p.alive = false; p.regrowT = 0; } // rebrota desde cero: 60s reales
  healEater(forAgent, pay.hp);
  refillHambre(forAgent, pay.hp);
  if (forAgent) { // IA: vida siempre; karma de buena acción por especie (spec ai-karma)
    if (forAgent.speciesKey === 'oruga' && p.kind === 'leaves' && p.amount > 0)
      addKarma(TUNING.prudentKarma, `Mordisqueo prudente (+${TUNING.prudentKarma} karma)`, 'good', forAgent);
    return true; // sin PA ni registro: la IA solo cobra buenas acciones
  }
  addPa(pay.pa);
  // Oruga prudente: +2 si dejó hojas en la mata
  if (state.speciesKey === 'oruga' && p.kind === 'leaves' && p.amount > 0) {
    addKarma(TUNING.prudentKarma, `Mordisqueo prudente (+${TUNING.prudentKarma} karma)`, 'good');
  }
  record(`Comida sostenible (+${pay.hp} vida, +${pay.pa} PA)`);
  log(`Comes ${p.kind} (${p.amount} restantes) +vida`, 'info');
  return true;
}

function eatInsect(i, forAgent) {
  if (!i || !DIET[dietKey(forAgent)].includes('insects')) return false;
  state.insects.splice(state.insects.indexOf(i), 1);
  const pay = FOODDEF.insects;
  healEater(forAgent, pay.hp);
  refillHambre(forAgent, pay.hp);
  if (forAgent) { // IA: karma de control de plagas si es sapo (spec ai-karma)
    if (forAgent.speciesKey === 'sapo')
      addKarma(TUNING.pestKarma, `Control de plagas (+${TUNING.pestKarma} karma)`, 'good', forAgent);
    return true;
  }
  addPa(pay.pa);
  if (state.speciesKey === 'sapo') {
    addKarma(TUNING.pestKarma, `Control de plagas (+${TUNING.pestKarma} karma)`, 'good');
  }
  record(`Insecto (+${pay.hp} vida)`);
  return true;
}

function carrionStage(c) {
  if (c.age < TUNING.carrionFreshT) return 'fresh';
  if (c.age < TUNING.carrionRottenT) return 'stale';
  return 'rotten';
}
function addCarrion(x, y) {
  state.carrions.push({ x, y, age: 0 });
  while (state.carrions.length > TUNING.carrionCap) {
    // cap 5: fuera la podrida más vieja primero, si no la más vieja
    let idx = 0, worst = -1;
    state.carrions.forEach((c,i) => {
      const score = (carrionStage(c)==='rotten' ? 10000 : 0) + c.age;
      if (score > worst) { worst = score; idx = i; }
    });
    state.carrions.splice(idx, 1);
  }
}
function eatCarrion(c, forAgent) {
  if (!c || !DIET[dietKey(forAgent)].includes('carrion')) return false;
  const stage = carrionStage(c);
  state.carrions.splice(state.carrions.indexOf(c), 1);
  if (stage === 'fresh') {
    healEater(forAgent, TUNING.carrionFreshHp);
    refillHambre(forAgent, TUNING.carrionFreshHp);
    if (!forAgent) {
      addPa(TUNING.carrionFreshPa);
      if (state.stash > 0) { // bono de despensa propia: se consume en la próxima
        state.stash--;
        addPa(TUNING.pouncePa);
        record(`Bono de despensa (+${TUNING.pouncePa} PA)`);
      }
      record(`Carroña fresca (+${TUNING.carrionFreshHp} vida, sin karma)`);
      log('Comes carroña fresca (+vida)', 'info');
    }
  } else if (stage === 'stale') {
    healEater(forAgent, TUNING.carrionStaleHp);
    refillHambre(forAgent, TUNING.carrionStaleHp);
    if (!forAgent) {
      if (state.stash > 0) { // el bono también vale en pasada
        state.stash--;
        addPa(TUNING.pouncePa);
        record(`Bono de despensa (+${TUNING.pouncePa} PA)`);
      }
      record(`Carroña pasada (+${TUNING.carrionStaleHp} vida, sin karma)`);
      log('Carroña pasada (+poca vida)', 'info');
    }
  } else {
    hurtEater(forAgent, TUNING.carrionRottenHp); // podrida: TUNING guarda −25
    if (!forAgent) {
      record('Carroña podrida (−25 vida, sin karma)');
      log('¡Podrida! Carroña en mal estado (−25 vida)', 'bad');
    }
  }
  return true;
}

// Llevar/enterrar nuez (C y verbo 2 de la ardilla, jugador o IA: un solo núcleo)
function buryOrCarryNut(forAgent) {
  const t = forAgent || state;
  const px = forAgent ? forAgent.x : state.px, py = forAgent ? forAgent.y : state.py;
  if (t.carriedNut) {
    t.carriedNut = false;
    if (forAgent) t.saplings = (t.saplings || 0) + 1;
    else state.saplings++;
    dropSeed('oak-tree', px, py); // la nuez enterrada brota aquí (flora-lifecycle)
    if (forAgent) {
      addKarma(TUNING.plantKarma, `Planta un bosque futuro (+${TUNING.plantKarma} karma)`, 'good', forAgent);
      return true;
    }
    addKarma(TUNING.plantKarma, `Plantas un bosque futuro (+${TUNING.plantKarma} karma, retoño banked)`, 'good');
    record('Nuez enterrada (retoño +1)');
    return true;
  }
  const oak = state.oaks.find(o => o.alive && o.amount > 0 && Math.hypot(o.x-px, o.y-py) <= 46);
  if (!oak) return false;
  oak.amount--;
  if (oak.amount <= 0) oak.alive = false; // se agota en silencio: reubicas, no destruyes con karma
  t.carriedNut = true;
  if (!forAgent) log('Llevas una nuez (C para enterrar)', 'info');
  return true;
}
function carryAction() {
  if (state.dead || state.hidden || state.speciesKey !== 'ardilla') return false;
  return buryOrCarryNut(null);
}

// Sentido de especie (V: topo temblor / zorro rastro)
function sensePulse() {
  if (state.dead || state.hidden || state.senseCd > 0) return false;
  if (state.speciesKey === 'topo') {
    state.senseCd = TUNING.senseTremorCd; state.revealT = TUNING.revealTime;
    log('Temblor: sientes comida y peligro (3s)', 'info');
    return true;
  }
  if (state.speciesKey === 'zorro') {
    if (!state.carrions.length) { log('Sin rastro de carroña', 'info'); return false; }
    state.senseCd = TUNING.senseTrackCd; state.trackT = TUNING.trackTime;
    log('Rastro: hueles carroña (5s)', 'info');
    return true;
  }
  return false;
}

