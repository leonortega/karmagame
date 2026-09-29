// test/state.test.js - semilla de mundo, stats efectivos, karma, refugio, grito
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S } = require('./harness');

describe('newRun', () => {
  it('siembra comida, bichos, depredadores, congéneres y refugios', () => {
    const s = reset('raton');
    assert.ok(s.bushes.length >= scaledCount(7));
    assert.ok(s.shrubs.length === scaledCount(3) && s.oaks.length === scaledCount(2));
    assert.equal(s.insects.length, scaledCount(6));
    assert.ok(hunterAgents().length === 2 * Math.max(1, Math.round(areaScale()))
      && companyAgents().length === 4);
    assert.ok(s.refuges.length > 0 && s.carrions.length === 0);
    assert.equal(s.hp, SPECIES.raton.maxHp);
  });
  it('densidad: baseline reproduce constantes, area x4 cuadruplica', () => {
    WORLD.w = 1600; WORLD.h = 1200;
    let s = reset('raton');
    assert.equal(s.bushes.length, 7);
    assert.equal(s.shrubs.length, 3);
    assert.equal(s.insects.length, 6);
    assert.equal(s.refuges.length, 12); // 10 clásicos + 2 viejos robles (flora-lifecycle)
    assert.equal(hunterAgents().length, 2);
    WORLD.w = 3200; WORLD.h = 2400;
    s = reset('raton');
    assert.equal(s.bushes.length, 28);
    assert.equal(s.shrubs.length, 12);
    assert.equal(s.insects.length, 24);
    assert.equal(s.refuges.length, 48); // escalado x4: 12 por área base × 4
    assert.equal(hunterAgents().length, 8);
  });
  it('los retoños plantados dan arbustos extra con tope', () => {
    const s = reset('raton', 0, 0, 99);
    assert.equal(s.bushes.length, scaledCount(7) + TUNING.saplingCap);
  });
});

describe('roster unificado', () => {
  it('agents con roles, poseído y sin castas separadas', () => {
    const s = reset('raton');
    assert.ok(Array.isArray(s.agents) && s.possessed === 0);
    assert.ok(s.agents.some((a) => a.role === 'company' && a.speciesKey === 'raton'));
    assert.ok(s.agents.some((a) => a.role === 'hunter'));
    assert.ok(!('mates' in s) && !('predators' in s));
    const me = playerAgent();
    assert.equal(me.speciesKey, 'raton');
    assert.equal(roster().length, s.agents.length + 1);
  });
});

describe('población mixta', () => {
  it('las 8 especies presentes con pisos por densidad', () => {
    const s = reset('raton');
    for (const k of Object.keys(SPECIES)) {
      const floor = Math.max(1, Math.round((POP.faunaFloor[k] || 0) * areaScale() / 4));
      const n = s.agents.filter((a) => a.speciesKey === k).length;
      assert.ok(n >= floor, `${k}: ${n} < ${floor}`);
    }
    assert.ok(faunaAgents().length > 0);
  });
});

describe('eff*', () => {
  it('aplica adaptaciones de tienda', () => {
    const s = reset();
    const base = s.sp.speed;
    assert.equal(effSpeed(), base);
    s.owned.swift = true;
    assert.ok(effSpeed() > base);
    s.owned.nose = true;
    assert.equal(effVision(), s.sp.vision + 50);
    s.owned.stomach = true;
    assert.equal(effMaxHp(), s.sp.maxHp + 25);
  });
  it('halcon en tierra va a mitad (por la marcha, no effSpeed)', () => {
    const s = reset('halcon');
    s.grounded = true;
    assert.equal(locoMult('halcon', true, 0), 0.5); // el chapoteo vive en la marcha (species-locomotion-verbs)
    assert.equal(effSpeed(), s.sp.speed); // effSpeed ya no duplica el ×0.5
  });
  it('raton cabe en S', () => {
    reset('raton');
    assert.equal(effSize(), 1);
    reset('ardilla');
    assert.equal(effSize(), SPECIES.ardilla.size);
  });
});

describe('dieta/dietHint', () => {
  it('puerta de dieta dura por especie', () => {
    let s = reset('oruga');
    assert.ok(DIET[s.speciesKey].includes('leaves') && !DIET[s.speciesKey].includes('berries'));
    s = reset('zorro');
    assert.ok(DIET[s.speciesKey].includes('carrion') && !DIET[s.speciesKey].includes('berries'));
  });
  it('dietHint respeta cooldown', () => {
    const s = reset();
    s.dietHintT = 0;
    dietHint();
    assert.equal(s.dietHintT, TUNING.dietHintCd);
  });
});

describe('addKarma', () => {
  it('acota a [-100,100]', () => {
    const s = reset();
    addKarma(500);
    assert.equal(s.karma, 100);
    addKarma(-500);
    assert.equal(s.karma, -100);
  });
});

describe('refugio', () => {
  it('refugeFits respeta talla y trepa', () => {
    reset('raton'); // effSize 1: cabe en S
    assert.ok(refugeFits({ maxSize: 1, climbOnly: false }));
    reset('ardilla'); // size 2: no cabe en S
    assert.ok(!refugeFits({ maxSize: 1, climbOnly: false }));
    assert.ok(refugeFits({ maxSize: 2, climbOnly: false }));
    reset('raton'); // sin trepa: el hueco lo rechaza
    assert.ok(!refugeFits({ maxSize: 2, climbOnly: true }));
  });
  it('ardilla trepa al hueco', () => {
    reset('ardilla'); // climb:true
    assert.ok(refugeFits({ maxSize: 2, climbOnly: true }));
  });
  it('toggleHide entra y sale junto a refugio apto', () => {
    const s = reset('raton');
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: s.px + 5, y: s.py }];
    assert.ok(toggleHide());
    assert.ok(s.hidden);
    assert.ok(toggleHide());
    assert.ok(!s.hidden);
  });
});

