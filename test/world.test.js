// test/world.test.js - nearest* (utils con estado) + invariantes de data.js
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

describe('nearest', () => {
  it('devuelve el mas cercano dentro del rango', () => {
    const s = reset();
    s.px = 0; s.py = 0;
    const list = [{ x: 100, y: 0 }, { x: 10, y: 0 }, { x: 500, y: 0 }];
    assert.equal(nearest(list, 200), list[1]);
  });
  it('nearestFrom mide desde un punto dado', () => {
    reset();
    const list = [{ x: 100, y: 0 }, { x: 10, y: 0 }];
    assert.equal(nearestFrom(0, 0, list, 200), list[1]);
    assert.equal(nearestFrom(100, 0, list, 200), list[0]);
    assert.equal(nearestFrom(0, 0, list, 5), null);
  });
  it('edibleFor equivale a playerEdibleFor para la especie poseída', () => {
    reset('oruga');
    assert.equal(edibleFor('zorro', 'oruga', 100), playerEdibleFor({ type: 'zorro' }, 100));
    assert.equal(edibleFor('zorro', 'oruga', TUNING.snapRange),
      playerEdibleFor({ type: 'zorro' }, TUNING.snapRange));
    reset('halcon');
    assert.equal(edibleFor('lobo', 'halcon', 10), playerEdibleFor({ type: 'lobo' }, 10));
  });
  it('devuelve null fuera de rango', () => {
    const s = reset();
    s.px = 0; s.py = 0;
    assert.equal(nearest([{ x: 500, y: 0 }], 50), null);
  });
});

describe('nearestPredOf', () => {
  it('filtra por tipo y distancia', () => {
    const s = reset();
    s.agents = [
      { role: 'hunter', type: 'zorro', x: 10, y: 0 },
      { role: 'hunter', type: 'lobo', x: 12, y: 0 },
    ];
    assert.equal(nearestPredOf(['lobo'], 100, { x: 0, y: 0 }).type, 'lobo');
    assert.equal(nearestPredOf(['zorro'], 5, { x: 0, y: 0 }), null);
  });
});

describe('data', () => {
  it('SPECIES cubre el pool T1 y los T2', () => {
    for (const k of [...T1POOL, 'halcon', 'zorro', 'oruga']) assert.ok(SPECIES[k], k);
    assert.ok(SPECIES.halcon.tier === 2 && SPECIES.zorro.tier === 2);
  });
  it('toda dieta referencia comidas con pago', () => {
    for (const foods of Object.values(DIET)) {
      for (const f of foods) {
        if (f === 'carrion' || f === 'mates') continue;
        assert.ok(FOODDEF[f], f);
      }
    }
  });
  it('lobo es especie T2 completa con dieta de carroña y presas', () => {
    assert.equal(SPECIES.lobo.tier, 2);
    assert.equal(SPECIES.lobo.size, 4);
    assert.ok(DIET.lobo.includes('carrion') && DIET.lobo.includes('mates'));
    assert.ok(DIET_HINT.lobo);
  });
  it('PRED caza por tabla y TIER_SPAWNS cubre tiers 0-2', () => {
    assert.ok(PRED.zorro.huntsTiers.includes(1));
    assert.ok(PRED.lobo.huntsTiers.includes(2));
    assert.deepEqual(Object.keys(TIER_SPAWNS).sort(), ['0', '1', '2']);
  });
  it('TUNING tiene las claves que usa el codigo', () => {
    for (const k of ['eatRange', 'tongueRange', 'mimicHp', 'carrionRottenHp', 'pounceRange', 'saplingCap']) {
      assert.ok(k in TUNING, k);
    }
    assert.equal(TUNING.eatRange, 46);
    assert.equal(TUNING.mimicHp, -20);
    assert.equal(TUNING.carrionRottenHp, -25);
  });
  it('SHOP tiene 4 items con tecla unica', () => {
    assert.equal(SHOP.length, 4);
    assert.equal(new Set(SHOP.map((s) => s.key)).size, 4);
  });
});
