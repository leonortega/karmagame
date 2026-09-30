// test/loco.test.js - marchas por especie: sapo salta, oruga undula, topo tunela (species-locomotion-verbs)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, key, keyUp } = require('./harness');

function clearWorld(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
  s.refuges = []; s.rocks = []; s.waters = []; // sin orillas: la marcha se mide en abierto
  s.agents = s.agents.filter(a => a.role !== 'hunter' && a.role !== 'company');
}

describe('marcha continua (control del cambio)', () => {
  it('el ratón avanza en cada tick mientras la tecla se mantiene', () => {
    const s = reset('raton');
    clearWorld(s);
    key('d');
    const d0 = s.px;
    update(0.1);
    const d1 = s.px;
    update(0.1);
    keyUp('d');
    assert.ok(d1 > d0 && s.px > d1, 'avanza en ambos ticks');
  });
});

describe('sapo: salto (1.1)', () => {
  it('avanza a impulsos con pausas forzadas, sin deslizar siempre', () => {
    const s = reset('sapo');
    clearWorld(s);
    key('d');
    let moved = 0, still = 0;
    for (let i = 0; i < 40; i++) {
      const x0 = s.px;
      update(0.1);
      if (s.px - x0 > 0.5) moved++; else still++;
    }
    keyUp('d');
    assert.ok(moved >= 3 && still >= 2, `saltos=${moved} pausas=${still}`);
    assert.ok(moved < 38, `no desliza siempre: ${moved}/40`);
  });
  it('en 4s cubre claramente menos que su velocidad máxima', () => {
    const s = reset('sapo');
    clearWorld(s);
    const x0 = s.px;
    key('d');
    for (let i = 0; i < 40; i++) update(0.1);
    keyUp('d');
    const dist = s.px - x0, max = SPECIES.sapo.speed * 4;
    assert.ok(dist <= max * 0.9, `con pausas: ${dist.toFixed(0)} < ${max * 0.9}`);
  });
});

describe('oruga: undulación (1.2)', () => {
  it('se congela dentro de cada ciclo y es lenta de media', () => {
    const s = reset('oruga');
    clearWorld(s);
    const x0 = s.px;
    key('d');
    let still = 0;
    for (let i = 0; i < 60; i++) {
      const p = s.px;
      update(0.1);
      if (s.px - p < 0.5) still++;
    }
    keyUp('d');
    assert.ok(still >= 8, `ciclos con congelación: ${still}/60`);
    const dist = s.px - x0;
    assert.ok(dist < SPECIES.raton.speed * 6 * 0.6, `lenta: ${dist.toFixed(0)} en 6s`);
  });
});

describe('continuas no se rompen (1.3, 1.4)', () => {
  it('ardilla (bound) y zorro (trote) avanzan en todos los ticks', () => {
    for (const sp of ['ardilla', 'zorro']) {
      const s = reset(sp);
      clearWorld(s);
      key('d');
      let stalls = 0;
      for (let i = 0; i < 20; i++) { const x0 = s.px; update(0.1); if (s.px - x0 < 1) stalls++; }
      keyUp('d');
      assert.ok(stalls === 0, `${sp} sin parones: ${stalls}`);
    }
  });
  it('halcón en tierra chapotea continuo a media velocidad', () => {
    const s = reset('halcon');
    s.grounded = true;
    clearWorld(s);
    key('d');
    let stalls = 0;
    for (let i = 0; i < 20; i++) { const x0 = s.px; update(0.1); if (s.px - x0 < 1) stalls++; }
    keyUp('d');
    assert.ok(stalls === 0, `continuo en tierra: ${stalls}`);
  });
});

describe('paridad IA en el mundo (1.5, 1.10)', () => {
  it('el desplazamiento IA pasa por la marcha: aiForage avanza el reloj de fase del agente', () => {
    const s = reset('raton');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'oruga', x: 0, y: 0, hp: 60, face: { x: 1, y: 0 }, kind: 'grazer' });
    s.agents = [a];
    s.clumps = [mkPatch('leaves', 60, 0, 3, { regrowT: 0 })]; // 60px: fuera de boca (46), dentro de forrajeo (65)
    assert.equal(a.locoT, undefined, 'antes de moverse no hay reloj');
    aiOruga(a, 0.1);
    assert.ok(a.locoT > 0, 'forageó a través de moveToward (marcha compartida)');
  });
});

