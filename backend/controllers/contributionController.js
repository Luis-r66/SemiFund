const mongoose = require('mongoose');
const Contribution = require('../models/Contribution');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');
const { registrar } = require('../utils/audit');
const { estaConfigurado, subirComprobante, borrarComprobante } = require('../services/cloudinary');
const { parsePagination, paginatedBody } = require('../utils/pagination');
const { invalidateBalance } = require('../utils/balance');
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

// Nombres de los integrantes de la página consultada. Evita que el cliente
// tenga que bajar toda la lista de integrantes solo para poner nombres.
async function nombresDeIntegrantes(semilleroId, ids) {
  if (!ids || ids.length === 0) return new Map();
  const miembros = await Member.find({ _id: { $in: ids }, semilleroId }).select('nombre');
  return new Map(miembros.map((m) => [m.id, m.nombre]));
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

function auditar(req, item, accion, detalle = null) {
  return registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion,
    entidad: 'aporte',
    entidadId: item.id,
    detalle: detalle || item.mes
  });
}

function miMemberId(req) {
  return req.membership.memberId ? req.membership.memberId.toString() : null;
}

const list = asyncHandler(async (req, res) => {
  const paginacion = parsePagination(req.query);
  if (paginacion.error) return res.status(400).json({ error: paginacion.error });

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

  const consulta = Contribution.find(filter).sort({ _id: -1 });
  if (!paginacion.paginated) {
    const items = await consulta;
    const memberId = miMemberId(req);
    return res.status(200).json(
      items.map((item) => {
        const data = item.toJSON();
        data.esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
        return data;
      })
    );
  }

  const [docs, total] = await Promise.all([
    consulta.skip(paginacion.skip).limit(paginacion.limit),
    Contribution.countDocuments(filter)
  ]);
  const nombres = await nombresDeIntegrantes(
    req.semilleroId,
    [...new Set(docs.map((item) => String(item.integranteId)))]
  );
  const memberId = miMemberId(req);
  const items = docs.map((item) => {
    const data = item.toJSON();
    data.esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
    data.integranteNombre = nombres.get(String(item.integranteId)) || null;
    return data;
  });
  res.status(200).json(paginatedBody(items, total, paginacion.page, paginacion.limit));
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
  await auditar(req, contribution, 'aporte.crear', `${contribution.mes} · ${contribution.monto}`);
  res.status(201).json(contribution);
});

// POST /api/contributions/bulk  { mes, monto, concepto, integranteIds? }  (tesorero)
// Crea una cuota por integrante activo que aún no la tenga para ese mes.
const bulkCreate = asyncHandler(async (req, res) => {
  const body = cuerpo(req);
  const { mes, monto, concepto, integranteIds } = body;
  if (typeof mes !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(mes)) {
    return res.status(400).json({ error: 'mes debe tener formato YYYY-MM' });
  }
  if (typeof monto !== 'number' || !Number.isFinite(monto) || round(monto) <= 0) {
    return res.status(400).json({ error: 'El monto debe ser un número mayor a 0' });
  }
  if (typeof concepto !== 'string' || !concepto.trim()) {
    return res.status(400).json({ error: 'El concepto no puede estar vacío' });
  }
  if (integranteIds !== undefined && (!Array.isArray(integranteIds) || integranteIds.some((id) => !mongoose.Types.ObjectId.isValid(id)))) {
    return res.status(400).json({ error: 'integranteIds debe ser una lista de ids válidos' });
  }

  const filtro = { semilleroId: req.semilleroId, activo: true };
  if (integranteIds) filtro._id = { $in: integranteIds };
  const miembros = await Member.find(filtro);
  const idsValidos = new Set(miembros.map((m) => m.id));

  const existentes = await Contribution.find({
    semilleroId: req.semilleroId,
    mes,
    integranteId: { $in: miembros.map((m) => m._id) }
  }).select('integranteId');
  const yaTienen = new Set(existentes.map((item) => item.integranteId.toString()));

  const omitidas = [];
  let creadas = 0;
  for (const member of miembros) {
    if (yaTienen.has(member.id)) {
      omitidas.push({ integranteId: member.id, motivo: 'Ya tiene cuota para ese mes' });
      continue;
    }
    await Contribution.create({
      integranteId: member._id,
      semilleroId: req.semilleroId,
      monto: round(monto),
      mes,
      concepto: concepto.trim(),
      montoPagado: 0
    });
    creadas++;
  }
  for (const id of integranteIds || []) {
    if (!idsValidos.has(String(id))) {
      omitidas.push({ integranteId: String(id), motivo: 'Integrante no existe o está inactivo' });
    }
  }

  await registrar({
    semilleroId: req.semilleroId,
    usuarioId: req.userId,
    accion: 'aporte.cuotas_masivas',
    entidad: 'aporte',
    detalle: `${mes} · ${creadas} creadas · ${round(monto)}`
  });
  res.status(201).json({ creadas, omitidas });
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, esTesorero ? 'aporte.abono_registrado' : 'aporte.abono_reportado', `${monto}`);
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.abono_aprobado', `${abono.monto}`);
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.abono_rechazado', `${abono.monto}`);
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.abono_anulado', `${abono.monto}`);
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.reportado');
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.pago_total', `${item.monto}`);
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
  invalidateBalance(req.semilleroId);
  await auditar(req, item, 'aporte.reporte_rechazado');
  res.status(200).json(item);
});

