const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

// Mapea el filtro en inglés de la spec a los estados en español de la DB
const STATUS_MAP = { pending: 'pendiente', paid: 'pagado', overdue: 'vencido' };

// GET /api/contributions?status=pending&memberId=  (filtrado por semillero activo)
const list = asyncHandler(async (req, res) => {
  const filter = { semilleroId: req.semilleroId };
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
  const member = await Member.findOne({ _id: integranteId, semilleroId: req.semilleroId });
  if (!member) return res.status(400).json({ error: 'El integrante no existe' });

  const contribution = await Contribution.create({ integranteId, monto, mes, semilleroId: req.semilleroId });
  res.status(201).json(contribution);
});

// PATCH /api/contributions/:id/pay  (solo si pertenece al semillero activo)
const pay = asyncHandler(async (req, res) => {
  const item = await Contribution.findOne({ _id: req.params.id, semilleroId: req.semilleroId });
  if (!item) return res.status(404).json({ error: 'Aporte no encontrado' });
  if (item.estado === 'pagado') {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  item.estado = 'pagado';
  item.fechaPago = new Date();
  await item.save();
  res.status(200).json(item);
});

module.exports = { list, create, pay };
