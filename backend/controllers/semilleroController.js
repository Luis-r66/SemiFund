const mongoose = require('mongoose');
const Semillero = require('../models/Semillero');
const Membership = require('../models/Membership');
const Member = require('../models/Member');
const User = require('../models/User');
const asyncHandler = require('../middleware/asyncHandler');

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
  const membresias = await Membership.find({ userId: req.userId })
    .populate('semilleroId', 'nombre codigo')
    .sort({ createdAt: -1 });
  const items = [];
  for (const m of membresias) {
    const miembros = await Member.countDocuments({
      semilleroId: m.semilleroId._id,
      activo: true
    });
    items.push({
      id: m.id,
      semilleroId: m.semilleroId._id,
      semilleroNombre: m.semilleroId.nombre,
      semilleroCodigo: m.esTesorero ? m.semilleroId.codigo : null,
      esTesorero: m.esTesorero,
      estado: m.estado,
      miembros
    });
  }
  res.status(200).json(items);
});

// POST /api/semilleros  { nombre }
const crear = asyncHandler(async (req, res) => {
  const { nombre } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El nombre del semillero es requerido' });
  }
  const userId = req.userId;
  const user = await User.findById(userId);
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  let codigo = generarCodigo();
  while (await Semillero.findOne({ codigo })) {
    codigo = generarCodigo();
  }
  const semillero = await Semillero.create({
    nombre: nombre.trim(),
    codigo,
    creadoPor: userId
  });
  // El creador queda como tesorero activo y se crea su registro de integrante vinculado
  const member = await Member.create({
    nombre: user.nombre,
    programa: 'Sin definir',
    semestre: 1,
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
  res.status(201).json({
    semillero: { id: semillero.id, nombre: semillero.nombre, codigo: semillero.codigo },
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
    yaExiste.memberId = null;
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
  const respuesta = {
    id: semillero.id,
    nombre: semillero.nombre,
    creadoPor: semillero.creadoPor.toString(),
    esTesorero
  };
  if (esTesorero) {
    respuesta.codigo = semillero.codigo;
  }
  res.status(200).json(respuesta);
});

// PATCH /api/semillero  { nombre }  (solo tesorero)
const renombrar = asyncHandler(async (req, res) => {
  const { nombre } = req.body;
  if (!nombre || !nombre.trim()) {
    return res.status(400).json({ error: 'El nombre es requerido' });
  }
  const semillero = await Semillero.findByIdAndUpdate(
    req.semillero._id,
    { nombre: nombre.trim() },
    { returnDocument: 'after' }
  );
  res.status(200).json({ id: semillero.id, nombre: semillero.nombre });
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
    .populate('userId', 'nombre email')
    .populate('memberId', 'nombre programa semestre activo')
    .sort({ createdAt: -1 });
  res.status(200).json(
    membresias.map(m => ({
      id: m.id,
      usuario: m.userId ? { id: m.userId.id, nombre: m.userId.nombre, email: m.userId.email } : null,
      integrante: m.memberId
        ? {
            id: m.memberId.id,
            nombre: m.memberId.nombre,
            programa: m.memberId.programa,
            semestre: m.memberId.semestre,
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
  if (estado) membresia.estado = estado;
  if (typeof esTesorero === 'boolean') membresia.esTesorero = esTesorero;
  await membresia.save();

  if (membresia.estado === 'activo' && !membresia.memberId && membresia.userId) {
    const member = await Member.create({
      nombre: membresia.userId.nombre || 'Integrante',
      programa: 'Sin definir',
      semestre: 1,
      activo: true,
      semilleroId: membresia.semilleroId
    });
    membresia.memberId = member._id;
    await membresia.save();
  }

  res.status(200).json({ id: membresia.id, estado: membresia.estado, esTesorero: membresia.esTesorero });
});

module.exports = { listarMisSemilleros, crear, unirse, detalle, renombrar, rotarCodigo, listarCuentas, actualizarCuenta };
