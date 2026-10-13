const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');

// Calcula el saldo en el momento con agregaciones de Mongo (no se almacena).
// totalAportado = SUM aportes con estado "pagado"
// totalGastado  = SUM gastos
async function getBalance() {
  const [aportes] = await Contribution.aggregate([
    { $match: { estado: 'pagado' } },
    { $group: { _id: null, total: { $sum: '$monto' } } }
  ]);

  const [gastos] = await Expense.aggregate([
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
