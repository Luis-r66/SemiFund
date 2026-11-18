const test = require('node:test');
const assert = require('node:assert/strict');
const {
  nombreValido,
  nombreSemilleroValido,
  textoValido,
  identificacionValida,
  hoyBogota
} = require('../utils/validators');

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

test('el nombre del semillero no admite números', () => {
  assert.equal(nombreSemilleroValido('Semillero de Software'), true);
  assert.equal(nombreSemilleroValido('Semillero de Investigación & Gestión'), true);
  assert.equal(nombreSemilleroValido('Semillero de Software, Grupo A'), true);
  assert.equal(nombreSemilleroValido('Semillero 2026'), false);
  assert.equal(nombreSemilleroValido('Grupo 4'), false);
  assert.equal(nombreSemilleroValido('   '), false);
  assert.equal(nombreSemilleroValido('a'.repeat(61)), false);
});

test('hoyBogota devuelve la fecha en Colombia aunque el servidor esté en UTC', () => {
  // 03:00 UTC del 10 de noviembre es 22:00 del 9 de noviembre en Bogotá.
  assert.equal(hoyBogota(new Date('2026-11-10T03:00:00Z')), '2026-11-09');
  assert.equal(hoyBogota(new Date('2026-11-10T15:00:00Z')), '2026-11-10');
});

test('los textos de carrera, ciudad y centro de costos no aceptan números', () => {
  assert.deepEqual(textoValido('Ingeniería de Software'), { valor: 'Ingeniería de Software' });
  assert.deepEqual(textoValido('Bogotá D.C.'), { valor: 'Bogotá D.C.' });
  assert.deepEqual(textoValido('  Centro Norte  '), { valor: 'Centro Norte' });
  assert.ok(textoValido('Ingeniería 2026').error);
  assert.ok(textoValido('Semestre 4').error);
  assert.ok(textoValido('A').error);
  assert.ok(textoValido('X'.repeat(81)).error);
  assert.ok(textoValido(null).error);
});

test('la identificación solo admite dígitos con puntos, guiones o espacios', () => {
  assert.equal(identificacionValida('1020304050'), true);
  assert.equal(identificacionValida('1.020.304.050'), true);
  assert.equal(identificacionValida('1020-304050'), true);
  assert.equal(identificacionValida('1234'), false);
  assert.equal(identificacionValida('CC 1020304050'), false);
  assert.equal(identificacionValida('1020304050X'), false);
  assert.equal(identificacionValida(null), false);
});
