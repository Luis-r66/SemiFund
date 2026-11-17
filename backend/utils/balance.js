const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const Semillero = require('../models/Semillero');

// Caché corta del saldo por semillero. Se invalida en cada escritura de
// aportes o gastos, así que solo evita repetir las dos agregaciones cuando el
// inicio y un módulo piden el saldo casi al mismo tiempo.
const CACHE_TTL_MS = Number.parseInt(process.env.BALANCE_CACHE_MS, 10) || 45000;
const cache = new Map();

function clave(semilleroId) {
  return String(semilleroId);
}

function invalidateBalance(semilleroId) {
  cache.delete(clave(semilleroId));
}

// Calcula el saldo de un semillero en el momento con agregaciones de Mongo (no se almacena).
// saldoInicial  = dinero que el semillero ya tenía; no es aporte de nadie
// totalAportado = SUM de abonos cobrados (montoPagado; aportes antiguos sin montoPagado cuentan completos si están pagados)
// totalGastado  = SUM gastos
const round = (value) => Math.round(Number(value) * 100) / 100;

// Fórmula única del saldo, aislada para probarla sin base de datos.
function calcularSaldo({ saldoInicial = 0, totalAportado = 0, totalGastado = 0 } = {}) {
  const inicial = round(saldoInicial) || 0;
  const aportado = round(totalAportado) || 0;
  const gastado = round(totalGastado) || 0;
  return {
    saldoInicial: inicial,
    totalAportado: aportado,
    totalGastado: gastado,
    saldoDisponible: round(inicial + aportado - gastado)
  };
}

async function calcularBalance(semilleroId) {
  const [aportes, gastos, semillero] = await Promise.all([
    Contribution.aggregate([
      { $match: { semilleroId: new mongoose.Types.ObjectId(semilleroId) } },
      {
        $group: {
          _id: null,
          total: {
            $sum: {
              $ifNull: ['$montoPagado', { $cond: [{ $eq: ['$estado', 'pagado'] }, '$monto', 0] }]
            }
          }
        }
      }
    ]),
    Expense.aggregate([
      { $match: { semilleroId: new mongoose.Types.ObjectId(semilleroId) } },
      { $group: { _id: null, total: { $sum: '$monto' } } }
    ]),
    Semillero.findById(semilleroId).select('saldoInicial').lean()
  ]);

  const [datosAportes] = aportes;
  const [datosGastos] = gastos;

  return calcularSaldo({
    saldoInicial: semillero && semillero.saldoInicial ? semillero.saldoInicial.monto : 0,
    totalAportado: datosAportes ? datosAportes.total : 0,
    totalGastado: datosGastos ? datosGastos.total : 0
  });
}

async function getBalance(semilleroId, { force = false } = {}) {
  const key = clave(semilleroId);
  const guardado = cache.get(key);
  if (!force && guardado && guardado.expiresAt > Date.now()) {
    return guardado.value;
  }

  const value = await calcularBalance(semilleroId);
  cache.set(key, { value, expiresAt: Date.now() + CACHE_TTL_MS });
  return value;
}

module.exports = { getBalance, invalidateBalance, calcularSaldo };
