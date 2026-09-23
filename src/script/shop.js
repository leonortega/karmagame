// shop.js - juicio de reencarnacion y tienda (extraido de game.js, sin cambios)
// Depende de globales: state, SPECIES, T1POOL, TUNING, SHOP + game.js (record, log, addKarma, addPa, hideShop).
function judge() {
  const { karma, pa, lifeLog } = state;
  let next, reason, choice = null;
  if (karma >= TUNING.tierUpKarma && pa >= TUNING.tierUpPa) {
    next = 'halcon';
    choice = ['halcon','zorro']; // ascenso dual, pick gratis
    reason = `Karma ${karma} ≥ +50 y PA ${Math.floor(pa)} ≥ 100 → asciendes. Elige cuerpo T2.`;
  } else if (karma <= TUNING.tierDownKarma) {
    next = 'oruga';
    reason = `Karma ${karma} ≤ -50 → involución (castigo), sin importar PA.`;
  } else if (state.speciesKey === 'oruga' && karma >= TUNING.sapoHopKarma) {
    next = 'sapo'; // salto de redención
    reason = `Oruga con karma ${karma} ≥ +20 → redención parcial: Sapo.`;
  } else {
    const i = T1POOL.indexOf(state.speciesKey);
    next = i >= 0 ? T1POOL[(i+1) % T1POOL.length] : 'raton';
    reason = `Karma neutral (${karma}) → adaptación lateral, misma dificultad.`;
  }
  return { next, reason, choice, log: [...lifeLog] };
}

function isLateral(next) {
  return T1POOL.includes(state.speciesKey) && T1POOL.includes(next);
}

function showJudgment() {
  const { next, reason, choice } = judge();
  state.pendingNext = next;
  state.pendingChoice = choice;
  state.formChosen = false;
  state.shopOpen = false;
  state.hidden = false;
  hideShop();
  document.getElementById('jStats').innerHTML =
    `Karma final: <b>${state.karma}</b> · PA: <b>${Math.floor(state.pa)}</b> · Tiempo: <b>${fmtTime(state.time)}</b>`;
  document.getElementById('jReason').textContent = reason;
  document.getElementById('jNext').textContent = `Siguiente vida: ${SPECIES[next].name} (Tier ${SPECIES[next].tier})`;
  // Historial causa-efecto
  const hist = state.lifeLog.slice(-4).map(e=>`• ${e}`).join('<br>');
  document.getElementById('jReason').innerHTML = reason + (hist?`<br><br>${hist}`:'');
  // Pick T2 gratis vs Choose-form lateral de pago
  document.getElementById('t2pick').style.display = choice ? 'block' : 'none';
  const cf = document.getElementById('chooseForm');
  cf.style.display = (!choice && isLateral(next)) ? 'block' : 'none';
  refreshChooseButtons();
  refreshT2Buttons();
  document.getElementById('judgment').classList.remove('hidden');
}
function hideJudgment(){ document.getElementById('judgment').classList.add('hidden'); }

function refreshChooseButtons() {
  const can = state.pa >= TUNING.chooseFormCost && !state.formChosen;
  ['Raton','Ardilla','Topo','Sapo'].forEach(f => {
    document.getElementById('btnChoose'+f).disabled = !can;
  });
}
function refreshT2Buttons() {
  const off = state.formChosen;
  document.getElementById('btnT2Halcon').disabled = off;
  document.getElementById('btnT2Zorro').disabled = off;
}
function paintNext(form) {
  document.getElementById('jNext').textContent = `Siguiente vida: ${SPECIES[form].name} (Tier ${SPECIES[form].tier})`;
  document.getElementById('jStats').innerHTML =
    `Karma final: <b>${state.karma}</b> · PA: <b>${Math.floor(state.pa)}</b> · Tiempo: <b>${fmtTime(state.time)}</b>`;
}

// Pick T2 gratis en el juicio
function pickT2(form) {
  if (!state.dead || state.formChosen) return false;
  if (!state.pendingChoice || !state.pendingChoice.includes(form)) return false;
  state.pendingNext = form;
  state.formChosen = true;
  paintNext(form);
  refreshT2Buttons(); refreshChooseButtons();
  record(`Elegiste cuerpo T2 ${SPECIES[form].name} (gratis)`);
  log(`Eliges reencarnar como ${SPECIES[form].name}`, 'info');
  return true;
}

// Item Choose-form del juicio: elige lateral T1 por 15 PA del saldo arrastrado
function chooseForm(form) {
  if (!state.dead || state.formChosen) return false;
  if (!isLateral(state.pendingNext)) return false;
  if (!T1POOL.includes(form)) return false;
  if (state.pa < TUNING.chooseFormCost) return false;
  state.pa -= TUNING.chooseFormCost;
  state.pendingNext = form;
  state.formChosen = true;
  paintNext(form);
  refreshChooseButtons();
  record(`Elegiste forma ${SPECIES[form].name} (−${TUNING.chooseFormCost} PA)`);
  log(`Eliges reencarnar como ${SPECIES[form].name} (−${TUNING.chooseFormCost} PA)`, 'info');
  return true;
}

function toggleShop() {
  if (state.dead) return;
  state.shopOpen = !state.shopOpen;
  document.getElementById('shop').classList.toggle('hidden', !state.shopOpen);
  if (state.shopOpen) renderShop();
  else hideShop();
}
function hideShop(){
  if (state) state.shopOpen = false;
  document.getElementById('shop').classList.add('hidden');
}
function renderShop() {
  const box = document.getElementById('shopItems');
  box.innerHTML = SHOP.map(s => {
    const owned = !!state.owned[s.id] || (s.id==='voice' && state.voiceUsed);
    const poor = !owned && state.pa < s.cost;
    const tag = owned ? '[comprado]' : poor ? '[sin PA]' : `[${s.key}]`;
    const cls = owned ? 'owned' : poor ? 'poor' : '';
    return `<div class="item ${cls}">${tag} <b>${s.name}</b> −${s.cost} PA · ${s.desc}</div>`;
  }).join('') + `<div class="item">Saldo: <b>${Math.floor(state.pa)} PA</b></div>`;
}
function buyItem(id) {
  if (state.dead || !state.shopOpen) return false;
  const item = SHOP.find(s=>s.id===id);
  if (!item) return false;
  if (state.owned[id]) return false; // sin apilado: una compra por stat
  if (id === 'voice' && state.voiceUsed) return false;
  if (state.pa < item.cost) return false; // sin deuda
  state.pa -= item.cost;
  state.owned[id] = true;
  if (id === 'stomach') state.hp = Math.min(effMaxHp(), state.hp + 25);
  record(`Adaptación ${item.name} (−${item.cost} PA)`);
  log(`Compras <b>${item.name}</b> (−${item.cost} PA): ${item.desc}`, 'info');
  renderShop();
  return true;
}

