// test/water.test.js - necesidades vitales y agua (vitals-water)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, key, elsById } = require('./harness');

describe('espiral de muerte 60s por arquetipo (7.1)', () => {
  function empty(speciesKey, hp) {
    return { speciesKey, hambre: 0, sed: 0, hp, edad: 0 };
  }
  it('vacio 60s: fragil pierde mas que apice y nadie regen-era', () => {
    const oruga = empty('oruga', 60), raton = empty('raton', 100), lobo = empty('lobo', 160);
    updateNeeds(oruga, 60, 60); updateNeeds(raton, 100, 60); updateNeeds(lobo, 160, 60);
    assert.ok(oruga.hp < 60 && raton.hp < 100 && lobo.hp < 160, 'neto negativo en los tres');
    assert.ok(60 - oruga.hp > 160 - lobo.hp, `oruga pierde mas (${60 - oruga.hp}) que lobo (${160 - lobo.hp})`);
  });
  it('toda especie bajo umbral pierde vida en 60s (regen no compensa)', () => {
    for (const k of Object.keys(SPECIES)) {
      const t = { speciesKey: k, hambre: 10, sed: 10, hp: SPECIES[k].maxHp, edad: 0 };
      updateNeeds(t, SPECIES[k].maxHp, 60);
      assert.ok(t.hp < SPECIES[k].maxHp, `${k} pierde bajo umbral`);
    }
  });
});
describe('campos de necesidad y reset por vida (1.2)', () => {
  it('vida nueva arranca llena de hambre/sed y edad cero', () => {
    const s = reset('raton');
    assert.equal(s.hambre, 100);
    assert.equal(s.sed, 100);
    assert.equal(s.edad, 0);
  });
  it('agente IA nace con necesidades plenas y edad cero', () => {
    reset('raton');
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0 });
    assert.equal(a.hambre, 100);
    assert.equal(a.sed, 100);
    assert.equal(a.edad, 0);
  });
  it('reencarnar resetea necesidades aunque la vida anterior muriera vacia', () => {
    reset('raton');
    const s = S();
    s.hambre = 5; s.sed = 3; s.edad = 120;
    s.dead = true; s.karma = 0; s.pa = 0; s.pendingNext = 'raton';
    reincarnate();
    const n = S();
    assert.equal(n.hambre, 100);
    assert.equal(n.sed, 100);
    assert.equal(n.edad, 0);
  });
});
describe('IA bebe y busca agua (6.1-6.3)', () => {
  function dryWorld(s) {
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
    s.refuges = []; s.rocks = [];
  }
  it('sediento con agua en rango bebe en vez de buscar comida', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    a.hambre = 70; a.sed = 20;
    s.agents = [a];
    s.waters = [{ kind: 'charco', x: 10, y: 0, r: TUNING.charcoR }];
    s.bushes = [mkPatch('berries', 90, 0, 3)]; // comida lejos, agua al lado
    aiRaton(a, 0.2);
    assert.ok(a.sed > 20, `bebio: sed ${a.sed}`);
    assert.equal(s.bushes[0].amount, 3);
  });
  it('sediento sin agua en boca camina al charco en forrajeo', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    a.hambre = 70; a.sed = 20;
    s.agents = [a];
    s.waters = [{ kind: 'charco', x: 90, y: 0, r: TUNING.charcoR }];
    const d0 = Math.hypot(a.x - 90, a.y);
    for (let i = 0; i < 20; i++) updateAgents(0.1);
    assert.ok(Math.hypot(a.x - 90, a.y) < d0, 'se acerco al agua');
  });
  it('hambriento con comida y agua en forrajeo va a la comida', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    a.hambre = 20; a.sed = 80;
    s.agents = [a];
    s.waters = [{ kind: 'charco', x: -90, y: 0, r: TUNING.charcoR }];
    s.bushes = [mkPatch('berries', 90, 0, 3)];
    for (let i = 0; i < 20; i++) updateAgents(0.1);
    assert.ok(Math.hypot(a.x - 90, a.y) < 90, 'fue a la comida');
  });
  it('saciado no viaja al agua (sin bucle de sed junto a la orilla)', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    s.agents = [a];
    s.waters = [{ kind: 'charco', x: 90, y: 0, r: TUNING.charcoR }];
    s.bushes = [mkPatch('berries', -90, 0, 3)];
    for (let i = 0; i < 20; i++) updateAgents(0.1);
    assert.ok(a.x < 40, `no se anclo al agua: x=${a.x}`);
  });
  it('topo sediento no cava teniendo agua a mano', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'topo', x: 0, y: 0, hp: 50 });
    a.hambre = 70; a.sed = 20;
    s.agents = [a];
    s.waters = [{ kind: 'charco', x: 90, y: 0, r: TUNING.charcoR }];
    const refuges0 = s.refuges.length;
    aiTopo(a, 0.2);
    assert.equal(s.refuges.length, refuges0); // no cavo: el agua manda
  });
  it('oculto drena sed y suspende regen salvo doble umbral', () => {
    const s = reset('raton');
    s.hidden = true;
    s.hambre = 90; s.sed = 20; // sed bajo: sin regen
    const hp0 = s.hp;
    update(1);
    assert.ok(S().sed < 20);
    assert.ok(S().hp <= hp0);
    s.hambre = 100; s.sed = 100; s.hp = 50; // doble umbral: regen aunque oculto
    update(1);
    assert.ok(S().hp > 50);
  });
  it('IA oculta drena sed como el hambre', () => {
    const s = reset('raton');
    dryWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 100, y: 100, hp: 50 });
    a.hambre = 20; a.sed = 20;
    a.hidden = true; a.hideT = TUNING.aiHideMax;
    a.hideRef = { type: 'burrow-M', maxSize: 2, x: 100, y: 100 };
    s.agents = [a];
    updateAgents(1);
    assert.ok(a.sed < 20 && a.hambre < 20);
  });
});
describe('HUD de necesidades y avisos (5.1-5.2)', () => {
  it('pinta hambre, sed y edad junto a vida', () => {
    const s = reset('raton');
    s.hambre = 50; s.sed = 70; s.edad = 65;
    updateHud();
    assert.equal(elsById.hungerText.textContent, '50');
    assert.equal(elsById.hungerFill.style.width, '50%');
    assert.equal(elsById.sedText.textContent, '70');
    assert.equal(elsById.sedFill.style.width, '70%');
    assert.ok(elsById.edadLabel.textContent.includes('65'));
  });
  it('marca el umbral y tiñe de corto cuando falta', () => {
    const s = reset('raton');
    s.hambre = 20; s.sed = 80;
    updateHud();
    assert.equal(elsById.hungerMark.style.left, TUNING.regenHambre + '%');
    assert.equal(elsById.sedMark.style.left, TUNING.regenSed + '%');
    assert.ok(elsById.hungerFill.className.includes('low'));
    assert.ok(!elsById.sedFill.className.includes('low'));
  });
  it('oculto avisa que hambre y sed siguen drenando', () => {
    const s = reset('raton');
    s.hidden = true;
    updateHud();
    assert.ok(elsById.prompt.textContent.includes('sed'));
  });
  it('cruzar el umbral avisa una vez; recuperarse rearma', () => {
    const s = reset('raton');
    s.agents = []; // sin mundo: el log solo habla de necesidades
    elsById.log.children.length = 0; // el log es compartido y con tope: parte limpio
    const warns = () => elsById.log.children.filter((c) => (c.innerHTML || '').includes('umbral')).length;
    s.hambre = 31; s.sed = 100;
    update(0.5);
    assert.equal(warns(), 0);
    s.hambre = 29;
    update(0.5);
    assert.equal(warns(), 1);
    update(0.5); // sigue bajo: sin duplicado
    assert.equal(warns(), 1);
    s.hambre = 80; // se recupera: rearma
    update(0.5);
    s.hambre = 29;
    update(0.5);
    assert.equal(warns(), 2);
  });
  it('E sediento deja en el log que bebio agua', () => {
    const s = reset('raton');
    s.waters = [{ kind: 'charco', x: s.px + 10, y: s.py, r: TUNING.charcoR }];
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.insects = []; s.carrions = [];
    s.hambre = 90; s.sed = 10;
    key('e');
    assert.ok(elsById.log.children.some((c) => (c.innerHTML || '').includes('agua')));
  });
});
describe('insectos anclados al lago (4.1-4.2)', () => {
  it('con sesgo total los nuevos insectos nacen en la orilla', () => {
    const s = reset('sapo');
    s.waters = [{ kind: 'lago', x: 1600, y: 1200, r: TUNING.lagoR }];
    s.insects = [];
    const keep = TUNING.lakeInsectBias;
    TUNING.lakeInsectBias = 1;
    try {
      for (let i = 0; i < 5; i++) { s.insectT = TUNING.insectRespawn; ageWorld(0.1); }
    } finally { TUNING.lakeInsectBias = keep; }
    assert.ok(s.insects.length > 0);
    assert.ok(s.insects.every((ins) =>
      Math.hypot(ins.x - 1600, ins.y - 1200) - TUNING.lagoR <= TUNING.lakeShore + 1));
  });
  it('tope y cadencia intactos aunque haya lago', () => {
    const s = reset('sapo');
    s.waters = [{ kind: 'lago', x: 1600, y: 1200, r: TUNING.lagoR }];
    s.insects = [];
    while (s.insects.length < TUNING.insectMax) s.insects.push({ x: 100, y: 100 });
    for (let i = 0; i < 10; i++) { s.insectT = TUNING.insectRespawn; ageWorld(0.1); }
    assert.ok(s.insects.length <= TUNING.insectMax);
  });
  it('insecto de lago paga igual al sapo (+10/+3 y plagas)', () => {
    const s = reset('sapo');
    s.waters = [{ kind: 'lago', x: s.px, y: s.py, r: TUNING.lagoR }];
    s.insects = [{ x: s.px + 5, y: s.py }];
    s.hp = 50; s.hambre = 50;
    key('e');
    assert.equal(S().insects.length, 0);
    assert.ok(S().hp > 50 && S().hambre > 50);
  });
});
describe('E bebe o come por necesidad (3.1-3.3)', () => {
  function pond(s, kind = 'charco') {
    s.waters = [{ kind, x: s.px + 10, y: s.py, r: kind === 'lago' ? TUNING.lagoR : TUNING.charcoR }];
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.insects = []; s.carrions = [];
  }
  it('thirstier: mas sediento que hambriento bebe; al reves come; empate bebe', () => {
    const s = reset('raton');
    s.hambre = 70; s.sed = 20;
    assert.equal(thirstier(), true);
    s.hambre = 20; s.sed = 80;
    assert.equal(thirstier(), false);
    s.hambre = 50; s.sed = 50;
    assert.equal(thirstier(), true);
  });
  it('thirstier vale para agentes IA con su propio ledger', () => {
    reset('raton');
    assert.equal(thirstier({ speciesKey: 'raton', hambre: 70, sed: 20 }), true);
    assert.equal(thirstier({ speciesKey: 'raton', hambre: 20, sed: 80 }), false);
  });
  it('beber recarga sed y sorbe vida sin gastar el agua (infinita)', () => {
    const s = reset('raton');
    pond(s);
    s.sed = 40; s.hp = 50;
    assert.equal(tryDrink(), true);
    assert.ok(S().sed > 40);
    assert.ok(S().hp > 50);
    assert.equal(S().waters.length, 1);
  });
  it('sin agua en rango E no bebe', () => {
    const s = reset('raton');
    s.waters = [];
    assert.equal(tryDrink(), false);
  });
  it('comer recarga hambre ademas de curar (mismo pago de vida)', () => {
    const s = reset('raton');
    s.hambre = 50; s.hp = 50;
    s.bushes = [mkPatch('berries', s.px + 5, s.py, 3)];
    assert.equal(eatPatch(s.bushes[0]), true);
    assert.ok(S().hambre > 50);
    assert.ok(S().hp > 50);
  });
  it('sediento con comida y agua en rango: E bebe, no come', () => {
    const s = reset('raton');
    pond(s);
    s.bushes = [mkPatch('berries', s.px + 5, s.py, 3)];
    s.hambre = 70; s.sed = 20;
    key('e');
    assert.ok(S().sed > 20);
    assert.equal(S().bushes[0].amount, 3);
  });
  it('hambriento con comida y agua en rango: E come, no bebe', () => {
    const s = reset('raton');
    pond(s);
    s.bushes = [mkPatch('berries', s.px + 5, s.py, 3)];
    s.hambre = 20; s.sed = 80;
    const sed0 = s.sed;
    key('e');
    assert.equal(S().bushes[0].amount, 2);
    assert.equal(S().sed, sed0);
  });
  it('zorro con presa a rango ignora el agua y caza', () => {
    const s = reset('zorro');
    pond(s);
    s.sed = 5; s.hambre = 90; // sediento pero con presa
    s.agents = [{ role: 'company', speciesKey: 'raton', x: s.px + 5, y: s.py, hp: 60, saved: false }];
    s.pounceCd = 0;
    key('e');
    assert.ok(S().carrions.length > 0);
  });
  it('halcon bebe aterrizando por la ventana de 1s como con carroña', () => {
    const s = reset('halcon');
    s.agents = []; // sin presas ni cazadores: solo el agua manda
    pond(s, 'lago');
    s.sed = 10; s.hp = 50;
    key('e'); // primer E: aterriza
    assert.ok(S().grounded);
    S().landT = 0;
    key('e'); // segundo E: bebe
    assert.ok(S().sed > 10);
  });
  it('beber en agente IA recarga sin karma ni PA', () => {
    const s = reset('raton');
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    a.sed = 40;
    s.waters = [{ kind: 'charco', x: 5, y: 0, r: TUNING.charcoR }];
    assert.equal(drinkWater(s.waters[0], a), true);
    assert.ok(a.sed > 40 && a.hp > 50);
    assert.equal(a.karma, 0);
    assert.equal(a.pa, 0);
  });
});
describe('agua infinita en el mapa (2.1-2.3)', () => {
  it('siembra charcos chicos y lagos grandes por densidad', () => {
    const s = reset('raton');
    const charcos = s.waters.filter((w) => w.kind === 'charco');
    const lagos = s.waters.filter((w) => w.kind === 'lago');
    assert.equal(charcos.length, scaledCount(TUNING.charcoCount));
    assert.equal(lagos.length, scaledCount(TUNING.lagoCount));
    assert.ok(charcos.every((w) => w.r === TUNING.charcoR));
    assert.ok(lagos.every((w) => w.r === TUNING.lagoR));
    assert.ok(TUNING.lagoR > TUNING.charcoR);
  });
  it('el agua persiste entre vidas en el mismo sitio', () => {
    reset('raton');
    const before = S().waters.map((w) => [w.kind, w.x, w.y, w.r]);
    const s = S();
    s.dead = true; s.karma = 0; s.pa = 0; s.pendingNext = 'raton';
    reincarnate();
    assert.deepEqual(S().waters.map((w) => [w.kind, w.x, w.y, w.r]), before);
  });
  it('dibuja charcos y lagos con glifo propio sin reventar', () => {
    reset('raton');
    assert.ok(waterIcon('charco') !== waterIcon('lago'));
    render();
  });
});
describe('cableado del tick (1.4)', () => {
  it('update con necesidades agotadas drena vida y avanza edad sin tocar PA', () => {
    const s = reset('raton');
    s.hambre = 10; s.sed = 10;
    const hp0 = s.hp, pa0 = s.pa;
    update(1);
    assert.ok(S().hp < hp0, `drena: ${hp0} → ${S().hp}`);
    assert.equal(S().edad, 1);
    assert.ok(S().pa >= pa0);
  });
  it('update saciado regenera hacia el maximo', () => {
    const s = reset('raton');
    s.hp = 50;
    update(1);
    assert.ok(S().hp > 50, `regen: 50 → ${S().hp}`);
  });
  it('juicio intacto: a 0 con necesidades agotadas muere igual', () => {
    const s = reset('raton');
    s.hp = 0.01; s.hambre = 5; s.sed = 5;
    update(1);
    assert.ok(S().dead);
    assert.ok(S().pendingNext);
  });
  it('el loop IA drena necesidades del agente bajo umbral', () => {
    const s = reset('raton');
    s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
    s.clumps = []; s.oaks = []; s.insects = []; s.carrions = [];
    s.refuges = []; s.rocks = [];
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 50 });
    a.hambre = 10; a.sed = 10;
    s.agents = [a];
    updateAgents(1);
    assert.ok(a.hp < 50 && a.edad === 1);
  });
  it('cazador drena necesidades sin efecto en vida (rol de presion intacto)', () => {
    const s = reset('raton');
    s.px = 1000; s.py = 1000;
    const p = mkAgent({ role: 'hunter', ...mkPredator('zorro', 0, 0, 1) });
    s.agents = [p];
    const hp0 = p.hp;
    updatePredators(1);
    assert.ok(p.hambre < 100 && p.sed < 100 && p.edad === 1);
    assert.equal(p.hp, hp0);
  });
});
describe('updateNeeds compartido (1.3)', () => {
  function needs(hambre, sed, hp, edad = 0) {
    return { speciesKey: 'raton', hambre, sed, hp, edad };
  }
  it('saciado e hidratado regenera vida con el tiempo', () => {
    const t = needs(100, 100, 50);
    updateNeeds(t, 100, 10);
    assert.ok(t.hp > 50, `regen: 50 → ${t.hp}`);
  });
  it('necesitado drena vida en vez de regenerar', () => {
    const t = needs(10, 10, 50);
    updateNeeds(t, 100, 10);
    assert.ok(t.hp < 50, `drena: 50 → ${t.hp}`);
  });
  it('mas vacio drena mas rapido (sed igual, hambre 10 vs 50)', () => {
    const full = needs(50, 10, 50), empty = needs(10, 10, 50);
    updateNeeds(full, 100, 10); updateNeeds(empty, 100, 10);
    assert.ok(empty.hp < full.hp, `vacio ${empty.hp} < medio ${full.hp}`);
  });
  it('bajo umbral nunca cura: el dano directo no se compensa', () => {
    const t = needs(10, 10, 50);
    t.hp -= 20; // dano directo (mordisco/ponzona): bypass de necesidades
    const afterHit = t.hp;
    updateNeeds(t, 100, 1);
    assert.ok(t.hp < afterHit, `sigue drenando tras el golpe: ${afterHit} → ${t.hp}`);
  });
  it('la cura topa en el maximo', () => {
    const t = needs(100, 100, 99);
    updateNeeds(t, 100, 60);
    assert.equal(t.hp, 100);
  });
  it('edad avanza monotona sin efecto en la vida', () => {
    const young = needs(100, 100, 50, 0), old = needs(100, 100, 50, 900);
    updateNeeds(young, 100, 10); updateNeeds(old, 100, 10);
    assert.equal(young.hp, old.hp);
    assert.equal(young.edad, 10);
    assert.equal(old.edad, 910);
  });
  it('hambre y sed drenan a ritmo de especie (sed mas rapido)', () => {
    const t = needs(100, 100, 100);
    updateNeeds(t, 100, 10);
    assert.ok(t.sed < t.hambre, `sed ${t.sed} < hambre ${t.hambre}`);
    assert.ok(t.hambre < 100);
  });
});
describe('TUNING de necesidades (1.1)', () => {
  it('umbrales de regen existen y sed exige mas que hambre vacia', () => {
    assert.equal(TUNING.regenHambre, 30);
    assert.equal(TUNING.regenSed, 30);
  });
  it('la sed drena mas rapido que el hambre (x2)', () => {
    assert.equal(TUNING.thirstMult, 2);
    assert.ok(thirstRateFor('raton') > hungerRateFor('raton'));
  });
  it('regen de vida por debajo del peor drenaje (nunca inmortal quieto)', () => {
    const worst = hungerRateFor('raton') * (1 + TUNING.deficitMax);
    assert.ok(TUNING.vidaRegenPerSec < worst);
  });
  it('sorbo documentado: sed + vida pequena', () => {
    assert.ok(TUNING.sipSed > 0 && TUNING.sipHp > 0 && TUNING.sipHp < TUNING.carrionFreshHp);
  });
  it('agua infinita: conteos y radios por tipo (lago mayor que charco)', () => {
    assert.ok(TUNING.lagoCount > 0 && TUNING.charcoCount > 0);
    assert.ok(TUNING.lagoR > TUNING.charcoR);
    assert.ok(TUNING.drinkRange > 0);
  });
  it('insectos anclados al lago: probabilidad y alcance de orilla', () => {
    assert.ok(TUNING.lakeInsectBias > 0 && TUNING.lakeInsectBias < 1);
    assert.ok(TUNING.lakeShore > 0);
  });
});
