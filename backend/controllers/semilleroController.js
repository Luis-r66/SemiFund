const mongoose = require('mongoose');
const Semillero = require('../models/Semillero');
const Membership = require('../models/Membership');
const Member = require('../models/Member');
const User = require('../models/User');
const asyncHandler = require('../middleware/asyncHandler');
const { academicFieldsFromUser } = require('../utils/memberSync');
const { notificar, tesorerosDe } = require('../utils/notifications');
const { registrar: auditar } = require('../utils/audit');
const { getBalance, invalidateBalance } = require('../utils/balance');
const { nombreSemilleroValido, textoValido } = require('../utils/validators');
const {
  puedeEliminar,
  nombreConfirma,
  puedeSalir,
  puedeAjustarSaldoInicial
} = require('../utils/semilleroRules');

const round = (value) => Math.round(Number(value) * 100) / 100;

// El saldo inicial de los semilleros anteriores a la 1.5.0 no existe en la
// base: se lee como cero sin reescribir el documento.
function saldoInicialDe(semillero) {
  const saldo = semillero && semillero.saldoInicial ? semillero.saldoInicial : null;
  return {
    monto: saldo && Number.isFinite(Number(saldo.monto)) ? round(saldo.monto) : 0,
    nota: saldo && saldo.nota ? saldo.nota : null,
    registradoPor: saldo && saldo.registradoPor ? String(saldo.registradoPor) : null,
    actualizadoEn: saldo && saldo.actualizadoEn ? saldo.actualizadoEn : null
  };
}

// Devuelve { monto } o { error }. Acepta número o texto numérico.
function leerMonto(valor, { requerido = false } = {}) {
  if (valor === undefined || valor === null || valor === '') {
    return requerido ? { error: 'El saldo inicial es requerido' } : { monto: 0 };
  }
  const numero = Number(valor);
  if (!Number.isFinite(numero)) return { error: 'El saldo inicial debe ser un número' };
  if (numero < 0) return { error: 'El saldo inicial no puede ser negativo' };
  return { monto: round(numero) };
}

function leerNota(valor) {
  if (valor === undefined || valor === null) return { nota: null };
  if (typeof valor !== 'string') return { error: 'La nota debe ser texto' };
  const nota = valor.trim();
  if (nota.length > 300) return { error: 'La nota no puede superar 300 caracteres' };
  return { nota: nota || null };
}

async function creadorSigueActivo(semillero) {
  if (!semillero.creadoPor) return false;
  const activa = await Membership.findOne({
    semilleroId: semillero._id,
    userId: semillero.creadoPor,
    estado: 'activo'
  }).select('_id');
  return Boolean(activa);
}

// Genera un código alfanumérico de 8 caracteres (mayúsculas y dígitos, sin ambiguos)
function generarCodigo() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let codigo = '';
  for (let i = 0; i < 8; i++) {
    codigo += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return codigo;
}

// GET /api/semilleros  -> lista las membresías del usuario con info del semillero
const listarMisSemilleros = asyncHandler(async (req, res) => {
  // Las membresías inactivas no se listan: al salir o eliminar el semillero
  // la tarjeta desaparece en lugar de quedar como un fantasma.
  const membresias = await Membership.find({ userId: req.userId, estado: { $ne: 'inactivo' } })
    .populate('semilleroId', 'nombre codigo activo creadoPor saldoInicial ciudad centroCostos')
    .sort({ createdAt: -1 });
  const items = [];
  for (const m of membresias) {
    if (!m.semilleroId || m.semilleroId.activo === false) continue;
    const miembros = await Member.countDocuments({
      semilleroId: m.semilleroId._id,
      activo: true
    });
    const esCreador = String(m.semilleroId.creadoPor) === String(req.userId);
    const creadorActivo = esCreador
      ? true
      : Boolean(await Membership.exists({
          semilleroId: m.semilleroId._id,
          userId: m.semilleroId.creadoPor,
          estado: 'activo'
        }));
    items.push({
      id: m.id,
      semilleroId: m.semilleroId._id,
      semilleroNombre: m.semilleroId.nombre,
      semilleroCodigo: m.esTesorero ? m.semilleroId.codigo : null,
      esTesorero: m.esTesorero,
      esCreador,
      estado: m.estado,
      miembros,
      ciudad: m.semilleroId.ciudad || null,
      centroCostos: m.semilleroId.centroCostos || null,
      saldoInicial: saldoInicialDe(m.semilleroId).monto,
      saldoInicialNota: saldoInicialDe(m.semilleroId).nota,
      puedeAjustarSaldoInicial: puedeAjustarSaldoInicial({
        creadoPor: m.semilleroId.creadoPor,
        userId: req.userId,
        esTesorero: m.esTesorero,
        creadorActivo
      })
    });
  }
  res.status(200).json(items);
});