describe('tryShout', () => {
  it('da karma y PA, marca mates y pone señuelo', () => {
    const s = reset('raton');
    s.pa = 0;
    tryShout();
    assert.equal(s.karma, TUNING.shoutKarma);
    assert.equal(s.pa, TUNING.shoutPa);
    assert.ok(companyAgents().every((m) => m.saved));
    assert.ok(s.lureTimer > 0 && s.shoutCd > 0);
  });
  it('zorro no puede gritar', () => {
    const s = reset('zorro');
    tryShout();
    assert.equal(s.karma, 0);
  });
});

describe('ledger de agente IA (ai-behavior-karma 1.1)', () => {
  it('mkAgent inicia karma/pa/owned/lifeLog en cero', () => {
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0 });
    assert.equal(a.karma, 0);
    assert.equal(a.pa, 0);
    assert.deepEqual(a.owned, {});
    assert.deepEqual(a.lifeLog, []);
  });
  it('mkPredator inicia karma/pa en cero', () => {
    const p = mkPredator('zorro', 0, 0, 1);
    assert.equal(p.karma, 0);
    assert.equal(p.pa, 0);
    assert.deepEqual(p.owned, {});
    assert.deepEqual(p.lifeLog, []);
  });
});

describe('addKarma/addPa/record con agente (ai-behavior-karma 1.2-1.4)', () => {
  it('sin agente escriben al jugador como siempre', () => {
    const s = reset();
    addKarma(10, 'prueba');
    addPa(5);
    record('apunte');
    assert.equal(s.karma, 10);
    assert.equal(s.pa, 5);
    assert.ok(s.lifeLog.includes('apunte'));
  });
  it('con agente escriben al agente y no tocan al jugador', () => {
    const s = reset();
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0 });
    addKarma(10, 'prueba IA', 'info', a);
    addPa(7, a);
    record('apunte IA', a);
    assert.equal(a.karma, 10);
    assert.equal(a.pa, 7);
    assert.ok(a.lifeLog.includes('apunte IA'));
    assert.equal(s.karma, 0);
    assert.equal(s.pa, 0);
    assert.ok(!s.lifeLog.includes('apunte IA'));
  });
  it('addKarma con agente acota a [-100,100] y registra con log', () => {
    reset();
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0 });
    addKarma(500, 'buenazo', 'good', a);
    assert.equal(a.karma, 100);
    assert.ok(a.lifeLog.includes('buenazo'));
  });
});

describe('aiTryShout (ai-behavior-karma 1.5)', () => {
  it('ratón IA grita: karma/PA al agente, mates salvados, cd propio', () => {
    const s = reset('raton');
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, brain: 'AI' });
    aiTryShout(a);
    assert.equal(a.karma, TUNING.shoutKarma);
    assert.equal(a.pa, TUNING.shoutPa);
    assert.ok(a.shoutCd > 0);
    assert.ok(companyAgents().every((m) => m.saved));
    assert.equal(s.karma, 0); // el jugador no cobra
  });
  it('zorro IA no puede gritar: sin efecto', () => {
    const s = reset('raton');
    const a = mkAgent({ role: 'fauna', speciesKey: 'zorro', x: 0, y: 0, brain: 'AI' });
    aiTryShout(a);
    assert.equal(a.karma, 0);
    assert.equal(a.pa, 0);
  });
  it('respeta el cooldown del agente', () => {
    reset('raton');
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, brain: 'AI' });
    aiTryShout(a);
    const karma0 = a.karma;
    aiTryShout(a); // cd activo: no-op
    assert.equal(a.karma, karma0);
  });
});

describe('reincarnate', () => {
  it('mismo mundo: lo comido sigue comido y el asesino persiste', () => {
    const s = reset('raton');
    s.bushes[0].amount = 0; s.bushes[0].alive = false; // arrasado
    const killer = { role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro',
      x: 111, y: 222, hp: 120, brain: 'AI' };
    s.agents.push(killer);
    s.carrions.push({ x: 5, y: 5, age: 10 });
    s.dead = true; s.karma = 50; s.pa = 80; s.pendingNext = 'sapo';
    reincarnate();
    const n = S();
    assert.equal(n.speciesKey, 'sapo');
    assert.equal(n.karma, 10);
    assert.equal(n.pa, 80);
    assert.ok(!n.bushes[0].alive); // sigue seco
    assert.ok(n.agents.includes(killer)); // el asesino sigue ahí
    assert.equal(n.carrions[0].age, 10); // la carroña no se reinicia
  });
  it('arrastra 20% karma y todo el PA', () => {
    const s = reset('raton');
    s.dead = true;
    s.karma = 50; s.pa = 80;
    s.pendingNext = 'sapo';
    reincarnate();
    const n = S();
    assert.equal(n.speciesKey, 'sapo');
    assert.equal(n.karma, 10);
    assert.equal(n.pa, 80);
  });
});
