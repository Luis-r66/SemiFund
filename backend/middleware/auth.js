const jwt = require('jsonwebtoken');
const User = require('../models/User');
const JWT_SECRET = require('../config/jwt');

// Middleware: valida el token Bearer y setea req.userId
async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Se requiere token de autenticación' });
  }
  const token = auth.substring(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ error: 'Usuario no encontrado o sesión inválida' });
    }
    if ((user.tokenVersion || 0) !== (decoded.tokenVersion || 0)) {
      return res.status(401).json({ error: 'Tu sesión expiró. Inicia sesión de nuevo.' });
    }
    req.userId = decoded.userId;
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
}
// Middleware: valida que exista X-Semillero-Id y que el usuario tenga membresía activa
async function requireSemillero(req, res, next) {
  const semilleroId = req.headers['x-semillero-id'];
  if (!semilleroId) {
    return res.status(400).json({ error: 'Se requiere el encabezado X-Semillero-Id' });
  }
  if (!require('mongoose').Types.ObjectId.isValid(semilleroId)) {
    return res.status(400).json({ error: 'ID de semillero no válido' });
  }
  const membresia = await require('../models/Membership').findOne({
    userId: req.userId,
    semilleroId,
    estado: 'activo'
  });
  if (!membresia) {
    return res.status(403).json({ error: 'No tienes acceso a este semillero' });
  }
  const semillero = await require('../models/Semillero').findById(semilleroId);
  if (!semillero) {
    return res.status(404).json({ error: 'Semillero no encontrado' });
  }
  req.semillero = semillero;
  req.semilleroId = semilleroId;
  req.membership = membresia;
  next();
}

// Middleware: solo tesorero del semillero activo
function requireTesorero(req, res, next) {
  if (!req.membership || !req.membership.esTesorero) {
    return res.status(403).json({ error: 'Se requiere rol de tesorero en este semillero' });
  }
  next();
}

module.exports = { requireAuth, requireSemillero, requireTesorero };
