// --- Iconos distinguibles por elemento (una sola fuente para canvas y tests) ---
const SPECIES_ICON = { oruga:'🐛', sapo:'🐸', raton:'🐭', ardilla:'🐿️', topo:'🦔', halcon:'🦅', zorro:'🦊', lobo:'🐺' };
const FOOD_ICON = { berries:'🍒', apples:'🍎', carrots:'🥕', mushrooms:'🍄', nuts:'🌰', leaves:'🍃', insects:'🦗', carrion:'🍖' };
const FOOD_LABEL = { berries:'bayas', apples:'manzana', carrots:'zanahoria', mushrooms:'setas', nuts:'nuez', leaves:'hojas', insects:'insectos', carrion:'carroña' };
const CARRION_ICON = { fresh:'🍖', stale:'🍗', rotten:'🤢' };
const REFUGE_ICON = { 'burrow-S':'🕳️', 'burrow-M':'🕳️', 'hollow-tree':'🪵', 'thorn-bush':'🌵', 'old-oak':'🌳', 'leafroll':'🍂' };
const WATER_ICON = { charco:'💧', lago:'🌊' };
const WATER_LABEL = { charco:'charco', lago:'lago' };
const REFUGE_LABEL = { 'burrow-S':'madriguera S', 'burrow-M':'madriguera M', 'hollow-tree':'tronco hueco', 'thorn-bush':'zarza', 'old-oak':'roble viejo', 'leafroll':'hoja enrollada' };
// Base opaca bajo el emoji: el color identifica el tipo, el emoji la especie exacta
const FOOD_BASE = { berries:'#1b5e20', apples:'#2e7d32', carrots:'#4e342e', mushrooms:'#8d6e63', nuts:'#5d4037', leaves:'#33691e' };
const REFUGE_BASE = { 'burrow-S':'#6d4c41', 'burrow-M':'#6d4c41', 'hollow-tree':'#5d4037', 'thorn-bush':'#1b5e20', 'old-oak':'#2e7d32' };
function speciesIcon(form) { return SPECIES_ICON[form] || '❓'; }
function foodIcon(kind) { return FOOD_ICON[kind] || '❓'; }
function refugeIcon(type) { return REFUGE_ICON[type] || '⛺'; }
function carrionIcon(stage) { return CARRION_ICON[stage] || '🍖'; }
function waterIcon(kind) { return WATER_ICON[kind] || '💧'; }

// Cohesion emoji por categoria: animal > comida > terreno > decor (tamanos en px)
// Los robles son hitos de paisaje: exceden la banda animal a proposito
const EMOJI_SIZE = { animal: 28, food: 18, terrain: 15, decor: 10 };
const EMOJI_FONT = '"Segoe UI Emoji","Apple Color Emoji","Noto Color Emoji",serif';
const ANIMAL_SIZE_DELTA = { oruga:-4, sapo:-2, raton:0, ardilla:0, topo:0, halcon:4, zorro:4, lobo:6 };
function animalEmojiSize(form) { return EMOJI_SIZE.animal + (ANIMAL_SIZE_DELTA[form] || 0); }
const REFUGE_SIZE = { 'old-oak': 34, 'hollow-tree': 26, 'thorn-bush': 20, 'burrow-S': 15, 'burrow-M': 15 };
function refugeEmojiSize(type) { return REFUGE_SIZE[type] || EMOJI_SIZE.terrain; }

function drawEmoji(icon, x, y, size) {
  ctx.save();
  ctx.font = size + 'px ' + EMOJI_FONT;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(icon, x, y);
  ctx.restore();
}

// Etiqueta legible: píldora oscura + texto claro (sin measureText: funciona con el stub de test)
function drawTag(text, x, y, bg) {
  const w = text.length * 6 + 10;
  ctx.save();
  ctx.globalAlpha = 0.92;
  ctx.fillStyle = bg || 'rgba(10,12,14,.85)';
  ctx.beginPath();
  ctx.ellipse(x, y, w / 2, 9, 0, 0, 7);
  ctx.fill();
  ctx.globalAlpha = 1;
  ctx.fillStyle = '#fff';
  ctx.font = '10px system-ui,sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, x, y + 0.5);
  ctx.restore();
}

function drawShadow(R) {
  ctx.fillStyle = 'rgba(0,0,0,.3)';
  ctx.beginPath();
  ctx.ellipse(0, 2, R * 1.1, R * 0.45, 0, 0, 7);
  ctx.fill();
}

// Medalla solida bajo el emoji: sombra + disco opaco + ribete (el emoji va encima).
// Llamar con translate ya aplicado; devuelve el radio del disco.
function drawMedal(size, color) {
  const R = size * 0.55;
  drawShadow(R);
  ctx.fillStyle = color;
  ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fill();
  ctx.strokeStyle = 'rgba(0,0,0,.28)'; ctx.lineWidth = 1.5;
  ctx.stroke();
  return R;
}

