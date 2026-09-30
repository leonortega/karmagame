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
function hungerRateFor(speciesKey){ return TUNING.hungerPerSec * ((SPECIES[speciesKey]||{}).hungerMult || 1); }
// sed drena thirstMult veces más rápido que el hambre (vitals-water)
function thirstRateFor(speciesKey){ return hungerRateFor(speciesKey) * TUNING.thirstMult; }
// Gancho futuro de edad: hoy 1.0 (la edad solo cuenta, no modera)
function effAgeMult(){ return 1; }
// ¿Más sediento que hambriento? El empate bebe: la sed drena más rápido (vitals-water).
// Sin argumento lee al jugador; con agente lee su propio ledger (paridad IA).
function thirstier(t) {
  const o = t || state;
  return (100 - (o.sed ?? 100)) >= (100 - (o.hambre ?? 100));
}
// Agua más cercana desde el borde (se bebe en la orilla, no en el centro)
function nearestWaterFor(ax, ay, maxD) {
  let best = null, bd = maxD;
  for (const w of state.waters || []) {
    const d = Math.hypot(w.x - ax, w.y - ay) - w.r;
    if (d < bd) { bd = d; best = w; }
  }
  return best;
}
// Solo agua dentro del agua: centro dentro de algun radio (+margen)
function insideWater(x, y, margin=0) {
  for (const w of state.waters || []) {
    if (Math.hypot(w.x - x, w.y - y) < w.r + margin) return true;
  }
  return false;
}
// Punto seco: reintentos acotados fuera del agua; si no hay hueco, el mas lejano.
function scatterDry(n, dryMargin=0) {
  const pts = [];
  for (let i=0;i<n;i++) {
    let best = scatter(1)[0];
    for (let t=0;t<12 && insideWater(best.x, best.y, dryMargin);t++) best = scatter(1)[0];
    if (insideWater(best.x, best.y, dryMargin)) nudgeDry(best, dryMargin); // ultimo recurso
    pts.push(best);
  }
  return pts;
}
function dryPt() { return scatterDry(1)[0]; }
// Orilla seca mas cercana: saca un punto del agua por la linea de centros.
// Varias pasadas: salir de un agua puede meter en otra vecina (lagos juntos).
function nudgeDry(pt, dryMargin=0) {
  for (let pass = 0; pass < 10; pass++) {
    let moved = false;
    for (const w of state.waters || []) {
      const dx = pt.x - w.x, dy = pt.y - w.y, d = Math.hypot(dx, dy);
      const min = w.r + dryMargin + 0.5; // epsilon: el borde matematico cuenta como fuera
      if (d < min) {
        if (d === 0) pt.x = w.x + min;
        else { pt.x = w.x + dx / d * min; pt.y = w.y + dy / d * min; }
        moved = true;
      }
    }
    if (!moved) break;
  }
  pt.x = clamp(pt.x, 20, WORLD.w - 20); pt.y = clamp(pt.y, 20, WORLD.h - 20);
  return pt;
}
// Tick compartido jugador/IA (vitals-water): stocks drenan siempre; la vida
// regen solo si hambre Y sed superan umbrales, si no drena con tope de déficit.
// El daño (mordisco, ponzoña, verbos) resta hp aparte: aquí nunca se compensa.
function updateNeeds(t, maxHp, dt) {
  t.hambre = clamp((t.hambre ?? 100) - hungerRateFor(t.speciesKey) * dt, 0, 100);
  t.sed = clamp((t.sed ?? 100) - thirstRateFor(t.speciesKey) * dt, 0, 100);
  t.edad = (t.edad || 0) + dt;
  if (t.hambre > TUNING.regenHambre && t.sed > TUNING.regenSed) {
    t.hp = Math.min(maxHp, t.hp + TUNING.vidaRegenPerSec * dt);
    return;
  }
  const deficit = Math.min((100 - t.hambre) / 100 + (100 - t.sed) / 100, TUNING.deficitMax);
  t.hp -= hungerRateFor(t.speciesKey) * (1 + deficit) * effAgeMult() * dt;
}

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
  for (const w of state.waters || []) out.push({ x: w.x, y: w.y, r: w.r, water: true }); // orilla: entra quien nada
  return out;
}
// Quien ignora la orilla: el sapo nada siempre; el halcón solo en vuelo.
// El topo tunela bajo piedras, no bajo lagos: queda bloqueado como el resto.
function skipsWater(speciesKey, grounded) {
  if (WATER_ENTER[speciesKey]) return true; // anfibios/agua (pato futuro: una fila)
  return speciesKey === 'halcon' && !grounded;
}
// Empuje circular con deslizamiento: saca al agente del sólido por la línea de centros.
// move: { get(): {x,y}, set(k,v) } — el agente se mueve en el espacio de propiedades de quien llama.
function resolveCollisions(agent, solids) {
  const list = solids || collectSolids();
  const pos = agent.get();
  for (const s of list) {
    if (agent.skipRock && s.rock) continue; // el topo subterráneo pasa bajo las piedras
    if (agent.skipWater && s.water) continue; // quien nada (sapo) o vuela (halcón) ignora la orilla
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
    if (s.water) continue; // el agua es plana: se ve al sapo dentro (water-terrain-entry)
    if (s.r < TUNING.solidRefuge) continue; // solo troncos (refugios grandes) tapan
    for (let i = 1; i < TUNING.losSamples; i++) {
      const t = i / TUNING.losSamples;
      const px = fx + (tx - fx) * t, py = fy + (ty - fy) * t;
      if (Math.hypot(px - s.x, py - s.y) < s.r) return true;
    }
  }
  return false;
}
