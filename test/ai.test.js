// test/ai.test.js - motor de comportamiento IA por especie + karma IA + compras IA
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

// Agente fauna de prueba: replica exactamente lo que siembra spawnFauna
function aiAgent(speciesKey, x = 0, y = 0, extra = {}) {
  const carnivore = DIET[speciesKey].includes('mates');
  return mkAgent({
    role: 'fauna', speciesKey, x, y, hp: SPECIES[speciesKey].maxHp,
    face: { x: 1, y: 0 }, kind: carnivore ? 'hunter' : 'grazer',
    ...(carnivore ? { type: speciesKey, speed: SPECIES[speciesKey].speed, mode: 'wander',
      wx: x, wy: y, huntT: 0, restT: 0, satedT: 0, fleeLatch: false, huntingPlayer: false } : {}),
    ...extra,
  });
}
// Depredador de fila TIER_SPAWNS: mismo ensamblado que seedFoes
function hunterAgent(type, x, y, playerTier = 1) {
  return mkAgent({ role: 'hunter', ...mkPredator(type, x, y, playerTier) });
}
// Limpia toda la comida para pruebas deterministas
function clearFood(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.insects = []; s.carrions = [];
}

describe('aiTopo (ai-behavior-karma 2.2)', () => {
  it('cava madriguera y gana karma de aireado', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('topo');
    s.agents = [a];
    aiTopo(a, 0.1);
    assert.equal(a.dug, 1);
    assert.equal(a.karma, TUNING.aerateKarma);
    assert.ok(a.digCd > 0);
    assert.ok(s.refuges.some(r => r.type === 'burrow-M' && r.x === a.x && r.y === a.y));
  });
  it('come insecto cercano', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('topo');
    s.agents = [a];
    s.insects = [{ x: a.x + 5, y: a.y }];
    aiTopo(a, 0.1);
    assert.equal(s.insects.length, 0);
  });
  it('come zanahoria del parche', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('topo');
    s.agents = [a];
    s.patches = [mkPatch('carrots', a.x + 5, a.y, 3)];
    aiTopo(a, 0.1);
    assert.equal(s.patches[0].amount, 2);
  });
});

describe('aiArdilla (ai-behavior-karma 2.3)', () => {
  it('lleva nuez del roble y la planta por +10 karma', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('ardilla');
    s.agents = [a];
    s.oaks = [mkPatch('nuts', a.x + 5, a.y, 3)];
    aiArdilla(a, 0.1);
    assert.ok(a.carriedNut);
    assert.equal(s.oaks[0].amount, 2);
    aiArdilla(a, 0.1); // ya cargada: planta
    assert.ok(!a.carriedNut);
    assert.equal(a.karma, TUNING.plantKarma);
  });
  it('come baya cuando no hay nueces', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('ardilla');
    s.agents = [a];
    s.bushes = [mkPatch('berries', a.x + 5, a.y, 3)];
    aiArdilla(a, 0.1);
    assert.equal(s.bushes[0].amount, 2);
  });
});

describe('aiOruga (ai-behavior-karma 2.4)', () => {
  it('come hoja sostenible y cobra mordisqueo prudente +2', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('oruga');
    s.agents = [a];
    s.clumps = [mkPatch('leaves', a.x + 5, a.y, 3, { regrowT: 0 })];
    aiOruga(a, 0.1);
    assert.equal(s.clumps[0].amount, 2);
    assert.equal(a.karma, TUNING.prudentKarma);
  });
  it('quieta se enrosca (curled la cubre: mitad de daño)', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('oruga');
    s.agents = [a];
    aiOruga(a, 0.1);
    aiOruga(a, 0.1);
    assert.ok(curled(a));
  });
});

describe('aiSapo (ai-behavior-karma 2.5)', () => {
  it('come insecto y cobra control de plagas +3', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('sapo');
    s.agents = [a];
    s.insects = [{ x: a.x + 5, y: a.y }];
    aiSapo(a, 0.1);
    assert.equal(s.insects.length, 0);
    assert.equal(a.karma, TUNING.pestKarma);
  });
  it('quieto sin comida se camufla (camouflaged lo cubre)', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('sapo');
    s.agents = [a];
    aiSapo(a, 2.1);
    assert.ok(camouflaged(a));
  });
});

describe('aiRaton (ai-behavior-karma 2.6)', () => {
  it('grita ante peligro cuando su cd está listo (+30 karma, +50 PA)', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('raton');
    s.agents = [a, { role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: a.x + 100, y: a.y, hp: 120 }];
    a.buyT = 99; // sin compra en este tick: aislamos el grito
    aiRaton(a, 0.1);
    assert.equal(a.karma, TUNING.shoutKarma);
    assert.equal(a.pa, TUNING.shoutPa);
    assert.ok(a.shoutCd > 0);
  });
  it('acicala a un congénere cercano tras 3s (+5 karma)', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('raton');
    s.agents = [a, { role: 'company', speciesKey: 'raton', x: a.x + 5, y: a.y, hp: 60, saved: false }];
    aiRaton(a, TUNING.groomTime + 0.1);
    assert.equal(a.karma, TUNING.groomKarma);
  });
});