// --- Animales: medalla del color de la especie + emoji encima ---
function drawSpecies(form, x, y, dir, t, opts={}) {
  const sp = SPECIES[form];
  const s = opts.scale || 1;
  const size = animalEmojiSize(form) * s;
  ctx.save();
  ctx.translate(x, y);
  const R = drawMedal(size, sp.color);
  if (opts.outline) {
    ctx.strokeStyle = opts.outline; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.arc(0, 0, R + 2.5, 0, 7); ctx.stroke();
  }
  drawEmoji(speciesIcon(form), 0, 0, size);
  ctx.restore();
}

// Comida: medalla + emoji vivo, cruz + pelada si esta seca
function drawPatch(p) {
  ctx.save();
  ctx.translate(p.x, p.y);
  const dead = !p.alive || p.amount <= 0;
  if (dead) {
    ctx.strokeStyle = '#616161'; ctx.lineWidth = 2.5;
    ctx.beginPath(); ctx.moveTo(-8, -8); ctx.lineTo(8, 8); ctx.moveTo(8, -8); ctx.lineTo(-8, 8); ctx.stroke();
    drawTag('pelada', 0, 16);
    ctx.restore(); return;
  }
  const revealed = mimicsVisible(), toxR = toxicsVisible();
  const marked = (p.kind === 'berries' && p.mimic && !p.mimicEaten && revealed.includes(p)) ||
    (p.kind === 'mushrooms' && p.toxicLeft > 0 && toxR.includes(p));
  drawMedal(EMOJI_SIZE.food, FOOD_BASE[p.kind] || '#243528');
  if (marked) {
    ctx.strokeStyle = '#ff5252'; ctx.lineWidth = 2.5; ctx.setLineDash([5, 3]);
    ctx.beginPath(); ctx.arc(0, -6, 19, 0, 7); ctx.stroke();
    ctx.setLineDash([]);
    drawEmoji('☠️', 16, -20, 14);
  }
  drawEmoji(foodIcon(p.kind), 0, -8, EMOJI_SIZE.food);
  drawTag(FOOD_LABEL[p.kind] + ' ×' + p.amount, 0, 16);
  ctx.restore();
}

// Indicadores por agente: icono + barra de vida + karma sobre el sprite
function drawAgentIndicators(a, sp) {
  const key = a.speciesKey || a.type;
  const y = a.y - sp.radius - 12;
  drawTag(speciesIcon(key) + ' ' + Math.round(a.karma || 0), a.x, y - 8);
  const frac = Math.max(0, a.hp) / sp.maxHp;
  ctx.fillStyle = 'rgba(10,12,14,.85)';
  ctx.fillRect(a.x - 13, y - 3, 26, 5);
  ctx.fillStyle = frac > 0.5 ? '#66bb6a' : frac > 0.25 ? '#ffca28' : '#ef5350';
  ctx.fillRect(a.x - 12, y - 2, 24 * frac, 3);
}

function drawInsectSwarm(t) {
  for (const i of state.insects) drawEmoji(foodIcon('insects'), i.x, i.y, EMOJI_SIZE.food);
  if (state.insects.length) drawEmoji(foodIcon('insects'), state.insects[0].x, state.insects[0].y - 10, EMOJI_SIZE.food);
  for (const i of state.insects) drawTag(FOOD_LABEL.insects, i.x, i.y + 10);
}

function carrionLook(stage) {
  if (stage === 'fresh') return { meat: '#b03939', bone: '#efebe9', label: 'carroña fresca' };
  if (stage === 'stale') return { meat: '#795548', bone: '#d7ccc8', label: 'carroña pasada' };
  return { meat: '#33691e', bone: '#9e9e9e', label: '¡podrida: -25!' };
}

function drawCarrionPile(tracked, t) {
  for (const c of state.carrions) {
    const look = carrionLook(carrionStage(c));
    ctx.save(); ctx.translate(c.x, c.y);
    drawMedal(EMOJI_SIZE.terrain, look.meat);
    if (tracked === c || state.revealT > 0) {
      ctx.strokeStyle = '#ffeb3b'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.arc(0, 0, 14, 0, 7); ctx.stroke();
    }
    ctx.restore();
    drawEmoji(carrionIcon(carrionStage(c)), c.x, c.y - 4, EMOJI_SIZE.terrain);
    drawTag(look.label, c.x, c.y + 16);
  }
}

function drawRefugeField() {
  for (const r of state.refuges) {
    ctx.save(); ctx.translate(r.x, r.y);
    drawMedal(refugeEmojiSize(r.type), REFUGE_BASE[r.type] || '#4e342e');
    ctx.restore();
    drawEmoji(refugeIcon(r.type), r.x, r.y - 22, refugeEmojiSize(r.type));
    drawTag(REFUGE_LABEL[r.type] || r.type, r.x, r.y + 20);
  }
}

