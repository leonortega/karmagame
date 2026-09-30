// test/survival.test.js - IA que se alimenta y sobrevive (foraging-survival-ai)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

function clearWorld(s) {
  s.bushes = []; s.shrubs = [];
  s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
  s.refuges = []; s.rocks = [];
}
// Depredador de fila TIER_SPAWNS: mismo ensamblado que seedFoes (ledger completo incluido)
function predAgent(type, x, y) {
  return mkAgent({ role: 'hunter', ...mkPredator(type, x, y, 1) });
}
function grazerAgent(speciesKey, x = 0, y = 0, hp = SPECIES[speciesKey].maxHp) {
  return mkAgent({ role: 'fauna', speciesKey, x, y, hp,
    face: { x: 1, y: 0 }, kind: DIET[speciesKey].includes('mates') ? 'hunter' : 'grazer' });
}

describe('buscar comida (1.1-1.5)', () => {
  it('ratón sin comida cerca camina hacia un arbusto a 90px (dentro de visión×0.5)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 0, 0);
    s.agents = [a];
    s.bushes = [mkPatch('berries', 90, 0, 3)];
    const d0 = Math.hypot(a.x - 90, a.y);
    for (let i = 0; i < 30; i++) updateAgents(0.1);
    const d1 = Math.hypot(a.x - 90, a.y);
    assert.ok(d1 < d0, `se acercó: ${d0} → ${d1}`);
  });
  it('al llegar al rango de comida come (busca → come)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 0, 0, 30);
    s.agents = [a];
    s.bushes = [mkPatch('berries', 60, 0, 3)]; // dentro de forage, fuera de eat? 60>46: busca
    const hp0 = a.hp;
    for (let i = 0; i < 40; i++) updateAgents(0.1);
    assert.ok(a.hp > hp0 - TUNING.hungerPerSec * 4, `comió en el camino: hp ${hp0} → ${a.hp}`);
    assert.ok(s.bushes[0].amount < 3); // mordió alguna
  });
  it('sin comida en rango de forrajeo: deambula sin teletransportarse', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 0, 0);
    s.agents = [a];
    const x0 = a.x, y0 = a.y;
    for (let i = 0; i < 10; i++) updateAgents(0.1);
    assert.ok(Math.hypot(a.x - x0, a.y - y0) < 50); // solo jitter local
  });
  it('sapo insectívoro busca insectos lejanos (dentro de visión×0.5)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('sapo', 0, 0);
    s.agents = [a];
    // fuera de lengua (90) pero dentro de forrajeo: sapo vision 170×0.5=85 → 84
    s.insects = [{ x: 84, y: 0 }];
    for (let i = 0; i < 10; i++) updateAgents(0.1);
    assert.ok(s.insects.length === 0 || Math.hypot(a.x - 84, a.y) < 84, 'lo alcanza o lo come');
  });
});

describe('carroña a distancia para carnívoros (1.6-1.8)', () => {
  it('lobo con hambre camina a carroña a 200px en vez de quedarse quieto', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const l = grazerAgent('lobo', 0, 0, SPECIES.lobo.maxHp * 0.3); // hambriento
    s.agents = [l];
    s.carrions = [{ x: 200, y: 0, age: 0 }];
    for (let i = 0; i < 30; i++) updateAgents(0.1);
    assert.ok(Math.hypot(l.x - 200, l.y) < 100, `fue a la carroña: dist ${Math.hypot(l.x - 200, l.y)}`);
  });
  it('lobo hambriento prefiere carroña aunque haya presa más cerca', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const l = grazerAgent('lobo', 0, 0, SPECIES.lobo.maxHp * 0.3);
    const prey = grazerAgent('zorro', 50, 0);
    s.agents = [l, prey];
    s.carrions = [{ x: 200, y: 0, age: 0 }];
    for (let i = 0; i < 15; i++) updateAgents(0.1);
    assert.ok(s.agents.includes(prey)); // no lo cazó aún
    assert.ok(l.x > 30, `caminó hacia la carroña (x=${l.x}) sin detenerse en la presa`);
  });
  it('lobo sano caza presa aunque haya carroña (regla actual)', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const l = grazerAgent('lobo', 0, 0);
    const prey = grazerAgent('zorro', 35, 0); // 35px: matanza en 2 ticks segura ante jitter (±3)
    s.agents = [l, prey];
    s.carrions = [{ x: 400, y: 0, age: 0 }];
    updateAgents(0.1); updateAgents(0.1); // acercarse y matar
    assert.ok(!s.agents.includes(prey)); // cazó como siempre
  });
});

