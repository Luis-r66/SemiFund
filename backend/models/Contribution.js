const mongoose = require('mongoose');

const ESTADOS = ['pendiente', 'pagado', 'vencido', 'reportado'];

const contributionSchema = new mongoose.Schema(
  {
    integranteId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Member',
      required: [true, 'integranteId es requerido']
    },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true },
    monto: { type: Number, required: [true, 'El monto es requerido'], min: [0.01, 'El monto debe ser mayor a 0'] },
    mes: {
      type: String,
      required: [true, 'El mes es requerido'],
      match: [/^\d{4}-(0[1-9]|1[0-2])$/, 'El mes debe tener formato YYYY-MM, ej. 2026-09']
    },
    concepto: {
      type: String,
      required: [true, 'El concepto es requerido'],
      trim: true,
      maxlength: [200, 'El concepto no puede superar 200 caracteres']
    },
    estado: { type: String, enum: ESTADOS, default: 'pendiente' },
    fechaPago: { type: Date, default: null },
    referencia: { type: String, trim: true, maxlength: [120, 'La referencia no puede superar 120 caracteres'], default: null },
    fechaReporte: { type: Date, default: null },
    reportadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    fechaRevision: { type: Date, default: null },
    revisadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    motivoRechazo: { type: String, trim: true, maxlength: [200, 'El motivo no puede superar 200 caracteres'], default: null }
  },
  { collection: 'contributions', timestamps: { createdAt: true, updatedAt: false } }
);

contributionSchema.index({ integranteId: 1, estado: 1 });
contributionSchema.index({ semilleroId: 1, integranteId: 1, mes: 1 });

contributionSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  if (obj.integranteId) obj.integranteId = obj.integranteId.toString();
  return obj;
});

module.exports = mongoose.model('Contribution', contributionSchema);
