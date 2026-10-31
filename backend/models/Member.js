const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
    nombre: { type: String, required: [true, 'El nombre es requerido'], trim: true },
    nombres: { type: String, trim: true, default: null },
    apellidos: { type: String, trim: true, default: null },
    tipoUsuario: { type: String, enum: ['estudiante', 'profesor', null], default: null },
    programa: { type: String, required: [true, 'El programa es requerido'], trim: true },
    semestre: {
      type: Number,
      min: [1, 'Semestre mínimo 1'],
      max: [10, 'Semestre máximo 10'],
      default: null,
      validate: {
        validator: function (value) {
          if (this.tipoUsuario === 'profesor') return value == null;
          return value != null;
        },
        message: 'El semestre es requerido para estudiantes'
      }
    },
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
  obj.esCuentaVinculada = Boolean(obj.userId);
  delete obj.userId;
  return obj;
});

module.exports = mongoose.model('Member', memberSchema);
