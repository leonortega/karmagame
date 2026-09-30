// test/emoji-lifespan.test.js - cohesion emoji + hambre por especie (emoji-graphics-lifespan-cohesion)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

describe('hungerMult por especie', () => {
  it('oruga drena mas rapido que lobo; raton es baseline 1.0', () => {
    assert.ok(SPECIES.oruga.hungerMult > SPECIES.lobo.hungerMult);
    assert.equal(SPECIES.raton.hungerMult, 1.0);
  });
});

describe('hungerRateFor', () => {
  it('oruga > lobo; raton equivale a la base', () => {
    assert.ok(hungerRateFor('oruga') > hungerRateFor('lobo'));
    assert.equal(hungerRateFor('raton'), TUNING.hungerPerSec);
  });
  it('lobo sin comer vive 30 minutos; el resto escala por su mult', () => {
    const loboSecs = SPECIES.lobo.maxHp / hungerRateFor('lobo');
    assert.ok(Math.abs(loboSecs - 1800) < 1);
    const orugaSecs = SPECIES.oruga.maxHp / hungerRateFor('oruga');
    assert.ok(orugaSecs < loboSecs / 5);
  });
});

describe('tamano emoji por categoria', () => {
  it('animal > comida > terreno; lobo > oruga', () => {
    assert.ok(EMOJI_SIZE.animal > EMOJI_SIZE.food);
    assert.ok(EMOJI_SIZE.food > EMOJI_SIZE.terrain);
    assert.ok(animalEmojiSize('lobo') > animalEmojiSize('oruga'));
  });
  it('fuente emoji a todo color y robles mas grandes que madrigueras', () => {
    assert.ok(EMOJI_FONT.includes('Segoe UI Emoji'));
    assert.ok(refugeEmojiSize('old-oak') > refugeEmojiSize('burrow-M'));
    assert.ok(refugeEmojiSize('hollow-tree') > refugeEmojiSize('burrow-M'));
  });
});

describe('drawSpecies emoji-first', () => {
  it('pinta el emoji de la especie al tamano animal', () => {
    reset();
    const calls = [];
    const orig = globalThis.drawEmoji || drawEmoji;
    globalThis.drawEmoji = (icon, x, y, size) => { calls.push({ icon, size }); };
    try {
      drawSpecies('lobo', 100, 100, { x: 1, y: 0 }, 1, {});
      drawSpecies('oruga', 100, 100, { x: 1, y: 0 }, 1, {});
    } finally {
      globalThis.drawEmoji = orig;
    }
    assert.equal(calls.length, 2);
    assert.equal(calls[0].icon, speciesIcon('lobo'));
    assert.equal(calls[0].size, animalEmojiSize('lobo'));
    assert.equal(calls[1].icon, speciesIcon('oruga'));
    assert.equal(calls[1].size, animalEmojiSize('oruga'));
  });
});

describe('drawPatch emoji medio', () => {
  it('pinta el emoji de comida al tamano food sin vectores', () => {
    reset();
    const calls = [];
    const orig = globalThis.drawEmoji;
    globalThis.drawEmoji = (icon, x, y, size) => { calls.push({ icon, size }); };
    try {
      drawPatch({ kind: 'berries', x: 50, y: 50, amount: 2, alive: true });
    } finally {
      globalThis.drawEmoji = orig;
    }
    const food = calls.find((c) => c.icon === foodIcon('berries'));
    assert.ok(food);
    assert.equal(food.size, EMOJI_SIZE.food);
  });
});

describe('terreno emoji pequeno', () => {
  it('refugio, roca, brote y carroña usan tamano terrain', () => {
    const s = reset();
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: 100, y: 100 }];
    s.rocks = [{ x: 200, y: 200 }];
    s.seedlings = [{ kind: 'grass', x: 300, y: 300 }];
    s.carrions = [{ x: 400, y: 400, age: 0 }];
    const calls = [];
    const orig = globalThis.drawEmoji;
    globalThis.drawEmoji = (icon, x, y, size) => { calls.push({ icon, size }); };
    try {
      drawRefugeField();
      drawRockField();
      drawSeedlingField();
      drawCarrionPile(null, 0);
    } finally {
      globalThis.drawEmoji = orig;
    }
    const refuge = calls.find((c) => c.icon === refugeIcon('burrow-M'));
    assert.ok(refuge);
    assert.equal(refuge.size, EMOJI_SIZE.terrain);
    const rock = calls.find((c) => c.size === EMOJI_SIZE.terrain);
    assert.ok(rock);
    const seed = calls.find((c) => c.icon === '🌱');
    assert.ok(seed);
    assert.equal(seed.size, EMOJI_SIZE.terrain);
    const meat = calls.find((c) => c.icon === foodIcon('carrion'));
    assert.ok(meat);
    assert.equal(meat.size, EMOJI_SIZE.terrain);
  });
});

