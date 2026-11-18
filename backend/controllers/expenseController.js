const Expense = require('../models/Expense');
const asyncHandler = require('../middleware/asyncHandler');
const { getBalance, invalidateBalance } = require('../utils/balance');
const { hoyBogota } = require('../utils/validators');
const { registrar } = require('../utils/audit');
const { parsePagination, paginatedBody } = require('../utils/pagination');

// GET /api/expenses?category=&month=YYYY-MM&page=1&limit=20  (filtrado por semillero activo)
const list = asyncHandler(async (req, res) => {
  const paginacion = parsePagination(req.query);
  if (paginacion.error) return res.status(400).json({ error: paginacion.error });

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

  const consulta = Expense.find(filter).sort({ fecha: -1 });
  if (!paginacion.paginated) {
    return res.status(200).json(await consulta);
  }

  const [items, total] = await Promise.all([
    consulta.skip(paginacion.skip).limit(paginacion.limit),
    Expense.countDocuments(filter)
  ]);
  res.status(200).json(paginatedBody(items, total, paginacion.page, paginacion.limit));
});

// POST /api/expenses  { descripcion, categoria, monto, fecha? }
// REGLA 1: monto no puede superar el saldo disponible -> 409
const create = asyncHandler(async (req, res) => {
  const { descripcion, categoria, monto, fecha, proveedor, nit, numeroFactura, tasaCambio } = req.body;
  if (!descripcion || !categoria || monto === undefined) {
    return res.status(400).json({ error: 'descripcion, categoria y monto son requeridos' });
  }

  // Campos de factura: texto libre, se recortan y se guardan solo si vienen.
  const datosFactura = {};
  if (proveedor !== undefined && proveedor !== null && `${proveedor}`.trim()) {
    datosFactura.proveedor = `${proveedor}`.trim().slice(0, 120);
  }
  if (nit !== undefined && nit !== null && `${nit}`.trim()) {
    datosFactura.nit = `${nit}`.trim().slice(0, 40);
  }
  if (numeroFactura !== undefined && numeroFactura !== null && `${numeroFactura}`.trim()) {
    datosFactura.numeroFactura = `${numeroFactura}`.trim().slice(0, 60);
  }
  if (tasaCambio !== undefined && tasaCambio !== null && tasaCambio !== '') {
    const tasa = Number(tasaCambio);
    if (!Number.isFinite(tasa) || tasa < 0) {
      return res.status(400).json({ error: 'La tasa de cambio debe ser un número positivo' });
    }
    datosFactura.tasaCambio = tasa;
  }

  let fechaGasto = null;
  if (fecha !== undefined) {
    const dia = typeof fecha === 'string' ? fecha.slice(0, 10) : '';
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dia) || Number.isNaN(new Date(`${dia}T12:00:00-05:00`).getTime())) {
      return res.status(400).json({ error: 'fecha no es una fecha válida (YYYY-MM-DD)' });
    }
    if (dia > hoyBogota()) {
      return res.status(400).json({ error: 'La fecha del gasto no puede ser futura' });
    }
    // Mediodía de Colombia: la fecha no cambia de mes por diferencias de zona horaria.
    fechaGasto = new Date(`${dia}T12:00:00-05:00`);
  }

  const { saldoDisponible } = await getBalance(req.semilleroId);
  if (Number(monto) > saldoDisponible) {
    return res.status(409).json({ error: 'Saldo insuficiente' });
  }

  const expense = await Expense.create({
    descripcion,
    categoria,
    monto,
    ...datosFactura,
    semilleroId: req.semilleroId,
    ...(fechaGasto ? { fecha: fechaGasto } : {})
  });
  invalidateBalance(req.semilleroId);
  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'gasto.crear',
    entidad: 'gasto',
    entidadId: expense.id,
    detalle: `${descripcion} · ${monto}`
  });
  res.status(201).json(expense);
});

module.exports = { list, create };
