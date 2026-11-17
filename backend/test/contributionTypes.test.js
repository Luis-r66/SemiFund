const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizarTipo,
  tipoDe,
  claveConcepto
} = require('../utils/contributionTypes');

test('normalizarTipo distingue cuota y aporte', () => {
  assert.equal(normalizarTipo('cuota'), 'cuota');
  assert.equal(normalizarTipo('Aporte'), 'aporte');
  assert.equal(normalizarTipo('  CUOTA  '), 'cuota');
});

test('normalizarTipo usa cuota por defecto', () => {
  assert.equal(normalizarTipo(undefined), 'cuota');
  assert.equal(normalizarTipo(null), 'cuota');
  assert.equal(normalizarTipo(''), 'cuota');
  assert.equal(normalizarTipo(undefined, 'aporte'), 'aporte');
});

test('normalizarTipo rechaza valores desconocidos', () => {
  assert.equal(normalizarTipo('mensual'), null);
  assert.equal(normalizarTipo(3), null);
});

test('tipoDe trata los registros antiguos como cuota', () => {
  assert.equal(tipoDe({}), 'cuota');
  assert.equal(tipoDe({ tipo: undefined }), 'cuota');
  assert.equal(tipoDe({ tipo: 'cuota' }), 'cuota');
  assert.equal(tipoDe({ tipo: 'aporte' }), 'aporte');
});

test('claveConcepto ignora tildes, mayúsculas y espacios repetidos', () => {
  assert.equal(claveConcepto('  Viaje   a Medellín '), 'viaje a medellin');
  assert.equal(claveConcepto('VIAJE A MEDELLIN'), 'viaje a medellin');
  assert.equal(claveConcepto(null), '');
});
