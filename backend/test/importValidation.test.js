const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizarTexto,
  normalizarEncabezado,
  mesValido,
  fechaISOValida,
  parseMonto,
  parseFecha,
  fechaNoFutura,
  parseActivo,
  parseEstadoAbono,
  claveAporte,
  claveGasto,
  firmaAbono
} = require('../utils/importValidation');

test('normaliza nombres sin tildes, mayúsculas ni espacios repetidos', () => {
  assert.equal(normalizarTexto('  María   José  '), 'maria jose');
  assert.equal(normalizarTexto('PEÑALOZA'), 'penaloza');
  assert.equal(normalizarTexto(null), '');
});

test('normaliza encabezados de la plantilla', () => {
  assert.equal(normalizarEncabezado('Monto cuota'), 'monto_cuota');
  assert.equal(normalizarEncabezado('integrante_id'), 'integrante_id');
  assert.equal(normalizarEncabezado('Descripción'), 'descripcion');
});

test('valida meses AAAA-MM', () => {
  assert.equal(mesValido('2026-11'), true);
  assert.equal(mesValido('2026-1'), false);
  assert.equal(mesValido('2026-13'), false);
  assert.equal(mesValido('noviembre'), false);
  assert.equal(mesValido(202611), false);
});

test('valida fechas reales del calendario', () => {
  assert.equal(fechaISOValida('2026-11-09'), true);
  assert.equal(fechaISOValida('2026-02-29'), false);
  assert.equal(fechaISOValida('2024-02-29'), true);
  assert.equal(fechaISOValida('09/11/2026'), false);
});

test('convierte montos escritos en formato colombiano', () => {
  assert.equal(parseMonto(30000), 30000);
  assert.equal(parseMonto('30000'), 30000);
  assert.equal(parseMonto('30.000'), 30000);
  assert.equal(parseMonto('1.500.000'), 1500000);
  assert.equal(parseMonto('$ 30.000'), 30000);
  assert.equal(parseMonto('30000,50'), 30000.5);
  assert.equal(parseMonto('30.000,50'), 30000.5);
  assert.equal(parseMonto('30,000'), 30000);
  assert.equal(parseMonto(''), Number.NaN);
  assert.equal(parseMonto('abc'), Number.NaN);
});

test('convierte fechas de Excel y textos a AAAA-MM-DD', () => {
  assert.equal(parseFecha(new Date('2026-11-09T00:00:00.000Z')), '2026-11-09');
  assert.equal(parseFecha('2026-11-09'), '2026-11-09');
  assert.equal(parseFecha('09/11/2026'), '2026-11-09');
  assert.equal(parseFecha('2026-02-29'), null);
  assert.equal(parseFecha(''), null);
});

test('rechaza fechas futuras y compara contra hoy', () => {
  assert.equal(fechaNoFutura('2026-11-09', '2026-11-10'), true);
  assert.equal(fechaNoFutura('2026-11-10', '2026-11-10'), true);
  assert.equal(fechaNoFutura('2026-11-11', '2026-11-10'), false);
  assert.equal(fechaNoFutura('2026-02-30', '2026-11-10'), false);
});

test('interpreta activo y estado de abono', () => {
  assert.equal(parseActivo('Sí'), true);
  assert.equal(parseActivo('No'), false);
  assert.equal(parseActivo(''), true);
  assert.equal(parseActivo('quizá'), null);
  assert.equal(parseEstadoAbono(''), 'aprobado');
  assert.equal(parseEstadoAbono('Reportado'), 'reportado');
  assert.equal(parseEstadoAbono('anulado'), null);
});

test('genera claves estables para detectar duplicados', () => {
  assert.equal(claveAporte('member-1', '2026-11'), 'member-1|2026-11');
  assert.equal(
    claveGasto({ fecha: '2026-11-09', descripcion: '  Dominio  ', monto: 30000 }),
    '2026-11-09|dominio|30000.00'
  );
  assert.equal(
    firmaAbono('member-1|2026-11', {
      monto: 15000,
      fecha: '2026-11-09',
      referencia: '  Ref 1 '
    }),
    'member-1|2026-11|15000.00|2026-11-09|ref 1'
  );
});
