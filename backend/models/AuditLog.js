const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true },
    usuarioId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    accion: { type: String, required: true, maxlength: 60 },
    entidad: { type: String, required: true, maxlength: 40 },
    entidadId: { type: String, default: null, maxlength: 40 },
    detalle: { type: String, default: null, maxlength: 300 },
    creadoEn: { type: Date, default: Date.now }
  },
  { collection: 'audit_logs', timestamps: false }
);

auditLogSchema.index({ semilleroId: 1, creadoEn: -1 });

auditLogSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  delete obj.__v;
  return obj;
});

module.exports = mongoose.model('AuditLog', auditLogSchema);
