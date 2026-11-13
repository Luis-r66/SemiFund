const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const User = require('../models/User');
const asyncHandler = require('../middleware/asyncHandler');
const { parsePagination, paginatedBody } = require('../utils/pagination');

// GET /api/notifications?page=1&limit=20&unread=true
const list = asyncHandler(async (req, res) => {
  const paginacion = parsePagination(req.query);
  if (paginacion.error) return res.status(400).json({ error: paginacion.error });

  const filter = { userId: req.userId, semilleroId: req.semilleroId };
  if (req.query.unread === 'true') filter.leida = false;

  const consulta = Notification.find(filter).sort({ createdAt: -1, _id: -1 });
  if (!paginacion.paginated) {
    return res.status(200).json(await consulta.limit(50));
  }

  const [items, total] = await Promise.all([
    consulta.skip(paginacion.skip).limit(paginacion.limit),
    Notification.countDocuments(filter)
  ]);
  res.status(200).json(paginatedBody(items, total, paginacion.page, paginacion.limit));
});

// GET /api/notifications/unread-count
const unreadCount = asyncHandler(async (req, res) => {
  const count = await Notification.countDocuments({
    userId: req.userId,
    semilleroId: req.semilleroId,
    leida: false
  });
  res.status(200).json({ count });
});

// POST /api/notifications/read-all
const markAllRead = asyncHandler(async (req, res) => {
  const resultado = await Notification.updateMany(
    { userId: req.userId, semilleroId: req.semilleroId, leida: false },
    { $set: { leida: true } }
  );
  res.status(200).json({ updated: resultado.modifiedCount || 0 });
});

// PATCH /api/notifications/:id/read
const markRead = asyncHandler(async (req, res) => {
  if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
    return res.status(400).json({ error: 'El id de la notificación no es válido' });
  }
  const item = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.userId, semilleroId: req.semilleroId },
    { $set: { leida: true } },
    { returnDocument: 'after' }
  );
  if (!item) return res.status(404).json({ error: 'Notificación no encontrada' });
  res.status(200).json(item);
});

// GET /api/notifications/preferences
const getPreferences = asyncHandler(async (req, res) => {
  const user = await User.findById(req.userId).select('avisosPorCorreo');
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  res.status(200).json({ avisosPorCorreo: user.avisosPorCorreo !== false });
});

// PATCH /api/notifications/preferences  { avisosPorCorreo }
const updatePreferences = asyncHandler(async (req, res) => {
  const body = req.body || {};
  if (typeof body.avisosPorCorreo !== 'boolean') {
    return res.status(400).json({ error: 'avisosPorCorreo debe ser verdadero o falso' });
  }
  const user = await User.findByIdAndUpdate(
    req.userId,
    { $set: { avisosPorCorreo: body.avisosPorCorreo } },
    { new: true }
  ).select('avisosPorCorreo');
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  res.status(200).json({ avisosPorCorreo: user.avisosPorCorreo });
});

module.exports = {
  list,
  unreadCount,
  markAllRead,
  markRead,
  getPreferences,
  updatePreferences
};
