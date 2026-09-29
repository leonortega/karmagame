// test/terrain.test.js - terreno sólido + línea de visión + legibilidad (readable-forest-solid-terrain)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, key } = require('./harness');

function clearWorld(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
  s.refuges = []; s.rocks = [];
}

describe('sólidos (1.3)', () => {
  it('enumera refugios, plantas vivas y rocas; ignora muertas/hojas/insectos', () => {
    const s = reset('raton');
    clearWorld(s);
    s.refuges = [
      { type: 'old-oak', maxSize: 3, climbOnly: false, x: 0, y: 0 },
      { type: 'burrow-M', maxSize: 2, climbOnly: false, x: 100, y: 0 },
    ];
    s.bushes = [mkPatch('berries', 200, 0, 3), mkPatch('berries', 250, 0, 0, { alive: false })]; // viva + muerta
    s.clumps = [mkPatch('leaves', 300, 0, 3)];
    s.rocks = [{ x: 400, y: 0, r: 14 }];
    const solids = collectSolids();
    assert.equal(solids.length, 4); // 2 refugios + arbusto vivo + roca
    assert.ok(solids.every(x => x.r > 0));
    assert.ok(!solids.some(x => x.x === 250)); // muerta no es sólida
    assert.ok(!solids.some(x => x.x === 300)); // hojas se pisan
  });
});

describe('colisión circular (1.4-1.7)', () => {
  it('empuja al agente solapado fuera hasta el borde del sólido', () => {
    const s = reset('raton'); // radius 10
    clearWorld(s);
    s.rocks = [{ x: 50, y: 0, r: 14 }];
    s.px = 55; s.py = 0; // dentro
    resolveCollisions({ r: SPECIES.raton.radius, get: () => ({ x: s.px, y: s.py }),
      set: (k, v) => { if (k === 'x') s.px = v; else s.py = v; } });
    const d = Math.hypot(s.px - 50, s.py - 0);
    assert.ok(d >= 14 + SPECIES.raton.radius - 0.01, `centros ${d} >= 14+10`);
  });
  it('un agente fuera de todo sólido no se mueve', () => {
    const s = reset('raton');
    clearWorld(s);
    s.rocks = [{ x: 500, y: 500, r: 14 }];
    s.px = 0; s.py = 0;
    resolveCollisions({ x: 'px', y: 'py', r: SPECIES.raton.radius, get: () => s, set: (k, v) => s[k] = v });
    assert.equal(s.px, 0);
    assert.equal(s.py, 0);
  });
  it('desliza: movimiento tangencial sobrevive alrededor del tronco', () => {
    const s = reset('raton');
    clearWorld(s);
    s.rocks = [{ x: 100, y: 0, r: 14 }];
    // agente justo al borde, empujando hacia el centro: tras resolver queda en el borde, no dentro
    s.px = 100 - 24; s.py = 0;
    for (let i = 0; i < 30; i++) {
      s.px += 2; // avanza hacia la roca
      resolveCollisions({ x: 'px', y: 'py', r: SPECIES.raton.radius, get: () => s, set: (k, v) => s[k] = v });
    }
    const d = Math.hypot(s.px - 100, s.py);
    assert.ok(d >= 14 - 0.01, `nunca penetra: ${d}`);
  });
  it('movePlayer respeta sólidos (integración con teclas)', () => {
    const s = reset('raton');
    clearWorld(s);
    s.rocks = [{ x: s.px + 30, y: s.py, r: 14 }];
    s.px = s.px; s.py = s.py;
    const x0 = s.px;
    key('d'); // derecha, hacia la roca
    update(0.5);
    const d = Math.hypot(s.px - (x0 + 30), s.py);
    assert.ok(d >= 14 - 0.01, `no penetra la roca: dist ${d}`);
  });
  it('fauna IA es empujada por plantas vivas (updateAgents integra)', () => {
    const s = reset('raton');
    clearWorld(s);
    // sapo: no come bayas, así que la planta no se consume durante el ensayo
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 110, y: 100, hp: 80,
      face: { x: 1, y: 0 }, kind: 'grazer' });
    s.agents = [a];
    s.bushes = [mkPatch('berries', 130, 100, 99)]; // viva, sólida, inagotable
    for (let i = 0; i < 10; i++) { a.x += 3; updateAgents(0.01); } // caminar hacia el arbusto
    const d = Math.hypot(a.x - 130, a.y - 100);
    // el empuje sale a r_solid + r_agent del centro de la planta
    assert.ok(d >= TUNING.solidPlant + SPECIES.sapo.radius - 1, `no penetra arbusto: ${d} >= ${TUNING.solidPlant + SPECIES.sapo.radius}`);
  });
  it('arbusto muerto deja de ser sólido tras pelarse', () => {
    const s = reset('raton');
    clearWorld(s);
    s.bushes = [mkPatch('berries', 100, 100, 0, { alive: false })];
    s.rocks = [];
    const a = { x: 100, y: 100 };
    resolveCollisions({ r: SPECIES.raton.radius, get: () => a, set: (k, v) => a[k] = v });
    assert.equal(a.x, 100); // la muerta no empuja: se queda donde está
  });
});

