// shop.js - juicio de reencarnacion y tienda (extraido de game.js, sin cambios)
// Depende de globales: state, SPECIES, T1POOL, T2POOL, TUNING, SHOP_BY_SPECIES + game.js (record, log, addKarma, addPa, hideShop).
// Piso de desbloqueo por karma (azar-birth): castigo -> T1 -> T1+T2 aditivo, sin PA ni forma muerta.
function poolFor(karma) {
  if (karma <= TUNING.tierDownKarma) return ['oruga'];
  if (karma >= TUNING.tierUpKarma) return [...T1POOL, ...T2POOL];
  return [...T1POOL];
}
// Sorteo uniforme sobre el pool con azar inyectable (tests pasan stub, el juego pasa Math.random)
function drawFrom(pool, rand) {
  const r = typeof rand === 'function' ? rand : Math.random;
  return pool[Math.floor(r() * pool.length) % pool.length];
}
// Juicio azar: el pool lo decide el karma, el cuerpo lo deciden los dioses. Sin PA, sin forma muerta, sin elección.
function judge(rand) {
  const { karma } = state;
  const pool = poolFor(karma);
  const next = drawFrom(pool, rand);
  const names = pool.map(k => SPECIES[k].name).join(', ');
  let reason;
  if (karma <= TUNING.tierDownKarma) reason = `Karma ${karma} ≤ -50 → involución: los dioses te devuelven como Oruga.`;
  else if (karma >= TUNING.tierUpKarma) reason = `Karma ${karma} ≥ +50 → los dioses te abren el pool T1+T2 (${names}).`;
  else reason = `Karma neutral (${karma}) → pool T1 (${names}).`;
  return { pool, next, reason };
}

// Catálogo por especie: cada bicho compra solo lo suyo (misma lógica jugador/IA).
function catalogFor(speciesKey) { return SHOP_BY_SPECIES[speciesKey] || []; }
// Efecto mecánico de un item (las claves heredadas swift/stomach/nose/voice ya son su efecto).
function adaptEffect(id) {
  for (const k of Object.keys(SHOP_BY_SPECIES)) {
    const it = SHOP_BY_SPECIES[k].find(s => s.id === id);
    if (it) return it.effect;
  }
  return id;
}
function hasAdapt(t, effect) {
  if (!t || !t.owned) return false;
  if (t.owned[effect]) return true;
  return Object.keys(t.owned).some(id => t.owned[id] && adaptEffect(id) === effect);
}

let fateTimer = null; // el ciclo decorativo vive fuera del state: la pantalla inicial nace sin state
function clearFateTimer() { if (fateTimer) { clearTimeout(fateTimer); fateTimer = null; } }

function showJudgment() {
  const { pool, next, reason } = judge();
  state.pendingNext = next; // destino decidido en sincronía: la animación solo lo revela
  state.pendingPool = pool;
  state.shopOpen = false;
  state.hidden = false;
  hideShop();
  clearFateTimer();
  document.getElementById('jStats').innerHTML =
    `Karma final: <b>${state.karma}</b> · PA: <b>${Math.floor(state.pa)}</b> · Tiempo: <b>${fmtTime(state.time)}</b>`;
  // Historial causa-efecto
  const hist = state.lifeLog.slice(-4).map(e=>`• ${e}`).join('<br>');
  document.getElementById('jReason').innerHTML = reason + (hist?`<br><br>${hist}`:'');
  document.getElementById('jNext').textContent =
    `los dioses eligen que reencarnes en... ${SPECIES[next].name} (Tier ${SPECIES[next].tier})`;
  renderFateBlocks('fateBlocks', pool, next);
  animateFateBlocks('fateBlocks', pool, next);
  document.getElementById('judgment').classList.remove('hidden');
}
// Bloques del destino: un bloque por especie, las no elegibles atenuadas, la elegida iluminada. Sin botones: el azar no se negocia.
function renderFateBlocks(elId, pool, winner) {
  const el = document.getElementById(elId);
  if (!el) return;
  el.innerHTML = Object.keys(SPECIES).map(k => {
    const cls = k === winner ? 'fate winner' : pool.includes(k) ? 'fate' : 'fate dim';
    return `<span class="${cls}">${SPECIES[k].name}</span>`;
  }).join(' ');
}
// Ciclo decorativo (~1s): ilumina elegibles por turnos y se asienta en el destino ya decidido. Nunca cambia el resultado.
function animateFateBlocks(elId, pool, winner) {
  clearFateTimer();
  let i = 0;
  const tick = () => {
    renderFateBlocks(elId, pool, pool[i % pool.length]);
    if (++i < 10) fateTimer = setTimeout(tick, 90);
    else { renderFateBlocks(elId, pool, winner); fateTimer = null; }
  };
  fateTimer = setTimeout(tick, 90);
}
function hideJudgment(){
  clearFateTimer();
  document.getElementById('judgment').classList.add('hidden');
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
  box.innerHTML = catalogFor(state.speciesKey).map(s => {
    const owned = !!state.owned[s.id];
    const poor = !owned && state.pa < s.cost;
    const tag = owned ? '[comprado]' : poor ? '[sin PA]' : `[${s.key}]`;
    const cls = owned ? 'owned' : poor ? 'poor' : '';
    return `<div class="item ${cls}">${tag} <b>${s.name}</b> −${s.cost} PA · ${s.desc}</div>`;
  }).join('') + `<div class="item">Saldo: <b>${Math.floor(state.pa)} PA</b></div>`;
}
function buyItem(id) {
  if (state.dead || !state.shopOpen) return false;
  const item = catalogFor(state.speciesKey).find(s=>s.id===id);
  if (!item) return false; // solo tu especie vende
  if (state.owned[id]) return false; // sin apilado: una compra por item
  if (state.pa < item.cost) return false; // sin deuda
  state.pa -= item.cost;
  state.owned[id] = true;
  if (item.effect === 'stomach') state.hp = Math.min(effMaxHp(), state.hp + 25);
  record(`Adaptación ${item.name} (−${item.cost} PA)`);
  log(`Compras <b>${item.name}</b> (−${item.cost} PA): ${item.desc}`, 'info');
  renderShop();
  return true;
}

