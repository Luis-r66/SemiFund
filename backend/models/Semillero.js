const mongoose = require('mongoose');

const semilleroSchema = new mongoose.Schema(
  {
    nombre: { type: String, required: [true, 'El nombre del semillero es requerido'], trim: true },
    codigo: { type: String, required: true, unique: true, uppercase: true, trim: true },
    creadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    activo: { type: Boolean, default: true }
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
