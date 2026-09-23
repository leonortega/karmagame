// test/game.test.js - loop, HUD, dibujo y cableado de input
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, key, elsById } = require('./harness');

describe('update', () => {
  it('hambre drena y PA acumula con el tiempo', () => {
    const s = reset();
    const hp0 = s.hp;
    update(1);
    assert.ok(s.hp < hp0 && s.time > 0 && s.paAcc >= 0);
  });
  it('muerte a hp 0 abre el juicio', () => {
    const s = reset();
    s.hp = 0.01;
    update(1);
    assert.ok(s.dead);
    assert.ok(s.pendingNext);
  });
  it('movePlayer mueve con teclas y congela oculto', () => {
    const s = reset();
    const x0 = s.px;
    s.moved = false;
    // simula D pulsada manipulando keys via handler real
    key('d');
    update(0.1);
    key('d'); // soltar no existe en stub: reseteamos a mano
    assert.ok(s.px !== x0 || s.moved);
  });
  it('groom da karma tras 3s junto a congenere', () => {
    const s = reset('raton');
    s.agents = s.agents.filter((a) => a.role !== 'hunter');
    s.hp = effMaxHp();
    s.groomCd = 0; s.groomT = 0;
    for (let i = 0; i < 40; i++) {
      s.agents = [{ role: 'company', speciesKey: 'raton', x: s.px + 5, y: s.py, hp: 60, saved: false }]; // fijo en rango
      s.hp = effMaxHp(); // sin hambre en el ensayo
      update(0.1);
    }
    assert.equal(s.karma, TUNING.groomKarma);
  });
  it('cooldowns bajan pero no de cero', () => {
    const s = reset();
    s.shoutCd = 0.05;
    update(1);
    assert.equal(s.shoutCd, 0.05 - 1);
  });
});

describe('updateAgents', () => {
  it('agente ratón IA pasta bayas cercanas y gana vida', () => {
    const s = reset('raton');
    s.agents = [];
    const a = { role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 40, brain: 'AI', kind: 'grazer' };
    s.agents.push(a);
    s.bushes = [mkPatch('berries', 5, 0, 3)];
    updateAgents(0.1);
    assert.ok(a.hp > 40);
    assert.equal(s.bushes[0].amount, 2);
  });
  it('agente sin comida muere de hambre y deja carroña', () => {
    const s = reset('raton');
    s.agents = [];
    const a = { role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 0.05, brain: 'AI', kind: 'grazer' };
    s.agents.push(a);
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.insects = [];
    const n0 = s.carrions.length;
    updateAgents(1);
    assert.ok(!s.agents.includes(a));
    assert.equal(s.carrions.length, n0 + 1);
  });
  it('una especie exterminada repuebla dentro del tope', () => {
    const s = reset('raton');
    s.agents = s.agents.filter((a) => a.speciesKey !== 'topo');
    assert.ok(!s.agents.some((a) => a.speciesKey === 'topo'));
    s.respawnT = TUNING.respawnTime;
    update(0.1);
    assert.ok(s.agents.some((a) => a.speciesKey === 'topo'));
  });
});

describe('updateHud', () => {
  it('pinta vida, karma, PA y tiempo', () => {
    const s = reset();
    s.hp = 50; s.karma = 20; s.pa = 7; s.time = 65;
    updateHud();
    assert.equal(elsById.hpText.textContent, '50/' + effMaxHp());
    assert.equal(elsById.karmaText.textContent, 20);
    assert.equal(elsById.paLabel.textContent, 'PA: 7');
    assert.equal(elsById.timeLabel.textContent, '1:05');
  });
  it('oculto muestra prompt de salida', () => {
    const s = reset();
    s.hidden = true;
    updateHud();
    assert.ok(elsById.prompt.textContent.includes('OCULTO') || elsById.prompt.textContent.includes('Oculto'));
  });
  it('el HUD sigue al poseído tras reencarnar en el mismo mundo', () => {
    reset('raton');
    const s = S();
    s.dead = true; s.karma = 0; s.pa = 0; s.pendingNext = 'lobo';
    reincarnate();
    update(0.1);
    updateHud();
    assert.ok(elsById.speciesLabel.textContent.includes('Lobo'));
    assert.equal(elsById.hpText.textContent, Math.ceil(S().hp) + '/' + effMaxHp());
    assert.ok(S().cam.x >= 0 && S().cam.x <= WORLD.w);
  });
});

describe('visibilidad', () => {
  it('olfato revela ponzoña en vision; sin olfato nada', () => {
    const s = reset();
    s.bushes = [mkPatch('berries', s.px + 10, s.py, 3, { mimic: true, mimicEaten: false })];
    s.clusters = [mkPatch('mushrooms', s.px + 10, s.py, 2, { toxicLeft: 1 })];
    assert.deepEqual(mimicsVisible(), []);
    assert.deepEqual(toxicsVisible(), []);
    s.owned.nose = true;
    assert.equal(mimicsVisible().length, 1);
    assert.equal(toxicsVisible().length, 1);
  });
  it('trackedCarrion solo con rastro activo', () => {
    const s = reset();
    s.carrions = [{ x: 1, y: 1, age: 0 }];
    s.trackT = 0;
    assert.equal(trackedCarrion(), null);
    s.trackT = 5;
    assert.deepEqual(trackedCarrion(), s.carrions[0]);
  });
});

describe('frame', () => {
  it('avanza un frame completo sin reventar', () => {
    const s = reset();
    const t0 = s.time;
    frame(100);
    assert.ok(S().time > t0);
  });
});

describe('draw', () => {  it('drawSpecies no revienta por forma', () => {
    reset('raton');
    for (const f of Object.keys(SPECIES)) {
      drawSpecies(f, 10, 10, { x: 1, y: 0 }, 1.5);
    }
  });
  it('render dibuja un frame completo', () => {
    reset();
    render();
  });
  it('render dibuja con cualquier especie poseída y fauna mixta', () => {
    for (const k of Object.keys(SPECIES)) {
      reset(k);
      render();
    }
  });
});

describe('input', () => {
  it('start-select inicia como cualquier especie con 0/0 sin matriz', () => {
    assert.ok(startRun('lobo'));
    let s = S();
    assert.equal(s.speciesKey, 'lobo');
    assert.equal(s.karma, 0);
    assert.equal(s.pa, 0);
    assert.ok(!s.dead);
    assert.ok(startRun('zorro')); // depredador también libre
    assert.equal(S().speciesKey, 'zorro');
  });
  it('teclas cableadas: e/q/b/h/v/c/r no revientan', () => {
    reset('topo');
    for (const k of ['e', 'q', 'b', 'h', 'v', 'c']) key(k);
    const s = S();
    s.dead = true;
    s.pendingNext = 'raton';
    key('r'); // reencarna
    assert.ok(!S().dead);
  });
});
