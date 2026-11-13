const mongoose = require('mongoose');

const TIPOS = [
  'abono_reportado',
  'abono_aprobado',
  'abono_rechazado',
  'cuota_nueva',
  'invitacion_aceptada'
];

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true },
    tipo: { type: String, enum: TIPOS, required: true },
    titulo: { type: String, required: true, trim: true, maxlength: 120 },
    mensaje: { type: String, required: true, trim: true, maxlength: 300 },
    contributionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Contribution', default: null },
    memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', default: null },
    actorNombre: { type: String, trim: true, default: null },
    leida: { type: Boolean, default: false }
  },
  { collection: 'notifications', timestamps: { createdAt: true, updatedAt: false } }
);

notificationSchema.index({ userId: 1, semilleroId: 1, leida: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, semilleroId: 1, createdAt: -1 });

notificationSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  obj.userId = obj.userId ? obj.userId.toString() : null;
  obj.semilleroId = obj.semilleroId ? obj.semilleroId.toString() : null;
  obj.contributionId = obj.contributionId ? obj.contributionId.toString() : null;
  obj.memberId = obj.memberId ? obj.memberId.toString() : null;
  delete obj.__v;
  return obj;
});

module.exports = mongoose.model('Notification', notificationSchema);
module.exports.TIPOS = TIPOS;
