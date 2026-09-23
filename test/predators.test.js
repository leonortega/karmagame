// test/predators.test.js - cadena trofica y fases del depredador
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

describe('mkPredator', () => {
  it('oruga sufre mas presion del zorro', () => {
    const a = mkPredator('zorro', 0, 0, 0);
    const b = mkPredator('zorro', 0, 0, 1);
    assert.ok(a.speed > b.speed);
    assert.equal(a.mode, 'wander');
  });
});

describe('playerEdibleFor', () => {
  it('zorro ignora talla +2 salvo contacto', () => {
    reset('oruga'); // size 1 vs zorro 3
    const z = { type: 'zorro' };
    assert.ok(!playerEdibleFor(z, 100));
    assert.ok(playerEdibleFor(z, TUNING.snapRange));
    reset('halcon'); // tier 2 no esta en huntsTiers del zorro
    assert.ok(!playerEdibleFor(z, 10));
  });
  it('lobo solo caza T2', () => {
    reset('raton');
    assert.ok(!playerEdibleFor({ type: 'lobo' }, 10));
    reset('halcon');
    assert.ok(playerEdibleFor({ type: 'lobo' }, 10));
  });
});

describe('camouflaged/curled', () => {
  it('sapo quieto 2s se mimetiza', () => {
    const s = reset('sapo');
    s.stillT = 2;
    assert.ok(camouflaged());
    s.stillT = 1;
    assert.ok(!camouflaged());
  });
  it('oruga quieta se enrosca salvo cooldown', () => {
    const s = reset('oruga');
    s.stillT = 1; s.moved = false; s.curlCd = 0;
    assert.ok(curled());
    s.curlCd = 5;
    assert.ok(!curled());
  });
});

describe('fleeCheck/campStep', () => {
  it('zorro huye del lobo cercano', () => {
    const s = reset('raton');
    s.agents = [
      { role: 'hunter', type: 'zorro', x: 0, y: 0, speed: 100, mode: 'wander', fleeLatch: false },
      { role: 'hunter', type: 'lobo', x: 10, y: 0, speed: 150, mode: 'wander', fleeLatch: false },
    ];
    const z = s.agents[0];
    assert.ok(fleeCheck(z, PRED.zorro, 0.1));
    assert.equal(z.mode, 'flee');
  });
  it('acampa el refugio si el jugador se esconde', () => {
    const s = reset('raton');
    s.hidden = true;
    s.hideRef = { x: 100, y: 100 };
    const p = { type: 'zorro', x: 0, y: 0, speed: 100, mode: 'wander', huntingPlayer: true };
    assert.ok(campStep(p, 0.1));
    assert.equal(p.mode, 'camp');
  });
});

describe('pickTarget/chase', () => {
  it('el señuelo atrae dentro del rango', () => {
    const s = reset('raton');
    s.px = 0; s.py = 0;
    s.lureTimer = 5;
    const p = { type: 'zorro', x: 100, y: 0, restT: 0, satedT: 1, huntingPlayer: false };
    const hit = pickTarget(p, PRED.zorro, 100, true, false);
    assert.equal(hit.hunting, 'player');
  });
  it('sin presa vaga al waypoint', () => {
    const s = reset('raton');
    s.hidden = true;
    s.agents = s.agents.filter((a) => a.role === 'hunter');
    const p = { type: 'zorro', x: 0, y: 0, wx: 50, wy: 50, restT: 0, satedT: 1, huntingPlayer: false };
    const hit = pickTarget(p, PRED.zorro, 10, false, false);
    assert.equal(hit.hunting, false);
  });
  it('perseguir demasiado termina en descanso', () => {
    const s = reset('raton');
    const p = { type: 'zorro', x: 0, y: 0, speed: 100, mode: 'hunt', huntT: TUNING.chaseMax + 1, restT: 0 };
    chase(p, PRED.zorro, { tx: 10, ty: 0 }, false, 0.1);
    assert.equal(p.mode, 'wander');
    assert.ok(p.restT > 0);
  });
});

describe('strikeContact/feast', () => {
  it('el contacto hiere con invencibilidad', () => {
    const s = reset('raton');
    s.px = 0; s.py = 0; s.hp = 100; s.invuln = 0;
    strikeContact({ type: 'zorro', x: 5, y: 0 }, PRED.zorro, 5);
    assert.ok(s.hp < 100 && s.invuln > 0);
  });
  it('enroscado parte el daño a la mitad', () => {
    const s = reset('oruga');
    s.px = 0; s.py = 0; s.hp = 60; s.invuln = 0;
    s.stillT = 1; s.moved = false; s.curlCd = 0;
    strikeContact({ type: 'saponpc', x: 5, y: 0 }, PRED.saponpc, 5);
    assert.equal(s.hp, 60 - Math.ceil(PRED.saponpc.damage / 2));
  });
  it('zorro saciado deja carroña; lobo mata zorros', () => {
    const s = reset('raton');
    s.agents = s.agents.filter((a) => a.role !== 'company');
    s.agents.push({ role: 'company', speciesKey: 'raton', x: s.px + 1, y: s.py, hp: 50, brain: 'AI', saved: false }); // feast mide desde el jugador
    feast({ type: 'zorro', x: s.px + 1, y: s.py, satedT: 0 }, []);
    assert.equal(s.carrions.length, 1);
    s.agents = [{ role: 'hunter', type: 'zorro', x: 2, y: 2 }];
    const dead = [];
    feast({ type: 'lobo', x: 2, y: 2 }, dead);
    assert.equal(dead.length, 1);
  });
});

describe('updatePredators', () => {
  it('zorro IA caza fauna cercana y deja carroña', () => {
    const s = reset('halcon'); // T2: el zorro ignora al jugador
    s.px = 1000; s.py = 1000; // lejos de la caza
    s.agents = [];
    const z = { role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: 0, y: 0, hp: 120, speed: 100, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    const r = { role: 'fauna', speciesKey: 'raton', x: 5, y: 0, hp: 50, brain: 'AI', kind: 'grazer' };
    s.agents.push(z, r);
    const n0 = s.carrions.length;
    stepPredator(z, 0.1, []);
    assert.equal(s.carrions.length, n0 + 1);
    assert.ok(!s.agents.includes(r));
  });
  it('carnívoro de fauna acecha víctima lejana aunque el jugador esté lejos', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    s.agents = [];
    const l = { role: 'fauna', kind: 'hunter', type: 'lobo', speciesKey: 'lobo',
      x: 0, y: 0, hp: 160, speed: 150, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    const h = { role: 'fauna', speciesKey: 'halcon', x: 100, y: 0, hp: 100, brain: 'AI', kind: 'hunter' };
    s.agents.push(l, h);
    stepPredator(l, 0.1, []);
    assert.ok(l.x > 0); // avanzó hacia la víctima
  });
  it('un cazador nunca se elige a sí mismo como víctima', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    s.agents = [];
    const l = { role: 'fauna', kind: 'hunter', type: 'lobo', speciesKey: 'lobo',
      x: 0, y: 0, hp: 160, brain: 'AI', speed: 150, mode: 'wander', wx: 0, wy: 0,
      huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false };
    s.agents.push(l); // solo él en el mapa: sin presas válidas
    stepPredator(l, 0.1, []);
    assert.ok(s.agents.includes(l)); // sigue vivo
    assert.equal(s.carrions.length, 0); // y no dejó carroña propia
  });
  it('integra un tick sin romper el mundo', () => {
    const s = reset('raton');
    s.px = 800; s.py = 600;
    const n0 = hunterAgents().length;
    updatePredators(0.05);
    assert.equal(hunterAgents().length, n0);
  });
});
