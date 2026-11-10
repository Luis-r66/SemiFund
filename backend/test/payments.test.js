const test = require('node:test');
const assert = require('node:assert/strict');
const {
  montoPagadoDe,
  saldoPendiente,
  estadoCobro,
  agregarAbono,
  aprobarAbono,
  rechazarAbono,
  anularAbono
} = require('../utils/payments');

const TESORERO = 'tesorero';
const FUTURO = new Date('2026-11-15T12:00:00');

function cuota(monto = 30000, mes = '2026-11') {
  return { monto, mes, estado: 'pendiente', abonos: [], fechaPago: null };
}

function abonoPor(c, index) {
  return c.abonos[index];
}

test('cuota nueva sin pagos', () => {
  const c = cuota();
  assert.equal(montoPagadoDe(c), 0);
  assert.equal(saldoPendiente(c), 30000);
  assert.equal(estadoCobro(c), 'sin_pago');
});

test('abono del integrante queda reportado sin mover el saldo', () => {
  const c = cuota();
  agregarAbono(c, { monto: 15000, usuarioId: 'integrante', aprobado: false, now: FUTURO });
  c.estado = 'reportado';
  assert.equal(c.abonos[0].estado, 'reportado');
  assert.equal(montoPagadoDe(c), 0);
  assert.equal(saldoPendiente(c), 30000);
});

test('aprobar un abono parcial deja el aporte pendiente con saldo', () => {
  const c = cuota();
  const abono = agregarAbono(c, { monto: 15000, usuarioId: 'integrante', aprobado: false, now: FUTURO });
  aprobarAbono(c, abono, TESORERO, FUTURO);
  assert.equal(c.estado, 'pendiente');
  assert.equal(montoPagadoDe(c), 15000);
  assert.equal(saldoPendiente(c), 15000);
  assert.equal(estadoCobro(c), 'parcial');
  assert.equal(c.fechaPago, null);
});

test('segundo abono aprobado completa la cuota y marca pagado', () => {
  const c = cuota();
  aprobarAbono(c, agregarAbono(c, { monto: 15000, usuarioId: 'a', aprobado: false, now: FUTURO }), TESORERO, FUTURO);
  aprobarAbono(c, agregarAbono(c, { monto: 15000, usuarioId: 'a', aprobado: false, now: FUTURO }), TESORERO, FUTURO);
  assert.equal(c.estado, 'pagado');
  assert.equal(saldoPendiente(c), 0);
  assert.equal(estadoCobro(c), 'completo');
  assert.deepEqual(c.fechaPago, FUTURO);
});

test('rechazar un abono no cambia lo cobrado y vuelve a pendiente', () => {
  const c = cuota();
  const abono = agregarAbono(c, { monto: 10000, usuarioId: 'a', aprobado: false, now: FUTURO });
  c.estado = 'reportado';
  rechazarAbono(c, abono, TESORERO, 'Comprobante ilegible', FUTURO);
  assert.equal(abonoPor(c, 0).estado, 'rechazado');
  assert.equal(abonoPor(c, 0).motivo, 'Comprobante ilegible');
  assert.equal(c.estado, 'pendiente');
  assert.equal(montoPagadoDe(c), 0);
  assert.equal(c.motivoRechazo, 'Comprobante ilegible');
});

test('un abono rechazado no impide reportar otro', () => {
  const c = cuota();
  rechazarAbono(c, agregarAbono(c, { monto: 10000, usuarioId: 'a', aprobado: false, now: FUTURO }), TESORERO, null, FUTURO);
  const nuevo = agregarAbono(c, { monto: 30000, usuarioId: 'a', aprobado: false, now: FUTURO });
  assert.equal(nuevo.estado, 'reportado');
  assert.equal(c.abonos.filter((a) => a.estado === 'reportado').length, 1);
});

test('anular un abono aprobado recalcula el saldo y reabre la cuota', () => {
  const c = cuota();
  agregarAbono(c, { monto: 30000, usuarioId: TESORERO, aprobado: true, now: FUTURO });
  c.estado = 'pagado';
  assert.equal(montoPagadoDe(c), 30000);
  anularAbono(c, c.abonos[0], TESORERO, 'Aprobado por error', FUTURO);
  assert.equal(c.estado, 'pendiente');
  assert.equal(montoPagadoDe(c), 0);
  assert.equal(c.fechaPago, null);
});

test('tesorero registra pago en efectivo ya aprobado', () => {
  const c = cuota();
  agregarAbono(c, { monto: 12000, usuarioId: TESORERO, aprobado: true, now: FUTURO });
  assert.equal(c.abonos[0].estado, 'aprobado');
  assert.equal(montoPagadoDe(c), 12000);
  assert.equal(c.estado, 'pendiente');
});

test('cuota del mes pasado sin pagar se sincroniza como vencida', () => {
  const c = cuota(30000, '2026-09');
  const abono = agregarAbono(c, { monto: 5000, usuarioId: 'a', aprobado: false, now: FUTURO });
  aprobarAbono(c, abono, TESORERO, FUTURO);
  assert.equal(c.estado, 'vencido');
  assert.equal(saldoPendiente(c), 25000);
});

test('aportes antiguos sin montoPagado: pagados cubren la cuota completa', () => {
  const c = { monto: 30000, mes: '2026-06', estado: 'pagado', abonos: [], fechaPago: new Date() };
  assert.equal(montoPagadoDe(c), 30000);
  assert.equal(saldoPendiente(c), 0);
  assert.equal(estadoCobro(c), 'completo');
});

test('aportes antiguos sin montoPagado: no pagados cuentan en cero', () => {
  const c = { monto: 30000, mes: '2026-06', estado: 'vencido', abonos: [] };
  assert.equal(montoPagadoDe(c), 0);
  assert.equal(saldoPendiente(c), 30000);
});

test('no sobrepasa la cuota aunque se recalcule', () => {
  const c = cuota();
  assert.equal(saldoPendiente({ ...c, montoPagado: 40000 }), 0);
});
