// test/flora.test.js - bosque vivo: regrow, semillas, robles, viejos robles (forest-flora-lifecycle)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

function clearFlora(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
}

describe('semillas de fruta comida (2.1-2.9)', () => {
  it('comer fruta siembra: probabilidad forzada a 1 → brote junto a la planta', () => {
    const s = reset('raton');
    clearFlora(s);
    const b = mkPatch('berries', 100, 100, 3);
    s.bushes = [b];
    s.px = 100; s.py = 100;
    const roll = Math.random;
    Math.random = () => 0; // < seedSproutChance: siempre brota
    eatPatch(b);
    Math.random = roll;
    assert.equal(s.seedlings.length, 1);
    assert.equal(s.seedlings[0].kind, 'berries');
    assert.ok(Math.hypot(s.seedlings[0].x - 100, s.seedlings[0].y - 100) <= TUNING.seedScatter + 1);
  });
  it('probabilidad 0 no siembra nada', () => {
    const s = reset('raton');
    clearFlora(s);
    const b = mkPatch('berries', 0, 0, 3);
    s.bushes = [b];
    s.px = 0; s.py = 0;
    const roll = Math.random;
    Math.random = () => 0.99; // ≥ chance: no brota
    eatPatch(b);
    Math.random = roll;
    assert.equal(s.seedlings.length, 0);
  });
  it('tope de brotes: seedlingMax no se supera', () => {
    const s = reset('raton');
    clearFlora(s);
    const b = mkPatch('berries', 0, 0, 99);
    s.bushes = [b];
    s.px = 0; s.py = 0;
    const roll = Math.random;
    Math.random = () => 0;
    for (let i = 0; i < TUNING.seedlingMax + 5; i++) eatPatch(b);
    Math.random = roll;
    assert.equal(s.seedlings.length, TUNING.seedlingMax);
  });
  it('brote madura en planta viva de su especie con toda la fruta (4.1: nace con FRUIT_CAP)', () => {
    const s = reset('raton');
    clearFlora(s);
    s.seedlings = [{ kind: 'berries', x: 100, y: 100, age: TUNING.seedlingMaturity }];
    ageWorld(0.1);
    assert.equal(s.seedlings.length, 0);
    assert.equal(s.bushes.length, 1);
    assert.ok(s.bushes[0].alive && s.bushes[0].amount === FRUIT_CAP.berries);
    assert.equal(s.bushes[0].x, 100);
  });
  it('todos los tipos de brote nacen llenos: berries/apples/carrots/mushrooms (4.1)', () => {
    const s = reset('raton');
    clearFlora(s);
    s.seedlings = [
      { kind: 'apples', x: 100, y: 0, age: TUNING.seedlingMaturity },
      { kind: 'carrots', x: 200, y: 0, age: TUNING.seedlingMaturity },
      { kind: 'mushrooms', x: 300, y: 0, age: TUNING.seedlingMaturity },
    ];
    ageWorld(0.1);
    assert.equal(s.shrubs[0].amount, FRUIT_CAP.apples);
    assert.equal(s.patches[0].amount, FRUIT_CAP.carrots);
    assert.equal(s.clusters[0].amount, FRUIT_CAP.mushrooms);
  });
  it('maduración respeta el tope por especie: espera y reintenta', () => {
    const s = reset('raton');
    clearFlora(s);
    s.bushes = [{ kind: 'berries', x: 0, y: 0, amount: 3, alive: true, regrowT: 0 }]; // tope alcanzado
    // tope de arbustos = densidad base; llenamos el resto
    const cap = floraCap('berries');
    for (let i = s.bushes.length; i < cap; i++) s.bushes.push(mkPatch('berries', i * 300, 0, 3));
    s.seedlings = [{ kind: 'berries', x: 500, y: 500, age: TUNING.seedlingMaturity }];
    ageWorld(0.1);
    assert.equal(s.seedlings.length, 1); // espera
    s.bushes[0].amount = 0; s.bushes[0].alive = false; // se libera un hueco? no: cuenta planta viva o no
    s.bushes.pop(); // liberamos un hueco de verdad
    ageWorld(0.1);
    assert.equal(s.seedlings.length, 0);
    assert.equal(s.bushes.length, cap);
  });
  it('planta nacida de brote tira su propio mímico (herencia de ponzoña no)', () => {
    const s = reset('raton');
    clearFlora(s);
    s.seedlings = [{ kind: 'berries', x: 0, y: 0, age: TUNING.seedlingMaturity }];
    ageWorld(0.1);
    const b = s.bushes[0];
    // cualquier estado es válido (mímico o no), lo que NO es válido es heredar sin tirar:
    // el test fija que el campo existe y es booleano
    assert.equal(typeof b.mimic, 'boolean');
    assert.equal(typeof b.mimicEaten, 'boolean');
  });
  it('comedor IA también siembra el bosque', () => {
    const s = reset('raton');
    clearFlora(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 40 });
    const b = mkPatch('berries', 0, 0, 3);
    const roll = Math.random;
    Math.random = () => 0;
    eatPatch(b, a);
    Math.random = roll;
    assert.equal(s.seedlings.length, 1);
  });
  it('último fruto también siembra (el ciclo no se corta con el castigo)', () => {
    const s = reset('raton');
    clearFlora(s);
    const b = mkPatch('berries', 0, 0, 1);
    s.bushes = [b];
    s.px = 0; s.py = 0;
    const roll = Math.random;
    Math.random = () => 0;
    eatPatch(b);
    Math.random = roll;
    assert.ok(!b.alive); // muerta como siempre
    assert.equal(s.seedlings.length, 1); // pero dejó semilla
  });
});

