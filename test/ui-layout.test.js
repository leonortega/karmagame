// test/ui-layout.test.js - 3 columnas: izq leyenda+otros, centro canvas, der jugador+tierra
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { reset, S, elsById } = require('./harness');

const html = () => fs.readFileSync(path.join(__dirname, '..', 'src', 'index.html'), 'utf8');

describe('disposición UI 3 columnas', () => {
  it('sin leyenda en el canvas: vive solo en el panel izquierdo', () => {
    reset();
    assert.equal(typeof drawLegend, 'undefined', 'drawLegend eliminada del canvas');
    assert.ok(html().includes('id="legend"'), 'panel #legend existe en index.html');
  });
  it('avisos de tierra del jugador a la derecha del canvas', () => {
    reset();
    assert.equal(typeof statusAnchor, 'function');
    const a = statusAnchor();
    assert.ok(a.x > 700, 'ancla avisos a la derecha, x=' + a.x);
    assert.equal(a.align, 'right');
  });
  it('log jugador a la derecha, log otros animales a la izquierda', () => {
    reset();
    assert.equal(typeof logOther, 'function');
    log('soy jugador', 'info');
    logOther('un sapo croa', 'info');
    assert.ok(elsById.log.children.some((c) => String(c.innerHTML).includes('soy jugador')));
    assert.ok(!elsById.log.children.some((c) => String(c.innerHTML).includes('sapo croa')));
    assert.ok(elsById.otherLog.children.some((c) => String(c.innerHTML).includes('sapo croa')));
  });
  it('karma IA va al panel izquierdo, karma jugador al derecho', () => {
    reset();
    const s = S();
    const ia = s.agents.find((a) => a.speciesKey);
    assert.ok(ia, 'hay agentes para probar');
    const nLog = elsById.log.children.length;
    const nOther = elsById.otherLog.children.length;
    addKarma(5, 'hazaña IA', 'good', ia);
    assert.equal(elsById.log.children.length, nLog, 'panel jugador intacto');
    assert.equal(elsById.otherLog.children.length, nOther + 1, 'panel otros suma 1');
    addKarma(5, 'hazaña jugador', 'good');
    assert.ok(elsById.log.children.some((c) => String(c.innerHTML).includes('hazaña jugador')));
  });
  it('un solo bloque Otros animales: roster sin cabecera propia', () => {
    reset();
    assert.equal(typeof renderOtherPanel, 'function');
    renderOtherPanel();
    const panel = elsById.otherPanel.innerHTML;
    assert.ok(!panel.includes('<h3'), 'el roster no pinta su propia cabecera');
    assert.ok(panel.length > 20, 'el roster lista animales');
    const heads = (html().match(/Otros animales/g) || []).length;
    assert.equal(heads, 1, 'una sola cabecera Otros animales en index.html');
  });
  it('controles como lista', () => {
    const m = html().match(/<div id="controls">([\s\S]*?)<\/div>/);
    assert.ok(m, '#controls existe');
    assert.ok(m[1].includes('<ul>'), '#controls usa <ul>');
    const items = m[1].match(/<li>/g) || [];
    assert.ok(items.length >= 5, 'al menos 5 controles, hay ' + items.length);
  });
});
