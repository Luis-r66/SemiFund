const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema(
  {
    nombre: { type: String, required: [true, 'El nombre es requerido'], trim: true },
    programa: { type: String, required: [true, 'El programa es requerido'], trim: true },
    semestre: { type: Number, required: [true, 'El semestre es requerido'], min: [1, 'Semestre mínimo 1'], max: [10, 'Semestre máximo 10'] },
    activo: { type: Boolean, default: true },
    fechaIngreso: { type: Date, default: Date.now },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true }
  },
  { collection: 'members', timestamps: false }
);

// Expone `id` además de `_id` para facilitar el consumo desde Android
memberSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
});

module.exports = mongoose.model('Member', memberSchema);
