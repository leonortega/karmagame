// --- Iconos distinguibles por elemento (una sola fuente para canvas y tests) ---
const SPECIES_ICON = { oruga:'🐛', sapo:'🐸', raton:'🐭', ardilla:'🐿️', topo:'🦔', halcon:'🦅', zorro:'🦊', lobo:'🐺' };
const FOOD_ICON = { berries:'🍒', apples:'🍎', carrots:'🥕', mushrooms:'🍄', nuts:'🌰', leaves:'🍃', insects:'🦗', carrion:'🍖' };
const FOOD_LABEL = { berries:'bayas', apples:'manzana', carrots:'zanahoria', mushrooms:'setas', nuts:'nuez', leaves:'hojas', insects:'insectos', carrion:'carroña' };
const REFUGE_ICON = { 'burrow-S':'🕳️', 'burrow-M':'🕳️', 'hollow-tree':'🪵', 'thorn-bush':'🌵', 'old-oak':'🌳' };
const REFUGE_LABEL = { 'burrow-S':'madriguera S', 'burrow-M':'madriguera M', 'hollow-tree':'tronco hueco', 'thorn-bush':'zarza', 'old-oak':'roble viejo' };
function speciesIcon(form) { return SPECIES_ICON[form] || '❓'; }
function foodIcon(kind) { return FOOD_ICON[kind] || '❓'; }
function refugeIcon(type) { return REFUGE_ICON[type] || '⛺'; }