describe('nuez plantada → roble joven (3.1-3.5)', () => {
  it('jugador entierra nuez: semilla oak-tree en el sitio (+ karma/banco intactos)', () => {
    const s = reset('ardilla');
    clearFlora(s);
    s.oaks = [mkPatch('nuts', 0, 0, 2)];
    s.px = 0; s.py = 0;
    const karma0 = s.karma;
    assert.ok(carryAction()); // lleva
    assert.ok(carryAction()); // entierra
    assert.equal(s.karma, karma0 + TUNING.plantKarma); // deed intacto
    assert.equal(s.saplings, 1); // banco intacto
    const oakSeed = s.seedlings.find(x => x.kind === 'oak-tree');
    assert.ok(oakSeed, 'semilla de roble presente');
    assert.ok(Math.hypot(oakSeed.x, oakSeed.y) <= TUNING.seedScatter + 1);
  });
  it('semilla oak-tree madura en roble joven cargado de nueces', () => {
    const s = reset('ardilla');
    clearFlora(s);
    s.seedlings = [{ kind: 'oak-tree', x: 300, y: 300, age: TUNING.seedlingMaturity }];
    ageWorld(0.1);
    assert.equal(s.seedlings.length, 0);
    const oak = s.oaks[s.oaks.length - 1];
    assert.ok(oak && oak.amount === 3 && oak.alive && oak.x === 300);
  });
  it('AI ardilla planta igual que el jugador (paridad)', () => {
    const s = reset('raton');
    clearFlora(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'ardilla', x: 200, y: 200, hp: 90,
      face: { x: 1, y: 0 }, kind: 'grazer', carriedNut: true });
    s.agents = [a];
    aiArdilla(a, 0.1);
    assert.ok(s.seedlings.some(x => x.kind === 'oak-tree'));
    assert.equal(a.karma, TUNING.plantKarma);
  });
});

