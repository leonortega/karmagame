// test/verb.test.js - barra de verbos 1-5 por especie (species-locomotion-verbs, karma-verbs)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, key, keyUp } = require('./harness');

function clearWorld(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
  s.refuges = []; s.rocks = [];
  s.agents = s.agents.filter(a => a.role !== 'hunter' && a.role !== 'company');
}

describe('VERB_DEFS: 5 verbos × 8 especies (2.1)', () => {
  it('cada especie tiene exactamente 5 verbos en slots 1..5 con datos completos', () => {
    assert.equal(Object.keys(VERB_DEFS).length, 8);
    for (const sp of Object.keys(VERB_DEFS)) {
      const defs = VERB_DEFS[sp];
      assert.equal(defs.length, 5, `${sp} tiene 5 verbos`);
      defs.forEach((v, i) => {
        assert.equal(v.slot, i + 1, `${sp} slot ${i + 1} en orden`);
        assert.ok(v.id && v.name && v.desc, `${sp}#${v.slot} con id/name/desc`);
        assert.ok(v.cd > 0, `${sp}#${v.slot} con cooldown`);
        assert.ok(v.costHp >= 0 && v.costPa >= 0, `${sp}#${v.slot} costes declarados`);
      });
    }
  });
});

describe('castVerb: costes, cooldown y efecto (2.2)', () => {
  it('topo slot 1 airea: +3 karma, madriguera creada, cd puesto (migrado con valor intacto)', () => {
    const s = reset('topo');
    clearWorld(s);
    s.dug = 0;
    castVerb(1);
    assert.equal(s.karma, TUNING.aerateKarma, 'karma de aireado intacto');
    assert.ok(s.refuges.some(r => r.type === 'burrow-M' && r.dug), 'refugio creado');
    assert.equal(s.verbCds[0], VERB_DEFS.topo[0].cd, 'cooldown del verbo puesto');
  });
  it('verbo en cooldown no se lanza', () => {
    const s = reset('topo');
    clearWorld(s);
    castVerb(1);
    const k1 = s.karma;
    castVerb(1); // aún en cd
    assert.equal(s.karma, k1, 'sin doble efecto en cd');
  });
});

describe('enrutado de teclas (2.3)', () => {
  it('con la tienda abierta, 2 compra y no lanza verbo', () => {
    const s = reset('raton');
    s.pa = 50;
    s.shopOpen = true;
    key('2');
    assert.ok(s.owned.stomach, 'la tienda vende como siempre');
    assert.equal(s.karma, 0, 'ningún verbo lanzado');
  });
  it('con la tienda cerrada, 1 lanza el verbo del slot 1 (ratón: alarma +30)', () => {
    const s = reset('raton');
    clearWorld(s);
    key('1');
    assert.equal(s.karma, TUNING.shoutKarma, 'alarma con valor de grito intacto');
    assert.ok(s.verbCds[0] > 0, 'cd del verbo');
  });
  it('muerto no lanza nada', () => {
    const s = reset('raton');
    clearWorld(s);
    s.dead = true;
    key('1');
    assert.equal(s.karma, 0);
  });
  it('un coste que deja la vida a 0 lleva al juicio (2.4)', () => {
    const s = reset('oruga');
    clearWorld(s);
    s.px = 500; s.py = 500;
    s.agents = [{ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 520, y: 500, hp: 120 }];
    s.hp = 4; // el coste de la seda (8) supera la vida restante: el verbo ocurre y el coste mata
    castVerb(2);
    assert.ok(s.hp <= 0, `el coste drenó la vida: hp=${s.hp}`);
    update(1); // el bucle normal detecta vida 0
    assert.ok(s.dead, 'el juicio se abre como con cualquier muerte');
  });
  it('sin cazador cerca la seda no se paga (contexto imposible: ni coste ni cd)', () => {
    const s = reset('oruga');
    clearWorld(s);
    const hp0 = s.hp;
    assert.equal(castVerb(2), false);
    assert.equal(s.hp, hp0, 'sin coste');
    assert.equal(s.verbCds[1], 0, 'sin cooldown');
  });
});

