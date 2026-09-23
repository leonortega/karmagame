// test/eat.test.js - comer, cazar y acciones de especie
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

function at(s, o, x = 0, y = 0) {
  s.px = x; s.py = y; o.x = x; o.y = y;
  return o;
}

describe('eatRange', () => {
  it('sapo usa lengua, resto usa rango base', () => {
    reset('sapo');
    assert.equal(eatRange(), TUNING.tongueRange);
    reset('raton');
    assert.equal(eatRange(), TUNING.eatRange);
  });
});

describe('carrion', () => {
  it('carrionStage por edad', () => {
    reset();
    assert.equal(carrionStage({ age: 0 }), 'fresh');
    assert.equal(carrionStage({ age: TUNING.carrionRottenT }), 'rotten');
  });
  it('addCarrion aplica tope sacando podrida vieja', () => {
    const s = reset('zorro');
    for (let i = 0; i < TUNING.carrionCap + 2; i++) addCarrion(i * 50, 0);
    assert.equal(s.carrions.length, TUNING.carrionCap);
  });
  it('eatCarrion fresca da vida sin karma; podrida quita 25', () => {
    const s = reset('zorro');
    s.hp = 50;
    eatCarrion(at(s, { age: 0 }));
    assert.ok(s.hp > 50 && s.karma === 0);
    const before = s.hp;
    eatCarrion(at(s, { age: 999 }));
    assert.equal(s.hp, before + TUNING.carrionRottenHp);
  });
  it('sin dieta de carroña no come', () => {
    reset('raton');
    assert.equal(eatCarrion({ x: 0, y: 0, age: 0 }), false);
  });
});

describe('eatPatch', () => {
  it('rechaza dieta ajena y parche nulo', () => {
    reset('oruga');
    assert.equal(eatPatch(null), false);
    assert.equal(eatPatch(mkPatch('berries', 0, 0, 3)), false);
  });
  it('mimico quita 20 sin karma', () => {
    const s = reset('raton');
    s.hp = 80;
    const b = mkPatch('berries', 0, 0, 3, { mimic: true, mimicEaten: false });
    at(s, b);
    assert.ok(eatPatch(b));
    assert.equal(s.hp, 80 + TUNING.mimicHp);
    assert.equal(s.karma, 0);
  });
  it('ultimo fruto seca el parche con karma negativo', () => {
    const s = reset('raton');
    s.hp = 50;
    const b = mkPatch('berries', 0, 0, 1);
    at(s, b);
    eatPatch(b);
    assert.ok(!b.alive && s.karma === TUNING.lastFruitKarma);
  });
  it('oruga prudente gana karma si deja hojas', () => {
    const s = reset('oruga');
    const l = mkPatch('leaves', 0, 0, 3);
    at(s, l);
    eatPatch(l);
    assert.equal(s.karma, TUNING.prudentKarma);
  });
  it('hojas agotadas rebrotan desde cero', () => {
    const s = reset('oruga');
    const l = mkPatch('leaves', 0, 0, 1, { regrowT: 0 });
    at(s, l);
    eatPatch(l);
    assert.ok(!l.alive && l.regrowT === 0);
  });
});

describe('eatInsect', () => {
  it('sapo gana karma de plagas', () => {
    const s = reset('sapo');
    s.insects = [{ x: 0, y: 0 }];
    s.px = 0; s.py = 0;
    eatInsect(s.insects[0]);
    assert.equal(s.karma, TUNING.pestKarma);
    assert.equal(s.insects.length, 0);
  });
  it('raton no come insectos', () => {
    reset('raton');
    assert.equal(eatInsect({ x: 0, y: 0 }), false);
  });
});

describe('NPC eat loop', () => {
  it('agente IA come baya sostenible: gana vida sin karma ni PA', () => {
    const s = reset('raton');
    const pa0 = s.pa;
    const a = { speciesKey: 'raton', x: 0, y: 0, hp: 40 };
    const b = mkPatch('berries', 0, 0, 3);
    assert.ok(eatPatch(b, a));
    assert.ok(a.hp > 40 && a.hp <= SPECIES.raton.maxHp);
    assert.equal(s.karma, 0);
    assert.equal(s.pa, pa0);
    assert.equal(b.amount, 2);
  });
  it('agente IA respeta dieta ajena y sufre ponzoña sin karma', () => {
    const s = reset('raton');
    const o = { speciesKey: 'oruga', x: 0, y: 0, hp: 50 };
    assert.equal(eatPatch(mkPatch('berries', 0, 0, 3), o), false);
    assert.equal(o.hp, 50);
    const r = { speciesKey: 'raton', x: 0, y: 0, hp: 80 };
    const m = mkPatch('berries', 0, 0, 3, { mimic: true, mimicEaten: false });
    assert.ok(eatPatch(m, r));
    assert.equal(r.hp, 80 + TUNING.mimicHp);
    assert.equal(s.karma, 0);
  });
  it('agente IA come insecto y carroña con pagos de vida', () => {
    const s = reset('sapo');
    const a = { speciesKey: 'sapo', x: 0, y: 0, hp: 30 };
    s.insects = [{ x: 0, y: 0 }];
    assert.ok(eatInsect(s.insects[0], a));
    assert.ok(a.hp > 30 && s.karma === 0);
    const z = { speciesKey: 'zorro', x: 0, y: 0, hp: 50 };
    assert.ok(eatCarrion({ x: 0, y: 0, age: 0 }, z));
    assert.ok(z.hp > 50);
  });
});

