// ai.js - motor de comportamiento IA por especie (ai-behavior-karma)
// Depende de globales: state, SPECIES, DIET, TUNING, SHOP + utils.js
//   + state.js (addKarma, addPa, record, aiTryShout, removeAgent, companyAgents, allHunters)
//   + eat.js (eatPatch, eatInsect, eatCarrion, healEater, nearestEdiblePatchFor, addCarrion)
//   + predators.js (PRED, edibleFor, strikePredator).
const AI_SHOUTERS = ['raton', 'topo', 'sapo', 'ardilla', 'lobo']; // grito de especie (spec ai-karma)

// --- Percepción según karma de la víctima (6.2): bueno=esquiva, malo=imán ---
// Multiplica la distancia efectiva: con mod 0.8 una víctima a d se ve solo si d < P*0.8 (spec exacto).
function karmaSightMult(karma) {
  if (karma >= TUNING.aiKarmaGood) return 1 - TUNING.aiPredPerceptMod;
  if (karma <= TUNING.aiKarmaBad) return 1 + TUNING.aiPredPerceptMod;
  return 1;
}
// nearest con percepción karma-ahora: e = d / mult(víctima); detecta si e < maxD
function nearestVictimKarmaAware(ax, ay, list, maxD) {
  let best = null, be = maxD;
  for (const o of list) {
    const d = Math.hypot(o.x - ax, o.y - ay);
    const e = d / karmaSightMult(o.karma || 0);
    if (e < be) { be = e; best = o; }
  }
  return best;
}

// Fila de la tabla PRED para un agente fauna carnívoro (el halcón usa reglas propias)
function aiPredRow(a) {
  return PRED[a.speciesKey] || { perception: SPECIES[a.speciesKey].vision, damage: 15, body: 18 };
}

// Víctima fauna comestible más cercana (tabla trófica; halcón: talla ≤2), con karma de la víctima
// Presa oculta no es presa (3.2): los que cazan por tierra pierden al oculto
function nearestAiPrey(a, range) {
  const prey = state.agents.filter(v => v !== a && v.brain !== 'PLAYER' && v.role !== 'hunter' && !v.hidden &&
    (a.speciesKey === 'halcon' ? SPECIES[v.speciesKey].size <= 2 : edibleFor(a.speciesKey, v.speciesKey, 1e9)));
  return nearestVictimKarmaAware(a.x, a.y, prey, range);
}

// Caza IA: persigue y mata a bocado (carroña + curación, valores del jugador)
function aiHuntEat(a, prey, dt) {
  const d = Math.hypot(prey.x - a.x, prey.y - a.y) || 1;
  const killRange = a.speciesKey === 'halcon' ? 60 : 20;
  if (d <= killRange) {
    if (a.speciesKey === 'halcon') { a.x = prey.x; a.y = prey.y; }
    removeAgent(prey);
    addCarrion(prey.x, prey.y);
    healEater(a, TUNING.pounceHp);
    if (a.speciesKey === 'zorro') a.satedT = TUNING.satedTime;
    return true;
  }
  const mult = a.speciesKey === 'lobo' ? TUNING.loboChaseMult : TUNING.chaseMult;
  moveToward(a, prey.x, prey.y, mult, dt); // misma marcha que el jugador (paridad)
  return false;
}

// Huida del que la tabla PRED marca como miedo, sesgada hacia cobertura cercana (3.7)
function aiFlee(a, dt) {
  const fears = PRED[a.speciesKey] && PRED[a.speciesKey].fears;
  if (!fears || !fears.length) return false;
  const fear = nearestFrom(a.x, a.y, state.agents.filter(o =>
    (o.role === 'hunter' || o.kind === 'hunter') && fears.includes(o.type)), 200);
  if (!fear) return false;
  let dx = a.x - fear.x, dy = a.y - fear.y;
  const d = Math.hypot(dx, dy) || 1;
  dx /= d; dy /= d;
  // sesgo: si hay refugio apto cerca, mezcla el vector de huida con el de cobertura (60/40)
  const cover = state.refuges.find(r => refugeFitsSize(SPECIES[a.speciesKey], r) &&
    Math.hypot(r.x - a.x, r.y - a.y) <= TUNING.aiCoverRange);
  if (cover) {
    const cd = Math.hypot(cover.x - a.x, cover.y - a.y) || 1;
    dx = dx * 0.6 + (cover.x - a.x) / cd * 0.4;
    dy = dy * 0.6 + (cover.y - a.y) / cd * 0.4;
  }
  const dl = Math.hypot(dx, dy) || 1;
  moveToward(a, a.x + dx / dl * 100, a.y + dy / dl * 100, 1, dt); // huida por la marcha propia (paridad)
  return true;
}

