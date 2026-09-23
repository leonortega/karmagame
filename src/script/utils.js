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
