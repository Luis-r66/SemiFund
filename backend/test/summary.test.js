const test = require('node:test');
const assert = require('node:assert/strict');
const { filtroCuotasPorCobrar } = require('../utils/summary');

const SEMILLERO = 'semillero-1';

test('el tesorero cuenta las cuotas por cobrar de todo el semillero', () => {
  const filtro = filtroCuotasPorCobrar({
    semilleroId: SEMILLERO,
    esTesorero: true,
    memberId: 'member-1'
  });
  assert.deepEqual(filtro, {
    semilleroId: SEMILLERO,
    estado: { $ne: 'pagado' }
  });
});

test('el integrante solo cuenta sus propias cuotas', () => {
  const filtro = filtroCuotasPorCobrar({
    semilleroId: SEMILLERO,
    esTesorero: false,
    memberId: 'member-2'
  });
  assert.deepEqual(filtro, {
    semilleroId: SEMILLERO,
    estado: { $ne: 'pagado' },
    integranteId: 'member-2'
  });
});

test('sin integrante vinculado no hay cuotas que contar', () => {
  assert.equal(
    filtroCuotasPorCobrar({
      semilleroId: SEMILLERO,
      esTesorero: false,
      memberId: null
    }),
    null
  );
});