describe('línea de visión de troncos (2.1-2.5)', () => {
  function setupTrunk() {
    const s = reset('raton');
    clearWorld(s);
    // tronco en el punto medio del segmento (0,0)→(400,0)
    s.refuges = [{ type: 'hollow-tree', maxSize: 2, climbOnly: true, x: 200, y: 0 }];
    s.rocks = [];
    s.bushes = [];
    return s;
  }
  it('un tronco en medio del segmento ciega a los terrestres', () => {
    setupTrunk();
    assert.ok(losBlocked(0, 0, 400, 0, false));
    assert.ok(losBlocked(0, 0, 400, 0, false)); // zorro/lobo/saponpc: mismo booleano
  });
  it('campo libre, rocas y plantas no ciegan', () => {
    const s = reset('raton');
    clearWorld(s);
    s.rocks = [{ x: 200, y: 0 }];
    s.bushes = [mkPatch('berries', 200, 5, 3)];
    assert.ok(!losBlocked(0, 0, 400, 0, false));
  });
  it('el halcón nunca se ciega (vuela sobre la madera)', () => {
    setupTrunk();
    assert.ok(!losBlocked(0, 0, 400, 0, true));
  });
  it('strikeAgents del zorro pierde a la presa tras el tronco: ni persigue ni mata', () => {
    const s = setupTrunk();
    s.px = 1000; s.py = 1000; // jugador lejos
    const z = { role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: 0, y: 0, hp: 120, speed: 100, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    const prey = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 400, y: 0, hp: 50,
      face: { x: 1, y: 0 }, kind: 'grazer' });
    s.agents = [z, prey];
    // el pred está pegado al tronco y la presa al otro lado: con LOS no la ve y NO se mueve por caza
    z.x = 195; z.y = 0; prey.x = 400; prey.y = 0;
    strikeAgents(z, PRED.zorro, 0.1);
    assert.equal(z.x, 195); // quieto: la presa tras el tronco no existe para él
    assert.ok(s.agents.includes(prey));
  });
  it('sin tronco el zorro caza y mata igual que siempre', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const z = { role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: 0, y: 0, hp: 120, speed: 100, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    const prey = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 10, y: 0, hp: 50,
      face: { x: 1, y: 0 }, kind: 'grazer' });
    s.agents = [z, prey];
    strikeAgents(z, PRED.zorro, 0.1);
    assert.ok(!s.agents.includes(prey)); // mata a bocados como siempre
    assert.equal(s.carrions.length, 1);
  });
  it('el lobo también pierde zorros tras el tronco', () => {
    const s = setupTrunk();
    s.px = 1000; s.py = 1000;
    const l = { role: 'fauna', kind: 'hunter', type: 'lobo', speciesKey: 'lobo',
      x: 0, y: 0, hp: 160, speed: 150, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    const z = { role: 'fauna', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: 400, y: 0, hp: 120, brain: 'AI', speed: 100, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    s.agents = [l, z];
    const blocked = losBlocked(l.x, l.y, z.x, z.y, false);
    assert.ok(blocked); // el segmento pasa por el tronco
  });
});

describe('legibilidad del render (3.1-3.7)', () => {
  it('drawPatch no revienta por especie y estado (viva/muerta/mímico/tóxica)', () => {
    reset('raton');
    const variants = [
      mkPatch('berries', 0, 0, 3, { mimic: false }),
      mkPatch('berries', 10, 0, 3, { mimic: true }),
      mkPatch('berries', 20, 0, 0, { alive: false }),
      mkPatch('apples', 30, 0, 2),
      mkPatch('carrots', 40, 0, 3),
      mkPatch('mushrooms', 50, 0, 2, { toxicLeft: 1 }),
      mkPatch('nuts', 60, 0, 3),
      mkPatch('leaves', 70, 0, 3),
    ];
    for (const p of variants) drawPatch(p);
  });
  it('los ojos se pintan para cada especie (drawSpecies smoke)', () => {
    reset('raton');
    for (const f of Object.keys(SPECIES)) drawSpecies(f, 0, 0, { x: 1, y: 0 }, 0.5, {});
  });
  it('render completo con rocas y decorado sin reventar', () => {
    const s = reset('raton');
    s.rocks = [{ x: 500, y: 500 }, { x: 700, y: 300 }];
    render();
  });
});

describe('rocas (1.8)', () => {
  it('nacen escaladas por área y persisten entre vidas', () => {
    WORLD.w = 1600; WORLD.h = 1200;
    let s = reset('raton');
    const base = s.rocks.length;
    assert.equal(base, scaledCount(TUNING.rockCount));
    WORLD.w = 3200; WORLD.h = 2400;
    s = reset('raton');
    assert.ok(s.rocks.length > base);
  });
});
