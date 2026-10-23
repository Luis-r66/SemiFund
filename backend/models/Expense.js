const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    descripcion: { type: String, required: [true, 'La descripcion es requerida'], trim: true },
    categoria: { type: String, required: [true, 'La categoria es requerida'], trim: true, lowercase: true },
    monto: { type: Number, required: [true, 'El monto es requerido'], min: [0.01, 'El monto debe ser mayor a 0'] },
    fecha: { type: Date, default: Date.now },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true }
  },
  { collection: 'expenses', timestamps: false }
);

expenseSchema.index({ categoria: 1, fecha: 1 });

expenseSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
});

module.exports = mongoose.model('Expense', expenseSchema);
