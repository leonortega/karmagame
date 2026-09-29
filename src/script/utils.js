// utils.js - helpers puros (extraidos de game.js, sin cambios de comportamiento)
// Dependen de globales: WORLD, state. Sin DOM.
function scatter(n, margin=120) {
  const pts = [];
  for (let i=0;i<n;i++) pts.push({ x: margin+Math.random()*(WORLD.w-margin*2), y: margin+Math.random()*(WORLD.h-margin*2) });
  return pts;
}
function mkPatch(kind, x, y, amount, extra={}) {
  return { kind, x, y, amount, alive:true, ...extra };
}
function spawnPt() { return scatter(1)[0]; }
function areaScale() { return (WORLD.w * WORLD.h) / BASE_AREA; }
function scaledCount(base) { return Math.max(1, Math.round(base * areaScale())); }
function nearestFrom(ax, ay, list, maxD) {
  let best=null, bd=maxD;
  for (const o of list) { const d = Math.hypot(o.x-ax, o.y-ay); if (d<bd){bd=d;best=o;} }
  return best;
}
function nearest(list, maxD) {
  return nearestFrom(state.px, state.py, list, maxD);
}
function nearestPredOf(types, maxD, from) {
  let best=null, bd=maxD;
  for (const p of state.agents) {
    if (!(p.role === 'hunter' || p.kind === 'hunter') || !types.includes(p.type)) continue;
    const d = Math.hypot(p.x-from.x, p.y-from.y);
    if (d<bd){bd=d;best=p;}
  }
  return best;
}
function fmtTime(s){ const m=Math.floor(s/60), ss=Math.floor(s%60); return `${m}:${String(ss).padStart(2,'0')}`; }
function clamp(v,a,b){ return Math.max(a,Math.min(b,v)); }

// --- Terreno sólido (readable-forest-solid-terrain) ---
// Sólidos derivados del estado existente: refugios, plantas vivas y rocas. Sin registro paralelo.
function solidRadius(refugeType) {
  if (refugeType === 'old-oak' || refugeType === 'hollow-tree') return TUNING.solidRefuge + 4; // troncos
  return TUNING.solidRefuge;
}
function collectSolids() {
  const out = [];
  for (const r of state.refuges) out.push({ x: r.x, y: r.y, r: solidRadius(r.type) });
  for (const p of state.bushes) if (p.alive && p.amount > 0) out.push({ x: p.x, y: p.y, r: TUNING.solidPlant });
  for (const p of state.shrubs) if (p.alive && p.amount > 0) out.push({ x: p.x, y: p.y, r: TUNING.solidPlant });
  for (const p of state.patches) if (p.alive && p.amount > 0) out.push({ x: p.x, y: p.y, r: TUNING.solidPlant });
  for (const p of state.clusters) if (p.alive && p.amount > 0) out.push({ x: p.x, y: p.y, r: TUNING.solidPlant });
  for (const p of state.oaks) if (p.alive && p.amount > 0) out.push({ x: p.x, y: p.y, r: TUNING.solidPlant + 2 });
  for (const k of state.rocks || []) out.push({ x: k.x, y: k.y, r: TUNING.solidRock, rock: true });
  return out;
}
// Empuje circular con deslizamiento: saca al agente del sólido por la línea de centros.
// move: { get(): {x,y}, set(k,v) } — el agente se mueve en el espacio de propiedades de quien llama.
function resolveCollisions(agent, solids) {
  const list = solids || collectSolids();
  const pos = agent.get();
  for (const s of list) {
    if (agent.skipRock && s.rock) continue; // el topo subterráneo pasa bajo las piedras
    const dx = pos.x - s.x, dy = pos.y - s.y;
    const d = Math.hypot(dx, dy), min = s.r + agent.r;
    if (d >= min || d === 0) continue;
    pos.x = s.x + dx / d * min;
    pos.y = s.y + dy / d * min;
    agent.set('x', pos.x); agent.set('y', pos.y);
  }
}
// LOS por muestreo del segmento: solo troncos ciegan (rocas y plantas son cobertura baja).
function losBlocked(fx, fy, tx, ty, flying) {
  if (flying) return false; // el halcón ve por encima de todo tronco
  for (const s of collectSolids()) {
    if (s.r < TUNING.solidRefuge) continue; // solo troncos (refugios grandes) tapan
    for (let i = 1; i < TUNING.losSamples; i++) {
      const t = i / TUNING.losSamples;
      const px = fx + (tx - fx) * t, py = fy + (ty - fy) * t;
      if (Math.hypot(px - s.x, py - s.y) < s.r) return true;
    }
  }
  return false;
}
