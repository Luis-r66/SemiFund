const test = require('node:test');
const assert = require('node:assert/strict');

const { destinatariosUnicos, dinero } = require('../utils/notifications');

test('los destinatarios se deduplican y descartan vacíos', () => {
  assert.deepEqual(
    destinatariosUnicos(['a', 'a', null, undefined, 'b', '']),
    ['a', 'b']
  );
  assert.deepEqual(destinatariosUnicos(), []);
});

test('el dinero se muestra en pesos colombianos sin decimales', () => {
  assert.match(dinero(50000), /50\.000/);
  assert.match(dinero('1250000'), /1\.250\.000/);
  assert.match(dinero(undefined), /\b0\b/);
});
