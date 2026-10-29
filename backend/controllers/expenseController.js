const Expense = require('../models/Expense');
const asyncHandler = require('../middleware/asyncHandler');
const { getBalance } = require('../utils/balance');

// GET /api/expenses?category=&month=YYYY-MM  (filtrado por semillero activo)
const list = asyncHandler(async (req, res) => {
  const filter = { semilleroId: req.semilleroId };
  if (req.query.category) filter.categoria = String(req.query.category).toLowerCase();

  if (req.query.month) {
    if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(req.query.month)) {
      return res.status(400).json({ error: 'month debe tener formato YYYY-MM' });
    }
    const [y, m] = req.query.month.split('-').map(Number);
    filter.fecha = {
      $gte: new Date(y, m - 1, 1),
      $lt: new Date(y, m, 1)
    };
  }

  const items = await Expense.find(filter).sort({ fecha: -1 });
  res.status(200).json(items);
});

// POST /api/expenses  { descripcion, categoria, monto, fecha? }
// REGLA 1: monto no puede superar el saldo disponible -> 409
const create = asyncHandler(async (req, res) => {
  const { descripcion, categoria, monto, fecha } = req.body;
  if (!descripcion || !categoria || monto === undefined) {
    return res.status(400).json({ error: 'descripcion, categoria y monto son requeridos' });
  }

  if (fecha !== undefined) {
    const fechaGasto = new Date(fecha);
    if (Number.isNaN(fechaGasto.getTime())) {
      return res.status(400).json({ error: 'fecha no es una fecha válida' });
    }
    // Margen de un día por diferencias de zona horaria
    if (fechaGasto.getTime() > Date.now() + 24 * 60 * 60 * 1000) {
      return res.status(400).json({ error: 'La fecha del gasto no puede ser futura' });
    }
  }

  const { saldoDisponible } = await getBalance(req.semilleroId);
  if (Number(monto) > saldoDisponible) {
    return res.status(409).json({ error: 'Saldo insuficiente' });
  }

  const expense = await Expense.create({ descripcion, categoria, monto, semilleroId: req.semilleroId, ...(fecha ? { fecha } : {}) });
  res.status(201).json(expense);
});

module.exports = { list, create };