// Grito de especie ante peligro cercano (alerta): el premio va al ledger del agente
function aiShoutIfReady(a) {
  if (!AI_SHOUTERS.includes(a.speciesKey)) return false;
  if ((a.shoutCd || 0) > 0) return false;
  if (!nearestFrom(a.x, a.y, state.agents.filter(o => o.role === 'hunter'), TUNING.shoutLureRange)) return false;
  return aiTryShout(a);
}

// Desface común: cooldowns propios, grito oportunista, compra periódica, imán del señuelo
function aiBase(a, dt) {
  for (const k of ['shoutCd', 'pounceCd', 'strikeCd', 'digCd', 'curlCd', 'groomCd', 'senseCd', 'lureTimer', 'satedT', 'landT'])
    if ((a[k] || 0) > 0) a[k] -= dt;
  aiShoutIfReady(a);
  a.buyT = (a.buyT || 0) - dt; // compra de adaptaciones: evaluación periódica (3.2)
  if (a.buyT <= 0) {
    a.buyT = TUNING.aiBuyEvery;
    if (a.owned) aiBuyAdaptation(a); // los agentes sin ledger (veteranos de test) no compran
  }
  if ((a.lureTimer || 0) > 0) { // el señuelo acerca a los cazadores al gritón
    const p = nearestFrom(a.x, a.y, allHunters(), TUNING.shoutLureRange);
    if (p) {
      const d = Math.hypot(p.x - a.x, p.y - a.y) || 1;
      p.x += (a.x - p.x) / d * 60 * dt;
      p.y += (a.y - p.y) / d * 60 * dt;
    }
  }
}

// Hazaña IA: ahuyentar depredador (mismos valores que el jugador: lobo 20, resto 5)
function aiStrike(a, p) {
  strikePredator(p, a);
  const k = p.type === 'lobo' ? TUNING.loboStrikeKarma : TUNING.strikeKarma;
  addKarma(k, `¡Ahuyenta a un ${p.type}! (+${k} karma)`, k > 5 ? 'good' : 'info', a);
  addPa(TUNING.strikePa, a);
  a.hp = Math.min(SPECIES[a.speciesKey].maxHp, a.hp + TUNING.strikeHp);
  a.strikeCd = TUNING.strikeCd;
}

// --- Compra de adaptaciones (3.1-3.5): PA interno, sin UI, una por stat ---
function aiBuyAdaptation(a) {
  if (a.owned.stomach && a.owned.swift && a.owned.nose) return false;
  const maxHp = SPECIES[a.speciesKey].maxHp + (a.owned.stomach ? 25 : 0);
  let want = null;
  if (a.hp < maxHp / 2 && !a.owned.stomach) want = 'stomach';
  else if (!a.owned.nose) want = 'nose';
  else if (!a.owned.swift) want = 'swift';
  if (!want) return false;
  const item = SHOP.find(s => s.id === want);
  if (!item || a.pa < item.cost) return false;
  a.pa -= item.cost;
  a.owned[want] = true;
  if (want === 'stomach') a.hp = Math.min(maxHp, a.hp + 25);
  record(`Adaptación IA ${item.name} (−${item.cost} PA)`, a);
  return true;
}

// --- Supervivencia (foraging-survival-ai) ---
// ¿Hambriento? El umbral corta comportamientos secundarios cuando la vida baja
function isHungry(a) {
  return a.hp < SPECIES[a.speciesKey].maxHp * TUNING.hungerPriority;
}
// Buscar comida más allá del rango de boca: camina hacia el parche o insecto de dieta más cercano
function aiForage(a, dt) {
  const range = SPECIES[a.speciesKey].vision * TUNING.forageRangeMult;
  let target = null, bd = range;
  if (DIET[a.speciesKey].includes('insects')) {
    const ins = nearestFrom(a.x, a.y, state.insects, range);
    if (ins) { target = ins; bd = Math.hypot(ins.x - a.x, ins.y - a.y); }
  }
  const patch = nearestEdiblePatchFor(a, bd);
  if (patch) target = patch;
  if (!target) return false;
  moveToward(a, target.x, target.y, 1, dt); // misma marcha que el jugador (paridad)
  return true;
}
// Ocultación real (3.1-3.6): entra en un refugio apto como el jugador; sale al irse el peligro o por tope
function aiTryHide(a) {
  if (a.hidden) return true;
  const near = state.refuges.filter(r => Math.hypot(r.x - a.x, r.y - a.y) <= TUNING.hideRange);
  const fit = near.find(r => refugeFitsSize(SPECIES[a.speciesKey], r));
  if (!fit) return false;
  a.hidden = true; a.hideRef = fit; a.hideT = TUNING.aiHideMax;
  return true;
}
function refugeFitsSize(sp, r) {
  if (sp.size > r.maxSize) return false;
  if (r.climbOnly && !sp.climb) return false;
  return true;
}
// ¿Alguien me caza? depredador de fila que me tiene en su menú, dentro de mi ventana de miedo
function isHunted(a) {
  return !!nearestFrom(a.x, a.y, state.agents.filter(o =>
    o.role === 'hunter' && edibleFor(o.type, a.speciesKey, 1e9)), TUNING.aiFearRange);
}
// Tick de escondite: salir al irse el peligro o al agotar el tope
function aiHideTick(a, dt) {
  if (!a.hidden) return false;
  a.hideT = (a.hideT || 0) - dt;
  const danger = nearestFrom(a.x, a.y, state.agents.filter(o => o.role === 'hunter'),
    aiPredRow({ speciesKey: a.speciesKey }).perception);
  if (a.hideT <= 0 || !danger) { a.hidden = false; a.hideRef = null; }
  return true; // sigue ocupado escondido (o recién salido este tick)
}

