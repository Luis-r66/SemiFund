const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    descripcion: { type: String, required: [true, 'La descripcion es requerida'], trim: true },
    categoria: { type: String, required: [true, 'La categoria es requerida'], trim: true, lowercase: true },
    monto: { type: Number, required: [true, 'El monto es requerido'], min: [0.01, 'El monto debe ser mayor a 0'] },
    fecha: { type: Date, default: Date.now },
    // Datos de la factura o recibo. Opcionales: solo se piden cuando el gasto
    // se va a legalizar (viáticos) o cuando el profesor genera un documento.
    proveedor: { type: String, trim: true, default: null },
    nit: { type: String, trim: true, default: null },
    numeroFactura: { type: String, trim: true, default: null },
    tasaCambio: { type: Number, default: null, min: [0, 'La tasa de cambio no puede ser negativa'] },
    semilleroId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semillero', required: true }
  },
  { collection: 'expenses', timestamps: false }
);

expenseSchema.index({ semilleroId: 1, fecha: -1 });
expenseSchema.index({ categoria: 1, fecha: 1 });

expenseSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  return obj;
});

module.exports = mongoose.model('Expense', expenseSchema);
