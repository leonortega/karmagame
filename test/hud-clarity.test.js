// test/hud-clarity.test.js - per-species controls, PA/edad/time, vertical verbs, emoji feed
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { reset, S, elsById } = require('./harness');

describe('controls per-species', () => {
  it('topo ve E/Q/V sin C ni R', () => {
    reset('topo');
    updateHud();
    const html = document.getElementById('controls').innerHTML;
    assert.ok(html.includes('E'), 'muestra E cavar');
    assert.ok(html.includes('Q'), 'muestra Q gritar');
    assert.ok(html.includes('V'), 'muestra V temblor');
    assert.ok(!html.includes('>R<') && !html.includes('<b>R</b>'), 'sin R en vida');
    assert.ok(!html.includes('<b>C</b>'), 'topo sin C');
  });
  it('zorro ve E/V sin Q ni R', () => {
    reset('zorro');
    updateHud();
    const html = document.getElementById('controls').innerHTML;
    assert.ok(html.includes('E'), 'muestra E zarpazo');
    assert.ok(html.includes('V'), 'muestra V rastro');
    assert.ok(!html.includes('<b>Q</b>'), 'zorro sin Q');
    assert.ok(!html.includes('<b>R</b>'), 'sin R en vida');
  });
  it('cooldowns cuentan como verbos con (Ns)', () => {
    const s = reset('topo');
    s.shoutCd = 4.2; s.digCd = 12.1; s.senseCd = 0;
    updateHud();
    const html = document.getElementById('controls').innerHTML;
    assert.ok(html.includes('(5s)') || html.includes('(4s)'), 'Q con cuenta: ' + html);
    assert.ok(html.includes('(13s)') || html.includes('(12s)'), 'E con cuenta: ' + html);
  });
});

describe('identity split', () => {
  it('speciesLabel solo identidad, sin Q/E', () => {
    reset('ardilla');
    S().shoutCd = 0;
    updateHud();
    const t = elsById.speciesLabel.textContent;
    assert.ok(t.includes('Ardilla'), 'nombre: ' + t);
    assert.ok(!t.includes('Q'), 'sin Q en speciesLabel: ' + t);
    assert.ok(!t.includes('E '), 'sin E en speciesLabel: ' + t);
  });
});

describe('PA emphasis', () => {
  it('PA con icono y estilo propio', () => {
    reset('raton');
    S().pa = 42;
    updateHud();
    const el = elsById.paLabel;
    const html = el.innerHTML || el.textContent;
    assert.ok(String(html).includes('42'), 'numero visible: ' + html);
    assert.ok(String(html).length > String(42).length, 'con icono extra: ' + html);
    assert.ok(String(el.className || '').includes('pa') || String(html).includes('pa-'), 'clase/icono PA');
  });
});

describe('edad animal-years', () => {
  it('raton 40s muestra anos y segundos', () => {
    reset('raton');
    S().edad = 40;
    updateHud();
    const t = elsById.edadLabel.textContent;
    assert.ok(t.includes('40'), 'segundos: ' + t);
    assert.ok(/2/.test(t) && /año|ano/i.test(t), 'anos: ' + t);
  });
  it('tiempo rotulado como reloj de vida', () => {
    reset('raton');
    S().time = 65;
    updateHud();
    assert.ok(elsById.timeLabel.textContent.includes('1:05'), 'reloj: ' + elsById.timeLabel.textContent);
  });
});

describe('verbBar vertical', () => {
  it('cinco filas apiladas, no spans en linea', () => {
    reset('raton');
    updateHud();
    const html = elsById.verbBar.innerHTML;
    const rows = (html.match(/<li|verb-row/g) || []).length;
    assert.ok(rows >= 5, 'cinco filas: ' + html.slice(0, 200));
    assert.ok(html.includes('<ul') || html.includes('<li'), 'lista vertical: ' + html.slice(0, 200));
  });
});

describe('otherLog emoji-first', () => {
  it('prefija emoji del actor', () => {
    reset('raton');
    const s = S();
    const olog = document.getElementById('otherLog');
    olog.children.length = 0;
    const ia = s.agents.find((a) => a.speciesKey === 'sapo') || { speciesKey: 'sapo', karma: 0, pa: 0, owned: {}, lifeLog: [] };
    if (!s.agents.includes(ia)) s.agents.push(ia);
    addKarma(5, 'Rocio toxico (+5 karma)', 'good', ia);
    const first = document.getElementById('otherLog').children[0];
    assert.ok(String(first.innerHTML).startsWith('🐸'), 'emoji primero: ' + first.innerHTML);
  });
  it('grito IA ya no es silencioso', () => {
    reset('raton');
    const s = S();
    const olog = document.getElementById('otherLog');
    olog.children.length = 0;
    const ia = mkAgent({ role: 'fauna', speciesKey: 'raton', hp: 100, x: 0, y: 0 });
    s.agents.push(ia);
    ia.shoutCd = 0;
    const n0 = document.getElementById('otherLog').children.length;
    aiTryShout(ia);
    assert.equal(document.getElementById('otherLog').children.length, n0 + 1, 'feed suma 1');
  });
});
