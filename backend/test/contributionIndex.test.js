const test = require('node:test');
const assert = require('node:assert/strict');

const Contribution = require('../models/Contribution');

// La comprobación previa del controlador no es atómica: el índice es la única
// defensa real contra dos peticiones simultáneas creando la misma cuota.
test('la cuota tiene un índice único parcial por integrante y mes', () => {
  const indices = Contribution.schema.indexes();
  const cuota = indices.find(
    ([, opciones]) => opciones && opciones.name === 'cuota_unica_por_integrante_mes'
  );

  assert.ok(cuota, 'falta el índice de cuota única');
  assert.deepEqual(cuota[0], { semilleroId: 1, integranteId: 1, mes: 1 });
  assert.equal(cuota[1].unique, true);
  assert.deepEqual(cuota[1].partialFilterExpression, { tipo: 'cuota' });
});

// Los aportes (viaje, materiales, etc.) sí pueden repetirse en el mismo mes:
// el índice no debe cubrirlos.
test('los aportes quedan fuera del índice único', () => {
  const indices = Contribution.schema.indexes();
  const cuota = indices.find(
    ([, opciones]) => opciones && opciones.name === 'cuota_unica_por_integrante_mes'
  );

  assert.notDeepEqual(cuota[1].partialFilterExpression, {});
  assert.notEqual(cuota[1].partialFilterExpression.tipo, 'aporte');
});