// Carroña a distancia para carnívoros: busca dentro de percepción (ampliada si flaco)
function aiSeekCarrion(a, dt) {
  const percept = aiPredRow(a).perception * (isHungry(a) ? TUNING.lowHpPercept : 1);
  const c = nearestFrom(a.x, a.y, state.carrions.filter(k => !k.ceded || isHungry(a)), percept);
  if (!c) return false;
  const d = Math.hypot(c.x - a.x, c.y - a.y) || 1;
  if (d > TUNING.eatRange) {
    moveToward(a, c.x, c.y, 1, dt); // misma marcha que el jugador (paridad)
    return true;
  }
  return !!eatCarrion(c, a);
}

// --- Especies: hambre + hábitos propios ---
function aiGrazerEat(a, range) {
  if (DIET[a.speciesKey].includes('insects')) {
    const ins = nearestFrom(a.x, a.y, state.insects, range);
    if (ins && eatInsect(ins, a)) return true;
  }
  const p = nearestEdiblePatchFor(a, range);
  return p ? eatPatch(p, a) : false;
}

function aiOruga(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiHideTick(a, dt)) return; // oculto: nada de nada (el hambre ya drenó arriba)
  if (isHunted(a) && aiTryHide(a)) return;
  if (aiGrazerEat(a, TUNING.eatRange)) { a.stillT = 0; return; }
  if (aiForage(a, dt)) { a.stillT = 0; return; } // hambre manda: buscar antes que enroscarse
  a.stillT = (a.stillT || 0) + dt; // quieta: enroscada (curled(a) la cubre, mitad de daño)
}

function aiSapo(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiHideTick(a, dt)) return;
  if (isHunted(a) && aiTryHide(a)) return;
  if (aiFlee(a, dt)) { a.stillT = 0; return; }
  if (aiGrazerEat(a, TUNING.tongueRange)) { a.stillT = 0; return; }
  if (aiForage(a, dt)) { a.stillT = 0; return; } // hambre manda: buscar antes que camuflarse
  a.stillT = (a.stillT || 0) + dt; // quieto: camuflado (predators.js lo respeta vía camouflaged(a))
}

function aiRaton(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiHideTick(a, dt)) return;
  if (isHunted(a) && aiTryHide(a)) return;
  if (aiGrazerEat(a, TUNING.eatRange)) return;
  if (aiForage(a, dt)) return; // buscar antes que acicalar/deambular (hambre o provisión)
  // Acicalado: congénere cerca, cd listo → +5 karma tras groomTime
  if ((a.groomCd || 0) <= 0 && nearestFrom(a.x, a.y, companyAgents(), TUNING.groomRange)) {
    a.groomT = (a.groomT || 0) + dt;
    if (a.groomT >= TUNING.groomTime) {
      a.groomT = 0; a.groomCd = TUNING.groomCd;
      addKarma(TUNING.groomKarma, `Acicala a un congénere (+${TUNING.groomKarma} karma)`, 'good', a);
    }
  } else a.groomT = 0;
  a.x += (Math.random() - 0.5) * 40 * dt;
  a.y += (Math.random() - 0.5) * 40 * dt;
}

function aiArdilla(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiHideTick(a, dt)) return;
  if (isHunted(a) && aiTryHide(a)) return;
  if (a.carriedNut && isHungry(a)) a.carriedNut = false; // hambre: suelta la nuez y come (spec ai-survival)
  if (a.carriedNut) { // planta donde está: +10 karma, retoño banked, brote real (flora-lifecycle)
    a.carriedNut = false; a.saplings = (a.saplings || 0) + 1;
    dropSeed('oak-tree', a.x, a.y);
    addKarma(TUNING.plantKarma, `Planta un bosque futuro (+${TUNING.plantKarma} karma)`, 'good', a);
    return;
  }
  const oak = state.oaks.find(o => o.alive && o.amount > 0 && Math.hypot(o.x - a.x, o.y - a.y) <= TUNING.eatRange);
  if (oak && !isHungry(a)) { // el roble es despensa para llevar, no merienda (identidad de especie)
    oak.amount--; if (oak.amount <= 0) oak.alive = false;
    a.carriedNut = true;
    return;
  }
  if (aiGrazerEat(a, TUNING.eatRange)) return; // comer (no-nuez) si hay; con hambre también nuez al vuelo
  a.x += (Math.random() - 0.5) * 40 * dt;
  a.y += (Math.random() - 0.5) * 40 * dt;
}

