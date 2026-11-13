const test = require('node:test');
const assert = require('node:assert/strict');

const { parsePagination, paginatedBody } = require('../utils/pagination');
const { mesActual } = require('../utils/vencimientos');

test('sin page ni limit conserva la respuesta completa', () => {
  const resultado = parsePagination({});
  assert.equal(resultado.paginated, false);
  assert.equal(resultado.page, 1);
  assert.equal(resultado.skip, 0);
});

test('calcula el desplazamiento de la página pedida', () => {
  const resultado = parsePagination({ page: '3', limit: '10' });
  assert.equal(resultado.paginated, true);
  assert.equal(resultado.page, 3);
  assert.equal(resultado.limit, 10);
  assert.equal(resultado.skip, 20);
});

test('page sola usa el límite por defecto', () => {
  const resultado = parsePagination({ page: '2' });
  assert.equal(resultado.page, 2);
  assert.equal(resultado.limit, 20);
  assert.equal(resultado.skip, 20);
});

test('rechaza páginas y límites inválidos', () => {
  assert.match(parsePagination({ page: '0' }).error, /page/);
  assert.match(parsePagination({ page: 'abc' }).error, /page/);
  assert.match(parsePagination({ limit: '-5' }).error, /limit/);
});

test('limita el tamaño de página al máximo permitido', () => {
  const resultado = parsePagination({ limit: '5000' });
  assert.equal(resultado.limit, 100);
});

test('el sobre paginado calcula el total de páginas', () => {
  assert.deepEqual(paginatedBody([1, 2], 45, 2, 20), {
    items: [1, 2],
    total: 45,
    page: 2,
    limit: 20,
    pages: 3
  });
  assert.equal(paginatedBody([], 0, 1, 20).pages, 1);
});

test('el mes de vencimiento se calcula en hora de Colombia', () => {
  // 1 de marzo a las 03:00 UTC todavía es 28 de febrero en Bogotá.
  assert.equal(mesActual(new Date('2026-03-01T03:00:00.000Z')), '2026-02');
  assert.equal(mesActual(new Date('2026-03-01T06:00:00.000Z')), '2026-03');
});
