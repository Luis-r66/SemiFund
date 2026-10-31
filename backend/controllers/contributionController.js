const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');

const STATUS_MAP = {
  pending: 'pendiente',
  paid: 'pagado',
  overdue: 'vencido',
  reported: 'reportado'
};

async function marcarVencidos(semilleroId) {
  const now = new Date();
  const mesActual = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  await Contribution.updateMany(
    { semilleroId, estado: 'pendiente', mes: { $lt: mesActual } },
    { $set: { estado: 'vencido' } }
  );
}

const list = asyncHandler(async (req, res) => {
  await marcarVencidos(req.semilleroId);
  const filter = { semilleroId: req.semilleroId };
  if (req.query.status) {
    const estado = STATUS_MAP[req.query.status];
    if (!estado) {
      return res.status(400).json({
        error: 'status debe ser pending, paid, overdue o reported'
      });
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
  const memberId = req.membership.memberId
    ? req.membership.memberId.toString()
    : null;
  res.status(200).json(
    items.map((item) => {
      const data = item.toJSON();
      data.esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
      return data;
    })
  );
});

const create = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body)
    ? req.body
    : {};
  const { integranteId, monto, mes, concepto } = body;
  if (!integranteId || monto === undefined || !mes || !concepto) {
    return res.status(400).json({
      error: 'integranteId, monto, mes y concepto son requeridos'
    });
  }
  if (typeof concepto !== 'string' || !concepto.trim()) {
    return res.status(400).json({ error: 'El concepto no puede estar vacío' });
  }
  if (!mongoose.Types.ObjectId.isValid(integranteId)) {
    return res.status(400).json({ error: 'integranteId no es válido' });
  }
  const member = await Member.findOne({
    _id: integranteId,
    semilleroId: req.semilleroId
  });
  if (!member) {
    return res.status(400).json({ error: 'El integrante no existe' });
  }

  const existente = await Contribution.findOne({
    semilleroId: req.semilleroId,
    integranteId,
    mes
  });
  if (existente) {
    return res.status(409).json({
      error: 'Ya existe un aporte para ese integrante en ese mes'
    });
  }

  const contribution = await Contribution.create({
    integranteId,
    monto,
    mes,
    concepto: concepto.trim(),
    semilleroId: req.semilleroId
  });
  res.status(201).json(contribution);
});

const report = asyncHandler(async (req, res) => {
  const memberId = req.membership.memberId
    ? req.membership.memberId.toString()
    : null;
  if (!memberId) {
    return res.status(403).json({
      error: 'Tu cuenta no está vinculada a un integrante de este semillero'
    });
  }

  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  if (item.integranteId.toString() !== memberId) {
    return res.status(403).json({ error: 'Solo puedes reportar tus propios aportes' });
  }
  if (item.estado === 'pagado') {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  if (item.estado === 'reportado') {
    return res.status(409).json({ error: 'El aporte ya fue reportado' });
  }

  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body)
    ? req.body
    : {};
  const { referencia } = body;
  if (referencia !== undefined && typeof referencia !== 'string') {
    return res.status(400).json({ error: 'La referencia debe ser texto' });
  }

  item.estado = 'reportado';
  item.fechaReporte = new Date();
  item.reportadoPor = req.userId;
  item.referencia = typeof referencia === 'string' ? referencia.trim() || null : null;
  item.fechaRevision = null;
  item.revisadoPor = null;
  item.motivoRechazo = null;
  await item.save();
  res.status(200).json(item);
});

const pay = asyncHandler(async (req, res) => {
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  if (item.estado === 'pagado') {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  item.estado = 'pagado';
  item.fechaPago = new Date();
  item.fechaRevision = new Date();
  item.revisadoPor = req.userId;
  item.motivoRechazo = null;
  await item.save();
  res.status(200).json(item);
});

const reject = asyncHandler(async (req, res) => {
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  if (item.estado !== 'reportado') {
    return res.status(409).json({
      error: 'Solo se pueden rechazar aportes reportados'
    });
  }

  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body)
    ? req.body
    : {};
  const { motivo } = body;
  if (motivo !== undefined && typeof motivo !== 'string') {
    return res.status(400).json({ error: 'El motivo debe ser texto' });
  }

  item.estado = 'pendiente';
  item.fechaRevision = new Date();
  item.revisadoPor = req.userId;
  item.motivoRechazo = typeof motivo === 'string' ? motivo.trim() || null : null;
  await item.save();
  res.status(200).json(item);
});

module.exports = { list, create, report, pay, reject, marcarVencidos };
