const asyncHandler = require('../middleware/asyncHandler');
const Member = require('../models/Member');
const Contribution = require('../models/Contribution');
const Expense = require('../models/Expense');
const { getBalance } = require('../utils/balance');
const { filtroCuotasPorCobrar } = require('../utils/summary');

// GET /api/summary
// Todo lo que el inicio necesita, en una sola llamada: saldo, integrantes
// activos, cuotas por cobrar y gastos registrados. La cuenta de cuotas es
// personal para el integrante; el tesorero ve el semillero completo.
const get = asyncHandler(async (req, res) => {
  const esTesorero = Boolean(req.membership.esTesorero);
  const memberId = req.membership.memberId
    ? req.membership.memberId.toString()
    : null;
  const filtroCuotas = filtroCuotasPorCobrar({
    semilleroId: req.semilleroId,
    esTesorero,
    memberId
  });

  const [balance, activeMembers, pendingContributions, expensesCount] = await Promise.all([
    getBalance(req.semilleroId),
    Member.countDocuments({ semilleroId: req.semilleroId, activo: true }),
    filtroCuotas ? Contribution.countDocuments(filtroCuotas) : 0,
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