// Agua infinita: cuerpo azul a escala del radio + glifo por tipo + etiqueta (sin agotamiento)
// waterDisc mapea el cuerpo (puro, testeable); drawWaterField lo pinta con glifo y etiqueta.
function waterDisc(w) {
  return { r: w.r, color: w.kind === 'lago' ? '#1565c0' : '#42a5f5' };
}
function drawWaterField() {
  for (const w of state.waters || []) {
    const body = waterDisc(w);
    ctx.save(); ctx.translate(w.x, w.y);
    ctx.fillStyle = body.color;
    ctx.beginPath(); ctx.arc(0, 0, body.r, 0, 7); ctx.fill();
    ctx.strokeStyle = 'rgba(13,71,161,.8)'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(0, 0, body.r, 0, 7); ctx.stroke();
    if (state.revealT > 0) { // ojeada/temblor: la orilla se delinea
      ctx.strokeStyle = '#ffee58'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(0, 0, body.r, 0, 7); ctx.stroke();
    }
    ctx.restore();
    drawEmoji(waterIcon(w.kind), w.x, w.y - 6, EMOJI_SIZE.terrain);
    drawTag(WATER_LABEL[w.kind] || w.kind, w.x, w.y + 16);
  }
}

function drawRockField() {
  for (const k of state.rocks || []) {
    ctx.save(); ctx.translate(k.x, k.y);
    drawMedal(EMOJI_SIZE.terrain, '#546e7a');
    ctx.restore();
    drawEmoji('🪨', k.x, k.y - 6, EMOJI_SIZE.terrain);
    drawTag('roca', k.x, k.y + 16);
  }
}

function drawSeedlingField() {
  for (const s of state.seedlings || []) {
    const oak = s.kind === 'oak-tree';
    ctx.save(); ctx.translate(s.x, s.y);
    drawMedal(EMOJI_SIZE.terrain, '#33691e');
    ctx.restore();
    drawEmoji(oak ? '🌳' : '🌱', s.x, s.y - 14, EMOJI_SIZE.terrain);
    drawTag(oak ? 'roble futuro' : 'brote', s.x, s.y + 10);
  }
}

function drawMeadow(x0, y0, tile) {
  for (let gx = x0; gx <= x0 + canvas.width + tile; gx += tile) {
    for (let gy = y0; gy <= y0 + canvas.height + tile; gy += tile) {
      const h = Math.abs(Math.sin(gx * 12.9898 + gy * 78.233) * 43758.5453) % 1;
      if (h < 0.55) continue;
      const ox = gx + (h * 97 % 1) * tile, oy = gy + (h * 57 % 1) * tile;
      if (h > 0.85) {
        ctx.fillStyle = h > 0.93 ? '#f8bbd0' : '#fff59d';
        ctx.beginPath(); ctx.arc(ox, oy, 2.5, 0, 7); ctx.fill();
        ctx.fillStyle = '#66bb6a';
        ctx.fillRect(ox - 0.5, oy, 1, 5);
      } else {
        ctx.strokeStyle = '#4a6572'; ctx.lineWidth = 1.5;
        for (let b = -1; b <= 1; b++) {
          ctx.beginPath(); ctx.moveTo(ox + b * 3, oy); ctx.lineTo(ox + b * 4, oy - 6 - Math.abs(b)); ctx.stroke();
        }
      }
    }
  }
}

const LEGEND_LINES = ['🐛oruga 🐸sapo 🐭ratón 🐿️ardilla', '🦔topo 🦅halcón 🦊zorro 🐺lobo', '🍒bayas 🍎manzana 🥕zanahoria', '🍄setas 🌰nuez 🍃hojas 🦗bicho', '🍖carroña 🕳️madriguera 🪵tronco', '🌵zarza 🌳roble 🪨roca 🌱brote'];
// Disposición UI: la leyenda vive en el panel izquierdo HTML; en el canvas
// solo quedan los avisos del jugador, anclados a la derecha.
function statusAnchor() {
  const w = (typeof canvas !== 'undefined' && canvas.width) || 960;
  return { x: w - 12, align: 'right' };
}

