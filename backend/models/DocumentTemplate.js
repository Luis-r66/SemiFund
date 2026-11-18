const mongoose = require('mongoose');

// Plantilla de documento que sube un profesor: su .docx o .xlsx con etiquetas
// {{campo}}. Se guarda en Cloudinary porque el disco de Render es efímero.
// El archivo generado nunca se guarda: se devuelve y se descarta.
const documentTemplateSchema = new mongoose.Schema(
  {
    semilleroId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Semillero',
      required: true,
      index: true
    },
    nombre: { type: String, required: [true, 'El nombre es requerido'], trim: true },
    tipo: { type: String, enum: ['docx', 'xlsx'], required: true },
    // URL y public_id de Cloudinary (resource_type: raw).
    url: { type: String, required: true },
    publicId: { type: String, required: true },
    bytes: { type: Number, default: null },
    // Etiquetas encontradas al subirla, para mostrarlas en la app.
    etiquetas: { type: [String], default: [] },
    creadoPor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
  },
  { collection: 'document_templates', timestamps: true }
);

documentTemplateSchema.method('toJSON', function () {
  const obj = this.toObject();
  obj.id = obj._id.toString();
  delete obj.url;
  delete obj.publicId;
  delete obj.__v;
  return obj;
});

module.exports = mongoose.model('DocumentTemplate', documentTemplateSchema);
