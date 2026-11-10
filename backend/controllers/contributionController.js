const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');
const {
  round,
  montoPagadoDe,
  saldoPendiente,
  abonoReportado,
  sincronizarEstado,
  agregarAbono,
  aprobarAbono,
  rechazarAbono,
  anularAbono
} = require('../utils/payments');

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

function cuerpo(req) {
  return req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
}

function validarMonto(valor, saldo) {
  if (typeof valor !== 'number' || !Number.isFinite(valor)) return 'El monto debe ser un número';
  if (round(valor) <= 0) return 'El monto debe ser mayor a 0';
  if (round(valor) > saldo) return `El monto supera el saldo pendiente (${saldo})`;
  return null;
}

function validarMotivo(motivo) {
  if (motivo !== undefined && typeof motivo !== 'string') return 'El motivo debe ser texto';
  return null;
}

function miMemberId(req) {
  return req.membership.memberId ? req.membership.memberId.toString() : null;
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
  const memberId = miMemberId(req);
  res.status(200).json(
    items.map((item) => {
      const data = item.toJSON();
      data.esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
      return data;
    })
  );
});

const create = asyncHandler(async (req, res) => {
  const body = cuerpo(req);
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
    montoPagado: 0,
    semilleroId: req.semilleroId
  });
  res.status(201).json(contribution);
});

// POST /api/contributions/:id/payments  { monto?, referencia? }
// Integrante: registra un abono reportado (espera revisión del tesorero).
// Tesorero: registra un abono ya aprobado (dinero recibido en efectivo o consignado).
// Sin monto se usa el saldo pendiente completo.
const addPayment = asyncHandler(async (req, res) => {
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }

  const esTesorero = Boolean(req.membership.esTesorero);
  const memberId = miMemberId(req);
  const esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
  if (!esTesorero && !esPropio) {
    return res.status(403).json({ error: 'Solo puedes reportar tus propios aportes' });
  }

  const saldo = saldoPendiente(item);
  if (saldo === 0 || item.estado === 'pagado') {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  if (abonoReportado(item)) {
    return res.status(409).json({ error: 'Ya hay un abono esperando revisión' });
  }

  const body = cuerpo(req);
  const monto = body.monto === undefined ? saldo : body.monto;
  const errorMonto = validarMonto(monto, saldo);
  if (errorMonto) {
    return res.status(400).json({ error: errorMonto });
  }
  if (body.referencia !== undefined && typeof body.referencia !== 'string') {
    return res.status(400).json({ error: 'La referencia debe ser texto' });
  }
  const referencia = typeof body.referencia === 'string' ? body.referencia.trim() || null : null;

  const now = new Date();
  agregarAbono(item, { monto, referencia, usuarioId: req.userId, aprobado: esTesorero, now });
  sincronizarEstado(item, now);
  await item.save();
  res.status(201).json(item);
});

// PATCH /api/contributions/:id/payments/:abonoId/approve
const approvePayment = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.abonoId)) {
    return res.status(400).json({ error: 'El id del abono no es válido' });
  }
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  const abono = item.abonos.id(req.params.abonoId);
  if (!abono) {
    return res.status(404).json({ error: 'Abono no encontrado' });
  }
  if (abono.estado !== 'reportado') {
    return res.status(409).json({ error: 'Solo se pueden aprobar abonos reportados' });
  }
  if (round(montoPagadoDe(item) + abono.monto) > round(item.monto)) {
    return res.status(409).json({ error: 'El abono supera el saldo pendiente' });
  }

  aprobarAbono(item, abono, req.userId, new Date());
  await item.save();
  res.status(200).json(item);
});

