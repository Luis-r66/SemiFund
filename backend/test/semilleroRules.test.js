const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizarNombre,
  puedeEliminar,
  nombreConfirma,
  puedeSalir
} = require('../utils/semilleroRules');

test('normaliza mayúsculas, tildes y espacios', () => {
  assert.equal(normalizarNombre('  Semillero   de Ingeniería  '), 'semillero de ingenieria');
  assert.equal(normalizarNombre(null), '');
});

test('solo el creador puede eliminar', () => {
  assert.equal(puedeEliminar('user-1', 'user-1'), true);
  assert.equal(puedeEliminar('user-1', 'user-2'), false);
  assert.equal(puedeEliminar(null, 'user-1'), false);
});

test('la confirmación exige el nombre exacto', () => {
  assert.equal(nombreConfirma('Semillero de Software', 'semillero de software'), true);
  assert.equal(nombreConfirma('Semillero de Software', 'Semillero de Software '), true);
  assert.equal(nombreConfirma('Semillero de Software', 'Semillero'), false);
  assert.equal(nombreConfirma('Semillero de Software', ''), false);
  assert.equal(nombreConfirma('', ''), false);
});

test('el último tesorero no puede salir', () => {
  assert.equal(puedeSalir({ esTesorero: false, tesorerosActivos: 1 }), true);
  assert.equal(puedeSalir({ esTesorero: true, tesorerosActivos: 2 }), true);
  assert.equal(puedeSalir({ esTesorero: true, tesorerosActivos: 1 }), false);
});