describe('prioridad de hambre (2.1-2.4)', () => {
  it('ratón hambriento junto a mate+comida come en vez de acicalar', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 0, 0, SPECIES.raton.maxHp * 0.3);
    s.agents = [a, { role: 'company', speciesKey: 'raton', x: 5, y: 0, hp: 60, saved: false }];
    s.bushes = [mkPatch('berries', 8, 0, 3)];
    aiRaton(a, TUNING.groomTime + 0.2);
    assert.ok(a.karma === 0 || a.karma === null); // no acicaló
    assert.ok(s.bushes[0].amount < 3); // comió
  });
  it('ratón sano junto a mate acicala como siempre (sin comida en boca)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 0, 0);
    s.agents = [a, { role: 'company', speciesKey: 'raton', x: 5, y: 0, hp: 60, saved: false }];
    aiRaton(a, TUNING.groomTime + 0.2);
    assert.equal(a.karma, TUNING.groomKarma);
  });
  it('ardilla hambrienta suelta la nuez y come', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('ardilla', 0, 0, SPECIES.ardilla.maxHp * 0.3);
    a.carriedNut = true;
    s.agents = [a];
    s.bushes = [mkPatch('berries', 8, 0, 3)];
    aiArdilla(a, 0.2);
    assert.ok(!a.carriedNut); // soltó/dejó la nuez
    assert.ok(s.bushes[0].amount < 3 || a.hp > SPECIES.ardilla.maxHp * 0.3); // comió
  });
  it('oruga hambrienta con comida disponible no se queda quieta a enroscarse', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('oruga', 0, 0, SPECIES.oruga.maxHp * 0.3);
    s.agents = [a];
    s.clumps = [mkPatch('leaves', 60, 0, 3)]; // 60 > eatRange 46, < forage 65
    for (let i = 0; i < 10; i++) aiOruga(a, 0.1);
    assert.ok(s.clumps[0].amount < 3 || a.x >= 50, `llegó y comió: x=${a.x}, hojas=${s.clumps[0].amount}`);
  });
});

describe('ocultación real (3.1-3.7)', () => {
  function huntedSetup() {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 100, 100);
    a.hambre = 20; a.sed = 20; // bajo umbral: el escondite drena, no regenera
    s.agents = [a, predAgent('zorro', 160, 100)];
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: 104, y: 100 }];
    return { s, a };
  }
  it('ratón perseguido junto a madriguera se esconde', () => {
    const { a } = huntedSetup();
    for (let i = 0; i < 3; i++) updateAgents(0.1);
    assert.ok(a.hidden, 'se escondió');
    assert.ok(a.hideRef);
  });
  it('sale tras aiHideMax aunque el peligro siga', () => {
    const { a } = huntedSetup();
    for (let i = 0; i < 3; i++) updateAgents(0.1);
    assert.ok(a.hidden);
    updateAgents(TUNING.aiHideMax + 0.1);
    assert.ok(!a.hidden, 'salió al vencer el tope');
  });
  it('sale antes si el peligro desaparece', () => {
    const { s, a } = huntedSetup();
    for (let i = 0; i < 3; i++) updateAgents(0.1);
    assert.ok(a.hidden);
    s.agents = s.agents.filter(o => o.role !== 'hunter'); // el zorro se va
    updateAgents(0.1);
    assert.ok(!a.hidden, 'salió al irse el peligro');
  });
  it('el hambre drena mientras está oculto', () => {
    const { a } = huntedSetup();
    for (let i = 0; i < 3; i++) updateAgents(0.1);
    const hp0 = a.hp;
    updateAgents(1);
    assert.ok(a.hp < hp0, 'el hambre no perdona el escondite');
  });
  it('huida se curva hacia el refugio cercano (3.7)', () => {
    const s = reset('halcon'); // jugador T2 lejos de la acción
    s.px = 1000; s.py = 1000;
    clearWorld(s);
    const z = grazerAgent('zorro', 0, 0);
    s.agents = [z, predAgent('lobo', 100, 0)]; // el lobo caza zorros: fears['lobo']
    s.refuges = [{ type: 'old-oak', maxSize: 3, climbOnly: false, x: 0, y: 150 }];
    aiFlee(z, 0.5);
    const toRef = Math.hypot(z.x - 0, z.y - 150);
    assert.ok(z.y > 10, `la huida se curvó hacia la copa (y=${z.y.toFixed(1)}; recta sería y=0)`);
    assert.ok(toRef < 150, `se aproximó a la cobertura: dist ${toRef.toFixed(1)} (huida recta: 176)`);
  });
  it('presa oculta no es cazable (3.2: las reglas de ocultación valen para la IA)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = grazerAgent('raton', 100, 100);
    a.hidden = true;
    a.hideT = TUNING.aiHideMax; // estado que aiTryHide deja tras entrar
    const z = predAgent('zorro', 105, 105);
    s.agents = [a, z];
    for (let i = 0; i < 20; i++) updateAgents(0.1);
    assert.ok(s.agents.includes(a), 'el zorro no puede matar a una presa oculta');
    assert.ok(!(z.satedT > 0), 'ni comerla por contacto');
  });
});