// POST /api/semilleros  { nombre, saldoInicial?, saldoInicialNota? }
const crear = asyncHandler(async (req, res) => {
  const { nombre, saldoInicial, saldoInicialNota } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El nombre del semillero es requerido' });
  }
  if (!nombreSemilleroValido(nombre)) {
    return res.status(400).json({
      error: 'El nombre del semillero solo puede tener letras, espacios y signos como &, punto, coma o guion'
    });
  }
  const monto = leerMonto(saldoInicial);
  if (monto.error) return res.status(400).json({ error: monto.error });
  const nota = leerNota(saldoInicialNota);
  if (nota.error) return res.status(400).json({ error: nota.error });

  const userId = req.userId;
  const user = await User.findById(userId);
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  let codigo = generarCodigo();
  while (await Semillero.findOne({ codigo })) {
    codigo = generarCodigo();
  }
  let semillero;
  let member;
  try {
    semillero = await Semillero.create({
      nombre: nombre.trim(),
      codigo,
      creadoPor: userId,
      saldoInicial: {
        monto: monto.monto,
        nota: nota.nota,
        registradoPor: userId,
        actualizadoEn: monto.monto > 0 || nota.nota ? new Date() : null
      }
    });
    member = await Member.create({
      ...academicFieldsFromUser(user),
      userId,
      activo: true,
      semilleroId: semillero._id
    });
    await Membership.create({
      userId,
      semilleroId: semillero._id,
      esTesorero: true,
      estado: 'activo',
      memberId: member._id
    });
  } catch (error) {
    if (member) await Member.deleteOne({ _id: member._id });
    if (semillero) await Semillero.deleteOne({ _id: semillero._id });
    throw error;
  }
  if (monto.monto > 0 || nota.nota) {
    await auditar({
      semilleroId: semillero._id,
      usuarioId: userId,
      accion: 'semillero.saldo_inicial',
      entidad: 'Semillero',
      entidadId: semillero._id,
      detalle: `${monto.monto}${nota.nota ? ` · ${nota.nota}` : ''}`
    });
  }
  res.status(201).json({
    semillero: {
      id: semillero.id,
      nombre: semillero.nombre,
      codigo: semillero.codigo,
      saldoInicial: saldoInicialDe(semillero)
    },
    saldoInicial: saldoInicialDe(semillero),
    memberId: member.id
  });
});

// POST /api/semilleros/join  { código }
const unirse = asyncHandler(async (req, res) => {
  const { codigo } = req.body;
  if (!codigo) {
    return res.status(400).json({ error: 'El código es requerido' });
  }
  const semillero = await Semillero.findOne({ codigo: codigo.toUpperCase(), activo: true });
  if (!semillero) {
    return res.status(404).json({ error: 'Código de semillero inválido' });
  }
  const userId = req.userId;
  const yaExiste = await Membership.findOne({ userId, semilleroId: semillero._id });
  if (yaExiste) {
    if (yaExiste.estado === 'activo') {
      return res.status(409).json({ error: 'Ya eres miembro activo de este semillero' });
    }
    yaExiste.estado = 'pendiente';
    yaExiste.esTesorero = false;
    // Se conserva memberId para que las cuotas anteriores sigan ligadas a la
    // misma persona. Al aprobar se reactiva el integrante, no se crea otro.
    await yaExiste.save();
    return res.status(201).json({
      semilleroId: semillero._id,
      semilleroNombre: semillero.nombre,
      estado: 'pendiente',
      mensaje: 'Solicitud reenviada. El tesorero debe aprobar tu cuenta.'
    });
  }
  const membresia = await Membership.create({
    userId,
    semilleroId: semillero._id,
    esTesorero: false,
    estado: 'pendiente'
  });
  res.status(201).json({
    semilleroId: semillero._id,
    semilleroNombre: semillero.nombre,
    estado: 'pendiente',
    mensaje: 'Solicitud enviada. El tesorero debe aprobar tu cuenta.'
  });
});