function drawEmoji(icon, x, y, size) {
  ctx.save();
  ctx.font = size + 'px serif';
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

// --- Animales: retrato vectorial limpio, una cara por especie (sin emoji encima) ---
function drawSpecies(form, x, y, dir, t, opts={}) {
  const sp = SPECIES[form];
  const s = opts.scale || 1;
  const R = sp.radius * s;
  ctx.save();
  ctx.translate(x, y);
  drawShadow(R);
  const ang = form === 'halcon' ? 0 : Math.atan2(dir.y, dir.x);
  ctx.save();
  ctx.rotate(ang);
  if (opts.outline) {
    ctx.strokeStyle = opts.outline; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.arc(0, 0, R + 2.5, 0, 7); ctx.stroke();
  }
  if (form === 'oruga') paintOruga(R, t);
  else if (form === 'sapo') paintSapo(R, t);
  else if (form === 'raton') paintRaton(R, t);
  else if (form === 'ardilla') paintArdilla(R, t);
  else if (form === 'topo') paintTopo(R, t);
  else if (form === 'halcon') paintHalcon(R, t);
  else if (form === 'zorro') paintZorro(R, t);
  else if (form === 'lobo') paintLobo(R, t);
  else { ctx.fillStyle = sp.color; ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fill(); }
  ctx.restore();
  ctx.restore();
}

// Ribete sutil común: da volumen sin ensuciar
function rim() {
  ctx.strokeStyle = 'rgba(0,0,0,.28)'; ctx.lineWidth = 1.5;
}

// Ojo cartoon coherente: esclerótica + iris + brillo
function paintEye(ex, ey, er, iris) {
  ctx.fillStyle = '#fff';
  ctx.beginPath(); ctx.arc(ex, ey, er, 0, 7); ctx.fill();
  ctx.fillStyle = iris || '#1a1a1a';
  ctx.beginPath(); ctx.arc(ex + er * 0.25, ey, er * 0.55, 0, 7); ctx.fill();
  ctx.fillStyle = '#fff';
  ctx.beginPath(); ctx.arc(ex + er * 0.1, ey - er * 0.25, er * 0.22, 0, 7); ctx.fill();
}

function paintEar(ex, ey, er, outer, inner) {
  ctx.fillStyle = outer;
  ctx.beginPath(); ctx.arc(ex, ey, er, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = inner;
  ctx.beginPath(); ctx.arc(ex, ey, er * 0.5, 0, 7); ctx.fill();
}

function paintOruga(R, t) {
  ctx.strokeStyle = '#558b2f'; ctx.lineWidth = 1.5; // patitas
  for (let i = 1; i <= 3; i++) {
    const lx = -i * R * 0.5;
    ctx.beginPath(); ctx.moveTo(lx, R * 0.45); ctx.lineTo(lx, R * 0.8); ctx.stroke();
  }
  for (let i = 4; i >= 1; i--) { // segmentos que reptan
    const sx = -i * R * 0.5, sy = Math.sin(t * 8 + i * 1.3) * R * 0.12;
    ctx.fillStyle = i % 2 ? '#8bc34a' : '#7cb342';
    ctx.beginPath(); ctx.arc(sx, sy, R * 0.5, 0, 7); ctx.fill();
    rim(); ctx.stroke();
  }
  const hx = R * 0.45; // cabeza
  ctx.fillStyle = '#9ccc65';
  ctx.beginPath(); ctx.arc(hx, 0, R * 0.55, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.strokeStyle = '#558b2f'; ctx.lineWidth = 1.5; // antenas
  ctx.beginPath(); ctx.moveTo(hx + R * 0.2, -R * 0.45); ctx.lineTo(hx + R * 0.45, -R * 0.85); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(hx + R * 0.35, -R * 0.4); ctx.lineTo(hx + R * 0.7, -R * 0.7); ctx.stroke();
  ctx.fillStyle = '#558b2f';
  ctx.beginPath(); ctx.arc(hx + R * 0.45, -R * 0.85, R * 0.09, 0, 7); ctx.arc(hx + R * 0.7, -R * 0.7, R * 0.09, 0, 7); ctx.fill();
  paintEye(hx + R * 0.25, -R * 0.12, R * 0.2);
  paintEye(hx + R * 0.25, R * 0.26, R * 0.2);
  ctx.strokeStyle = '#33691e'; ctx.lineWidth = 1.5; // sonrisa
  ctx.beginPath(); ctx.arc(hx + R * 0.3, R * 0.02, R * 0.22, 0.5, 1.8); ctx.stroke();
}

function paintSapo(R, t) {
  const wig = Math.sin(t * 4) * R * 0.06;
  ctx.fillStyle = '#3d8b40'; // ancas traseras
  ctx.beginPath(); ctx.ellipse(-R * 0.75, R * 0.5, R * 0.5, R * 0.32, 0.5, 0, 7); ctx.fill();
  ctx.fillStyle = '#66bb6a'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R * 1.25, R * 0.9, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#388e3c'; // manchas
  ctx.beginPath();
  ctx.arc(-R * 0.55, -R * 0.35, R * 0.14, 0, 7); ctx.arc(-R * 0.1, -R * 0.5, R * 0.11, 0, 7); ctx.arc(-R * 0.45, R * 0.05, R * 0.1, 0, 7);
  ctx.fill();
  ctx.fillStyle = '#c8e6c9'; // vientre
  ctx.beginPath(); ctx.ellipse(R * 0.35, R * 0.35, R * 0.6, R * 0.38, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#e8f5e9'; // saco gular que pulsa
  ctx.beginPath(); ctx.arc(R * 0.75, R * 0.15, R * 0.3 + wig, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.strokeStyle = '#1b5e20'; ctx.lineWidth = 1.5; // sonrisa ancha
  ctx.beginPath(); ctx.arc(R * 0.55, -R * 0.05, R * 0.5, 0.3, 1.9); ctx.stroke();
  for (const ey of [-R * 0.42, R * 0.42]) { // ojos dorsales de rana
    ctx.fillStyle = '#66bb6a';
    ctx.beginPath(); ctx.arc(R * 0.25, ey, R * 0.3, 0, 7); ctx.fill();
    rim(); ctx.stroke();
    paintEye(R * 0.32, ey, R * 0.2);
  }
}

function paintRaton(R, t) {
  const wig = Math.sin(t * 5) * R * 0.15;
  ctx.strokeStyle = '#a1887f'; ctx.lineWidth = 2; ctx.lineCap = 'round'; // cola fina
  ctx.beginPath(); ctx.moveTo(-R * 0.9, R * 0.25); ctx.quadraticCurveTo(-R * 1.9, wig, -R * 2.3, R * 0.55); ctx.stroke();
  ctx.fillStyle = '#78909c'; // patitas
  ctx.beginPath(); ctx.ellipse(-R * 0.3, R * 0.85, R * 0.28, R * 0.14, 0, 0, 7); ctx.ellipse(R * 0.45, R * 0.8, R * 0.28, R * 0.14, 0, 0, 7); ctx.fill();
  paintEar(-R * 0.3, -R * 0.85, R * 0.42, '#8fa8bf', '#f4b8c1');
  paintEar(R * 0.35, -R * 0.75, R * 0.42, '#8fa8bf', '#f4b8c1');
  ctx.fillStyle = '#8fa8bf'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R * 1.05, R * 0.85, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#dfe9f2'; // vientre + hocico
  ctx.beginPath(); ctx.ellipse(R * 0.2, R * 0.4, R * 0.55, R * 0.35, 0, 0, 7); ctx.fill();
  ctx.beginPath(); ctx.ellipse(R * 0.85, R * 0.05, R * 0.35, R * 0.25, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#d81b60'; // nariz
  ctx.beginPath(); ctx.arc(R * 1.12, R * 0.05, R * 0.13, 0, 7); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.6)'; ctx.lineWidth = 1; // bigotes
  for (const wy of [-0.05, 0.12]) {
    ctx.beginPath(); ctx.moveTo(R * 0.8, R * wy); ctx.lineTo(R * 1.7, R * (wy - 0.25)); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(R * 0.8, R * wy); ctx.lineTo(R * 1.7, R * (wy + 0.25)); ctx.stroke();
  }
  paintEye(R * 0.4, -R * 0.3, R * 0.24);
}

function paintArdilla(R, t) {
  const wig = Math.sin(t * 4) * R * 0.15;
  ctx.fillStyle = '#a84300'; // cola: silueta oscura detrás
  ctx.beginPath(); ctx.ellipse(-R * 1.25, -R * 0.9 + wig, R * 0.55, R * 1.05, 0.5, 0, 7); ctx.fill();
  ctx.fillStyle = '#e6892e'; // cola interior
  ctx.beginPath(); ctx.ellipse(-R * 1.2, -R * 0.85 + wig, R * 0.36, R * 0.8, 0.5, 0, 7); ctx.fill();
  ctx.fillStyle = '#e6892e'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R, R * 0.85, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#fdebc8'; // pecho
  ctx.beginPath(); ctx.ellipse(R * 0.35, R * 0.35, R * 0.45, R * 0.38, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#a84300'; // orejas con penacho
  for (const ex of [-R * 0.25, R * 0.35]) {
    ctx.beginPath(); ctx.moveTo(ex - R * 0.2, -R * 0.6); ctx.lineTo(ex, -R * 1.2); ctx.lineTo(ex + R * 0.2, -R * 0.6); ctx.closePath(); ctx.fill();
  }
  ctx.fillStyle = '#7b2d00'; // nariz
  ctx.beginPath(); ctx.arc(R * 0.95, R * 0.05, R * 0.12, 0, 7); ctx.fill();
  ctx.strokeStyle = '#7b2d00'; ctx.lineWidth = 1.2; // sonrisa
  ctx.beginPath(); ctx.arc(R * 0.7, R * 0.15, R * 0.2, 0.4, 1.9); ctx.stroke();
  paintEye(R * 0.4, -R * 0.28, R * 0.24);
  ctx.fillStyle = '#fff'; // diente
  ctx.fillRect(R * 0.78, R * 0.28, R * 0.1, R * 0.16);
}

function paintTopo(R, t) {
  ctx.fillStyle = '#8d7b72'; // zarpas pala
  for (const py of [-R * 0.95, R * 0.95]) {
    ctx.beginPath(); ctx.ellipse(R * 0.15, py, R * 0.4, R * 0.2, py > 0 ? -0.4 : 0.4, 0, 0, 7); ctx.fill();
    rim(); ctx.stroke();
  }
  ctx.fillStyle = '#6d5b52'; // cuerpo aterciopelado
  ctx.beginPath(); ctx.ellipse(0, 0, R * 1.1, R * 0.9, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#57453e'; // lomo
  ctx.beginPath(); ctx.ellipse(-R * 0.2, -R * 0.35, R * 0.65, R * 0.4, 0, 0, 7); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.35)'; ctx.lineWidth = 1; // brillo de pelaje
  ctx.beginPath(); ctx.moveTo(-R * 0.7, -R * 0.1); ctx.lineTo(R * 0.3, -R * 0.3); ctx.stroke();
  ctx.fillStyle = '#f2b8b8'; // morro
  ctx.beginPath(); ctx.arc(R * 1.0, 0, R * 0.34, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#c97e7e'; // fosas nasales
  ctx.beginPath(); ctx.arc(R * 1.05, -R * 0.1, R * 0.07, 0, 7); ctx.arc(R * 1.05, R * 0.1, R * 0.07, 0, 7); ctx.fill();
  ctx.fillStyle = '#2e2220'; // ojillos casi ciegos
  ctx.beginPath(); ctx.arc(R * 0.35, -R * 0.25, R * 0.07, 0, 7); ctx.arc(R * 0.35, R * 0.25, R * 0.07, 0, 7); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.5)'; ctx.lineWidth = 1; // bigotes que tantean
  const sniff = Math.sin(t * 6) * R * 0.06;
  ctx.beginPath(); ctx.moveTo(R * 0.8, -R * 0.2); ctx.lineTo(R * 1.4, -R * 0.35 + sniff); ctx.stroke();
  ctx.beginPath(); ctx.moveTo(R * 0.8, R * 0.2); ctx.lineTo(R * 1.4, R * 0.35 - sniff); ctx.stroke();
}

function paintHalcon(R, t) { // vista cenital, mira hacia arriba (-Y)
  const flap = Math.sin(t * 6) * R * 0.35;
  for (const side of [-1, 1]) { // alas con plumas
    ctx.fillStyle = '#5d4037';
    ctx.beginPath();
    ctx.moveTo(0, -R * 0.2);
    ctx.quadraticCurveTo(side * R * 1.2, -R * 1.1 - flap, side * R * 2.0, -R * 0.7 - flap);
    ctx.quadraticCurveTo(side * R * 1.5, -R * 0.3, side * R * 1.7, R * 0.25);
    ctx.quadraticCurveTo(side * R * 0.9, R * 0.15, 0, R * 0.4);
    ctx.closePath(); ctx.fill();
    rim(); ctx.stroke();
    ctx.fillStyle = '#8d6e63'; // coberteras
    ctx.beginPath();
    ctx.moveTo(0, -R * 0.1);
    ctx.quadraticCurveTo(side * R * 0.8, -R * 0.7 - flap * 0.6, side * R * 1.3, -R * 0.45 - flap * 0.6);
    ctx.quadraticCurveTo(side * R * 0.8, -R * 0.1, 0, R * 0.3);
    ctx.closePath(); ctx.fill();
  }
  ctx.fillStyle = '#5d4037'; // cola en abanico con banda clara
  ctx.beginPath(); ctx.moveTo(-R * 0.4, R * 0.8); ctx.lineTo(R * 0.4, R * 0.8); ctx.lineTo(0, R * 1.7); ctx.closePath(); ctx.fill();
  ctx.strokeStyle = '#d7ccc8'; ctx.lineWidth = 1.5;
  ctx.beginPath(); ctx.moveTo(-R * 0.25, R * 1.05); ctx.lineTo(R * 0.25, R * 1.05); ctx.stroke();
  ctx.fillStyle = '#795548'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R * 0.62, R, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#f5efe4'; // pecho barrado
  ctx.beginPath(); ctx.ellipse(0, R * 0.3, R * 0.36, R * 0.5, 0, 0, 7); ctx.fill();
  ctx.strokeStyle = '#a1887f'; ctx.lineWidth = 1;
  for (let i = 0; i < 3; i++) {
    ctx.beginPath(); ctx.moveTo(-R * 0.25, R * (0.15 + i * 0.2)); ctx.lineTo(R * 0.25, R * (0.15 + i * 0.2)); ctx.stroke();
  }
  ctx.fillStyle = '#795548'; // cabeza
  ctx.beginPath(); ctx.arc(0, -R * 0.85, R * 0.5, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#fff'; // cejas fieras
  ctx.beginPath(); ctx.ellipse(-R * 0.2, -R * 0.95, R * 0.2, R * 0.12, -0.3, 0, 7); ctx.ellipse(R * 0.2, -R * 0.95, R * 0.2, R * 0.12, 0.3, 0, 7); ctx.fill();
  paintEye(-R * 0.18, -R * 0.85, R * 0.14, '#3e2723');
  paintEye(R * 0.18, -R * 0.85, R * 0.14, '#3e2723');
  ctx.fillStyle = '#ffb300'; // pico ganchudo
  ctx.beginPath(); ctx.moveTo(-R * 0.16, -R * 1.15); ctx.lineTo(R * 0.16, -R * 1.15); ctx.lineTo(0, -R * 0.85); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#5d4037';
  ctx.beginPath(); ctx.arc(0, -R * 0.92, R * 0.05, 0, 7); ctx.fill();
}

function paintZorro(R, t) {
  const wig = Math.sin(t * 4) * R * 0.15;
  ctx.fillStyle = '#3e2723'; // calcetines
  ctx.beginPath(); ctx.ellipse(-R * 0.35, R * 0.8, R * 0.22, R * 0.16, 0, 0, 7); ctx.ellipse(R * 0.4, R * 0.8, R * 0.22, R * 0.16, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#bf360c'; // cola cepillo
  ctx.beginPath(); ctx.ellipse(-R * 1.45, R * 0.45 + wig, R * 0.55, R * 0.42, 0.5, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#fff'; // punta blanca
  ctx.beginPath(); ctx.arc(-R * 1.85, R * 0.7 + wig, R * 0.24, 0, 7); ctx.fill();
  ctx.fillStyle = '#e86a33'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R * 1.05, R * 0.85, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#fff3e0'; // pecho
  ctx.beginPath(); ctx.ellipse(R * 0.35, R * 0.35, R * 0.48, R * 0.38, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#e86a33'; // orejas
  for (const ex of [-R * 0.3, R * 0.35]) {
    ctx.beginPath(); ctx.moveTo(ex - R * 0.22, -R * 0.6); ctx.lineTo(ex, -R * 1.25); ctx.lineTo(ex + R * 0.22, -R * 0.6); ctx.closePath(); ctx.fill();
    rim(); ctx.stroke();
  }
  ctx.fillStyle = '#3e2723'; // reverso oscuro de orejas
  ctx.beginPath();
  ctx.moveTo(-R * 0.38, -R * 0.75); ctx.lineTo(-R * 0.3, -R * 1.15); ctx.lineTo(-R * 0.2, -R * 0.75); ctx.closePath();
  ctx.moveTo(R * 0.27, -R * 0.75); ctx.lineTo(R * 0.35, -R * 1.15); ctx.lineTo(R * 0.45, -R * 0.75); ctx.closePath();
  ctx.fill();
  ctx.fillStyle = '#f7c9a8'; // hocico fino
  ctx.beginPath(); ctx.moveTo(R * 0.45, -R * 0.3); ctx.lineTo(R * 1.55, 0); ctx.lineTo(R * 0.45, R * 0.3); ctx.closePath(); ctx.fill();
  ctx.fillStyle = '#212121'; // trufa
  ctx.beginPath(); ctx.arc(R * 1.5, 0, R * 0.14, 0, 7); ctx.fill();
  paintEye(R * 0.35, -R * 0.3, R * 0.22, '#4e2600');
}

function paintLobo(R, t) {
  const wig = Math.sin(t * 4) * R * 0.12;
  ctx.fillStyle = '#455a64'; // cola poblada
  ctx.beginPath(); ctx.ellipse(-R * 1.45, R * 0.4 + wig, R * 0.5, R * 0.32, 0.3, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#37474f'; // punta de la cola
  ctx.beginPath(); ctx.arc(-R * 1.8, R * 0.5 + wig, R * 0.2, 0, 7); ctx.fill();
  ctx.fillStyle = '#37474f'; // patas
  ctx.beginPath(); ctx.ellipse(-R * 0.4, R * 0.85, R * 0.24, R * 0.16, 0, 0, 7); ctx.ellipse(R * 0.45, R * 0.85, R * 0.24, R * 0.16, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#7e939e'; // cuerpo
  ctx.beginPath(); ctx.ellipse(0, 0, R * 1.15, R * 0.95, 0, 0, 7); ctx.fill();
  rim(); ctx.stroke();
  ctx.fillStyle = '#546e7a'; // silla + crines
  ctx.beginPath(); ctx.ellipse(-R * 0.15, -R * 0.35, R * 0.7, R * 0.42, 0, 0, 7); ctx.fill();
  ctx.beginPath();
  ctx.moveTo(-R * 0.7, -R * 0.6); ctx.lineTo(-R * 0.5, -R * 0.95); ctx.lineTo(-R * 0.3, -R * 0.62); ctx.closePath();
  ctx.moveTo(-R * 0.1, -R * 0.68); ctx.lineTo(R * 0.1, -R * 1.0); ctx.lineTo(R * 0.3, -R * 0.66); ctx.closePath();
  ctx.fill();
  ctx.fillStyle = '#eceff1'; // pecho y hocico
  ctx.beginPath(); ctx.ellipse(R * 0.4, R * 0.35, R * 0.5, R * 0.4, 0, 0, 7); ctx.fill();
  ctx.beginPath(); ctx.ellipse(R * 0.8, R * 0.05, R * 0.42, R * 0.3, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#7e939e'; // orejas erguidas
  for (const ex of [-R * 0.35, R * 0.3]) {
    ctx.beginPath(); ctx.moveTo(ex - R * 0.2, -R * 0.65); ctx.lineTo(ex, -R * 1.3); ctx.lineTo(ex + R * 0.2, -R * 0.65); ctx.closePath(); ctx.fill();
    rim(); ctx.stroke();
  }
  ctx.fillStyle = '#37474f'; // interior
  ctx.beginPath();
  ctx.moveTo(-R * 0.42, -R * 0.78); ctx.lineTo(-R * 0.35, -R * 1.15); ctx.lineTo(-R * 0.26, -R * 0.78); ctx.closePath();
  ctx.moveTo(R * 0.23, -R * 0.78); ctx.lineTo(R * 0.3, -R * 1.15); ctx.lineTo(R * 0.39, -R * 0.78); ctx.closePath();
  ctx.fill();
  ctx.fillStyle = '#212121'; // nariz + boca
  ctx.beginPath(); ctx.arc(R * 1.15, R * 0.02, R * 0.15, 0, 7); ctx.fill();
  ctx.strokeStyle = '#37474f'; ctx.lineWidth = 1.2;
  ctx.beginPath(); ctx.moveTo(R * 1.15, R * 0.15); ctx.lineTo(R * 0.8, R * 0.3); ctx.stroke();
  paintEye(R * 0.35, -R * 0.32, R * 0.22, '#c77800');
}

// Glifo por comida: silueta propia + emoji + etiqueta con existencias
function drawPatch(p) {
  ctx.save();
  ctx.translate(p.x, p.y);
  const dead = !p.alive || p.amount <= 0;
  ctx.fillStyle = 'rgba(0,0,0,.28)';
  ctx.beginPath(); ctx.ellipse(0, 5, 16, 5, 0, 0, 7); ctx.fill();
  if (dead) {
    ctx.strokeStyle = '#616161'; ctx.lineWidth = 2.5;
    ctx.beginPath(); ctx.moveTo(-8, -8); ctx.lineTo(8, 8); ctx.moveTo(8, -8); ctx.lineTo(-8, 8); ctx.stroke();
    drawTag('pelada', 0, 16);
    ctx.restore(); return;
  }
  const revealed = mimicsVisible(), toxR = toxicsVisible();
  const marked = (p.kind === 'berries' && p.mimic && !p.mimicEaten && revealed.includes(p)) ||
    (p.kind === 'mushrooms' && p.toxicLeft > 0 && toxR.includes(p));
  if (marked) {
    ctx.strokeStyle = '#ff5252'; ctx.lineWidth = 2.5; ctx.setLineDash([5, 3]);
    ctx.beginPath(); ctx.arc(0, -6, 19, 0, 7); ctx.stroke();
    ctx.setLineDash([]);
    drawEmoji('☠️', 16, -20, 14);
  }
  if (p.kind === 'berries') paintBerries(p);
  else if (p.kind === 'apples') paintApples(p);
  else if (p.kind === 'carrots') paintCarrots(p);
  else if (p.kind === 'mushrooms') paintMushrooms(p);
  else if (p.kind === 'nuts') paintNuts(p);
  else if (p.kind === 'leaves') paintLeaves(p);
  drawEmoji(foodIcon(p.kind), 0, -8, 17);
  drawTag(FOOD_LABEL[p.kind] + ' ×' + p.amount, 0, 16);
  ctx.restore();
}

function paintBerries(p) {
  ctx.fillStyle = '#1b5e20';
  ctx.beginPath(); ctx.ellipse(0, 0, 15, 10, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#2e7d32';
  ctx.beginPath(); ctx.ellipse(0, -3, 12, 6, 0, 0, 7); ctx.fill();
  for (let i = 0; i < Math.min(p.amount, 3); i++) {
    const poison = p.mimic && !p.mimicEaten && i === 0;
    ctx.fillStyle = poison ? '#33691e' : '#e53935';
    ctx.beginPath(); ctx.arc(-8 + i * 8, -2, 4.5, 0, 7); ctx.fill();
    ctx.fillStyle = 'rgba(255,255,255,.7)';
    ctx.beginPath(); ctx.arc(-9 + i * 8, -3, 1.4, 0, 7); ctx.fill();
  }
}

function paintApples(p) {
  ctx.fillStyle = '#4e342e';
  ctx.fillRect(-2.5, -6, 5, 12);
  ctx.fillStyle = '#2e7d32';
  ctx.beginPath(); ctx.arc(-7, -14, 9, 0, 7); ctx.arc(7, -14, 9, 0, 7); ctx.arc(0, -18, 10, 0, 7); ctx.fill();
  ctx.fillStyle = '#1b5e20';
  ctx.beginPath(); ctx.arc(-4, -16, 3, 0, 7); ctx.arc(5, -13, 3, 0, 7); ctx.fill();
  for (let i = 0; i < Math.min(p.amount, 2); i++) {
    ctx.fillStyle = '#e53935';
    ctx.beginPath(); ctx.arc(i ? 7 : -7, -8, 5, 0, 7); ctx.fill();
    ctx.fillStyle = '#fff';
    ctx.beginPath(); ctx.arc((i ? 7 : -7) - 1.5, -9.5, 1.4, 0, 7); ctx.fill();
  }
}

function paintCarrots(p) {
  ctx.fillStyle = '#4e342e';
  ctx.beginPath(); ctx.ellipse(0, 3, 15, 5, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#3e2723';
  ctx.beginPath(); ctx.arc(-6, 3, 1.5, 0, 7); ctx.arc(3, 4, 1.5, 0, 7); ctx.arc(9, 2, 1.2, 0, 7); ctx.fill();
  for (let i = 0; i < Math.min(p.amount, 3); i++) {
    const cx = -9 + i * 9;
    ctx.strokeStyle = '#2e7d32'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(cx, -8); ctx.quadraticCurveTo(cx - 2, -13, cx + 1, -15); ctx.stroke();
    ctx.fillStyle = '#fb8c00';
    ctx.beginPath(); ctx.moveTo(cx - 3, 2); ctx.lineTo(cx, -8); ctx.lineTo(cx + 3, 2); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = '#e65100'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(cx - 1.5, -2); ctx.lineTo(cx + 1.5, -2); ctx.stroke();
  }
}

function paintMushrooms(p) {
  ctx.strokeStyle = '#33691e'; ctx.lineWidth = 2;
  for (let b = -1; b <= 1; b++) {
    ctx.beginPath(); ctx.moveTo(b * 8, 5); ctx.lineTo(b * 8 + 2, -2); ctx.stroke();
  }
  const n = Math.min(p.amount + (p.toxicLeft || 0), 3);
  for (let i = 0; i < n; i++) {
    const tox = p.toxicLeft > 0 && i === 0;
    const mx = -9 + i * 9;
    ctx.fillStyle = '#efebe9';
    ctx.fillRect(mx - 1.5, -6, 3, 6);
    ctx.fillStyle = tox ? '#4a148c' : '#d32f2f';
    ctx.beginPath(); ctx.ellipse(mx, -7, 6.5, 4.5, 0, 0, 7); ctx.fill();
    if (!tox) {
      ctx.fillStyle = '#fff';
      ctx.beginPath(); ctx.arc(mx - 2, -8, 1.3, 0, 7); ctx.arc(mx + 2, -6.5, 1.1, 0, 7); ctx.fill();
    } else {
      ctx.fillStyle = '#fff';
      ctx.font = '7px serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('☠', mx, -7);
    }
  }
}

function paintNuts(p) {
  ctx.fillStyle = '#5d4037';
  ctx.beginPath(); ctx.ellipse(0, -6, 5.5, 12, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#3e2723';
  ctx.fillRect(-1, -8, 2, 10);
  ctx.fillStyle = '#1b5e20';
  ctx.beginPath(); ctx.arc(0, -18, 9, 0, 7); ctx.fill();
  ctx.fillStyle = '#2e7d32';
  ctx.beginPath(); ctx.arc(-4, -19, 4, 0, 7); ctx.fill();
  for (let i = 0; i < Math.min(p.amount, 3); i++) {
    ctx.fillStyle = '#8d6e63';
    ctx.beginPath(); ctx.ellipse(-7 + i * 7, 3, 4, 3.2, 0.4, 0, 7); ctx.fill();
    ctx.fillStyle = '#4e342e';
    ctx.beginPath(); ctx.ellipse(-7 + i * 7, 1, 2.2, 1.4, 0.4, 0, 7); ctx.fill();
  }
}

function paintLeaves(p) {
  ctx.fillStyle = '#1b5e20';
  ctx.beginPath(); ctx.ellipse(0, 1, 13, 6, 0, 0, 7); ctx.fill();
  for (let i = 0; i < Math.min(p.amount, 3); i++) {
    ctx.save(); ctx.translate(-8 + i * 8, 0); ctx.rotate(-0.5 + i * 0.5);
    ctx.fillStyle = '#43a047';
    ctx.beginPath(); ctx.ellipse(0, -6, 4, 8, 0, 0, 7); ctx.fill();
    ctx.strokeStyle = '#1b5e20'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(0, 1); ctx.lineTo(0, -12); ctx.stroke();
    ctx.restore();
  }
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
  for (const i of state.insects) {
    ctx.save(); ctx.translate(i.x, i.y);
    ctx.fillStyle = 'rgba(0,0,0,.25)';
    ctx.beginPath(); ctx.ellipse(0, 2, 5, 2, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#212121';
    ctx.beginPath(); ctx.ellipse(-3, 0, 2.4, 1.8, 0, 0, 7); ctx.ellipse(0, 0, 2, 1.6, 0, 0, 7); ctx.ellipse(3, 0, 1.8, 1.6, 0, 0, 7); ctx.fill();
    ctx.strokeStyle = '#212121'; ctx.lineWidth = 1;
    for (let l = -1; l <= 1; l++) {
      ctx.beginPath(); ctx.moveTo(-1 + l, 0); ctx.lineTo(-3 + l * 2, -3 + Math.sin(t * 10 + i.x) ); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-1 + l, 0); ctx.lineTo(-3 + l * 2, 3 - Math.sin(t * 10 + i.x)); ctx.stroke();
    }
    ctx.restore();
  }
  if (state.insects.length) drawEmoji(foodIcon('insects'), state.insects[0].x, state.insects[0].y - 10, 12);
  for (const i of state.insects) drawTag(FOOD_LABEL.insects, i.x, i.y + 10);
}

function carrionLook(stage) {
  if (stage === 'fresh') return { meat: '#b03939', bone: '#efebe9', label: 'carroña fresca' };
  if (stage === 'stale') return { meat: '#795548', bone: '#d7ccc8', label: 'carroña pasada' };
  return { meat: '#33691e', bone: '#9e9e9e', label: '¡podrida: -25!' };
}

function drawCarrionPile(tracked, t) {
  for (const c of state.carrions) {
    const st = carrionStage(c);
    const look = carrionLook(st);
    ctx.save(); ctx.translate(c.x, c.y);
    ctx.fillStyle = 'rgba(0,0,0,.3)';
    ctx.beginPath(); ctx.ellipse(0, 4, 12, 4, 0, 0, 7); ctx.fill();
    ctx.fillStyle = look.meat; // costillar
    ctx.beginPath(); ctx.ellipse(0, 0, 9, 7, 0.3, 0, 7); ctx.fill();
    ctx.strokeStyle = look.bone; ctx.lineWidth = 2.5;
    for (let r = -1; r <= 1; r++) {
      ctx.beginPath(); ctx.moveTo(-5, r * 3.5); ctx.quadraticCurveTo(0, r * 3.5 - 2, 5, r * 3.5); ctx.stroke();
    }
    ctx.strokeStyle = look.bone; ctx.lineWidth = 3; // hueso fuera
    ctx.beginPath(); ctx.moveTo(6, 5); ctx.lineTo(12, 9); ctx.stroke();
    ctx.fillStyle = look.bone;
    ctx.beginPath(); ctx.arc(13, 10, 2.2, 0, 7); ctx.arc(15, 8, 2.2, 0, 7); ctx.fill();
    if (st === 'rotten') {
      ctx.fillStyle = '#9e9e9e'; // moscas
      ctx.beginPath();
      ctx.arc(8 + Math.sin(t * 9) * 2, -8, 1.8, 0, 7); ctx.arc(-7 + Math.cos(t * 8) * 2, 6, 1.8, 0, 7);
      ctx.fill();
      ctx.strokeStyle = '#33691e'; ctx.lineWidth = 1.5; // tufo
      ctx.beginPath(); ctx.moveTo(-4, -8); ctx.quadraticCurveTo(-6, -13, -3, -16); ctx.stroke();
    }
    if (tracked === c || state.revealT > 0) {
      ctx.strokeStyle = '#ffeb3b'; ctx.lineWidth = 2.5;
      ctx.beginPath(); ctx.arc(0, 0, 14, 0, 7); ctx.stroke();
    }
    ctx.restore();
    drawEmoji(foodIcon('carrion'), c.x, c.y - 4, 15);
    drawTag(look.label, c.x, c.y + 16);
  }
}

function drawRefugeField() {
  for (const r of state.refuges) {
    ctx.save(); ctx.translate(r.x, r.y);
    ctx.fillStyle = 'rgba(0,0,0,.28)';
    ctx.beginPath(); ctx.ellipse(0, 8, 20, 6, 0, 0, 7); ctx.fill();
    if (r.type === 'old-oak') paintOldOak(r);
    else if (r.type === 'hollow-tree') paintHollowTree();
    else if (r.type === 'thorn-bush') paintThornBush();
    else paintBurrow(r);
    ctx.restore();
    drawEmoji(refugeIcon(r.type), r.x, r.y - 22, 15);
    drawTag(REFUGE_LABEL[r.type] || r.type, r.x, r.y + 20);
  }
}

function paintOldOak(r) {
  ctx.fillStyle = '#3e2723';
  ctx.beginPath(); ctx.arc(0, 0, 13, 0, 7); ctx.fill();
  ctx.fillStyle = '#5d4037';
  ctx.beginPath(); ctx.arc(-3, -3, 6, 0, 7); ctx.fill();
  ctx.fillStyle = '#1b5e20';
  ctx.beginPath(); ctx.arc(0, -14, 30, 0, 7); ctx.fill();
  ctx.fillStyle = '#2e7d32';
  ctx.beginPath(); ctx.arc(-10, -20, 15, 0, 7); ctx.arc(10, -18, 13, 0, 7); ctx.fill();
  ctx.fillStyle = '#14161a';
  ctx.beginPath(); ctx.arc(0, 0, 10, 0, 7); ctx.fill();
}

function paintHollowTree() {
  ctx.fillStyle = '#5d4037';
  ctx.beginPath(); ctx.ellipse(0, 0, 16, 21, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#4e342e';
  ctx.beginPath(); ctx.ellipse(-4, -4, 5, 12, 0.2, 0, 7); ctx.fill();
  ctx.fillStyle = '#14161a';
  ctx.beginPath(); ctx.ellipse(4, -4, 5.5, 7.5, 0.3, 0, 7); ctx.fill();
  ctx.fillStyle = '#8d6e63';
  ctx.beginPath(); ctx.ellipse(4, -4, 7.5, 9.5, 0.3, 0, 7); ctx.stroke();
}

function paintThornBush() {
  ctx.fillStyle = '#1b5e20';
  for (let s = 0; s < 7; s++) {
    const a = s * 6.283 / 7;
    ctx.beginPath(); ctx.arc(Math.cos(a) * 9, Math.sin(a) * 8, 6.5, 0, 7); ctx.fill();
  }
  ctx.fillStyle = '#33691e';
  ctx.beginPath(); ctx.arc(0, 0, 8, 0, 7); ctx.fill();
  ctx.strokeStyle = '#ffeb3b'; ctx.lineWidth = 1.8;
  for (let s = 0; s < 9; s++) {
    const a = s * 6.283 / 9 + 0.3;
    ctx.beginPath(); ctx.moveTo(Math.cos(a) * 6, Math.sin(a) * 6);
    ctx.lineTo(Math.cos(a) * 15, Math.sin(a) * 14); ctx.stroke();
  }
}

function paintBurrow(r) {
  ctx.fillStyle = r.type === 'burrow-S' ? '#8d6e63' : '#6d4c41';
  ctx.beginPath(); ctx.ellipse(0, 4, 17, 10, 0, 0, 7); ctx.fill();
  ctx.fillStyle = r.type === 'burrow-S' ? '#6d4c41' : '#4e342e';
  ctx.beginPath(); ctx.ellipse(0, 1, 17, 6, 0, 0, 7); ctx.fill();
  ctx.fillStyle = '#14161a';
  ctx.beginPath(); ctx.ellipse(0, 0, r.maxSize === 1 ? 5.5 : 8.5, r.maxSize === 1 ? 4 : 6, 0, 0, 7); ctx.fill();
}

function drawRockField() {
  for (const k of state.rocks || []) {
    ctx.save(); ctx.translate(k.x, k.y);
    ctx.fillStyle = 'rgba(0,0,0,.3)';
    ctx.beginPath(); ctx.ellipse(0, 5, 14, 4, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#546e7a';
    ctx.beginPath(); ctx.moveTo(-12, 4); ctx.lineTo(-6, -10); ctx.lineTo(4, -12); ctx.lineTo(12, 0); ctx.lineTo(6, 6); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#90a4ae';
    ctx.beginPath(); ctx.moveTo(-6, -10); ctx.lineTo(4, -12); ctx.lineTo(0, -2); ctx.lineTo(-8, -1); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = '#37474f'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(-2, -8); ctx.lineTo(2, 2); ctx.stroke();
    ctx.restore();
    drawTag('roca', k.x, k.y + 16);
  }
}

function drawSeedlingField() {
  for (const s of state.seedlings || []) {
    const oak = s.kind === 'oak-tree';
    ctx.save(); ctx.translate(s.x, s.y);
    ctx.strokeStyle = oak ? '#6d4c41' : '#7cb342';
    ctx.lineWidth = oak ? 3 : 2;
    const h = oak ? 15 : 9;
    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, -h); ctx.stroke();
    ctx.fillStyle = '#33691e';
    ctx.beginPath(); ctx.ellipse(-4, -h, 3.5, 2.2, -0.5, 0, 7); ctx.ellipse(4, -h, 3.5, 2.2, 0.5, 0, 7); ctx.fill();
    ctx.restore();
    drawEmoji('🌱', s.x, s.y - (oak ? 20 : 14), 12);
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

function drawLegend() {
  const lines = ['🐛oruga 🐸sapo 🐭ratón 🐿️ardilla', '🦔topo 🦅halcón 🦊zorro 🐺lobo', '🍒bayas 🍎manzana 🥕zanahoria', '🍄setas 🌰nuez 🍃hojas 🦗bicho', '🍖carroña 🕳️madriguera 🪵tronco', '🌵zarza 🌳roble 🪨roca 🌱brote'];
  ctx.save();
  ctx.globalAlpha = 0.9;
  ctx.fillStyle = 'rgba(12,14,17,.85)';
  ctx.fillRect(canvas.width - 208, 8, 200, lines.length * 14 + 22);
  ctx.globalAlpha = 1;
  ctx.fillStyle = '#fff';
  ctx.font = '11px system-ui,sans-serif';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  ctx.fillText('LEYENDA', canvas.width - 200, 12);
  lines.forEach((ln, i) => ctx.fillText(ln, canvas.width - 200, 28 + i * 14));
  ctx.restore();
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
  drawLegend();
  let y = 18;
  if (state.lureTimer > 0) { ctx.fillStyle = '#ff5252'; ctx.fillText('¡Te expusiste! Depredadores hacia ti ' + Math.ceil(state.lureTimer) + 's', 12, y); y += 16; }
  if (state.hidden) { ctx.fillStyle = '#9ccc65'; ctx.fillText('OCULTO (H para salir, el hambre sigue)', 12, y); y += 16; }
  if (state.grounded) { ctx.fillStyle = '#ffcc80'; ctx.fillText('EN TIERRA (muévete para despegar)', 12, y); y += 16; }
  if (camouflaged()) { ctx.fillStyle = '#4db6ac'; ctx.fillText('MIMETIZADO (inmóvil)', 12, y); y += 16; }
  if (curled()) { ctx.fillStyle = '#9ccc65'; ctx.fillText('ENROSCADO (mitad de daño)', 12, y); }
}
