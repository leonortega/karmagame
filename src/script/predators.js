// predators.js - cadena trofica y depredadores (extraido de game.js, sin cambios)
// Depende de globales: state, PRED, TUNING, WORLD + utils.js + game.js (addCarrion, record, log).
// Fila trófica de reserva para carnívoros sin entrada en PRED (halcón de fauna)
const PRED_FALLBACK = { name: 'Depredador', speed: 150, perception: 250, damage: 20,
  body: 22, size: 3, huntsTiers: [], huntsMates: false, huntsZorro: false, fears: ['lobo'] };
function mkPredator(type, x, y, playerTier) {
  const t = PRED[type];
  return { type, speciesKey: type === 'saponpc' ? 'sapo' : type, kind: 'hunter',
    hp: SPECIES[type === 'saponpc' ? 'sapo' : type].maxHp,
    x, y, wx:x, wy:y,
    speed: t.speed + (playerTier===0 && type==='zorro' ? 25 : 0), // oruga: más presión
    mode:'wander', campT:0, huntT:0, restT:0, satedT:0, fleeLatch:false, huntingPlayer:false,
  };
}
// Forrajeo óptimo: dif talla ≥2 se ignora salvo snap por contacto
function edibleFor(hunterType, victimKey, dist) {
  const v = SPECIES[victimKey];
  if (hunterType === 'saponpc') return victimKey === 'oruga';
  const t = PRED[hunterType];
  if (!t || !t.huntsTiers) return false; // sin fila trófica (halcón): no caza al jugador
  if (!t.huntsTiers.includes(v.tier)) return false;
  if (hunterType === 'zorro' && t.size - v.size >= 2 && dist > TUNING.snapRange) return false;
  return true;
}
function playerEdibleFor(p, dist) {
  return edibleFor(p.type, state.speciesKey, dist);
}
function camouflaged() {
  return state.speciesKey === 'sapo' && state.stillT >= 2;
}
function curled() {
  return state.speciesKey === 'oruga' && state.stillT >= 0.01 && state.curlCd <= 0 && !state.moved;
}
function updatePredators(dt) {
  const dead = [];
  for (const p of allHunters()) stepPredator(p, dt, dead);
  for (const z of dead) removeAgent(z);
}

function stepPredator(p, dt, dead) {
  const t = PRED[p.type] || PRED_FALLBACK;
  if (p.satedT>0) p.satedT-=dt;
  if (p.restT>0) p.restT-=dt;
  if (fleeCheck(p, t, dt)) return;
  if (campStep(p, dt)) return;
  const dp = Math.hypot(state.px-p.x, state.py-p.y);
  // (camuflado rompe el seguimiento del zorro, no del lobo)
  const camoHidden = camouflaged() && p.type === 'zorro';
  // señuelo (la quietud del camuflaje calla hasta el reclamo: el sapo inmóvil pierde al zorro)
  const lureOn = state.lureTimer>0 && !state.hidden && !(camouflaged() && p.type==='zorro');
  const hit = pickTarget(p, t, dp, lureOn, camoHidden);
  if (hit.hunting) chase(p, t, hit, lureOn, dt);
  else { p.huntT = 0; strikeAgents(p, t, dt); }
  strikeContact(p, t, dp);
  feast(p, dead);
}

// Caza entre NPCs: el carnívoro acecha a la víctima IA comestible más cercana
function edibleAgentFor(hunterType, a, dist) {
  if (a.brain === 'PLAYER') return false;
  if (hunterType === 'halcon') return SPECIES[a.speciesKey].size <= 2;
  return edibleFor(hunterType, a.speciesKey, dist);
}
function stalkVictims(p) {
  return state.agents.filter(a => a !== p && a.role !== 'hunter' && edibleAgentFor(p.type, a, 1e9));
}
function strikeAgents(p, t, dt) {
  if (p.restT > 0) return;
  const v = nearestFrom(p.x, p.y, stalkVictims(p), t.perception);
  if (!v) return;
  const d = Math.hypot(v.x-p.x, v.y-p.y) || 1;
  const killRange = p.type === 'halcon' ? 60 : 20;
  if (d <= killRange) {
    if (p.type === 'halcon') { diveKill(v, p); removeAgent(v); return; }
    removeAgent(v);
    addCarrion(v.x, v.y);
    healEater(p, TUNING.pounceHp); // el cazador se alimenta de su presa
    if (p.type === 'zorro') p.satedT = TUNING.satedTime;
    return;
  }
  const mult = p.type === 'lobo' ? TUNING.loboChaseMult : TUNING.chaseMult;
  p.x += (v.x-p.x)/d*p.speed*mult*dt; p.y += (v.y-p.y)/d*p.speed*mult*dt;
  p.mode = 'hunt';
}

