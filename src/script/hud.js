// hud.js - log y HUD (extraido de game.js, sin cambios)
// Depende de globales: state + state.js (effMaxHp, effSize, refugeFits) + utils.js (fmtTime) + shop.js (renderShop).
function log(html, cls='info') {
  const el = document.getElementById('log');
  if (!el) return;
  const d = document.createElement('div');
  d.className = cls; d.innerHTML = html;
  el.prepend(d);
  while (el.children.length>5) el.lastChild.remove();
}

// Eventos de otros animales: panel izquierdo (leyenda + fauna)
function logOther(html, cls='info') {
  const el = document.getElementById('otherLog');
  if (!el) return;
  const d = document.createElement('div');
  d.className = cls; d.innerHTML = html;
  el.prepend(d);
  while (el.children.length>5) el.lastChild.remove();
}

// Fila del panel izquierdo: icono + karma + vida de cada agente visible
function otherPanelLines() {
  if (typeof state === 'undefined' || !state.agents) return [];
  return state.agents.slice(0, 8).map(a => {
    const sp = SPECIES[a.speciesKey];
    if (!sp) return '';
    const icon = speciesIcon(a.speciesKey);
    const last = (a.lifeLog || []).slice(-1)[0];
    return `${icon} ${sp.name} k:${Math.round(a.karma || 0)} hp:${Math.ceil(a.hp)}${last ? ' · ' + last : ''}`;
  });
}

function renderOtherPanel() {
  const el = document.getElementById('otherPanel');
  if (!el) return;
  const lines = otherPanelLines();
  el.innerHTML = lines.length
    ? lines.map(l => `<div class="other">${l}</div>`).join('')
    : '<div class="other">sin fauna cerca</div>';
}

// Controles por especie (hud-clarity): BASE + extras, con cuentas (Ns) estilo verbos.
// R fuera en vida; Q solo gritones; V solo topo/zorro; C solo ardilla.
function controlRows() {
  const sk = state.speciesKey;
  const rows = [];
  rows.push({ key:'WASD/Flechas', label:'moverse', cd:0 });
  let eCd = 0, eExtra = '';
  if (sk === 'zorro' && state.pounceCd > 0) eCd = state.pounceCd;
  if (sk === 'topo') {
    if (state.digCd > 0) eCd = state.digCd;
    eExtra = ` (${state.dug}/${TUNING.digMax})`;
  }
  rows.push({ key:'E', label:(CONTROLS_E[sk] || 'comer/cazar') + eExtra, cd:eCd });
  if (CONTROLS_Q.includes(sk)) rows.push({ key:'Q', label:'gritar', cd:state.shoutCd });
  if (CONTROLS_V[sk]) rows.push({ key:'V', label:CONTROLS_V[sk], cd:state.senseCd });
  if (CONTROLS_C.includes(sk)) {
    const nut = state.carriedNut ? ' (nuez en lomo: C enterrar)' : '';
    rows.push({ key:'C', label:'llevar/enterrar' + nut, cd:0 });
  }
  rows.push({ key:'H', label: state.hidden ? 'salir (hambre y sed siguen)' : 'esconderse', cd:0 });
  rows.push({ key:'B', label:'tienda (1-3 comprar)', cd:0 });
  return rows;
}

function renderControls() {
  const el = document.getElementById('controls');
  if (!el) return;
  el.innerHTML = '<ul>' + controlRows().map(r => {
    const cd = r.cd > 0 ? ` (${Math.ceil(r.cd)}s)` : '';
    return `<li class="ctl${cd ? ' cd' : ''}"><b>${r.key}</b> ${r.label}${cd}</li>`;
  }).join('') + '</ul>';
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
  document.getElementById('edadLabel').textContent =
    `Edad ${Math.floor(state.edad || 0)}s (~${animalYears(state.speciesKey, state.edad || 0).toFixed(1)} años)`;
  document.getElementById('karmaText').textContent = state.karma;
  const kf = document.getElementById('karmaFill');
  kf.style.width = Math.abs(state.karma)/2+'%';
  kf.style.marginLeft = state.karma>=0 ? '50%' : (50+state.karma/2)+'%';
  kf.style.background = state.karma>=0 ? '#4caf50' : '#f44336';
  const paEl = document.getElementById('paLabel');
  paEl.innerHTML = `<span class="pa-icon">✦</span> <b>${Math.floor(state.pa)} PA</b>`;
  paEl.className = 'pa-emph';
  document.getElementById('timeLabel').textContent = 'Tiempo ' + fmtTime(state.time);
  document.getElementById('speciesLabel').textContent = `${state.sp.name} Tier ${state.sp.tier}`;
  // prompt de refugio
  const near = state.refuges.filter(r => Math.hypot(r.x-state.px, r.y-state.py) <= TUNING.hideRange);
  const fit = near.find(r => refugeFits(r));
  const pr = document.getElementById('prompt');
  if (state.hidden) pr.textContent = 'Oculto — H salir · hambre y sed siguen drenando';
  else if (fit) pr.textContent = `H esconderse (${fit.type})`;
  else if (near.length) pr.textContent = `No cabes aquí (tamaño ${effSize()})`;
  else pr.textContent = '';
  // Barra de verbos 1-5 (karma-verbs): lista vertical, cd y coste a la vista
  const defs = VERB_DEFS[state.speciesKey] || [];
  document.getElementById('verbBar').innerHTML = '<ul class="verbs">' + defs.map((v, i) => {
    const cd = state.verbCds[i] > 0 ? ` (${Math.ceil(state.verbCds[i])}s)` : '';
    const poor = state.pa < v.costPa ? ' poor' : '';
    return `<li class="verb verb-row${cd ? ' cd' : ''}${poor}" title="${v.desc}">[${v.slot}] ${v.name}${cd}</li>`;
  }).join('') + '</ul>';
  renderControls();
  if (state.shopOpen) renderShop();
  renderOtherPanel();
}