// GET /api/semillero  (requiere X-Semillero-Id)
const detalle = asyncHandler(async (req, res) => {
  const semillero = req.semillero;
  const esTesorero = req.membership.esTesorero;
  const esCreador = String(semillero.creadoPor) === String(req.userId);
  const creadorActivo = esCreador ? true : await creadorSigueActivo(semillero);
  const respuesta = {
    id: semillero.id,
    nombre: semillero.nombre,
    creadoPor: semillero.creadoPor.toString(),
    esTesorero,
    esCreador,
    ciudad: semillero.ciudad || null,
    centroCostos: semillero.centroCostos || null,
    saldoInicial: saldoInicialDe(semillero),
    puedeAjustarSaldoInicial: puedeAjustarSaldoInicial({
      creadoPor: semillero.creadoPor,
      userId: req.userId,
      esTesorero,
      creadorActivo
    })
  };
  if (esTesorero) {
    respuesta.codigo = semillero.codigo;
  }
  res.status(200).json(respuesta);
});

// PATCH /api/semilleros/me/saldo-inicial  { monto, nota? }
// Ajuste auditado del dinero con el que arrancó el semillero. No crea aportes.
const actualizarSaldoInicial = asyncHandler(async (req, res) => {
  const semillero = req.semillero;
  const esCreador = String(semillero.creadoPor) === String(req.userId);
  const creadorActivo = esCreador ? true : await creadorSigueActivo(semillero);
  if (!puedeAjustarSaldoInicial({
    creadoPor: semillero.creadoPor,
    userId: req.userId,
    esTesorero: Boolean(req.membership.esTesorero),
    creadorActivo
  })) {
    return res.status(403).json({
      error: 'Solo quien creó el semillero puede ajustar el saldo inicial'
    });
  }

  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const monto = leerMonto(body.monto, { requerido: true });
  if (monto.error) return res.status(400).json({ error: monto.error });
  const nota = leerNota(body.nota !== undefined ? body.nota : body.saldoInicialNota);
  if (nota.error) return res.status(400).json({ error: nota.error });

  const anterior = saldoInicialDe(semillero).monto;
  semillero.saldoInicial = {
    monto: monto.monto,
    nota: nota.nota,
    registradoPor: req.userId,
    actualizadoEn: new Date()
  };
  await semillero.save();
  invalidateBalance(semillero._id);

  await auditar({
    semilleroId: semillero._id,
    usuarioId: req.userId,
    accion: 'semillero.saldo_inicial_ajustado',
    entidad: 'Semillero',
    entidadId: semillero._id,
    detalle: `${anterior} → ${monto.monto}${nota.nota ? ` · ${nota.nota}` : ''}`
  });

  const balance = await getBalance(semillero._id, { force: true });
  res.status(200).json({
    saldoInicial: saldoInicialDe(semillero),
    ...balance
  });
});

// PATCH /api/semillero  { nombre?, ciudad?, centroCostos? }  (solo tesorero)
// Los tres datos alimentan los documentos del profesor: la ciudad se imprime
// en las actas y el centro de costos en la legalización de viáticos.
const renombrar = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const cambios = {};

  if (body.nombre !== undefined) {
    const { nombre } = body;
    if (!nombre || !nombre.trim()) {
      return res.status(400).json({ error: 'El nombre es requerido' });
    }
    if (!nombreSemilleroValido(nombre)) {
      return res.status(400).json({
        error: 'El nombre del semillero solo puede tener letras, espacios y signos como &, punto, coma o guion'
      });
    }
    cambios.nombre = nombre.trim();
  }

  if (body.ciudad !== undefined) {
    if (body.ciudad === null || `${body.ciudad}`.trim() === '') {
      cambios.ciudad = null;
    } else {
      const ciudad = textoValido(body.ciudad, { campo: 'La ciudad', maximo: 60 });
      if (ciudad.error) return res.status(400).json({ error: ciudad.error });
      cambios.ciudad = ciudad.valor;
    }
  }

  if (body.centroCostos !== undefined) {
    if (body.centroCostos === null || `${body.centroCostos}`.trim() === '') {
      cambios.centroCostos = null;
    } else {
      const centro = textoValido(body.centroCostos, { campo: 'El centro de costos', maximo: 80 });
      if (centro.error) return res.status(400).json({ error: centro.error });
      cambios.centroCostos = centro.valor;
    }
  }

  if (Object.keys(cambios).length === 0) {
    return res.status(400).json({ error: 'No hay datos para actualizar' });
  }

  const semillero = await Semillero.findByIdAndUpdate(
    req.semillero._id,
    { $set: cambios },
    { returnDocument: 'after' }
  );

  await auditar({
    semilleroId: req.semillero._id,
    usuarioId: req.userId,
    accion: 'semillero.datos_actualizados',
    entidad: 'Semillero',
    entidadId: req.semillero._id,
    detalle: Object.keys(cambios).join(', ')
  });

  res.status(200).json({
    id: semillero.id,
    nombre: semillero.nombre,
    ciudad: semillero.ciudad || null,
    centroCostos: semillero.centroCostos || null
  });
});