function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const bg = ctx.createLinearGradient ? ctx.createLinearGradient(0, 0, 0, canvas.height) : null;
  if (bg && bg.addColorStop) {
    // El stub de test devuelve función: createLinearGradient es noop allí.
    try {
      bg.addColorStop(0, '#26322b'); bg.addColorStop(1, '#1c2620');
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    } catch (e) { /* stub sin gradiente: sigue el fondo del canvas */ }
  }
  ctx.save(); ctx.translate(-state.cam.x, -state.cam.y);
  ctx.strokeStyle = 'rgba(255,255,255,.06)'; ctx.lineWidth = 1;
  for (let x = 0; x < WORLD.w; x += 80) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, WORLD.h); ctx.stroke(); }
  for (let y = 0; y < WORLD.h; y += 80) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(WORLD.w, y); ctx.stroke(); }
  const t = state.time;
  const tile = 160;
  const x0 = Math.floor(state.cam.x / tile) * tile, y0 = Math.floor(state.cam.y / tile) * tile;
  drawMeadow(x0, y0, tile);
  drawWaterField();
  drawRockField();
  drawRefugeField();
  drawSeedlingField();
  for (const p of state.bushes) drawPatch(p);
  for (const p of state.shrubs) drawPatch(p);
  for (const p of state.patches) drawPatch(p);
  for (const p of state.clusters) drawPatch(p);
  for (const p of state.oaks) drawPatch(p);
  for (const p of state.clumps) drawPatch(p);
  drawInsectSwarm(t);
  const tracked = trackedCarrion();
  drawCarrionPile(tracked, t);
  if (state.revealT > 0) {
    ctx.strokeStyle = '#ffee58'; ctx.lineWidth = 2;
    for (const p of hunterAgents()) { ctx.beginPath(); ctx.arc(p.x, p.y, 20, 0, 7); ctx.stroke(); }
  }
  for (const m of companyAgents()) {
    ctx.globalAlpha = 0.6;
    drawSpecies(m.speciesKey, m.x, m.y, { x: 1, y: 0 }, t, { scale: 0.7 });
    ctx.globalAlpha = 1;
    drawAgentIndicators(m, SPECIES[m.speciesKey]);
  }
  for (const m of faunaAgents()) {
    drawSpecies(m.speciesKey, m.x, m.y, m.face || { x: 1, y: 0 }, t, {});
    drawAgentIndicators(m, SPECIES[m.speciesKey]);
  }
  for (const p of allHunters()) {
    const form = p.type === 'saponpc' ? 'sapo' : (p.speciesKey || p.type);
    const lure = state.lureTimer > 0 && p.mode !== 'flee';
    drawSpecies(form, p.x, p.y, { x: 1, y: 0 }, t, { scale: 1, outline: lure ? '#ff5252' : '#7a1f1f' });
    drawEmoji('⚠️', p.x, p.y - SPECIES[form].radius - 26, 13);
    drawAgentIndicators(p, SPECIES[form]);
  }
  ctx.strokeStyle = 'rgba(255,255,255,.35)'; ctx.setLineDash([8, 6]);
  ctx.beginPath(); ctx.arc(state.px, state.py, effVision(), 0, 7); ctx.stroke();
  ctx.setLineDash([]);
  ctx.globalAlpha = state.hidden ? 0.35 : 1;
  drawSpecies(state.speciesKey, state.px, state.py, state.face, t, {});
  if (state.carriedNut) {
    ctx.fillStyle = '#8d6e63';
    ctx.beginPath(); ctx.arc(state.px, state.py - state.sp.radius - 10, 5.5, 0, 7); ctx.fill();
    ctx.fillStyle = '#4e342e';
    ctx.beginPath(); ctx.ellipse(state.px, state.py - state.sp.radius - 13, 3.5, 2, 0, 0, 7); ctx.fill();
    drawEmoji('🌰', state.px + 10, state.py - state.sp.radius - 10, 12);
  }
  ctx.globalAlpha = 1;
  drawTag('TÚ ' + speciesIcon(state.speciesKey) + ' ' + state.sp.name, state.px, state.py + state.sp.radius + 14, '#1565c0');
  ctx.restore();
  const anchor = statusAnchor();
  ctx.save();
  ctx.textAlign = anchor.align;
  ctx.textBaseline = 'top';
  ctx.font = '12px system-ui,sans-serif';
  let y = 18;
  if (state.lureTimer > 0) { ctx.fillStyle = '#ff5252'; ctx.fillText('¡Te expusiste! Depredadores hacia ti ' + Math.ceil(state.lureTimer) + 's', anchor.x, y); y += 16; }
  if (state.hidden) { ctx.fillStyle = '#9ccc65'; ctx.fillText('OCULTO (H para salir, hambre y sed siguen)', anchor.x, y); y += 16; }
  if (state.grounded) { ctx.fillStyle = '#ffcc80'; ctx.fillText('EN TIERRA (muévete para despegar)', anchor.x, y); y += 16; }
  if (camouflaged()) { ctx.fillStyle = '#4db6ac'; ctx.fillText('MIMETIZADO (inmóvil)', anchor.x, y); y += 16; }
  if (curled()) { ctx.fillStyle = '#9ccc65'; ctx.fillText('ENROSCADO (mitad de daño)', anchor.x, y); }
  ctx.restore();
}