function aiTopo(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiHideTick(a, dt)) return;
  if (isHunted(a) && aiTryHide(a)) return;
  if (aiGrazerEat(a, TUNING.eatRange)) return;
  if (aiForage(a, dt)) return; // buscar antes que cavar
  if ((a.digCd || 0) <= 0 && (a.dug || 0) < TUNING.digMax) { // cavar: +3 karma de aireado
    a.digCd = TUNING.digCd; a.dug = (a.dug || 0) + 1;
    state.refuges.push({ type: 'burrow-M', maxSize: 2, climbOnly: false, x: a.x, y: a.y, dug: true });
    addKarma(TUNING.aerateKarma, `Airea la tierra (+${TUNING.aerateKarma} karma)`, 'good', a);
    return;
  }
  a.x += (Math.random() - 0.5) * 40 * dt;
  a.y += (Math.random() - 0.5) * 40 * dt;
}

function aiZorro(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (aiFlee(a, dt)) return;
  if ((a.satedT || 0) > 0) { // saciado: cede carroña (+15) si la hay, si no deambula
    const c = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
    if (c && !c.ceded) {
      c.ceded = true;
      addKarma(TUNING.cedeKarma, `Cede la presa a otros (+${TUNING.cedeKarma} karma)`, 'good', a);
    }
    return;
  }
  if (isHungry(a) && aiSeekCarrion(a, dt)) return; // flaco: carroña primero, a cualquier distancia
  const prey = nearestAiPrey(a, aiPredRow(a).perception);
  if (prey) { aiHuntEat(a, prey, dt); return; }
  const c = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
  if (c) eatCarrion(c, a);
  else if (!aiForage(a, dt)) { a.x += (Math.random() - 0.5) * 60 * dt; a.y += (Math.random() - 0.5) * 60 * dt; }
}

function aiLobo(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if ((a.strikeCd || 0) <= 0) { // hazaña primero: ahuyentar otro depredador de fila TIER_SPAWNS
    const p = nearestFrom(a.x, a.y, state.agents.filter(o =>
      o !== a && o.role === 'hunter' && o.type !== a.speciesKey), 60);
    if (p) { aiStrike(a, p); return; }
  }
  if (isHungry(a) && aiSeekCarrion(a, dt)) return; // flaco: carroña primero
  const prey = nearestAiPrey(a, aiPredRow(a).perception);
  if (prey) { aiHuntEat(a, prey, dt); return; }
  const c = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
  if (c) eatCarrion(c, a);
}

function aiHalcon(a, dt) {
  a.hp -= TUNING.hungerPerSec * dt;
  aiBase(a, dt);
  if (!a.grounded && (a.strikeCd || 0) <= 0) { // hazaña: picado defensivo contra depredador
    const p = nearestFrom(a.x, a.y, state.agents.filter(o =>
      o !== a && (o.role === 'hunter' || o.kind === 'hunter')), 60);
    if (p) { aiStrike(a, p); return; }
  }
  if (a.grounded) { // en tierra: come carroña o despega
    const c = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
    if (c && (a.landT || 0) <= 0 && eatCarrion(c, a)) { a.grounded = false; return; }
    if ((a.landT || 0) <= 0) a.grounded = false;
    return;
  }
  const prey = nearestAiPrey(a, 200);
  if (prey) {
    if (aiHuntEat(a, prey, dt)) { a.grounded = true; a.landT = TUNING.landTime; }
    return;
  }
  const c = nearestFrom(a.x, a.y, state.carrions, TUNING.eatRange);
  if (c) { a.grounded = true; a.landT = TUNING.landTime; return; } // aterriza para comer
  a.x += (Math.random() - 0.5) * 80 * dt;
  a.y += (Math.random() - 0.5) * 80 * dt;
}

// Despacho por especie (tabla, no switch: PRED-first por convención del repo)
const AI_BY_SPECIES = {
  oruga: aiOruga, sapo: aiSapo, raton: aiRaton, ardilla: aiArdilla,
  topo: aiTopo, zorro: aiZorro, lobo: aiLobo, halcon: aiHalcon,
};
function aiStep(a, dt) {
  const fn = AI_BY_SPECIES[a.speciesKey];
  if (fn) fn(a, dt);
}
