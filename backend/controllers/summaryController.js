const asyncHandler = require('../middleware/asyncHandler');
const Member = require('../models/Member');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const { getBalance } = require('../utils/balance');

// GET /api/summary
// Todo lo que el inicio necesita, en una sola llamada: saldo, integrantes
// activos, cuotas por cobrar y gastos registrados. Evita que el cliente baje
// las tres colecciones completas solo para contar.
const get = asyncHandler(async (req, res) => {
  const [balance, activeMembers, pendingContributions, expensesCount] = await Promise.all([
    getBalance(req.semilleroId),
    Member.countDocuments({ semilleroId: req.semilleroId, activo: true }),
    Contribution.countDocuments({ semilleroId: req.semilleroId, estado: { $ne: 'pagado' } }),
    Expense.countDocuments({ semilleroId: req.semilleroId })
  ]);

  res.status(200).json({
    balance,
    activeMembers,
    pendingContributions,
    expensesCount,
    generatedAt: new Date().toISOString()
  });
});

module.exports = { get };
