const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');

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
// totalAportado = SUM de abonos cobrados (montoPagado; aportes antiguos sin montoPagado cuentan completos si están pagados)
// totalGastado  = SUM gastos
async function calcularBalance(semilleroId) {
  const [aportes] = await Contribution.aggregate([
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
  ]);

  const [gastos] = await Expense.aggregate([
    { $match: { semilleroId: new mongoose.Types.ObjectId(semilleroId) } },
    { $group: { _id: null, total: { $sum: '$monto' } } }
  ]);

  const totalAportado = aportes ? aportes.total : 0;
  const totalGastado = gastos ? gastos.total : 0;

  return {
    totalAportado,
    totalGastado,
    saldoDisponible: totalAportado - totalGastado
  };
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

module.exports = { getBalance, invalidateBalance };
