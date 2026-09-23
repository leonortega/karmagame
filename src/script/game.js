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

function ageWorld(dt) {
  // Carroña envejece; hojas rebrotan
  for (const c of state.carrions) c.age += dt;
  for (const l of state.clumps) {
    if (!l.alive || l.amount < 3) {
      l.regrowT += dt;
      if (l.regrowT >= TUNING.leafRegrow && l.amount < 3) {
        l.amount++; l.alive = true; l.regrowT = 0;
      }
    }
  }
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
    state.px = clamp(state.px + ix/l*effSpeed()*dt, 20, WORLD.w-20);
    state.py = clamp(state.py + iy/l*effSpeed()*dt, 20, WORLD.h-20);
  }
  // Quietud: camuflaje y rizo
  if (!state.moved) state.stillT += dt; else state.stillT = 0;
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

// Bucle compartido: toda la fauna pasa hambre, pasta su dieta y muere
function updateAgents(dt) {
  const dead = [];
  for (const a of state.agents) {
    a.hp -= TUNING.hungerPerSec * dt;
    if (a.hp <= 0) { dead.push(a); continue; }
    if (a.kind !== 'grazer') continue; // los carnívoros se alimentan cazando
    const range = a.speciesKey === 'sapo' ? TUNING.tongueRange : TUNING.eatRange;
    if (DIET[a.speciesKey].includes('insects')) {
      const ins = nearestFrom(a.x, a.y, state.insects, range);
      if (ins && eatInsect(ins, a)) continue;
    }
    const p = nearestEdiblePatchFor(a, range);
    if (p) eatPatch(p, a);
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
