// test/shop.test.js - juicio de reencarnacion y tienda
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, key, elsById } = require('./harness');

describe('drawFrom (azar-birth)', () => {
  it('sorteo uniforme con rand inyectado: primero, medio y último', () => {
    const pool = ['raton', 'ardilla', 'topo', 'sapo'];
    assert.equal(drawFrom(pool, () => 0), 'raton');
    assert.equal(drawFrom(pool, () => 0.5), 'topo');
    assert.equal(drawFrom(pool, () => 0.999), 'sapo');
  });
  it('sin rand usa azar pero cae dentro del pool', () => {
    const pool = ['raton', 'ardilla', 'topo', 'sapo'];
    assert.ok(pool.includes(drawFrom(pool)));
  });
});

describe('judge', () => {
  it('karma alto abre T2 sin PA: pool de 7 con lobo y sin choice', () => {
    const s = reset('raton');
    s.karma = 60; s.pa = 0;
    const j = judge(() => 0);
    assert.deepEqual(j.pool, [...T1POOL, ...T2POOL]);
    assert.ok(j.pool.includes(j.next));
    assert.ok(!('choice' in j));
  });
  it('karma -50 o menos involuciona a oruga sin importar PA ni forma', () => {
    const s = reset('lobo');
    s.karma = -60; s.pa = 500;
    const j = judge(() => 0.999);
    assert.deepEqual(j.pool, ['oruga']);
    assert.equal(j.next, 'oruga');
  });
  it('oruga muerta con karma neutral no redime a sapo: el pool manda', () => {
    const s = reset('oruga');
    s.karma = 10; s.pa = 30;
    const j = judge(() => 0);
    assert.deepEqual(j.pool, [...T1POOL]);
    assert.equal(j.next, 'raton');
  });
  it('razones citan el piso: involución, neutral y apertura T2', () => {
    reset('raton'); S().karma = -70;
    assert.ok(judge(() => 0).reason.includes('-50'));
    S().karma = 10;
    assert.ok(judge(() => 0).reason.toLowerCase().includes('neutral'));
    S().karma = 60;
    assert.ok(judge(() => 0).reason.includes('+50'));
  });
  it('gastar PA no cierra el pool: la PA es monedero, no llave', () => {
    const s = reset('raton');
    s.karma = 60; s.pa = 70; // ganó 120, gastó 50
    assert.deepEqual(judge(() => 0).pool.length, 7);
  });
});

describe('poolFor (azar-birth)', () => {
  it('karma <= -50 → solo oruga', () => {
    assert.deepEqual(poolFor(-70), ['oruga']);
    assert.deepEqual(poolFor(-50), ['oruga']);
  });
  it('karma neutral → pool T1 completo', () => {
    assert.deepEqual(poolFor(0), ['raton', 'ardilla', 'topo', 'sapo']);
    assert.deepEqual(poolFor(49), ['raton', 'ardilla', 'topo', 'sapo']);
  });
  it('karma >= +50 → pool T1+T2 con lobo', () => {
    assert.deepEqual(poolFor(50), ['raton', 'ardilla', 'topo', 'sapo', 'halcon', 'zorro', 'lobo']);
    assert.deepEqual(poolFor(100), ['raton', 'ardilla', 'topo', 'sapo', 'halcon', 'zorro', 'lobo']);
  });
});

describe('showJudgment (azar-birth)', () => {
  it('pinta drama, bloques y destino decidido en sincronía', () => {
    const s = reset('raton');
    s.karma = 0; s.pa = 40;
    s.dead = true;
    showJudgment();
    assert.ok(T1POOL.includes(s.pendingNext));
    assert.deepEqual(s.pendingPool, [...T1POOL]);
    assert.ok(elsById.jNext.textContent.includes('los dioses eligen'));
    assert.ok(elsById.jNext.textContent.includes(SPECIES[s.pendingNext].name));
    assert.ok(elsById.fateBlocks.innerHTML.includes(SPECIES[s.pendingNext].name));
  });
  it('no existe elección: ni pickT2 ni chooseForm', () => {
    assert.equal(typeof pickT2, 'undefined');
    assert.equal(typeof chooseForm, 'undefined');
  });
});

describe('adaptaciones por especie (azar-birth)', () => {
  it('catálogo: 3 por especie, 24 total, teclas 1-3 y coste 50-80', () => {
    assert.deepEqual(Object.keys(SHOP_BY_SPECIES).sort(), Object.keys(SPECIES).sort());
    let n = 0;
    for (const k of Object.keys(SHOP_BY_SPECIES)) {
      const cat = catalogFor(k);
      assert.equal(cat.length, 3, k);
      assert.deepEqual(cat.map((i) => i.key), ['1', '2', '3'], k);
      for (const it of cat) assert.ok(it.cost >= 50 && it.cost <= 80, it.id);
      n += cat.length;
    }
    assert.equal(n, 24);
  });
  it('lengua larga del sapo alcanza 130px', () => {
    const s = reset('sapo');
    assert.equal(eatRange(), TUNING.tongueRange);
    s.owned.sapo_lengua = true;
    assert.equal(eatRange(), TUNING.tongueRange + 40);
  });
  it('zarpas de rata aceleran vía efecto swift', () => {
    const s = reset('raton');
    s.owned.raton_zarpas = true;
    assert.ok(effSpeed() > s.sp.speed);
  });
});

describe('tienda por especie (azar-birth)', () => {
  it('compra del catálogo propio descuenta; sin apilado ni deuda', () => {
    const s = reset('raton');
    s.pa = 100;
    s.shopOpen = true;
    assert.ok(buyItem('raton_zarpas'));
    assert.equal(s.pa, 40);
    assert.ok(!buyItem('raton_zarpas')); // sin apilado
    s.pa = 0;
    assert.ok(!buyItem('raton_ojeada')); // sin deuda
  });
  it('rechaza item de otra especie', () => {
    const s = reset('raton');
    s.pa = 200;
    s.shopOpen = true;
    assert.ok(!buyItem('sapo_lengua'));
    assert.equal(s.pa, 200);
  });
  it('panza cura al comprar (efecto stomach)', () => {
    const s = reset('topo');
    s.pa = 100; s.hp = 10;
    s.shopOpen = true;
    assert.ok(buyItem('topo_panza'));
    assert.equal(s.hp, 35);
  });
  it('cerrada no vende', () => {
    reset('raton');
    S().pa = 100;
    S().shopOpen = false;
    assert.ok(!buyItem('raton_zarpas'));
  });
  it('teclas 1-3 compran del catálogo propio con la tienda abierta', () => {
    const s = reset('raton');
    s.pa = 100;
    key('b'); // abre tienda
    assert.ok(s.shopOpen);
    key('1'); // raton_zarpas 60
    assert.ok(s.owned.raton_zarpas);
    assert.equal(s.pa, 40);
  });
});
