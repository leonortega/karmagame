// test/shop.test.js - juicio de reencarnacion y tienda
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, elsById } = require('./harness');

describe('judge', () => {
  it('karma+PA altos ascienden con eleccion dual', () => {
    const s = reset('raton');
    s.karma = 60; s.pa = 120;
    const j = judge();
    assert.equal(j.next, 'halcon');
    assert.deepEqual(j.choice, ['halcon', 'zorro']);
  });
  it('karma -50 o menos involuciona a oruga', () => {
    const s = reset('raton');
    s.karma = -60; s.pa = 500;
    assert.equal(judge().next, 'oruga');
  });
  it('oruga con +20 redime a sapo', () => {
    const s = reset('oruga');
    s.karma = 25;
    assert.equal(judge().next, 'sapo');
  });
  it('karma neutral rota lateral en el pool', () => {
    const s = reset('raton');
    s.karma = 0;
    const j = judge();
    assert.ok(T1POOL.includes(j.next) && j.next !== 'raton');
  });
});

describe('showJudgment/pickT2/chooseForm', () => {
  it('el juicio pinta DOM y abre pick T2', () => {
    const s = reset('raton');
    s.karma = 60; s.pa = 120;
    s.dead = true;
    showJudgment();
    assert.equal(s.pendingNext, 'halcon');
    assert.ok(pickT2('zorro'));
    assert.equal(s.pendingNext, 'zorro');
    assert.ok(!pickT2('halcon')); // ya elegido
  });
  it('chooseForm lateral cobra 15 PA una vez', () => {
    const s = reset('raton');
    s.karma = 0; s.pa = 50;
    s.dead = true;
    showJudgment();
    const lateral = s.pendingNext;
    assert.ok(T1POOL.includes(lateral));
    const other = T1POOL.find((f) => f !== lateral && f !== 'raton') || 'sapo';
    assert.ok(chooseForm(other));
    assert.equal(s.pa, 50 - TUNING.chooseFormCost);
    assert.ok(!chooseForm('sapo')); // una sola eleccion
  });
  it('sin PA no hay chooseForm', () => {
    const s = reset('raton');
    s.karma = 0; s.pa = 0;
    s.dead = true;
    showJudgment();
    assert.ok(!chooseForm('sapo'));
  });
});

describe('tienda', () => {
  it('compra descuenta y aplica; sin apilado ni deuda', () => {
    const s = reset();
    s.pa = 100;
    s.shopOpen = true;
    assert.ok(buyItem('swift'));
    assert.equal(s.pa, 50);
    assert.ok(!buyItem('swift')); // sin apilado
    s.pa = 0;
    assert.ok(!buyItem('nose')); // sin deuda
  });
  it('estomago cura al comprar', () => {
    const s = reset();
    s.pa = 100; s.hp = 10;
    s.shopOpen = true;
    buyItem('stomach');
    assert.equal(s.hp, 35);
  });
  it('cerrada no vende', () => {
    reset();
    S().pa = 100;
    S().shopOpen = false;
    assert.ok(!buyItem('swift'));
  });
});