describe('leyenda emoji-first', () => {
  it('cubre animales, comidas y terreno en orden de tamano', () => {
    const all = LEGEND_LINES.join(' ');
    for (const f of Object.keys(SPECIES)) assert.ok(all.includes(speciesIcon(f)));
    for (const k of ['berries', 'carrion']) assert.ok(all.includes(foodIcon(k)));
    assert.ok(all.includes('🪨') && all.includes('🌱'));
  });
});

describe('info restaurada: etiquetas, barras y anillos', () => {
  it('helpers de informacion existen', () => {
    for (const fn of ['drawTag', 'drawShadow', 'drawMedal', 'drawAgentIndicators', 'drawMeadow'])
      assert.equal(typeof globalThis[fn], 'function');
  });
  it('parche vivo lleva etiqueta con existencias; pelado lleva cruz y pelada', () => {
    reset();
    const tags = [];
    const orig = globalThis.drawTag;
    globalThis.drawTag = (text) => { tags.push(String(text)); };
    try {
      drawPatch({ kind: 'berries', x: 50, y: 50, amount: 2, alive: true });
      assert.ok(tags.some((t) => t.includes('×2')));
      tags.length = 0;
      drawPatch({ kind: 'berries', x: 50, y: 50, amount: 0, alive: false });
      assert.ok(tags.some((t) => t.includes('pelada')));
    } finally {
      globalThis.drawTag = orig;
    }
  });
  it('indicador pinta etiqueta de karma sin lanzar', () => {
    reset();
    const a = { x: 100, y: 100, hp: 20, speciesKey: 'raton', karma: -15, brain: 'AI' };
    assert.doesNotThrow(() => drawAgentIndicators(a, SPECIES.raton));
  });
  it('carroña usa icono por estado', () => {
    reset();
    const calls = [];
    const orig = globalThis.drawEmoji;
    globalThis.drawEmoji = (icon, x, y, size) => { calls.push({ icon, size }); };
    try {
      S().carrions = [{ x: 1, y: 1, age: 0 }];
      drawCarrionPile(null, 0);
      assert.ok(calls.some((c) => c.icon === '🍖'));
      calls.length = 0;
      S().carrions = [{ x: 1, y: 1, age: 999 }];
      drawCarrionPile(null, 0);
      assert.ok(calls.some((c) => c.icon === '🤢'));
    } finally {
      globalThis.drawEmoji = orig;
    }
  });
  it('brote de roble futuro usa arbol y pasto usa brote', () => {
    reset();
    S().seedlings = [{ kind: 'oak-tree', x: 10, y: 10 }, { kind: 'grass', x: 20, y: 20 }];
    const calls = [];
    const orig = globalThis.drawEmoji;
    globalThis.drawEmoji = (icon, x, y, size) => { calls.push({ icon, size }); };
    try { drawSeedlingField(); } finally { globalThis.drawEmoji = orig; }
    assert.ok(calls.some((c) => c.icon === '🌳'));
    assert.ok(calls.some((c) => c.icon === '🌱'));
  });
});

describe('hambre por especie (jugador)', () => {
  it('oruga pierde mas vida que lobo en 1s sin comer ni depredadores', () => {
    let s = reset('oruga');
    s.agents = []; // sin fauna ni cazadores: solo las necesidades
    s.hambre = 10; s.sed = 10; // bajo umbral: drena en vez de regenerar
    const hp0 = s.hp;
    update(1);
    const lossOruga = hp0 - S().hp;
    reset('lobo');
    const s2 = S();
    s2.agents = [];
    s2.hambre = 10; s2.sed = 10;
    const hp02 = s2.hp;
    update(1);
    const lossLobo = hp02 - S().hp;
    assert.ok(lossOruga > lossLobo);
  });
});

describe('hambre por especie (IA)', () => {
  it('oruga IA pierde mas que lobo IA en el mismo dt', () => {
    reset('raton');
    const o = mkAgent({ role: 'fauna', speciesKey: 'oruga', x: 0, y: 0, hp: 50, brain: 'AI', kind: 'grazer' });
    const l = mkAgent({ role: 'fauna', speciesKey: 'lobo', x: 0, y: 0, hp: 50, brain: 'AI', kind: 'hunter', type: 'lobo' });
    o.hambre = 10; o.sed = 10; l.hambre = 10; l.sed = 10; // bajo umbral: drena
    const s = S();
    s.agents = [];
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.insects = []; s.carrions = [];
    const hpO0 = o.hp, hpL0 = l.hp;
    aiOruga(o, 1);
    aiLobo(l, 1);
    assert.ok(hpO0 - o.hp > hpL0 - l.hp);
  });
});
