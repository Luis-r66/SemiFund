const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizarNombre,
  puedeEliminar,
  nombreConfirma,
  puedeSalir,
  puedeAjustarSaldoInicial
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

test('el creador siempre puede ajustar el saldo inicial', () => {
  assert.equal(
    puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: 'u1', esTesorero: false, creadorActivo: true }),
    true
  );
});

test('otro integrante no puede ajustar el saldo inicial', () => {
  assert.equal(
    puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: 'u2', esTesorero: false, creadorActivo: true }),
    false
  );
  assert.equal(
    puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: 'u2', esTesorero: false, creadorActivo: false }),
    false
  );
});

test('el tesorero solo ajusta el saldo inicial si el creador ya no está activo', () => {
  assert.equal(
    puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: 'u2', esTesorero: true, creadorActivo: true }),
    false
  );
  assert.equal(
    puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: 'u2', esTesorero: true, creadorActivo: false }),
    true
  );
});

test('sin creador o sin usuario no hay permiso de ajuste', () => {
  assert.equal(puedeAjustarSaldoInicial({ creadoPor: null, userId: 'u2', esTesorero: true }), false);
  assert.equal(puedeAjustarSaldoInicial({ creadoPor: 'u1', userId: null, esTesorero: true }), false);
});