// POST /api/semillero/code/rotate  (solo tesorero)
const rotarCodigo = asyncHandler(async (req, res) => {
  let codigo = generarCodigo();
  while (await Semillero.findOne({ codigo, _id: { $ne: req.semillero._id } })) {
    codigo = generarCodigo();
  }
  const semillero = await Semillero.findByIdAndUpdate(
    req.semillero._id,
    { codigo },
    { returnDocument: 'after' }
  );
  res.status(200).json({ codigo: semillero.codigo });
});

// GET /api/semillero/accounts  (solo tesorero)
const listarCuentas = asyncHandler(async (req, res) => {
  const membresias = await Membership.find({ semilleroId: req.semillero._id })
    .populate('userId', 'nombre nombres apellidos email')
    .populate('memberId', 'userId nombre nombres apellidos tipoUsuario programa semestre activo')
    .sort({ createdAt: -1 });
  res.status(200).json(
    membresias.map(m => ({
      id: m.id,
      usuario: m.userId
        ? {
            id: m.userId.id,
            nombre: m.userId.nombre,
            nombres: m.userId.nombres || null,
            apellidos: m.userId.apellidos || null,
            email: m.userId.email
          }
        : null,
      integrante: m.memberId
        ? {
            id: m.memberId.id,
            nombre: m.memberId.nombre,
            nombres: m.memberId.nombres || null,
            apellidos: m.memberId.apellidos || null,
            tipoUsuario: m.memberId.tipoUsuario || null,
            programa: m.memberId.programa,
            semestre: m.memberId.semestre,
            esCuentaVinculada: Boolean(m.memberId.userId),
            activo: m.memberId.activo
          }
        : null,
      esTesorero: m.esTesorero,
      estado: m.estado,
      fechaSolicitud: m.createdAt
    }))
  );
});

// PATCH /api/semillero/accounts/:membershipId  { estado?, esTesorero? }  (solo tesorero)
const actualizarCuenta = asyncHandler(async (req, res) => {
  const { estado, esTesorero } = req.body;
  const membresia = await Membership.findById(req.params.membershipId).populate('userId');
  if (!membresia || membresia.semilleroId.toString() !== req.semillero._id.toString()) {
    return res.status(404).json({ error: 'Membresía no encontrada' });
  }
  // No permitir quitar el rol de tesorero si es el único tesorero activo
  if (esTesorero === false && membresia.esTesorero) {
    const tesorerosActivos = await Membership.countDocuments({
      semilleroId: req.semillero._id,
      esTesorero: true,
      estado: 'activo'
    });
    if (tesorerosActivos <= 1) {
      return res.status(409).json({ error: 'No se puede quitar el rol de tesorero: debe quedar al menos uno' });
    }
  }
  const estadoAnterior = membresia.estado;
  if (estado) membresia.estado = estado;
  if (typeof esTesorero === 'boolean') membresia.esTesorero = esTesorero;
  await membresia.save();

  if (membresia.estado === 'activo' && membresia.userId) {
    const fields = academicFieldsFromUser(membresia.userId);
    if (!membresia.memberId) {
      // Reutiliza el integrante que ya exista para esta cuenta y semillero:
      // evita duplicados al reingresar o al aprobar dos veces.
      const existente = await Member.findOne({
        semilleroId: membresia.semilleroId,
        userId: membresia.userId._id
      }).sort({ fechaIngreso: 1 });
      if (existente) {
        membresia.memberId = existente._id;
        await membresia.save();
      }
    }
    if (!membresia.memberId) {
      const member = await Member.create({
        ...fields,
        userId: membresia.userId._id,
        activo: true,
        semilleroId: membresia.semilleroId
      });
      membresia.memberId = member._id;
      await membresia.save();
    } else {
      await Member.findOneAndUpdate(
        { _id: membresia.memberId, semilleroId: membresia.semilleroId },
        { $set: { ...fields, userId: membresia.userId._id, activo: true } }
      );
    }
  }

  // Aviso al resto de tesoreros cuando una solicitud queda aceptada.
  if (estadoAnterior !== 'activo' && membresia.estado === 'activo') {
    const tesoreros = await tesorerosDe(req.semillero._id, { excluirUserId: req.userId });
    const nombre = membresia.userId ? membresia.userId.nombre : 'Un integrante';
    await notificar({
      semilleroId: req.semillero._id,
      destinatarios: tesoreros,
      tipo: 'invitacion_aceptada',
      titulo: 'Invitación aceptada',
      mensaje: `${nombre} ya es parte del semillero.`,
      memberId: membresia.memberId,
      actorNombre: nombre
    });
  }

  res.status(200).json({ id: membresia.id, estado: membresia.estado, esTesorero: membresia.esTesorero });
});

