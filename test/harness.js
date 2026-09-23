// test/harness.js - stubs minimos de navegador + carga src/script/*.js en orden.
// Uso: const { reset, S, key } = require('./harness');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

function makeEl() {
  const el = {
    children: [],
    style: {},
    textContent: '',
    innerHTML: '',
    className: '',
    disabled: false,
    onclick: null,
    classList: { add() {}, remove() {}, toggle() {} },
    prepend(c) { c._parent = el; el.children.unshift(c); },
    get lastChild() { return el.children[el.children.length - 1]; },
    remove() {
      const p = this._parent;
      if (p) { const i = p.children.indexOf(this); if (i >= 0) p.children.splice(i, 1); }
    },
  };
  return el;
}

const ctxStub = new Proxy(
  {},
  { get: (t, p) => (p in t ? t[p] : () => {}), set: () => true }
);

const elsById = {};
global.document = {
  getElementById(id) {
    if (!elsById[id]) {
      elsById[id] = makeEl();
      if (id === 'game') {
        elsById[id].width = 960;
        elsById[id].height = 600;
        elsById[id].getContext = () => ctxStub;
      }
    }
    return elsById[id];
  },
  createElement: () => makeEl(),
};

const handlers = { keydown: [], keyup: [] };
global.addEventListener = (type, fn) => {
  if (handlers[type]) handlers[type].push(fn);
};
global.performance = { now: () => 0 };
global.requestAnimationFrame = () => 0;

const ORDER = ['data.js', 'utils.js', 'state.js', 'predators.js', 'eat.js', 'shop.js', 'hud.js', 'game.js', 'draw.js'];
for (const f of ORDER) {
  const code = fs.readFileSync(path.join(__dirname, '..', 'src', 'script', f), 'utf8');
  vm.runInThisContext(code, { filename: f });
}
// Acceso robusto al `state` lexico compartido (los `let` no cuelgan de globalThis).
vm.runInThisContext('globalThis.__getState = () => state;');

// Resetea el mundo y devuelve el state fresco.
function reset(species = 'raton', karma = 0, pa = 0, saplings = 0) {
  newRun(species, karma, pa, saplings);
  return globalThis.__getState();
}
function S() {
  return globalThis.__getState();
}
// Simula una tecla (cubre el cableado de input de game.js).
function key(k) {
  handlers.keydown.forEach((fn) => fn({ key: k }));
}

module.exports = { reset, S, key, elsById };