// POST /api/contributions/:id/payments/:abonoId/comprobante
// Recibe un archivo (imagen o PDF) y lo sube a Cloudinary desde el backend.
const TIPOS_COMPROBANTE = {
  'image/jpeg': { tipo: 'imagen', resourceType: 'image' },
  'image/png': { tipo: 'imagen', resourceType: 'image' },
  'image/webp': { tipo: 'imagen', resourceType: 'image' },
  'application/pdf': { tipo: 'pdf', resourceType: 'raw' }
};

const attachReceipt = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.abonoId)) {
    return res.status(400).json({ error: 'El id del abono no es válido' });
  }
  if (!estaConfigurado()) {
    return res.status(503).json({ error: 'El almacenamiento de comprobantes no está configurado' });
  }
  if (!req.file || !req.file.buffer || req.file.buffer.length === 0) {
    return res.status(400).json({ error: 'Adjunta un archivo de comprobante' });
  }

  const formato = TIPOS_COMPROBANTE[req.file.mimetype];
  if (!formato) {
    return res.status(415).json({
      error: 'El comprobante debe ser una imagen JPG, PNG, WebP o un PDF'
    });
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
  if (abono.estado === 'anulado') {
    return res.status(409).json({ error: 'No se puede adjuntar un comprobante a un abono anulado' });
  }

  const esTesorero = Boolean(req.membership.esTesorero);
  const memberId = miMemberId(req);
  const esPropio = Boolean(memberId) && item.integranteId.toString() === memberId;
  if (!esTesorero && !esPropio) {
    return res.status(403).json({ error: 'Solo puedes adjuntar comprobantes de tus propios aportes' });
  }

  let subido;
  try {
    subido = await subirComprobante(req.file.buffer, {
      publicId: `${item._id}_${abono._id}_${Date.now()}`,
      resourceType: formato.resourceType
    });
  } catch (error) {
    return res.status(error.status || 502).json({ error: error.message });
  }

  const anterior = abono.comprobante ? abono.comprobante.publicId : null;
  const anteriorTipo = abono.comprobante ? abono.comprobante.tipo : null;

  abono.comprobante = {
    url: subido.url,
    publicId: subido.publicId,
    tipo: formato.tipo,
    nombre: req.file.originalname ? req.file.originalname.slice(0, 160) : null,
    bytes: subido.bytes || req.file.size || null,
    subidoPor: req.userId,
    subidoEn: new Date()
  };
  await item.save();

  if (anterior) {
    await borrarComprobante(anterior, anteriorTipo === 'pdf' ? 'raw' : 'image');
  }

  await auditar(req, item, 'aporte.comprobante_adjuntado', `${abono._id}`);
  res.status(200).json(item);
});

module.exports = {
  list,
  create,
  bulkCreate,
  report,
  pay,
  reject,
  addPayment,
  approvePayment,
  rejectPayment,
  voidPayment,
  attachReceipt
};
