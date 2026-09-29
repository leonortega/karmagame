// test/draw.test.js - cada elemento tiene icono/etiqueta distinguible (legibilidad)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset } = require('./harness');

describe('iconos distinguibles por elemento', () => {
  it('speciesIcon da un emoji distinto por especie (8 especies)', () => {
    const forms = ['oruga', 'sapo', 'raton', 'ardilla', 'topo', 'halcon', 'zorro', 'lobo'];
    const icons = forms.map((f) => speciesIcon(f));
    for (const ic of icons) assert.ok(ic && ic.length >= 1, ic);
    assert.equal(new Set(icons).size, forms.length);
  });
  it('foodIcon distingue las 6 comidas + insecto + carroña', () => {
    const kinds = ['berries', 'apples', 'carrots', 'mushrooms', 'nuts', 'leaves', 'insects', 'carrion'];
    const icons = kinds.map((k) => foodIcon(k));
    assert.equal(new Set(icons).size, kinds.length);
  });
  it('drawSpecies dibuja las 8 especies sin lanzar', () => {
    reset();
    for (const f of ['oruga', 'sapo', 'raton', 'ardilla', 'topo', 'halcon', 'zorro', 'lobo']) {
      assert.doesNotThrow(() => drawSpecies(f, 100, 100, { x: 1, y: 0 }, 1, {}));
    }
  });
  it('drawPatch dibuja las 6 comidas sin lanzar', () => {
    reset();
    const kinds = ['berries', 'apples', 'carrots', 'mushrooms', 'nuts', 'leaves'];
    for (const k of kinds) {
      assert.doesNotThrow(() => drawPatch({ kind: k, x: 50, y: 50, amount: 2, alive: true }));
    }
  });
  it('sprite animal puro vectorial: drawSpecies no pinta texto/emoji encima', () => {
    reset();
    const texts = [];
    globalThis.__ctxStub.fillText = (t) => { texts.push(String(t)); };
    try {
      for (const f of ['oruga', 'sapo', 'raton', 'ardilla', 'topo', 'halcon', 'zorro', 'lobo']) {
        drawSpecies(f, 100, 100, { x: 1, y: 0 }, 1, {});
        drawSpecies(f, 100, 100, { x: 1, y: 0 }, 1, { outline: '#7a1f1f' });
      }
    } finally {
      delete globalThis.__ctxStub.fillText;
    }
    assert.deepEqual(texts, []);
  });
  it('render dibuja un mundo fresco sin lanzar', () => {
    reset();
    assert.doesNotThrow(() => render());
  });
});
