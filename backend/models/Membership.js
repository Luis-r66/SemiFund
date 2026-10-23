const mongoose = require('mongoose');

const membershipSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true },
    esTesorero: { type: Boolean, default: false },
    estado: { type: String, enum: ['pendiente', 'activo', 'rechazado', 'inactivo'], default: 'pendiente' },
    memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'Member' }
  },
  { collection: 'memberships', timestamps: true }
);

// Un usuario solo puede tener una membresía por semillero
membershipSchema.index({ userId: 1, semilleroId: 1 }, { unique: true });

membershipSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  delete obj.__v;
  return obj;
});

module.exports = mongoose.model('Membership', membershipSchema);