describe('caza', () => {
  it('zarpazo necesitado cura; por deporte resta karma', () => {
    let s = reset('zorro');
    s.hp = 10;
    s.agents = [{ role: 'company', speciesKey: 'zorro', x: 0, y: 0, hp: 60, saved: false }];
    s.px = 0; s.py = 0; s.pounceCd = 0;
    pounceKill(s.agents[0]);
    assert.equal(s.karma, 0);
    s = reset('zorro');
    s.hp = effMaxHp();
    s.agents = [{ role: 'company', speciesKey: 'zorro', x: 0, y: 0, hp: 60, saved: false }];
    s.px = 0; s.py = 0; s.pounceCd = 0;
    pounceKill(s.agents[0]);
    assert.equal(s.karma, TUNING.wastefulKarma);
    assert.equal(s.carrions.length, 1);
  });
  it('picado deja al halcon en tierra', () => {
    const s = reset('halcon');
    s.hp = 10;
    diveKill({ x: 5, y: 5 });
    assert.ok(s.grounded && s.px === 5);
  });
  it('agente zorro IA caza sin karma y deja carroña', () => {
    const s = reset('raton');
    const z = { speciesKey: 'zorro', x: 0, y: 0, hp: 10, pounceCd: 0 };
    const n0 = s.carrions.length;
    pounceKill({ x: 0, y: 0, speciesKey: 'raton', hp: 50 }, z);
    assert.equal(s.carrions.length, n0 + 1);
    assert.ok(z.hp > 10 && s.karma === 0);
  });
  it('agente halcon IA pica y cae sobre la presa', () => {
    reset('raton');
    const h = { speciesKey: 'halcon', x: 0, y: 0, hp: 40 };
    diveKill({ x: 5, y: 5 }, h);
    assert.ok(h.x === 5 && h.y === 5 && h.hp > 40);
  });
});

describe('digBurrow/carryAction/sensePulse', () => {
  it('topo cava con tope y cooldown', () => {
    const s = reset('topo');
    assert.ok(digBurrow());
    assert.equal(s.dug, 1);
    assert.ok(!digBurrow()); // cooldown
    s.digCd = 0; s.dug = TUNING.digMax;
    assert.ok(!digBurrow()); // tope
  });
  it('ardilla lleva y entierra nuez', () => {
    const s = reset('ardilla');
    s.oaks = [mkPatch('nuts', 0, 0, 2)];
    s.px = 0; s.py = 0;
    assert.ok(carryAction());
    assert.ok(s.carriedNut);
    assert.ok(carryAction());
    assert.equal(s.saplings, 1);
    assert.equal(s.karma, TUNING.plantKarma);
  });
  it('raton no puede llevar nuez', () => {
    reset('raton');
    assert.equal(carryAction(), false);
  });
  it('topo revela, zorro rastrea, resto nada', () => {
    let s = reset('topo');
    assert.ok(sensePulse());
    assert.ok(s.revealT > 0);
    s = reset('zorro');
    s.carrions = [{ x: 0, y: 0, age: 0 }];
    assert.ok(sensePulse());
    assert.ok(s.trackT > 0);
    reset('raton');
    assert.equal(sensePulse(), false);
  });
});

describe('tryEat dispatch', () => {
  it('sapo come insecto a lengua; grazer come parche', () => {
    let s = reset('sapo');
    s.insects = [{ x: 90, y: 0 }]; // fuera de 46 pero dentro de lengua? no: ponlo cerca
    s.insects = [{ x: 10, y: 0 }];
    s.px = 0; s.py = 0;
    assert.ok(tryEat());
    s = reset('raton');
    s.bushes = [mkPatch('berries', 5, 0, 3)];
    s.px = 0; s.py = 0;
    assert.ok(tryEat());
  });
  it('halcon ahuyenta depredador cercano', () => {
    const s = reset('halcon');
    s.px = 0; s.py = 0;
    s.agents = [{ role: 'hunter', kind: 'hunter', type: 'zorro', x: 10, y: 0, speed: 1, mode: 'hunt', huntT: 0 }];
    s.strikeCd = 0;
    tryEat();
    assert.ok(s.strikeCd > 0);
  });
  it('zorro caza con E y cede carroña saciado', () => {
    let s = reset('zorro');
    s.hp = 10;
    s.agents = [{ role: 'company', speciesKey: 'zorro', x: s.px + 5, y: s.py, hp: 60, brain: 'AI', saved: false }];
    s.pounceCd = 0;
    const n0 = s.carrions.length;
    tryEat();
    assert.equal(s.carrions.length, n0 + 1);
    s = reset('zorro');
    s.hp = effMaxHp();
    s.pounceCd = 99; // sin zarpazo: va a la carroña
    s.agents = [];
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    tryEat();
    assert.equal(s.karma, TUNING.cedeKarma);
    assert.equal(s.carrions.length, 1); // la deja
  });
  it('halcon aterriza para comer carroña', () => {
    const s = reset('halcon');
    s.agents = [];
    s.hp = 50;
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    assert.ok(!s.grounded);
    tryEat();
    assert.ok(s.grounded); // primer E: aterriza
    s.landT = 0; // posado
    tryEat();
    assert.equal(s.carrions.length, 0);
    assert.ok(s.hp > 50);
  });
});
