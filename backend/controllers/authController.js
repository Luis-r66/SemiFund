const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const Membership = require('../models/Membership');
const PasswordReset = require('../models/PasswordReset');
const asyncHandler = require('../middleware/asyncHandler');
const { sendResetCode } = require('../utils/mailer');
const { syncMembersForUser } = require('../utils/memberSync');

const JWT_SECRET = require('../config/jwt');
const JWT_EXPIRES_IN = '7d';
const TIPOS_USUARIO = ['estudiante', 'profesor'];
const RESET_EXPIRES_MS = 15 * 60 * 1000;
const RESET_MAX_ATTEMPTS = 5;
const RESET_COOLDOWN_MS = 60 * 1000;

function firmarToken(user) {
  return jwt.sign(
    { userId: user._id, tokenVersion: user.tokenVersion || 0 },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

function publicUser(user) {
  return {
    id: user.id,
    nombre: user.nombre,
    nombres: user.nombres || null,
    apellidos: user.apellidos || null,
    email: user.email,
    tipoUsuario: user.tipoUsuario || null,
    programa: user.programa || null,
    semestre: user.semestre ?? null
  };
}

function extraerNombre(body, user = null) {
  const recibioPartes = body.nombres !== undefined || body.apellidos !== undefined;
  if (recibioPartes) {
    if (
      typeof body.nombres !== 'string' ||
      typeof body.apellidos !== 'string' ||
      !body.nombres.trim() ||
      !body.apellidos.trim()
    ) {
      return { error: 'nombres y apellidos son requeridos' };
    }
    const nombres = body.nombres.trim();
    const apellidos = body.apellidos.trim();
    return { nombres, apellidos, nombre: `${nombres} ${apellidos}` };
  }

  if (user) {
    return { nombres: user.nombres || null, apellidos: user.apellidos || null, nombre: user.nombre };
  }

  // Compatibilidad con clientes anteriores que envían un solo nombre.
  if (typeof body.nombre === 'string' && body.nombre.trim()) {
    return { nombres: null, apellidos: null, nombre: body.nombre.trim() };
  }
  return { error: 'nombres y apellidos son requeridos' };
}

// POST /api/auth/register
const register = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { email, password } = body;
  if (
    typeof email !== 'string' ||
    typeof password !== 'string' ||
    !email.trim() ||
    !password
  ) {
    return res.status(400).json({ error: 'nombres, apellidos, email y contraseña son requeridos' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
  }
  const nombre = extraerNombre(body);
  if (nombre.error) return res.status(400).json({ error: nombre.error });

  const existe = await User.findOne({ email: email.toLowerCase() });
  if (existe) return res.status(409).json({ error: 'El correo ya está registrado' });

  const user = await User.create({
    nombre: nombre.nombre,
    nombres: nombre.nombres,
    apellidos: nombre.apellidos,
    email: email.toLowerCase().trim(),
    passwordHash: await bcrypt.hash(password, 10)
  });
  const token = firmarToken(user);
  res.status(201).json({ token, user: publicUser(user), requierePerfil: true });
});

// POST /api/auth/login
const login = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { email, password } = body;
  if (typeof email !== 'string' || typeof password !== 'string' || !email.trim() || !password) {
    return res.status(400).json({ error: 'Correo y contraseña son requeridos' });
  }
  const user = await User.findOne({ email: email.toLowerCase().trim() });
  if (!user) return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
  const valida = await user.compararPassword(password);
  if (!valida) return res.status(401).json({ error: 'Correo o contraseña incorrectos' });

  const token = firmarToken(user);
  res.status(200).json({ token, user: publicUser(user) });
});

// POST /api/auth/logout
const logout = asyncHandler(async (req, res) => {
  res.status(200).json({ mensaje: 'Sesión cerrada' });
});

// GET /api/auth/me
const me = asyncHandler(async (req, res) => {
  const user = req.user || (await User.findById(req.userId));
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

  const membresias = await Membership.find({ userId: user._id, estado: 'activo' })
    .populate('semilleroId', 'nombre codigo');
  const semilleros = membresias
    .filter((m) => m.semilleroId)
    .map((m) => ({
      semilleroId: m.semilleroId._id,
      semilleroNombre: m.semilleroId.nombre,
      semilleroCodigo: m.esTesorero ? m.semilleroId.codigo : null,
      esTesorero: m.esTesorero,
      estado: m.estado
    }));

  res.status(200).json({ ...publicUser(user), semilleros });
});

