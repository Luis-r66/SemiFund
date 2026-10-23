const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const asyncHandler = require('../middleware/asyncHandler');

// Calcula el saldo de un semillero en el momento con agregaciones de Mongo (no se almacena).
// totalAportado = SUM aportes con estado "pagado"
// totalGastado  = SUM gastos
async function getBalance(semilleroId) {
  const [aportes] = await Contribution.aggregate([
    { $match: { semilleroId: new mongoose.Types.ObjectId(semilleroId), estado: 'pagado' } },
    { $group: { _id: null, total: { $sum: '$monto' } } }
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

module.exports = { getBalance };
