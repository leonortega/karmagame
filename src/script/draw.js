// --- Arte lifelike por especie (silueta + facing + wiggle) ---
function drawSpecies(form, x, y, dir, t, opts={}) {
  const sp = SPECIES[form];
  const s = opts.scale || 1;
  const wig = Math.sin(t * (form==='oruga' ? 8 : 4));
  ctx.save();
  ctx.translate(x, y);
  if (opts.outline) { ctx.strokeStyle = opts.outline; ctx.lineWidth = 3; }
  const ang = Math.atan2(dir.y, dir.x);
  const R = sp.radius * s;
  ctx.rotate(form==='halcon' ? 0 : ang);
  ctx.fillStyle = sp.color;
  if (form === 'oruga') {
    for (let i=0;i<4;i++) {
      ctx.beginPath();
      ctx.arc(-i*R*0.9, Math.sin(t*8+i)*2, R*(1-i*0.15), 0, 7);
      ctx.fill(); if (opts.outline) ctx.stroke();
    }
  } else if (form === 'halcon') {
    const flap = Math.sin(t*6)*R*0.5;
    ctx.beginPath();
    ctx.moveTo(-R,0); ctx.lineTo(0,-R-flap); ctx.lineTo(R,0);
    ctx.lineTo(0,R*0.6); ctx.closePath();
    ctx.fill(); if (opts.outline) ctx.stroke();
    ctx.fillStyle = '#5e35b1';
    ctx.beginPath(); ctx.arc(R*0.4,0,R*0.3,0,7); ctx.fill();
  } else if (form === 'sapo') {
    ctx.beginPath(); ctx.ellipse(0,0,R*1.3,R*0.9,0,0,7); ctx.fill();
    if (opts.outline) ctx.stroke();
    ctx.fillStyle = 'rgba(255,255,255,.7)'; // garganta que pulsa
    ctx.beginPath(); ctx.arc(R*0.5,0,R*0.3+wig,0,7); ctx.fill();
  } else if (form === 'zorro') {
    ctx.beginPath(); ctx.arc(0,0,R,0,7); ctx.fill();
    if (opts.outline) ctx.stroke();
    ctx.beginPath(); // hocico
    ctx.moveTo(R*0.5,-R*0.4); ctx.lineTo(R*1.6,0); ctx.lineTo(R*0.5,R*0.4); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = sp.color; ctx.lineWidth = R*0.5; // cola cepillo
    ctx.beginPath(); ctx.moveTo(-R*0.8,0);
    ctx.quadraticCurveTo(-R*1.8, wig*3, -R*1.5, R*0.8); ctx.stroke();
  } else if (form === 'lobo') {
    ctx.beginPath(); ctx.arc(0,0,R,0,7); ctx.fill();
    if (opts.outline) ctx.stroke();
    ctx.beginPath(); ctx.arc(-R*0.5,-R*0.8,R*0.35,0,7); ctx.arc(R*0.5,-R*0.8,R*0.35,0,7); ctx.fill();
  } else {
    ctx.beginPath(); ctx.arc(0,0,R,0,7); ctx.fill();
    if (opts.outline) ctx.stroke();
    if (form === 'raton') { // orejas + cola
      ctx.beginPath(); ctx.arc(-R*0.3,-R*0.8,R*0.35,0,7); ctx.arc(R*0.3,-R*0.8,R*0.35,0,7); ctx.fill();
      ctx.strokeStyle = sp.color; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(-R,0); ctx.quadraticCurveTo(-R*2,wig*2,-R*2.4,R*0.5); ctx.stroke();
    }
    if (form === 'ardilla') { // gran cola
      ctx.strokeStyle = sp.color; ctx.lineWidth = R*0.7;
      ctx.beginPath(); ctx.moveTo(-R*0.6,0);
      ctx.quadraticCurveTo(-R*1.6,-R*1.4+wig, -R*1.2,-R*2); ctx.stroke();
    }
    if (form === 'topo') { // hocico rosado
      ctx.fillStyle = '#ef9a9a';
      ctx.beginPath(); ctx.arc(R*0.9,0,R*0.35,0,7); ctx.fill();
    }
  }
  ctx.restore();
}