function fleeCheck(p, t, dt) {
  // 1) Miedo: huir del grande (con histéresis anti-oscilación)
  const fear = nearestPredOf(t.fears, t.perception * (p.fleeLatch ? TUNING.fleeHysteresis : 1), p);
  if (fear) p.fleeLatch = true;
  else if (!nearestPredOf(t.fears, t.perception * TUNING.fleeHysteresis, p)) p.fleeLatch = false;
  if (p.fleeLatch && fear) {
    const d = Math.hypot(p.x-fear.x, p.y-fear.y)||1;
    p.x += (p.x-fear.x)/d*p.speed*1.3*dt; p.y += (p.y-fear.y)/d*p.speed*1.3*dt;
    p.mode = 'flee';
    return true;
  }
  return false;
}

function campStep(p, dt) {
  // 2) Jugador oculto: acampar el refugio y luego vagar
  if (p.mode === 'camp') {
    p.campT -= dt;
    if (p.campT <= 0) { p.mode = 'wander'; }
    else if (state.hideRef) { // espera junto al refugio
      const dx = state.hideRef.x-p.x, dy = state.hideRef.y-p.y, dd = Math.hypot(dx,dy)||1;
      if (dd > 30) { p.x += dx/dd*p.speed*dt; p.y += dy/dd*p.speed*dt; }
    }
    return true;
  }
  if (state.hidden && p.huntingPlayer) {
    p.mode = 'camp'; p.campT = TUNING.campTime; p.huntingPlayer = false;
    return true;
  }
  return false;
}

function pickTarget(p, t, dp, lureOn, camoHidden) {
  // 3) Elegir presa: señuelo > jugador comestible > presa de cadena > vagar
  if ((lureOn && dp < TUNING.shoutLureRange) ||
      (!state.hidden && !camoHidden && playerEdibleFor(p, dp) && dp < t.perception && p.restT<=0)) {
    p.huntingPlayer = true;
    return { tx: state.px, ty: state.py, hunting: 'player' };
  }
  p.huntingPlayer = false;
  if (p.type === 'zorro' && p.satedT<=0) {
    const m = nearest(stalkVictims(p), t.perception);
    if (m && p.restT<=0) return { tx: m.x, ty: m.y, hunting: 'mate' };
  }
  if (p.type === 'lobo') {
    const z = nearestPredOf(['zorro'], t.perception, p);
    if (z && p.restT<=0) return { tx: z.x, ty: z.y, hunting: 'zorro' };
  }
  if (p.type === 'saponpc') {
    if (state.speciesKey === 'oruga' && !state.hidden && dp < t.perception && p.restT<=0) {
      p.huntingPlayer = true;
      return { tx: state.px, ty: state.py, hunting: 'player' };
    }
  }
  if (Math.hypot(p.wx-p.x,p.wy-p.y)<20){ p.wx=Math.random()*WORLD.w; p.wy=Math.random()*WORLD.h; }
  p.mode = 'wander';
  return { tx: p.wx, ty: p.wy, hunting: false };
}

function chase(p, t, hit, lureOn, dt) {
  const mult = p.type === 'lobo' ? TUNING.loboChaseMult : TUNING.chaseMult;
  const dd = Math.hypot(hit.tx-p.x,hit.ty-p.y)||1;
  p.x += (hit.tx-p.x)/dd*p.speed*mult*dt; p.y += (hit.ty-p.y)/dd*p.speed*mult*dt;
  p.mode = 'hunt'; p.huntT += dt;
  if (p.huntT > TUNING.chaseMax && !lureOn) { p.mode = 'wander'; p.huntT = 0; p.restT = TUNING.restTime; }
}

function strikeContact(p, t, dp) {
  // 4) Contacto (sapo: susto 10; rizo: mitad)
  if (!state.hidden && dp < state.sp.radius + t.body/2 && state.invuln<=0) {
    let dmg = t.damage;
    if (curled()) { dmg = Math.ceil(dmg/2); state.curlCd = TUNING.curlCd; }
    state.hp -= dmg;
    state.invuln = TUNING.predatorInvuln;
    log(`${t.name} te muerde (−${dmg} vida)`, 'bad');
    record(`Herido por ${t.name.toLowerCase()} (−${dmg} vida)`);
  }
}

function feast(p, dead) {
  if (p.type === 'zorro' && p.satedT<=0) {
    const m = nearest(stalkVictims(p), 16);
    if (m) {
      removeAgent(m);
      addCarrion(m.x, m.y);
      p.satedT = TUNING.satedTime;
      record('Un zorro cazó un congénere (hay carroña fresca)');
    }
  }
  if (p.type === 'lobo') {
    const z = nearestPredOf(['zorro'], 20, p);
    if (z) {
      dead.push(z);
      addCarrion(z.x, z.y);
      record('Un lobo mató un zorro (hay carroña fresca)');
    }
  }
}