// DELETE /api/semilleros/me  { confirmacion }  (solo quien creó el semillero)
// Borrado lógico: el semillero y sus membresías dejan de estar disponibles,
// pero los datos quedan en la base para auditoría.
const eliminar = asyncHandler(async (req, res) => {
  const semillero = req.semillero;
  if (!puedeEliminar(semillero.creadoPor, req.userId)) {
    return res.status(403).json({ error: 'Solo quien creó el semillero puede eliminarlo' });
  }
  const confirmacion = (req.body || {}).confirmacion;
  if (!nombreConfirma(semillero.nombre, confirmacion)) {
    return res.status(400).json({ error: 'Escribe el nombre exacto del semillero para confirmar' });
  }

  semillero.activo = false;
  semillero.eliminadoEn = new Date();
  semillero.eliminadoPor = req.userId;
  await semillero.save();

  await Membership.updateMany(
    { semilleroId: semillero._id },
    { $set: { estado: 'inactivo', esTesorero: false } }
  );
  await Member.updateMany(
    { semilleroId: semillero._id },
    { $set: { activo: false } }
  );
  await auditar({
    semilleroId: semillero._id,
    usuarioId: req.userId,
    accion: 'eliminar',
    entidad: 'Semillero',
    entidadId: semillero._id,
    detalle: `Semillero eliminado: ${semillero.nombre}`
  });

  res.status(200).json({ ok: true, mensaje: 'El semillero fue eliminado.' });
});

// POST /api/semilleros/me/leave  (cualquier integrante activo)
const salir = asyncHandler(async (req, res) => {
  const membresia = req.membership;
  const tesorerosActivos = await Membership.countDocuments({
    semilleroId: req.semillero._id,
    esTesorero: true,
    estado: 'activo'
  });
  if (!puedeSalir({ esTesorero: membresia.esTesorero, tesorerosActivos })) {
    return res.status(409).json({
      error: 'Eres el único tesorero. Transfiere la tesorería a otro integrante antes de salir.'
    });
  }

  membresia.estado = 'inactivo';
  membresia.esTesorero = false;
  await membresia.save();
  if (membresia.memberId) {
    await Member.updateOne(
      { _id: membresia.memberId, semilleroId: req.semillero._id },
      { $set: { activo: false } }
    );
  }
  await auditar({
    semilleroId: req.semillero._id,
    usuarioId: req.userId,
    accion: 'salir',
    entidad: 'Membership',
    entidadId: membresia._id,
    detalle: 'El integrante salió del semillero'
  });

  res.status(200).json({ ok: true, mensaje: 'Saliste del semillero.' });
});

module.exports = {
  listarMisSemilleros,
  crear,
  unirse,
  detalle,
  actualizarSaldoInicial,
  renombrar,
  rotarCodigo,
  listarCuentas,
  actualizarCuenta,
  eliminar,
  salir
};
