const mongoose = require('mongoose');

// Dinero que el semillero ya tenía antes de usar la app. No es un aporte de
// ningún integrante: se muestra aparte y solo el creador (o el tesorero actual
// si el creador ya no está activo) puede ajustarlo, siempre con auditoría.
const saldoInicialSchema = new mongoose.Schema(
  {
    monto: { type: Number, default: 0, min: [0, 'El saldo inicial no puede ser negativo'] },
    nota: { type: String, trim: true, maxlength: [300, 'La nota no puede superar 300 caracteres'], default: null },
    registradoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    actualizadoEn: { type: Date, default: null }
  },
  { _id: false }
);

const semilleroSchema = new mongoose.Schema(
  {
    nombre: { type: String, required: [true, 'El nombre del semillero es requerido'], trim: true },
    codigo: { type: String, required: true, unique: true, uppercase: true, trim: true },
    creadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    saldoInicial: { type: saldoInicialSchema, default: () => ({ monto: 0 }) },
    activo: { type: Boolean, default: true },
    eliminadoEn: { type: Date, default: null },
    eliminadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
  },
  { collection: 'semilleros', timestamps: true }
);

// Nunca devolver campos sensibles o internos innecesarios
semilleroSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  delete obj.__v;
  return obj;
});

module.exports = mongoose.model('Semillero', semilleroSchema);
