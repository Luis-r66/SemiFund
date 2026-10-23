const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Semillero = require('../models/Semillero');
const Membership = require('../models/Membership');
const Member = require('../models/Member');
const asyncHandler = require('../middleware/asyncHandler');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'semillero-dev-secret-cambiar-en-produccion';
const JWT_EXPIRES_IN = '7d';

function firmarToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

// POST /api/auth/register
const register = asyncHandler(async (req, res) => {
  const { nombre, email, password } = req.body;
  if (!nombre || !email || !password) {
    return res.status(400).json({ error: 'nombre, email y contraseña son requeridos' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
  }
  const existe = await User.findOne({ email: email.toLowerCase() });
  if (existe) {
    return res.status(409).json({ error: 'El correo ya está registrado' });
  }
  const user = await User.create({
    nombre: nombre.trim(),
    email: email.toLowerCase().trim(),
    passwordHash: await bcrypt.hash(password, 10)
  });
  const token = firmarToken(user._id);
  res.status(201).json({ token, user: { id: user.id, nombre: user.nombre, email: user.email } });
});

// POST /api/auth/login
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Correo y contraseña son requeridos' });
  }
  const user = await User.findOne({ email: email.toLowerCase().trim() });
  if (!user) {
    return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
  }
  const valida = await user.compararPassword(password);
  if (!valida) {
    return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
  }
  const token = firmarToken(user._id);
  res.status(200).json({ token, user: { id: user.id, nombre: user.nombre, email: user.email } });
});

// POST /api/auth/logout
const logout = asyncHandler(async (req, res) => {
  res.status(200).json({ mensaje: 'Sesión cerrada' });
});

// GET /api/auth/me
const me = asyncHandler(async (req, res) => {
  const user = await User.findById(req.userId);
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  const membresias = await Membership.find({ userId: user._id, estado: 'activo' })
    .populate('semilleroId', 'nombre codigo');
  res.status(200).json({
    id: user.id,
    nombre: user.nombre,
    email: user.email,
      semilleros: membresias.map(m => ({
        semilleroId: m.semilleroId._id,
        semilleroNombre: m.semilleroId.nombre,
        semilleroCodigo: m.esTesorero ? m.semilleroId.codigo : null,
        esTesorero: m.esTesorero,
        estado: m.estado
      }))
  });
});

module.exports = { register, login, logout, me };