function render() {
  ctx.clearRect(0,0,canvas.width,canvas.height);
  ctx.save(); ctx.translate(-state.cam.x, -state.cam.y);
  // fondo rejilla
  ctx.strokeStyle = '#2c333d'; ctx.lineWidth = 1;
  for (let x=0;x<WORLD.w;x+=80){ ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,WORLD.h);ctx.stroke(); }
  for (let y=0;y<WORLD.h;y+=80){ ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(WORLD.w,y);ctx.stroke(); }
  const t = state.time;
  // refugios
  for (const r of state.refuges) {
    ctx.fillStyle = r.type==='hollow-tree' ? '#5d4037' : r.type==='thorn-bush' ? '#33691e' : '#4e342e';
    ctx.beginPath(); ctx.arc(r.x,r.y, r.type==='hollow-tree'?20:14, 0, 7); ctx.fill();
    ctx.fillStyle = '#14161a';
    ctx.beginPath(); ctx.arc(r.x,r.y, r.maxSize===1?6:9, 0, 7); ctx.fill();
  }
  // comidas por tipo
  const revealed = mimicsVisible(), toxR = toxicsVisible();
  const patchDots = (list, color, r=6, dy=-26, step=12) => {
    for (const p of list) {
      if (!p.alive) { ctx.fillStyle = '#555'; ctx.beginPath(); ctx.arc(p.x,p.y,10,0,7); ctx.fill(); continue; }
      for (let i=0;i<p.amount;i++){
        let c = color;
        if (p.kind==='berries' && p.mimic && !p.mimicEaten && i===0) c = '#1b5e20';
        if (p.kind==='mushrooms' && p.toxicLeft>0 && i===0) c = '#4a148c';
        ctx.fillStyle = c;
        ctx.beginPath(); ctx.arc(p.x-12+i*step, p.y+dy, r, 0, 7); ctx.fill();
        const marked = (p.kind==='berries' && p.mimic && !p.mimicEaten && revealed.includes(p)) ||
                       (p.kind==='mushrooms' && p.toxicLeft>0 && toxR.includes(p));
        if (marked && i===0) {
          ctx.strokeStyle = '#ff5252'; ctx.lineWidth = 2;
          ctx.beginPath(); ctx.arc(p.x-12+i*step, p.y+dy, r+3, 0, 7); ctx.stroke();
        }
      }
    }
  };
  patchDots(state.bushes, '#e53935');                    // bayas rojas
  patchDots(state.shrubs, '#d81b60', 8);                 // manzanas grandes
  patchDots(state.patches, '#fb8c00', 6, 0);             // zanahorias a ras
  patchDots(state.clusters, '#f5f5f5', 5);               // setas claras
  patchDots(state.oaks, '#8d6e63', 6);                   // nueces marrones
  patchDots(state.clumps, '#66bb6a', 5);                 // hojas verdes
  // insectos: puntitos oscuros
  ctx.fillStyle = '#212121';
  for (const i of state.insects){ ctx.beginPath(); ctx.arc(i.x,i.y,3,0,7); ctx.fill(); }
  // carroña (enrojece y moscas al pudrirse) + rastro
  const tracked = trackedCarrion();
  for (const c of state.carrions) {
    const st = carrionStage(c);
    ctx.fillStyle = st==='fresh' ? '#8d3b3b' : st==='stale' ? '#6d4c41' : '#3e2723';
    ctx.beginPath(); ctx.arc(c.x,c.y,9,0,7); ctx.fill();
    if (tracked === c || (state.revealT>0)) {
      ctx.strokeStyle = '#ffeb3b'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(c.x,c.y,12,0,7); ctx.stroke();
    }
    if (st==='rotten') {
      ctx.fillStyle = '#9e9e9e';
      ctx.beginPath(); ctx.arc(c.x+8,c.y-8,2,0,7); ctx.arc(c.x-7,c.y+6,2,0,7); ctx.fill();
    }
  }
  // temblor: revela comida y peligro
  if (state.revealT > 0) {
    ctx.strokeStyle = '#ffee58'; ctx.lineWidth = 2;
    for (const p of hunterAgents()){ ctx.beginPath(); ctx.arc(p.x,p.y,20,0,7); ctx.stroke(); }
  }
  // congéneres: mini versión de la especie
  for (const m of companyAgents()){
    ctx.globalAlpha = .6;
    drawSpecies(m.speciesKey, m.x, m.y, {x:1,y:0}, t, { scale:.7 });
    ctx.globalAlpha = 1;
  }
  // fauna: resto de especies a tamaño real
  for (const m of faunaAgents()){
    drawSpecies(m.speciesKey, m.x, m.y, m.face || {x:1,y:0}, t, {});
  }
  // depredadores: reusan arte de especie con outline rojo
  for (const p of allHunters()){
    const form = p.type === 'saponpc' ? 'sapo' : (p.speciesKey || p.type);
    const lure = state.lureTimer>0 && p.mode!=='flee';
    drawSpecies(form, p.x, p.y, {x:1,y:0}, t, { scale:1, outline: lure ? '#ff5252' : '#7a1f1f' });
  }
  // jugador + visión (atenuado si oculto)
  ctx.strokeStyle = 'rgba(255,255,255,.15)';
  ctx.beginPath(); ctx.arc(state.px,state.py,effVision(),0,7); ctx.stroke();
  ctx.globalAlpha = state.hidden ? .35 : 1;
  drawSpecies(state.speciesKey, state.px, state.py, state.face, t, {});
  if (state.carriedNut) { // nuez en lomo
    ctx.fillStyle = '#8d6e63';
    ctx.beginPath(); ctx.arc(state.px, state.py-state.sp.radius-8, 5, 0, 7); ctx.fill();
  }
  ctx.globalAlpha = 1;
  ctx.restore();
  // viñetas
  let y = 18;
  if (state.lureTimer>0){ ctx.fillStyle='#ff5252'; ctx.fillText('¡Te expusiste! Depredadores hacia ti '+Math.ceil(state.lureTimer)+'s', 12, y); y+=16; }
  if (state.hidden){ ctx.fillStyle='#9ccc65'; ctx.fillText('OCULTO (H para salir, el hambre sigue)', 12, y); y+=16; }
  if (state.grounded){ ctx.fillStyle='#ffcc80'; ctx.fillText('EN TIERRA (muévete para despegar)', 12, y); y+=16; }
  if (camouflaged()){ ctx.fillStyle='#4db6ac'; ctx.fillText('MIMETIZADO (inmóvil)', 12, y); y+=16; }
  if (curled()){ ctx.fillStyle='#9ccc65'; ctx.fillText('ENROSCADO (mitad de daño)', 12, y); }
}