// PATCH /api/contributions/:id/payments/:abonoId/reject  { motivo? }
const rejectPayment = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.abonoId)) {
    return res.status(400).json({ error: 'El id del abono no es válido' });
  }
  const body = cuerpo(req);
  const errorMotivo = validarMotivo(body.motivo);
  if (errorMotivo) {
    return res.status(400).json({ error: errorMotivo });
  }
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  const abono = item.abonos.id(req.params.abonoId);
  if (!abono) {
    return res.status(404).json({ error: 'Abono no encontrado' });
  }
  if (abono.estado !== 'reportado') {
    return res.status(409).json({ error: 'Solo se pueden rechazar abonos reportados' });
  }

  rechazarAbono(item, abono, req.userId, typeof body.motivo === 'string' ? body.motivo.trim() || null : null, new Date());
  await item.save();
  res.status(200).json(item);
});

// PATCH /api/contributions/:id/payments/:abonoId/void  { motivo? }
// Anula un abono aprobado (por ejemplo, aprobado por error). Recalcula el saldo.
const voidPayment = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.abonoId)) {
    return res.status(400).json({ error: 'El id del abono no es válido' });
  }
  const body = cuerpo(req);
  const errorMotivo = validarMotivo(body.motivo);
  if (errorMotivo) {
    return res.status(400).json({ error: errorMotivo });
  }
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  const abono = item.abonos.id(req.params.abonoId);
  if (!abono) {
    return res.status(404).json({ error: 'Abono no encontrado' });
  }
  if (abono.estado !== 'aprobado') {
    return res.status(409).json({ error: 'Solo se pueden anular abonos aprobados' });
  }

  anularAbono(item, abono, req.userId, typeof body.motivo === 'string' ? body.motivo.trim() || null : null, new Date());
  await item.save();
  res.status(200).json(item);
});

const report = asyncHandler(async (req, res) => {
  const memberId = miMemberId(req);
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
  if (item.estado === 'pagado' || saldoPendiente(item) === 0) {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }
  if (item.estado === 'reportado' || abonoReportado(item)) {
    return res.status(409).json({ error: 'El aporte ya fue reportado' });
  }

  const body = cuerpo(req);
  const { referencia } = body;
  if (referencia !== undefined && typeof referencia !== 'string') {
    return res.status(400).json({ error: 'La referencia debe ser texto' });
  }

  const now = new Date();
  agregarAbono(item, {
    monto: saldoPendiente(item),
    referencia: typeof referencia === 'string' ? referencia.trim() || null : null,
    usuarioId: req.userId,
    aprobado: false,
    now
  });
  sincronizarEstado(item, now);
  await item.save();
  res.status(200).json(item);
});

// PATCH /api/contributions/:id/pay  (tesorero: cobra el saldo completo)
const pay = asyncHandler(async (req, res) => {
  const item = await Contribution.findOne({
    _id: req.params.id,
    semilleroId: req.semilleroId
  });
  if (!item) {
    return res.status(404).json({ error: 'Aporte no encontrado' });
  }
  if (item.estado === 'pagado' || saldoPendiente(item) === 0) {
    return res.status(409).json({ error: 'El aporte ya fue pagado' });
  }

  const now = new Date();
  const reportado = abonoReportado(item);
  if (reportado) {
    aprobarAbono(item, reportado, req.userId, now);
  }
  const saldo = saldoPendiente(item);
  if (saldo > 0) {
    agregarAbono(item, { monto: saldo, usuarioId: req.userId, aprobado: true, now });
  }
  sincronizarEstado(item, now);
  item.fechaPago = now;
  await item.save();
  res.status(200).json(item);
});

// PATCH /api/contributions/:id/reject  { motivo? }  (rechaza el abono reportado)
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

  const body = cuerpo(req);
  const { motivo } = body;
  if (motivo !== undefined && typeof motivo !== 'string') {
    return res.status(400).json({ error: 'El motivo debe ser texto' });
  }

  const now = new Date();
  const abono = abonoReportado(item);
  if (abono) {
    rechazarAbono(item, abono, req.userId, typeof motivo === 'string' ? motivo.trim() || null : null, now);
  } else {
    sincronizarEstado(item, now);
  }
  await item.save();
  res.status(200).json(item);
});

module.exports = {
  list,
  create,
  report,
  pay,
  reject,
  addPayment,
  approvePayment,
  rejectPayment,
  voidPayment,
  marcarVencidos
};
