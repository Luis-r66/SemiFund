const test = require('node:test');
const assert = require('node:assert/strict');

const { mesLegible } = require('../utils/fechas');

test('el mes de una cuota se muestra en español', () => {
  assert.equal(mesLegible('2026-11'), 'noviembre de 2026');
  assert.equal(mesLegible('2027-01'), 'enero de 2027');
  assert.equal(mesLegible('2026-12'), 'diciembre de 2026');
});

test('un valor inesperado se conserva tal cual', () => {
  assert.equal(mesLegible('2026-13'), '2026-13');
  assert.equal(mesLegible('noviembre'), 'noviembre');
  assert.equal(mesLegible(null), '');
});