describe('migraciones del jugador: mismos valores, una sola implementación (3.1-3.2)', () => {
  it('ratón 1 delega en el grito: +30 karma, +50 PA, señuelo (nada se pierde en la migración)', () => {
    const s = reset('raton');
    clearWorld(s);
    key('1');
    assert.equal(s.karma, TUNING.shoutKarma);
    assert.equal(s.pa, TUNING.shoutPa, 'el PA del grito sobrevive a la migración');
    assert.ok(s.lureTimer > 0, 'el señuelo también');
  });
  it('topo 1 delega en cavar: respeta el tope digMax y el cd propio', () => {
    const s = reset('topo');
    clearWorld(s);
    s.dug = TUNING.digMax; s.digCd = 0;
    const n0 = s.refuges.length;
    assert.equal(castVerb(1), false, 'al tope no se cava');
    assert.equal(s.refuges.length, n0);
  });
  it('zorro 3 cede carroña por +15 sin comerla (valor intacto)', () => {
    const s = reset('zorro');
    clearWorld(s);
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    assert.equal(castVerb(3), true);
    assert.equal(s.karma, TUNING.cedeKarma);
    assert.equal(s.carrions.length, 1, 'la carroña queda');
    assert.ok(s.carrions[0].ceded);
  });
  it('zorro 1 salta a la presa cercana: mata por necesidad y deja carroña', () => {
    const s = reset('zorro');
    clearWorld(s);
    s.hp = 10; // caza necesaria: sin mancha de deporte
    s.agents = [mkAgent({ role: 'company', speciesKey: 'raton', x: s.px + 20, y: s.py, hp: 60, saved: false })];
    const c0 = s.carrions.length;
    assert.equal(castVerb(1), true);
    assert.equal(s.carrions.length, c0 + 1);
    assert.ok(s.pounceCd > 0);
  });
  it('halcón 1 pica contra otro depredador cercano (+5 por zorro)', () => {
    const s = reset('halcon');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 30, y: s.py, hp: 120 })];
    assert.equal(castVerb(1), true);
    assert.equal(s.karma, TUNING.strikeKarma);
    assert.ok(s.strikeCd > 0);
  });
  it('sapo 2 devora un insecto y cobra control de plagas +3', () => {
    const s = reset('sapo');
    clearWorld(s);
    s.insects = [{ x: s.px + 5, y: s.py }];
    assert.equal(castVerb(2), true);
    assert.equal(s.insects.length, 0);
    assert.equal(s.karma, TUNING.pestKarma);
  });
  it('oruga 1 mordisco prudente: +2 si deja hojas en la mata', () => {
    const s = reset('oruga');
    clearWorld(s);
    s.clumps = [mkPatch('leaves', s.px + 5, s.py, 3, { regrowT: 0 })];
    assert.equal(castVerb(1), true);
    assert.equal(s.clumps[0].amount, 2);
    assert.equal(s.karma, TUNING.prudentKarma);
  });
  it('ardilla 2 planta la nuez que lleva: +10, retoño y banco intacto', () => {
    const s = reset('ardilla');
    clearWorld(s);
    s.carriedNut = true;
    assert.equal(castVerb(2), true);
    assert.equal(s.karma, TUNING.plantKarma);
    assert.equal(s.saplings, 1);
    assert.ok(s.seedlings.some(x => x.kind === 'oak-tree'));
  });
  it('acicala social instantánea: +2 con congénere cerca, nada sin él', () => {
    const s = reset('raton');
    clearWorld(s);
    assert.equal(castVerb(3), false, 'nadie a quien acicalar');
    s.agents = [mkAgent({ role: 'company', speciesKey: 'raton', x: s.px + 5, y: s.py, hp: 60, saved: false })];
    assert.equal(castVerb(3), true);
    assert.equal(s.karma, TUNING.groomSocialKarma);
  });
});
