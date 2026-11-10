const AuditLog = require('../models/AuditLog');

// Registra una acción del semillero. Si falla, solo se registra en consola:
// la operación principal no debe fallar por la auditoría.
async function registrar({ semilleroId, usuarioId, accion, entidad, entidadId = null, detalle = null }) {
  try {
    await AuditLog.create({
      semilleroId,
      usuarioId: usuarioId || null,
      accion,
      entidad,
      entidadId: entidadId ? String(entidadId) : null,
      detalle: detalle ? String(detalle).slice(0, 300) : null
    });
  } catch (error) {
    console.error('No se pudo registrar la auditoría:', error.message);
  }
}

module.exports = { registrar };