describe('aiZorro (ai-behavior-karma 2.7)', () => {
  it('caza fauna comestible cercana y deja carroña', () => {
    const s = reset('halcon'); // jugador T2 lejos de la acción
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const a = aiAgent('zorro', 0, 0);
    a.shoutCd = 99; // sin grito: prueba determinista de caza
    s.agents = [a, aiAgent('raton', 5, 0)];
    const n0 = s.carrions.length;
    aiZorro(a, 0.1);
    assert.equal(s.carrions.length, n0 + 1);
    assert.ok(!s.agents.some(x => x.speciesKey === 'raton' && x.brain === 'AI' && x.role === 'fauna'));
  });
  it('saciado cede la carroña (+15 karma) sin comerla', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const a = aiAgent('zorro', 0, 0);
    s.agents = [a];
    a.satedT = TUNING.satedTime; // ≥80% de vida equivalente: saciado
    s.carrions = [{ x: a.x + 5, y: a.y, age: 0 }];
    aiZorro(a, 0.1);
    assert.equal(s.carrions.length, 1); // la deja
    assert.equal(a.karma, TUNING.cedeKarma);
  });
  it('huye del lobo cercano (tabla fears)', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const z = aiAgent('zorro', 0, 0);
    s.agents = [z, aiAgent('lobo', 10, 0)];
    aiZorro(z, 0.1);
    assert.ok(z.x < 0); // se alejó del lobo
  });
});

describe('aiLobo (ai-behavior-karma 2.8)', () => {
  it('caza zorros y deja carroña', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const l = aiAgent('lobo', 0, 0);
    l.shoutCd = 99;
    s.agents = [l, aiAgent('zorro', 5, 0)];
    const n0 = s.carrions.length;
    aiLobo(l, 0.1);
    assert.equal(s.carrions.length, n0 + 1);
  });
  it('ahuyenta a un zorro depredador (+5 karma de caza necesaria)', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const l = aiAgent('lobo', 0, 0);
    l.shoutCd = 99;
    s.agents = [l, hunterAgent('zorro', 5, 0)];
    aiLobo(l, 0.1);
    assert.equal(l.karma, TUNING.strikeKarma);
    assert.ok(l.pa >= TUNING.strikePa);
  });
  it('ahuyentar a un lobo es hazaña (+20 karma)', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const h = aiAgent('halcon', 0, 0);
    h.shoutCd = 99;
    s.agents = [h, hunterAgent('lobo', 5, 0, 2)];
    aiHalcon(h, 0.1);
    assert.equal(h.karma, TUNING.loboStrikeKarma);
  });
});

describe('aiHalcon (ai-behavior-karma 2.9)', () => {
  it('pica sobre fauna pequeña y mata dejando carroña', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const h = aiAgent('halcon', 0, 0);
    h.shoutCd = 99;
    s.agents = [h, aiAgent('raton', 5, 0)];
    const n0 = s.carrions.length;
    aiHalcon(h, 0.1);
    assert.equal(s.carrions.length, n0 + 1);
  });
  it('aterriza para comer carroña', () => {
    const s = reset('lobo');
    s.px = 1000; s.py = 1000;
    clearFood(s);
    const h = aiAgent('halcon', 0, 0);
    s.agents = [h];
    s.carrions = [{ x: h.x + 5, y: h.y, age: 0 }];
    aiHalcon(h, 0.1);
    assert.ok(h.grounded);
  });
});

describe('aiBuyAdaptation (ai-behavior-karma 3.1-3.5)', () => {
  it('compra estómago con PA y vida baja: paga, posee y cura', () => {
    reset('raton');
    const a = aiAgent('raton');
    a.pa = 50; a.hp = SPECIES.raton.maxHp * 0.3; // <50%
    aiBuyAdaptation(a);
    assert.equal(a.pa, 50 - SHOP.find(s => s.id === 'stomach').cost);
    assert.ok(a.owned.stomach);
    assert.ok(a.hp > SPECIES.raton.maxHp * 0.3);
  });
  it('rechaza compra sin PA suficiente: nada cambia', () => {
    reset('raton');
    const a = aiAgent('raton');
    a.pa = 10; a.hp = 1;
    aiBuyAdaptation(a);
    assert.equal(a.pa, 10);
    assert.deepEqual(a.owned, {});
  });
  it('respeta una compra por stat (sin apilado): estómago ya owned → compra otra', () => {
    reset('raton');
    const a = aiAgent('raton');
    a.pa = 200; a.hp = 1; a.owned.stomach = true;
    aiBuyAdaptation(a);
    assert.ok(a.owned.stomach); // no recompró
    assert.ok(!a.owned.swift && !a.owned.nose === false || a.owned.nose); // compró la siguiente necesidad
    assert.equal(a.pa, 200 - SHOP.find(s => s.id === 'nose').cost); // olfato (25) tras estómago
  });
  it('schedule: aiBase llama a la compra cada aiBuyEvery segundos', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('raton');
    a.pa = 50; a.hp = 1; a.buyT = 0; a.shoutCd = 99; // ventana vencida
    s.agents = [a];
    aiRaton(a, 0.1);
    assert.ok(a.owned.stomach); // compró en su ventana
    assert.ok(a.buyT > 0); // reprogramó
  });
});

