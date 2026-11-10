const test = require('node:test');
const assert = require('node:assert/strict');
const { nombreValido, hoyBogota } = require('../utils/validators');

test('acepta nombres con letras, tildes, ñ, espacios, apóstrofe, punto y guion', () => {
  assert.equal(nombreValido('María José'), true);
  assert.equal(nombreValido("D'Angelo"), true);
  assert.equal(nombreValido('Peñaloza Muñoz'), true);
  assert.equal(nombreValido('Ana-Lucía'), true);
  assert.equal(nombreValido('J. Pérez'), true);
});

test('rechaza nombres con números, símbolos o vacíos', () => {
  assert.equal(nombreValido('Juan2'), false);
  assert.equal(nombreValido('Pérez 3'), false);
  assert.equal(nombreValido('Ana@'), false);
  assert.equal(nombreValido('   '), false);
  assert.equal(nombreValido(''), false);
  assert.equal(nombreValido(undefined), false);
  assert.equal(nombreValido(123), false);
});

test('rechaza nombres demasiado largos', () => {
  assert.equal(nombreValido('a'.repeat(61)), false);
  assert.equal(nombreValido('a'.repeat(60)), true);
});

test('hoyBogota devuelve la fecha en Colombia aunque el servidor esté en UTC', () => {
  // 03:00 UTC del 10 de noviembre es 22:00 del 9 de noviembre en Bogotá.
  assert.equal(hoyBogota(new Date('2026-11-10T03:00:00Z')), '2026-11-09');
  assert.equal(hoyBogota(new Date('2026-11-10T15:00:00Z')), '2026-11-10');
});