// PATCH /api/auth/me
const updateMe = asyncHandler(async (req, res) => {
  const user = req.user || (await User.findById(req.userId));
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};

  const nombre = extraerNombre(body, user);
  if (nombre.error) return res.status(400).json({ error: nombre.error });

  const tipoSolicitado = body.tipoUsuario !== undefined ? body.tipoUsuario : user.tipoUsuario;
  if (tipoSolicitado !== null && tipoSolicitado !== undefined && !TIPOS_USUARIO.includes(tipoSolicitado)) {
    return res.status(400).json({ error: 'tipoUsuario debe ser estudiante o profesor' });
  }

  const programaSolicitado = body.programa !== undefined
    ? (typeof body.programa === 'string' ? body.programa.trim() : null)
    : user.programa;

  let semestre = body.semestre !== undefined ? body.semestre : user.semestre;
  const tipo = tipoSolicitado || null;

  if (tipo === 'estudiante') {
    if (!programaSolicitado) {
      return res.status(400).json({ error: 'La carrera o programa es requerida para estudiantes' });
    }
    const numero = Number(semestre);
    if (!Number.isInteger(numero) || numero < 1 || numero > 10) {
      return res.status(400).json({ error: 'El semestre debe ser un entero entre 1 y 10' });
    }
    semestre = numero;
  } else if (tipo === 'profesor') {
    if (!programaSolicitado) {
      return res.status(400).json({ error: 'El área o departamento es requerido para profesores' });
    }
    semestre = null;
  } else {
    if (body.programa !== undefined || body.semestre !== undefined) {
      return res.status(400).json({ error: 'Selecciona estudiante o profesor antes de guardar los datos académicos' });
    }
    semestre = null;
  }

  user.nombre = nombre.nombre;
  user.nombres = nombre.nombres;
  user.apellidos = nombre.apellidos;
  user.tipoUsuario = tipo;
  user.programa = programaSolicitado || null;
  user.semestre = semestre ?? null;
  await user.save();
  await syncMembersForUser(user).catch((error) => {
    console.error('No se pudo sincronizar el perfil del integrante:', error.message);
  });

  res.status(200).json(publicUser(user));
});

// PATCH /api/auth/password
const changePassword = asyncHandler(async (req, res) => {
  const user = req.user || (await User.findById(req.userId));
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { currentPassword, newPassword } = body;

  if (typeof currentPassword !== 'string' || typeof newPassword !== 'string' || !currentPassword || !newPassword) {
    return res.status(400).json({ error: 'La contraseña actual y la nueva son requeridas' });
  }
  if (newPassword.length < 8) {
    return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 8 caracteres' });
  }
  const valida = await user.compararPassword(currentPassword);
  if (!valida) {
    return res.status(401).json({ error: 'La contraseña actual es incorrecta' });
  }

  user.passwordHash = await bcrypt.hash(newPassword, 10);
  user.tokenVersion = (user.tokenVersion || 0) + 1;
  await user.save();

  res.status(200).json({
    mensaje: 'Contraseña actualizada',
    token: firmarToken(user)
  });
});

// POST /api/auth/forgot-password
const forgotPassword = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { email } = body;
  if (typeof email !== 'string' || !email.trim()) {
    return res.status(400).json({ error: 'El correo es requerido' });
  }

  const mensajeGenerico = {
    mensaje: 'Si el correo está registrado, recibirás un código de recuperación.'
  };
  const user = await User.findOne({ email: email.toLowerCase().trim() });
  if (!user) return res.status(200).json(mensajeGenerico);

  const reciente = await PasswordReset.findOne({
    userId: user._id,
    createdAt: { $gt: new Date(Date.now() - RESET_COOLDOWN_MS) }
  });
  if (reciente) return res.status(200).json(mensajeGenerico);

  const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
  const codeHash = await bcrypt.hash(code, 10);
  await PasswordReset.deleteMany({ userId: user._id });
  await PasswordReset.create({
    userId: user._id,
    codeHash,
    expiresAt: new Date(Date.now() + RESET_EXPIRES_MS)
  });

  try {
    await sendResetCode({ to: user.email, nombre: user.nombre, code });
  } catch (error) {
    console.error('No se pudo enviar el código de recuperación:', error.message);
    return res.status(503).json({
      error: 'No pudimos enviar el código de recuperación. Intenta más tarde.'
    });
  }

  res.status(200).json(mensajeGenerico);
});

// POST /api/auth/reset-password
const resetPassword = asyncHandler(async (req, res) => {
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};
  const { email, code, password } = body;
  if (
    typeof email !== 'string' ||
    typeof code !== 'string' ||
    typeof password !== 'string' ||
    !email.trim() ||
    !code.trim() ||
    !password
  ) {
    return res.status(400).json({ error: 'Correo, código y nueva contraseña son requeridos' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
  }

  const user = await User.findOne({ email: email.toLowerCase().trim() });
  const invalido = { error: 'Código inválido o expirado' };
  if (!user) return res.status(400).json(invalido);

  const reset = await PasswordReset.findOne({
    userId: user._id,
    used: false,
    expiresAt: { $gt: new Date() }
  }).sort({ createdAt: -1 });
  if (!reset) return res.status(400).json(invalido);

  const correcto = await bcrypt.compare(code.trim(), reset.codeHash);
  if (!correcto) {
    reset.attempts += 1;
    if (reset.attempts >= RESET_MAX_ATTEMPTS) reset.used = true;
    await reset.save();
    return res.status(400).json(invalido);
  }

  user.passwordHash = await bcrypt.hash(password, 10);
  user.tokenVersion = (user.tokenVersion || 0) + 1;
  await user.save();

  reset.used = true;
  await reset.save();
  await PasswordReset.deleteMany({ userId: user._id, _id: { $ne: reset._id } });

  res.status(200).json({
    mensaje: 'Contraseña actualizada. Inicia sesión con tu nueva contraseña.'
  });
});

module.exports = {
  register,
  login,
  logout,
  me,
  updateMe,
  changePassword,
  forgotPassword,
  resetPassword
};
