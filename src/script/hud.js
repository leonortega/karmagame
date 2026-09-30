// hud.js - log y HUD (extraido de game.js, sin cambios)
// Depende de globales: state + state.js (effMaxHp, effSize, refugeFits) + utils.js (fmtTime) + shop.js (renderShop).
function log(html, cls='info') {
  const el = document.getElementById('log');
  const d = document.createElement('div');
  d.className = cls; d.innerHTML = html;
  el.prepend(d);
  while (el.children.length>5) el.lastChild.remove();
}

// utils.js: fmtTime

// Barra de necesidad con marca de umbral y tinte de corto (vitals-water)
const NEED_IDS = { hunger: ['hungerFill', 'hungerMark', 'hungerText'], sed: ['sedFill', 'sedMark', 'sedText'] };
function paintNeed(name, value, thresh) {
  const [fillId, markId, textId] = NEED_IDS[name];
  const fill = document.getElementById(fillId);
  fill.style.width = Math.max(0, value) + '%';
  fill.className = 'fill ' + name + (value <= thresh ? ' low' : '');
  document.getElementById(markId).style.left = thresh + '%';
  document.getElementById(textId).textContent = String(Math.ceil(Math.max(0, value)));
}

// --- loop ---
let last = performance.now();
function updateHud() {
  document.getElementById('hpFill').style.width = (100*state.hp/effMaxHp())+'%';
  document.getElementById('hpText').textContent = Math.ceil(state.hp)+'/'+effMaxHp();
  paintNeed('hunger', state.hambre, TUNING.regenHambre);
  paintNeed('sed', state.sed, TUNING.regenSed);
  document.getElementById('edadLabel').textContent = 'Edad ' + Math.floor(state.edad || 0) + 's';
  document.getElementById('karmaText').textContent = state.karma;
  const kf = document.getElementById('karmaFill');
  kf.style.width = Math.abs(state.karma)/2+'%';
  kf.style.marginLeft = state.karma>=0 ? '50%' : (50+state.karma/2)+'%';
  kf.style.background = state.karma>=0 ? '#4caf50' : '#f44336';
  document.getElementById('paLabel').textContent = 'PA: '+Math.floor(state.pa);
  document.getElementById('timeLabel').textContent = fmtTime(state.time);
  let extra = state.shoutCd>0?` · Q en ${Math.ceil(state.shoutCd)}s`:' · Q listo';
  if (state.speciesKey==='zorro') extra = state.pounceCd>0?` · Zarpazo en ${Math.ceil(state.pounceCd)}s`:' · E zarpazo';
  if (state.speciesKey==='topo') extra += state.digCd>0?` · Cavar en ${Math.ceil(state.digCd)}s`:` · E cavar (${state.dug}/${TUNING.digMax})`;
  if (state.senseCd>0) extra += ` · Sentido en ${Math.ceil(state.senseCd)}s`;
  if (state.carriedNut) extra += ' · nuez en lomo (C enterrar)';
  document.getElementById('speciesLabel').textContent = `${state.sp.name} T${state.sp.tier}` + extra;
  // prompt de refugio
  const near = state.refuges.filter(r => Math.hypot(r.x-state.px, r.y-state.py) <= TUNING.hideRange);
  const fit = near.find(r => refugeFits(r));
  const pr = document.getElementById('prompt');
  if (state.hidden) pr.textContent = 'Oculto — H salir · hambre y sed siguen drenando';
  else if (fit) pr.textContent = `H esconderse (${fit.type})`;
  else if (near.length) pr.textContent = `No cabes aquí (tamaño ${effSize()})`;
  else pr.textContent = '';
  // Barra de verbos 1-5 (karma-verbs): cd y coste a la vista
  const defs = VERB_DEFS[state.speciesKey] || [];
  document.getElementById('verbBar').innerHTML = defs.map((v, i) => {
    const cd = state.verbCds[i] > 0 ? ` (${Math.ceil(state.verbCds[i])}s)` : '';
    const poor = state.pa < v.costPa ? ' poor' : '';
    return `<span class="verb${cd ? ' cd' : ''}${poor}">[${v.slot}] ${v.name}${cd}</span>`;
  }).join(' ');
  if (state.shopOpen) renderShop();
}
