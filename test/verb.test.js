// test/verb.test.js - barra de verbos 1-5 por especie (species-locomotion-verbs, karma-verbs)
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, key, keyUp } = require('./harness');

function clearWorld(s) {
  s.bushes = []; s.shrubs = []; s.patches = []; s.clusters = [];
  s.clumps = []; s.oaks = []; s.seedlings = []; s.carrions = []; s.insects = [];
  s.refuges = []; s.rocks = []; s.waters = []; // sin agua: la E no bebe por empate
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
    s.pa = 100;
    s.shopOpen = true;
    key('2');
    assert.ok(s.owned.raton_ojeada, 'la tienda vende su catálogo');
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
    s.agents = []; // sin cazadores en el mapa: la premisa no depende del azar
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
describe('castVerbFor + aiMaybeVerb (3.3)', () => {
  it('castVerbFor ejecuta alarma en rata IA: karma/PA al ledger y cd propio', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 60 });
    s.agents = [a, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 100, y: 0, hp: 120 })];
    assert.equal(castVerbFor(a, 1), true);
    assert.equal(a.karma, TUNING.shoutKarma);
    assert.equal(a.pa, TUNING.shoutPa);
    assert.ok(a.shoutCd > 0);
  });
  it('castVerbFor con verbo sin implementar no cobra ni enfria', () => {
    const s = reset('sapo');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 60 });
    s.agents = [a];
    assert.equal(castVerbFor(a, 4), false); // toxin llega en 4.1
    assert.equal(a.hp, 60);
    assert.equal(a.pa, 0);
  });
  it('aiMaybeVerb topo cava por el nucleo (madriguera + karma)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'topo', x: 0, y: 0, hp: 60 });
    s.agents = [a];
    const n0 = s.refuges.length;
    assert.equal(aiMaybeVerb(a, 0.2), true);
    assert.equal(s.refuges.length, n0 + 1);
    assert.equal(a.karma, TUNING.aerateKarma);
  });
  it('aiMaybeVerb ardilla planta por el nucleo (+10 y brote)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'ardilla', x: 0, y: 0, hp: 60 });
    a.carriedNut = true;
    s.agents = [a];
    assert.equal(aiMaybeVerb(a, 0.2), true);
    assert.equal(a.karma, TUNING.plantKarma);
    assert.ok(s.seedlings.some((x) => x.kind === 'oak-tree'));
  });
  it('aiMaybeVerb zorro saciado cede por el nucleo; sin saciar no', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'zorro', x: 0, y: 0, hp: 60 });
    s.agents = [a];
    s.carrions = [{ x: 5, y: 0, age: 0 }];
    assert.equal(aiMaybeVerb(a, 0.2), false, 'sin saciar no cede');
    a.satedT = TUNING.satedTime;
    assert.equal(aiMaybeVerb(a, 0.2), true);
    assert.equal(a.karma, TUNING.cedeKarma);
    assert.equal(s.carrions.length, 1, 'la carroña queda');
  });
  it('strike del jugador: zorro ahuyenta (+5), ante lobo hazaña (+20)', () => {
    const s = reset('zorro');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 30, y: s.py, hp: 120 })];
    assert.equal(castVerb(5), true);
    assert.equal(s.karma, TUNING.strikeKarma);
    assert.ok(s.strikeCd > 0);
    const s2 = reset('lobo');
    clearWorld(s2);
    s2.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'lobo', speciesKey: 'lobo', x: s2.px + 30, y: s2.py, hp: 160 })];
    assert.equal(castVerb(3), true);
    assert.equal(S().karma, TUNING.loboStrikeKarma);
  });
  it('verbo IA respeta cooldown: toxina dos veces seguidas no repite', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 60 });
    a.shoutCd = TUNING.shoutCooldown; // sin grito: el señuelo no teletransporta al cazador
    s.agents = [a, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 30, y: 0, hp: 120 })];
    assert.equal(castVerbFor(a, 4), true);
    assert.equal(castVerbFor(a, 4), false, 'en cooldown no repite ni cobra');
    s.agents = [a]; // sin cazador: tickea sin gritos ni señuelos
    aiBase(a, VERB_DEFS.sapo[3].cd); // tickea cds propios
    s.agents = [a, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 30, y: 0, hp: 120 })];
    assert.equal(castVerbFor(a, 4), true, 'tras el cd vuelve a valer');
  });
  it('aiMaybeVerb sin regla (sapo hasta 4.1) no ocupa el tick', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 60 });
    s.agents = [a];
    assert.equal(aiMaybeVerb(a, 0.2), false);
  });
});
describe('sapo: croak, burrow-in, toxin, chorus (4.1)', () => {
  it('sapo 1 croa como alarma (+30.jugador)', () => {
    const s = reset('sapo');
    clearWorld(s);
    assert.equal(castVerb(1), true);
    assert.equal(s.karma, TUNING.shoutKarma);
  });
  it('burrow-in entierra sin refugio; H sale', () => {
    const s = reset('sapo');
    clearWorld(s);
    assert.equal(castVerb(3), true);
    assert.ok(S().hidden && !S().hideRef);
    toggleHide();
    assert.ok(!S().hidden);
  });
  it('toxin corta la caceria cercana (+karma, cuesta vida); sin depredador nada', () => {
    const s = reset('sapo');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 30, y: s.py, hp: 120 })];
    const hp0 = s.hp;
    assert.equal(castVerb(4), true);
    assert.equal(s.karma, TUNING.toxinKarma);
    assert.ok(s.hp < hp0, 'el coste hp se cobra');
    assert.ok(s.agents[0].restT > 0, 'el zorro descansa: caza rota');
    const s2 = reset('sapo');
    clearWorld(s2);
    const hp02 = s2.hp;
    assert.equal(castVerb(4), false);
    assert.equal(S().hp, hp02);
  });
  it('coro con dos cantores paga doble; solo no hay coro', () => {
    const s = reset('sapo');
    clearWorld(s);
    assert.equal(castVerb(5), false, 'solo no hay coro');
    s.agents = [mkAgent({ role: 'company', speciesKey: 'sapo', x: s.px + 5, y: s.py, hp: 60, saved: false })];
    assert.equal(castVerb(5), true);
    assert.equal(s.karma, TUNING.chorusKarma * 2);
  });
  it('IA sapo acorralada sin refugio se entierra por el nucleo', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 60 });
    s.agents = [a, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 100, y: 0, hp: 120 })];
    s.refuges = [];
    aiSapo(a, 0.2);
    assert.ok(a.hidden, 'burrow-in por aiMaybeVerb');
  });
  it('IA sapo con depredador encima usa toxina (ledger propio)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'sapo', x: 0, y: 0, hp: 60 });
    a.shoutCd = TUNING.shoutCooldown; // sin grito: aísla la toxina
    const z = mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 30, y: 0, hp: 120 });
    s.agents = [a, z];
    s.refuges = [];
    aiSapo(a, 0.2);
    assert.equal(a.karma, TUNING.toxinKarma);
    assert.ok(z.restT > 0);
  });
});
describe('oruga: nectar, leafroll, bristle (4.2)', () => {
  it('nectar atrae aliada que distrae (+karma, insecto nuevo, caza rota)', () => {
    const s = reset('oruga');
    clearWorld(s);
    s.pa = 50;
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 100, y: s.py, hp: 120 })];
    const n0 = s.insects.length;
    assert.equal(castVerb(3), true);
    assert.equal(s.karma, TUNING.nectarKarma);
    assert.equal(s.insects.length, n0 + 1, 'aliada invocada');
    assert.ok(s.agents[0].restT > 0, 'caza distraida');
    assert.ok(s.pa < 50, 'el PA se cobra');
  });
  it('nectar sin depredador o sin PA no ocurre', () => {
    const s = reset('oruga');
    clearWorld(s);
    s.pa = 50;
    assert.equal(castVerb(3), false);
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 100, y: s.py, hp: 120 })];
    s.pa = 0;
    assert.equal(castVerb(3), false, 'sin PA no hay nectar');
  });
  it('leafroll enrolla refugio junto a mata (+karma, oruga-only, temporal)', () => {
    const s = reset('oruga');
    clearWorld(s);
    s.clumps = [mkPatch('leaves', s.px + 10, s.py, 3, { regrowT: 0 })];
    assert.equal(castVerb(4), true);
    const r = S().refuges.find((x) => x.type === 'leafroll');
    assert.ok(r && r.orugaOnly, 'refugio propio');
    assert.equal(s.karma, TUNING.leafrollKarma);
    r.ttl = 0.05;
    ageWorld(0.1);
    assert.ok(!S().refuges.includes(r), 'temporal: caduca');
  });
  it('leafroll lejos de matas no ocurre', () => {
    const s = reset('oruga');
    clearWorld(s);
    assert.equal(castVerb(4), false);
  });
  it('bristle revierte el proximo zarpazo (sin dano, dano al cazador, se consume)', () => {
    const s = reset('oruga');
    clearWorld(s);
    assert.equal(castVerb(5), true);
    assert.ok(S().bristled);
    const z = mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 5, y: s.py, hp: 120 });
    s.agents = [z];
    s.invuln = 0;
    const hp0 = s.hp, zhp0 = z.hp;
    updatePredators(0.1);
    assert.equal(S().hp, hp0, 'ni un rasguño');
    assert.ok(z.hp < zhp0, 'el zarpazo se revierte');
    assert.ok(!S().bristled, 'se consume');
  });
  it('IA oruga acosada usa seda (huye por el nucleo)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'oruga', x: 200, y: 200, hp: 60 });
    s.agents = [a, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 300, y: 200, hp: 120 })];
    s.refuges = [];
    aiOruga(a, 0.2);
    assert.ok(a.x < 200, `seda: x=${a.x}`);
  });
  it('IA oruga en calma junto a mata enrolla hoja', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'oruga', x: 0, y: 0, hp: 60 });
    s.agents = [a];
    s.clumps = [mkPatch('leaves', 10, 0, 0, { regrowT: 0 })]; // pelada: no come, sí cobija
    aiOruga(a, 0.2);
    assert.ok(s.refuges.some((r) => r.type === 'leafroll'));
    assert.equal(a.karma, TUNING.leafrollKarma);
  });
});
describe('raton: seedcache, scout, share-bite (4.3)', () => {
  it('seedcache entierra semilla sin tocar la ultima (+karma lite, brote)', () => {
    const s = reset('raton');
    clearWorld(s);
    s.bushes = [mkPatch('berries', s.px + 5, s.py, 3)];
    const keep = TUNING.seedSproutChance;
    TUNING.seedSproutChance = 1;
    try {
      assert.equal(castVerb(2), true);
    } finally { TUNING.seedSproutChance = keep; }
    assert.equal(S().bushes[0].amount, 2);
    assert.equal(s.karma, TUNING.seedCacheKarma);
    assert.ok(S().seedlings.length > 0, 'semilla bancada');
  });
  it('seedcache nunca entierra la ultima fruta', () => {
    const s = reset('raton');
    clearWorld(s);
    s.bushes = [mkPatch('berries', s.px + 5, s.py, 1)];
    assert.equal(castVerb(2), false);
    assert.equal(S().bushes[0].amount, 1);
  });
  it('scout revela peligro y agua (+karma prudente, cuesta PA)', () => {
    const s = reset('raton');
    clearWorld(s);
    s.pa = 50;
    assert.equal(castVerb(4), true);
    assert.ok(S().revealT > 0);
    assert.equal(s.karma, TUNING.prudentKarma);
    const s2 = reset('raton');
    clearWorld(s2);
    s2.pa = 0;
    assert.equal(castVerb(4), false, 'sin PA no hay ojeada');
  });
  it('share-bite alimenta al hambriento (hambre manda, cuesta vida, +karma)', () => {
    const s = reset('raton');
    clearWorld(s);
    s.hp = 80;
    const m = mkAgent({ role: 'company', speciesKey: 'raton', x: s.px + 5, y: s.py, hp: 40, saved: false });
    m.hambre = 10;
    s.agents = [m];
    assert.equal(castVerb(5), true);
    assert.ok(m.hp > 40 && m.hambre > 10, 'el hambriento se recupera');
    assert.equal(S().hp, 80 - TUNING.shareBiteHp, 'compartir cuesta');
    assert.equal(s.karma, TUNING.shareKarma);
  });
  it('share-bite sin hambriento u sin resto no ocurre', () => {
    const s = reset('raton');
    clearWorld(s);
    s.hp = 80;
    const m = mkAgent({ role: 'company', speciesKey: 'raton', x: s.px + 5, y: s.py, hp: 40, saved: false });
    m.hambre = 90;
    s.agents = [m];
    assert.equal(castVerb(5), false, 'saciado no necesita');
    m.hambre = 10;
    s.hp = 10;
    assert.equal(castVerb(5), false, 'sin resto no se comparte');
  });
  it('IA raton comparte con hambriento por el nucleo', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'raton', x: 0, y: 0, hp: 90 });
    const m = mkAgent({ role: 'company', speciesKey: 'raton', x: 5, y: 0, hp: 40, saved: false });
    m.hambre = 10;
    s.agents = [a, m];
    aiRaton(a, 0.2);
    assert.equal(a.karma, TUNING.shareKarma);
    assert.ok(m.hp > 40 && m.hambre > 10);
  });
});
describe('ardilla: tailflick, falsecache, bark (4.4)', () => {
  it('tailflick avisa sin cebo (+karma menor, sin señuelo ni PA)', () => {
    const s = reset('ardilla');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'company', speciesKey: 'ardilla', x: s.px + 5, y: s.py, hp: 60, saved: false })];
    const pa0 = s.pa;
    assert.equal(castVerb(1), true);
    assert.equal(s.karma, TUNING.tailflickKarma);
    assert.equal(s.lureTimer, 0, 'sin cebo');
    assert.equal(s.pa, pa0, 'sin PA');
    assert.ok(s.agents[0].saved, 'avisa a los cercanos');
  });
  it('falsecache engaña al cazador (descansa, +karma); sin cazador nada', () => {
    const s = reset('ardilla');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 100, y: s.py, hp: 120 })];
    assert.equal(castVerb(3), true);
    assert.equal(s.karma, TUNING.falseCacheKarma);
    assert.ok(s.agents[0].restT > 0, 'pierde el tiempo');
    const s2 = reset('ardilla');
    clearWorld(s2);
    assert.equal(castVerb(3), false);
  });
  it('bark cosecha sin comer (+PA, karma menor, nuez intacta)', () => {
    const s = reset('ardilla');
    clearWorld(s);
    s.oaks = [mkPatch('nuts', s.px + 10, s.py, 3)];
    s.pa = 0;
    assert.equal(castVerb(4), true);
    assert.equal(s.pa, TUNING.barkPa);
    assert.equal(s.karma, TUNING.barkKarma);
    assert.equal(S().oaks[0].amount, 3, 'sin comer');
  });
  it('IA ardilla sin grito usa cola (backup sin señuelo)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'ardilla', x: 0, y: 0, hp: 60 });
    a.shoutCd = TUNING.shoutCooldown; // grito no listo: toca cola
    const m = mkAgent({ role: 'company', speciesKey: 'ardilla', x: 5, y: 0, hp: 60, saved: false });
    s.agents = [a, m, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 100, y: 0, hp: 120 })];
    aiMaybeVerb(a, 0.2);
    assert.equal(a.karma, TUNING.tailflickKarma);
    assert.ok(!a.lureTimer, 'sin cebo');
  });
  it('IA ardilla engaña al cercano y cosecha tras plantar (cd)', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'ardilla', x: 0, y: 0, hp: 60 });
    const z = mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: 100, y: 0, hp: 120 });
    s.agents = [a, z];
    aiMaybeVerb(a, 0.2);
    assert.equal(a.karma, TUNING.falseCacheKarma);
    assert.ok(z.restT > 0);
    const s2 = reset('raton');
    clearWorld(s2);
    const b = mkAgent({ role: 'fauna', speciesKey: 'ardilla', x: 0, y: 0, hp: 60 });
    s2.agents = [b];
    s2.oaks = [mkPatch('nuts', 5, 0, 3)];
    aiMaybeVerb(b, 0.2);
    assert.equal(b.karma, TUNING.barkKarma, 'corteza antes que despensa');
    assert.equal(s2.oaks[0].amount, 3);
  });
});
describe('topo: tunneline, worm, larder, nestdig (4.5)', () => {
  function dugNear(s, x = null) {
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: x ?? s.px + 10, y: s.py, dug: true }];
  }
  it('tunneline refuerza lo cavado (+karma); sin madriguera nada', () => {
    const s = reset('topo');
    clearWorld(s);
    assert.equal(castVerb(2), false);
    dugNear(s);
    assert.equal(castVerb(2), true);
    assert.ok(S().refuges[0].firm, 'refuerzo marcado');
    assert.equal(s.karma, TUNING.aerateKarma);
  });
  it('worm rescata lombriz en tierra fresca (+vida/+PA/+hambre); sin ella nada', () => {
    const s = reset('topo');
    clearWorld(s);
    s.hp = 50; s.hambre = 50; s.pa = 0;
    assert.equal(castVerb(3), false);
    dugNear(s);
    assert.equal(castVerb(3), true);
    assert.ok(S().hp > 50 && S().hambre > 50);
    assert.equal(s.pa, TUNING.wormPa);
  });
  it('larder guarda, come y comparte (capacidad 1)', () => {
    const s = reset('topo');
    clearWorld(s);
    s.hp = 50; s.hambre = 50;
    s.insects = [{ x: s.px + 5, y: s.py }];
    assert.equal(castVerb(4), true, 'guarda');
    assert.equal(S().larder, 1);
    assert.equal(S().insects.length, 0, 'el bicho va a la despensa, no a la boca');
    assert.equal(S().hp, 50, 'guardar no alimenta');
    s.hambre = 10; // hambriento para comer lo guardado
    s.verbCds = [0, 0, 0, 0, 0]; // cd cumplido entre pulsaciones
    assert.equal(castVerb(4), true, 'come lo guardado');
    assert.equal(S().larder, 0);
    assert.ok(S().hp > 50 && S().hambre > 10, 'lo guardado alimenta');
  });
  it('larder comparte con hambriento (+karma, el otro come)', () => {
    const s = reset('topo');
    clearWorld(s);
    s.larder = 1;
    const m = mkAgent({ role: 'company', speciesKey: 'topo', x: s.px + 5, y: s.py, hp: 40, saved: false });
    m.hambre = 10;
    s.agents = [m];
    assert.equal(castVerb(4), true);
    assert.equal(S().larder, 0);
    assert.ok(m.hp > 40 && m.hambre > 10);
    assert.equal(s.karma, TUNING.shareKarma);
  });
  it('nestdig cava extra sin tope (cuesta vida); con cd no', () => {
    const s = reset('topo');
    clearWorld(s);
    s.dug = TUNING.digMax; s.digCd = 0;
    const hp0 = s.hp, n0 = s.refuges.length;
    assert.equal(castVerb(5), true, 'extra aunque al tope');
    assert.equal(S().refuges.length, n0 + 1);
    assert.ok(S().hp < hp0, 'cuesta vida');
    assert.equal(castVerb(5), false, 'con cd no repite');
  });
  it('IA topo hambrienta con tierra fresca rescata lombriz', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'topo', x: 0, y: 0, hp: 30 });
    a.hambre = 20; a.sed = 80;
    s.agents = [a];
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: 10, y: 0, dug: true }];
    aiTopo(a, 0.2);
    assert.ok(a.hp > 30 && a.hambre > 20, 'lombriz por el nucleo');
  });
  it('IA topo saciada refuerza en vez de cavar de nuevo', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'topo', x: 0, y: 0, hp: 90 });
    s.agents = [a];
    s.refuges = [{ type: 'burrow-M', maxSize: 2, climbOnly: false, x: 10, y: 0, dug: true }];
    const n0 = s.refuges.length;
    aiTopo(a, 0.2);
    assert.equal(s.refuges.length, n0, 'no cava: refuerza');
    assert.ok(s.refuges[0].firm);
    assert.equal(a.karma, TUNING.aerateKarma);
  });
});
describe('halcon: thermal, courtesy, scare, bone (4.6)', () => {
  it('thermal sube vision breve (cuesta PA); sin PA nada', () => {
    const s = reset('halcon');
    clearWorld(s);
    s.pa = 50;
    const v0 = effVision();
    assert.equal(castVerb(2), true);
    assert.ok(S().thermalT > 0);
    assert.ok(effVision() > v0, 'ojo de águila');
    const s2 = reset('halcon');
    clearWorld(s2);
    s2.pa = 0;
    assert.equal(castVerb(2), false);
  });
  it('courtesy comparte carroña fresca (+karma, la deja)', () => {
    const s = reset('halcon');
    clearWorld(s);
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    assert.equal(castVerb(3), true);
    assert.equal(s.karma, TUNING.cedeKarma);
    assert.equal(S().carrions.length, 1, 'la deja');
    assert.ok(S().carrions[0].ceded, 'marcada compartida');
    const s2 = reset('halcon');
    clearWorld(s2);
    assert.equal(castVerb(3), false, 'sin carroña nada');
  });
  it('scare dispersa sin matar (+karma, sin carroña)', () => {
    const s = reset('halcon');
    clearWorld(s);
    const v = mkAgent({ role: 'fauna', speciesKey: 'raton', x: s.px + 30, y: s.py, hp: 60, brain: 'AI', kind: 'grazer' });
    s.agents = [v];
    const d0 = Math.hypot(v.x - s.px, v.y - s.py);
    const c0 = s.carrions.length;
    assert.equal(castVerb(4), true);
    assert.ok(Math.hypot(v.x - s.px, v.y - s.py) > d0, 'espantada');
    assert.ok(s.agents.includes(v), 'viva');
    assert.equal(s.carrions.length, c0, 'sin carroña');
    assert.equal(s.karma, TUNING.scareKarma);
  });
  it('bone suelta resto que alimenta (+karma, carroña fresca)', () => {
    const s = reset('halcon');
    clearWorld(s);
    const c0 = s.carrions.length;
    assert.equal(castVerb(5), true);
    assert.equal(S().carrions.length, c0 + 1);
    assert.equal(s.karma, TUNING.boneKarma);
  });
});
describe('zorro: cachecarrion, dendig (4.7)', () => {
  it('cache entierra fresca (despensa 1, sin comer); podrida o llena no', () => {
    const s = reset('zorro');
    clearWorld(s);
    s.hp = 50;
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    assert.equal(castVerb(2), true);
    assert.equal(S().carrions.length, 0, 'enterrada');
    assert.equal(S().stash, 1);
    assert.equal(S().hp, 50, 'sin comer');
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    assert.equal(castVerb(2), false, 'despensa llena');
    const s2 = reset('zorro');
    clearWorld(s2);
    s2.carrions = [{ x: s2.px + 5, y: s2.py, age: TUNING.carrionRottenT + 1 }];
    assert.equal(castVerb(2), false, 'podrida no se guarda');
  });
  it('despensa da bono PA en la proxima carroña', () => {
    const s = reset('zorro');
    clearWorld(s);
    s.stash = 1;
    s.pa = 0;
    s.hp = 50; // necesitado: come en vez de ceder
    s.carrions = [{ x: s.px + 5, y: s.py, age: 0 }];
    s.pounceCd = 99; // sin zarpazo: va a la carroña
    s.agents = [];
    key('e');
    assert.equal(S().stash, 0, 'bono consumido');
    assert.equal(s.pa, TUNING.carrionFreshPa + TUNING.pouncePa);
  });
  it('dendig excava madriguera-M (cuesta vida, con cd)', () => {
    const s = reset('zorro');
    clearWorld(s);
    const hp0 = s.hp, n0 = s.refuges.length;
    assert.equal(castVerb(4), true);
    assert.equal(S().refuges.length, n0 + 1);
    assert.equal(S().refuges[S().refuges.length - 1].type, 'burrow-M');
    assert.ok(S().hp < hp0, 'cuesta vida');
    assert.equal(castVerb(4), false, 'con cd no repite');
  });
});
describe('lobo: howl, regurg, escort, cull (4.8)', () => {
  it('howl anima a la manada (rally + karma); sin manada nada', () => {
    const s = reset('lobo');
    clearWorld(s);
    s.agents = [mkAgent({ role: 'company', speciesKey: 'lobo', x: s.px + 5, y: s.py, hp: 60, saved: false })];
    assert.equal(castVerb(1), true);
    assert.equal(s.karma, TUNING.howlKarma);
    assert.ok(s.agents[0].rallyT > 0, 'manada animada');
    const s2 = reset('lobo');
    clearWorld(s2);
    s2.agents = [];
    assert.equal(castVerb(1), false, 'sin manada no hay coro');
  });
  it('regurg alimenta al hambriento (cuesta vida, karma grande)', () => {
    const s = reset('lobo');
    clearWorld(s);
    s.hp = 80;
    const m = mkAgent({ role: 'company', speciesKey: 'lobo', x: s.px + 5, y: s.py, hp: 40, saved: false });
    m.hambre = 10;
    s.agents = [m];
    assert.equal(castVerb(2), true);
    assert.ok(m.hp > 40 && m.hambre > 10);
    assert.ok(S().hp < 80, 'regurgitar cuesta');
    assert.equal(s.karma, TUNING.regurgKarma);
    m.hambre = 90;
    s.hp = 80;
    assert.equal(castVerb(2), false, 'saciado no necesita');
  });
  it('escort premia si el protegido sobrevive (nada si cae)', () => {
    const s = reset('lobo');
    clearWorld(s);
    const m = mkAgent({ role: 'company', speciesKey: 'lobo', x: s.px + 20, y: s.py, hp: 60, saved: false });
    s.agents = [m, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s.px + 40, y: s.py, hp: 120 })];
    const d0 = Math.hypot(s.px - m.x, s.py - m.y);
    assert.equal(castVerb(4), true);
    assert.ok(Math.hypot(S().px - m.x, S().py - m.y) < d0, 'acude al lado');
    assert.ok(S().escortT > 0);
    update(TUNING.escortTime + 0.1);
    assert.equal(S().karma, TUNING.escortKarma, 'sobrevivió: karma');
    const s2 = reset('lobo');
    clearWorld(s2);
    const m2 = mkAgent({ role: 'company', speciesKey: 'lobo', x: s2.px + 20, y: s2.py, hp: 60, saved: false });
    s2.agents = [m2, mkAgent({ role: 'hunter', kind: 'hunter', type: 'zorro', speciesKey: 'zorro', x: s2.px + 40, y: s2.py, hp: 120 })];
    castVerb(4);
    removeAgent(m2); // cae antes del plazo
    update(TUNING.escortTime + 0.1);
    assert.equal(S().karma, 0, 'sin superviviente no hay karma');
  });
  it('cull caza al más débil (bonus si hp<30%, normal si sano)', () => {
    const s = reset('lobo');
    clearWorld(s);
    s.hp = 50; // necesitado: sin mancha de deporte
    const weak = mkAgent({ role: 'fauna', speciesKey: 'zorro', x: s.px + 30, y: s.py, hp: 20, brain: 'AI', kind: 'hunter', type: 'zorro' });
    s.agents = [weak];
    assert.equal(castVerb(5), true);
    assert.ok(!S().agents.includes(weak), 'cazado');
    assert.equal(s.karma, TUNING.cullKarma, 'bonus por débil');
    const s2 = reset('lobo');
    clearWorld(s2);
    s2.hp = 50;
    const fit = mkAgent({ role: 'fauna', speciesKey: 'zorro', x: s2.px + 30, y: s2.py, hp: 120, brain: 'AI', kind: 'hunter', type: 'zorro' });
    s2.agents = [fit];
    assert.equal(castVerb(5), true);
    assert.ok(!S().agents.includes(fit), 'cazado igual');
    assert.equal(S().karma, 0, 'sano: sin bonus');
    const s3 = reset('lobo');
    clearWorld(s3);
    assert.equal(castVerb(5), false, 'sin presa nada');
  });
  it('IA lobo regurgita al hambriento por el nucleo', () => {
    const s = reset('raton');
    clearWorld(s);
    const a = mkAgent({ role: 'fauna', speciesKey: 'lobo', x: 0, y: 0, hp: 100 });
    const m = mkAgent({ role: 'company', speciesKey: 'lobo', x: 5, y: 0, hp: 40, saved: false });
    m.hambre = 10;
    s.agents = [a, m];
    aiLobo(a, 0.2);
    assert.equal(a.karma, TUNING.regurgKarma);
    assert.ok(m.hp > 40 && m.hambre > 10);
  });
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