describe('paridad IA (1.5)', () => {
  it('moveToward da al sapo IA la misma cadencia de salto que al jugador', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 80, face: { x: 1, y: 0 }, kind: 'grazer' });
    let moved = 0, still = 0;
    for (let i = 0; i < 40; i++) {
      const x0 = a.x;
      moveToward(a, 400, 0, 1, 0.1);
      if (a.x - x0 > 0.5) moved++; else still++;
    }
    assert.ok(moved >= 3 && still >= 2, `saltos=${moved} pausas=${still}`);
    assert.ok(moved < 38, `no desliza siempre: ${moved}/40`);
  });
  it('un ratón IA por moveToward avanza en todos los ticks', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 100, face: { x: 1, y: 0 }, kind: 'grazer' });
    let stalls = 0;
    for (let i = 0; i < 20; i++) { const x0 = a.x; moveToward(a, 400, 0, 1, 0.1); if (a.x - x0 < 1) stalls++; }
    assert.ok(stalls === 0, `continuo también en IA: ${stalls}`);
  });
});

describe('topo tunela bajo rocas (1.6)', () => {
  it('el topo cruza una roca que frena al ratón', () => {
    const s = reset('topo');
    clearWorld(s);
    const rx = s.px + 100;
    s.rocks = [{ x: rx, y: s.py }];
    key('d');
    for (let i = 0; i < 80; i++) update(0.1);
    keyUp('d');
    assert.ok(s.px > rx + 20, `el topo cruzó: px=${s.px.toFixed(0)} vs roca=${rx}`);
    const s2 = reset('raton');
    clearWorld(s2);
    const rx2 = s2.px + 100;
    s2.rocks = [{ x: rx2, y: s2.py }];
    key('d');
    for (let i = 0; i < 80; i++) update(0.1);
    keyUp('d');
    assert.ok(Math.abs(s2.px - rx2) >= 14 - 0.01, `el ratón queda fuera: |px-roca|=${Math.abs(s2.px - rx2).toFixed(1)}`);
  });
  it('los refugios siguen frenando al topo (solo ignora rocas)', () => {
    const s = reset('topo');
    clearWorld(s);
    const rx = s.px + 100;
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: rx, y: s.py }];
    key('d');
    for (let i = 0; i < 80; i++) update(0.1);
    keyUp('d');
    assert.ok(s.px < rx, `el refugio frena: px=${s.px.toFixed(0)} < ${rx}`);
  });
});

describe('oculto congelado (1.7)', () => {
  it('ninguna marcha mueve a un jugador oculto', () => {
    const s = reset('sapo');
    clearWorld(s);
    // px+30: dentro de hideRange (40) pero fuera del círculo sólido (16+radio 9) para no ser empujado
    s.refuges = [{ type: 'burrow-M', maxSize: 1, climbOnly: false, x: s.px + 30, y: s.py }];
    assert.ok(toggleHide());
    const x0 = s.px;
    key('d');
    for (let i = 0; i < 20; i++) update(0.1);
    keyUp('d');
    assert.equal(s.px, x0, 'congelado bajo tierra');
  });
});

describe('la caza no se rompe (1.8)', () => {
  it('un lobo al trote alcanza a un zorro que huye en marcha', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const prey = mkAgent({ role: 'fauna', speciesKey: 'zorro', x: 0, y: 0, hp: 120, face: { x: 1, y: 0 }, kind: 'hunter', type: 'zorro', speed: SPECIES.zorro.speed });
    const l = mkAgent({ role: 'fauna', speciesKey: 'lobo', x: 40, y: 0, hp: 160, face: { x: 1, y: 0 }, kind: 'hunter', type: 'lobo', speed: SPECIES.lobo.speed });
    s.agents = [prey, l];
    for (let i = 0; i < 20; i++) updateAgents(0.1);
    assert.ok(!s.agents.includes(prey), 'la persecución atrapó en marcha');
  });
});