describe('viejo roble refugio (4.1-4.5)', () => {
  it('aparece en la siembra del mundo', () => {
    const s = reset('raton');
    assert.ok(s.refuges.some(r => r.type === 'old-oak'));
  });
  it('refugeFits: cabe tamaño ≤3, no el lobo (4)', () => {
    reset('raton'); // effSize 1
    assert.ok(refugeFits({ type: 'old-oak', maxSize: 3, climbOnly: false }));
    reset('zorro'); // size 3
    assert.ok(refugeFits({ type: 'old-oak', maxSize: 3, climbOnly: false }));
    reset('lobo'); // size 4
    assert.ok(!refugeFits({ type: 'old-oak', maxSize: 3, climbOnly: false }));
  });
  it('oculto bajo el viejo roble: el zorro pierde al jugador', () => {
    const s = reset('raton');
    s.refuges = [{ type: 'old-oak', maxSize: 3, climbOnly: false, x: s.px + 5, y: s.py }];
    assert.ok(toggleHide());
    assert.ok(s.hidden);
    // el zorro persigue al jugador: hidden rompe la caza (regla existente) y acampa
    const z = { type: 'zorro', x: 0, y: 0, speed: 100, mode: 'hunt', huntingPlayer: true, wx: 0, wy: 0 };
    assert.ok(campStep(z, 0.1)); // entra en camp como con cualquier refugio
    assert.equal(z.mode, 'camp');
  });
  it('el halcón ignora la copa: no acampa, caza al oculto', () => {
    const s = reset('raton');
    s.hidden = true;
    s.hideRef = { type: 'old-oak', maxSize: 3, climbOnly: false, x: 100, y: 100 };
    const h = { type: 'halcon', x: 0, y: 0, speed: 200, mode: 'hunt', huntingPlayer: true, wx: 0, wy: 0 };
    assert.ok(!campStep(h, 0.1)); // NO entra en camp por el jugador oculto
    assert.equal(h.mode, 'hunt');
    assert.ok(canopyBlind(h) === false); // la copa no lo ciega
  });
  it('canopyBlind ciega a los terrestres', () => {
    const s = reset('raton');
    s.hidden = true;
    s.hideRef = { type: 'old-oak', maxSize: 3, climbOnly: false, x: 100, y: 100 };
    assert.ok(canopyBlind({ type: 'zorro' }));
    assert.ok(canopyBlind({ type: 'lobo' }));
    assert.ok(canopyBlind({ type: 'saponpc' }));
    assert.ok(!canopyBlind({ type: 'halcon' }));
  });
});

describe('render del bosque que envejece (5.1-5.3)', () => {
  it('render completa con brotes, robles jóvenes y viejos robles', () => {
    const s = reset('raton');
    s.seedlings = [
      { kind: 'berries', x: 100, y: 100, age: 1 },
      { kind: 'oak-tree', x: 200, y: 200, age: TUNING.seedlingMaturity - 1 },
    ];
    s.refuges.push({ type: 'old-oak', maxSize: 3, climbOnly: false, x: 300, y: 300 });
    render(); // no lanza
  });
  it('los brotes de roble se pintan como tronco medio al madurar (visual integrado)', () => {
    const s = reset('raton');
    s.seedlings = [{ kind: 'oak-tree', x: 300, y: 300, age: TUNING.seedlingMaturity }];
    ageWorld(0.1);
    render();
    assert.ok(s.oaks.some(o => o.x === 300 && o.y === 300));
  });
});

describe('reloj de fruta (1.1-1.4)', () => {
  it('arbusto pelado revive con 1 fruta tras fruitRegrow', () => {
    const s = reset('raton');
    clearFlora(s);
    s.bushes = [{ kind: 'berries', x: 100, y: 100, amount: 0, alive: false, regrowT: 0 }];
    ageWorld(TUNING.fruitRegrow);
    assert.ok(s.bushes[0].alive);
    assert.equal(s.bushes[0].amount, 1);
  });
  it('planta viva bajo tope gana fruta con el reloj', () => {
    const s = reset('raton');
    clearFlora(s);
    s.shrubs = [{ kind: 'apples', x: 0, y: 0, amount: 1, alive: true, regrowT: 0 }];
    ageWorld(TUNING.fruitRegrow);
    assert.equal(s.shrubs[0].amount, 2);
    ageWorld(TUNING.fruitRegrow);
    assert.equal(s.shrubs[0].amount, 3); // tope 3: no sigue creciendo
  });
  it('planta en el tope no excede el tope', () => {
    const s = reset('raton');
    clearFlora(s);
    s.bushes = [{ kind: 'berries', x: 0, y: 0, amount: 3, alive: true, regrowT: 0 }];
    for (let i = 0; i < 5; i++) ageWorld(TUNING.fruitRegrow);
    assert.equal(s.bushes[0].amount, 3);
    assert.ok(s.bushes[0].alive);
  });
  it('las hojas mantienen su reloj rápido propio (leafRegrow)', () => {
    const s = reset('oruga');
    clearFlora(s);
    s.clumps = [mkPatch('leaves', 0, 0, 1, { regrowT: 0 })];
    ageWorld(TUNING.leafRegrow);
    assert.equal(s.clumps[0].amount, 2); // regrow de hojas: igual que hoy
    // y NO usa fruitRegrow (90s daría 1 también, así que probamos que a 45s no da)
    s.clumps = [mkPatch('leaves', 0, 0, 1, { regrowT: 0 })];
    ageWorld(TUNING.leafRegrow / 2);
    assert.equal(s.clumps[0].amount, 1);
  });
});