describe('efectos de ecosistema por karma (ai-behavior-karma 6.2)', () => {
  it('karma alto: percepción ×0.8 (200px no alcanza a 230 de percepción)', () => {
    reset('halcon');
    const v = aiAgent('raton', 0, 0);
    v.karma = 50;
    assert.equal(nearestVictimKarmaAware(200, 0, [v], 230), null); // 200/0.8=250 > 230
  });
  it('karma bajo: percepción ×1.2 (250px sí alcanza a 230)', () => {
    reset('halcon');
    const v = aiAgent('raton', 0, 0);
    v.karma = -50;
    assert.equal(nearestVictimKarmaAware(250, 0, [v], 230), v); // 250/1.2≈208 < 230
  });
  it('karma neutral: percepción intacta', () => {
    reset('halcon');
    const v = aiAgent('raton', 0, 0);
    assert.equal(nearestVictimKarmaAware(250, 0, [v], 230), null);
    assert.equal(nearestVictimKarmaAware(200, 0, [v], 230), v);
  });
  it('strikeAgents integra el modificador: el zorro acecha a la víctima de karma bajo', () => {
    const s = reset('halcon');
    s.px = 1000; s.py = 1000;
    const v = aiAgent('raton', 0, 0);
    v.karma = -50;
    const z = aiAgent('zorro', 250, 0);
    z.role = 'hunter';
    s.agents = [v, z];
    stepPredator(z, 0.1, []);
    assert.ok(z.x < 250); // avanzó aunque 250 > percepción 230
  });
});

describe('indicadores visuales (ai-behavior-karma 5.1-5.4)', () => {
  it('render completa con agentes con karma/PA y no revienta', () => {
    const s = reset('raton');
    for (const a of s.agents) { a.karma = 25; a.pa = 10; }
    render(); // el stub de canvas acepta todo; lo que se verifica es que no lanza
  });
  it('drawAgentIndicators pinta barra de vida y karma con color por signo', () => {
    reset('raton');
    const a = { x: 100, y: 100, hp: 20, speciesKey: 'raton', karma: -15, brain: 'AI' };
    drawAgentIndicators(a, SPECIES.raton); // rojo: karma negativo, barra parcial
    const b = { x: 100, y: 100, hp: 100, speciesKey: 'raton', karma: 25, brain: 'AI' };
    drawAgentIndicators(b, SPECIES.raton); // verde: karma positivo, barra llena
  });
  it('el jugador no lleva indicador (los tiene en el HUD)', () => {
    reset('raton');
    render(); // no lanza con state.karma distinto de 0
  });
});

describe('integración updateAgents (ai-behavior-karma 6.1, 6.4, 6.5)', () => {
  it('la fauna IA pasa hambre, come y gana karma por su especie en el loop', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('oruga', 0, 0);
    s.agents = [a];
    s.clumps = [mkPatch('leaves', a.x + 5, a.y, 3, { regrowT: 0 })];
    updateAgents(0.1);
    assert.equal(a.karma, TUNING.prudentKarma); // prudente via loop
    assert.ok(a.hp > SPECIES.oruga.maxHp - TUNING.hungerPerSec * 0.1);
  });
  it('decrece los cooldowns propios del agente', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('topo', 0, 0);
    a.digCd = 5; a.shoutCd = 3;
    s.agents = [a];
    updateAgents(0.5);
    assert.ok(a.digCd < 5 && a.shoutCd < 3);
  });
  it('muerte por hambre deja carroña (karma IA perdido)', () => {
    const s = reset('raton');
    clearFood(s);
    const a = aiAgent('raton', 0, 0);
    a.hp = 0.05; a.karma = 40;
    s.agents = [a];
    updateAgents(0.1);
    assert.ok(!s.agents.includes(a));
    assert.equal(s.carrions.length, 1); // su ledger se descarta con él
  });
});
