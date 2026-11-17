const test = require('node:test');
const assert = require('node:assert/strict');
const { calcularSaldo } = require('../utils/balance');

test('sin saldo inicial ni movimientos el disponible es cero', () => {
  assert.deepEqual(calcularSaldo(), {
    saldoInicial: 0,
    totalAportado: 0,
    totalGastado: 0,
    saldoDisponible: 0
  });
});

test('el saldo inicial se suma al disponible sin contarse como aporte', () => {
  const balance = calcularSaldo({ saldoInicial: 200000, totalAportado: 50000, totalGastado: 30000 });
  assert.equal(balance.saldoInicial, 200000);
  assert.equal(balance.totalAportado, 50000);
  assert.equal(balance.saldoDisponible, 220000);
});

test('se puede gastar el saldo inicial antes de que existan aportes', () => {
  const balance = calcularSaldo({ saldoInicial: 100000, totalAportado: 0, totalGastado: 60000 });
  assert.equal(balance.saldoDisponible, 40000);
});

test('redondea a centavos para evitar decimales arrastrados', () => {
  const balance = calcularSaldo({ saldoInicial: 0.1, totalAportado: 0.2, totalGastado: 0 });
  assert.equal(balance.saldoDisponible, 0.3);
  assert.equal(balance.saldoInicial, 0.1);
});

test('un ajuste puede dejar el disponible en negativo', () => {
  const balance = calcularSaldo({ saldoInicial: 0, totalAportado: 10000, totalGastado: 25000 });
  assert.equal(balance.saldoDisponible, -15000);
});

test('los semilleros anteriores sin saldo inicial se leen en cero', () => {
  const balance = calcularSaldo({ totalAportado: 30000, totalGastado: 10000 });
  assert.equal(balance.saldoInicial, 0);
  assert.equal(balance.saldoDisponible, 20000);
});
