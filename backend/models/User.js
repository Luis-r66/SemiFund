const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    nombre: { type: String, required: [true, 'El nombre es requerido'], trim: true },
    nombres: { type: String, trim: true, default: null },
    apellidos: { type: String, trim: true, default: null },
    email: { type: String, required: [true, 'El correo es requerido'], unique: true, lowercase: true, trim: true },
    googleId: { type: String, unique: true, sparse: true },
    passwordHash: {
      type: String,
      required: [
        function () {
          return !this.googleId;
        },
        'La contraseña es requerida'
      ]
    },
    tipoUsuario: { type: String, enum: ['estudiante', 'profesor', null], default: null },
    programa: { type: String, trim: true, default: null },
    semestre: {
      type: Number,
      default: null,
      validate: {
        validator: (value) => value === null || value === undefined || (Number.isInteger(value) && value >= 1 && value <= 10),
        message: 'El semestre debe ser un entero entre 1 y 10'
      }
    },
    tokenVersion: { type: Number, default: 0 },
    // Preferencia de avisos por correo; se puede desactivar desde la campanita.
    avisosPorCorreo: { type: Boolean, default: true },
    creadoEn: { type: Date, default: Date.now }
  },
  { collection: 'users', timestamps: true }
);

// Nunca devolver el passwordHash en respuestas JSON
userSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  delete obj.passwordHash;
  delete obj.__v;
  return obj;
});

// Comparar contraseña candidata contra el hash almacenado.
// Las cuentas creadas solo con Google no tienen contraseña.
userSchema.methods.compararPassword = async function (candidata) {
  if (!this.passwordHash) return false;
  return bcrypt.compare(candidata, this.passwordHash);
};

module.exports = mongoose.model('User', userSchema);
