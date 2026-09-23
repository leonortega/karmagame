// test/utils.test.js - helpers puros de utils.js
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
require('./harness');

describe('clamp', () => {
  it('recorta al rango', () => {
    assert.equal(clamp(5, 0, 10), 5);
    assert.equal(clamp(-3, 0, 10), 0);
    assert.equal(clamp(99, 0, 10), 10);
  });
});

describe('fmtTime', () => {
  it('formatea m:ss', () => {
    assert.equal(fmtTime(0), '0:00');
    assert.equal(fmtTime(65), '1:05');
    assert.equal(fmtTime(600), '10:00');
  });
});

describe('mkPatch', () => {
  it('crea parche vivo con extras', () => {
    const p = mkPatch('berries', 10, 20, 3, { mimic: true });
    assert.deepEqual(p, { kind: 'berries', x: 10, y: 20, amount: 3, alive: true, mimic: true });
  });
});

describe('scatter/spawnPt', () => {
  it('scatter genera n puntos dentro del mundo', () => {
    const pts = scatter(5);
    assert.equal(pts.length, 5);
    for (const p of pts) {
      assert.ok(p.x >= 120 && p.x <= WORLD.w - 120);
      assert.ok(p.y >= 120 && p.y <= WORLD.h - 120);
    }
  });
  it('spawnPt devuelve un punto', () => {
    const p = spawnPt();
    assert.ok(typeof p.x === 'number' && typeof p.y === 'number');
  });
});
