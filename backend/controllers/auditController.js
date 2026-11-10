const AuditLog = require('../models/AuditLog');
const asyncHandler = require('../middleware/asyncHandler');

// GET /api/audit?limit=100  (solo tesorero, semillero activo)
const list = asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 100, 1), 200);
  const items = await AuditLog.find({ semilleroId: req.semilleroId })
    .sort({ creadoEn: -1 })
    .limit(limit)
    .populate('usuarioId', 'nombres apellidos nombre email');
  res.status(200).json(items);
});

module.exports = { list };
