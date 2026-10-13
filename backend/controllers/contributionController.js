const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

// Mapea el filtro en inglés de la spec a los estados en español de la DB
const STATUS_MAP = { pending: 'pendiente', paid: 'pagado', overdue: 'vencido' };

// GET /api/contributions?status=pending&memberId=
const list = asyncHandler(async (req, res) => {
  const filter = {};
  if (req.query.status) {
    const estado = STATUS_MAP[req.query.status];
    if (!estado) {
      return res.status(400).json({ error: 'status debe ser pending, paid u overdue' });
    }
    filter.estado = estado;
  }
  if (req.query.memberId) {
    if (!mongoose.Types.ObjectId.isValid(req.query.memberId)) {
      return res.status(400).json({ error: 'memberId no es válido' });
    }
    filter.integranteId = req.query.memberId;
  }
  const items = await Contribution.find(filter).sort({ _id: -1 });
  res.status(200).json(items);
});

// POST /api/contributions  { integranteId, monto, mes }
const create = asyncHandler(async (req, res) => {
  const { integranteId, monto, mes } = req.body;
  if (!integranteId || monto === undefined || !mes) {
    return res.status(400).json({ error: 'integranteId, monto y mes son requeridos' });
  }
  if (!mongoose.Types.ObjectId.isValid(integranteId)) {
    return res.status(400).json({ error: 'integranteId no es válido' });
  }
  const member = await Member.findById(integranteId);
  if (!member) return res.status(400).json({ error: 'El integrante no existe' });

  const contribution = await Contribution.create({ integranteId, monto, mes });
  res.status(201).json(contribution);
});

// PATCH /api/contributions/:id/pay
// Regla: pendiente->pagado, vencido->pagado. Un pagado no se modifica (409).
const pay = asyncHandler(async (req, res) => {
  const item = await Contribution.findById(req.params.id);
  if (!item) return res.status(404).json({ error: 'Aporte no encontrado' });
  if (item.estado === 'pagado') {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  // Solo pendiente o vencido pueden pasar a pagado
  item.estado = 'pagado';
  item.fechaPago = new Date();
  await item.save();
  res.status(200).json(item);
});

module.exports = { list, create, pay };
