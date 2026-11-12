const crypto = require('crypto');
const { Readable } = require('stream');
const cloudinary = require('cloudinary').v2;

const CARPETA = 'semifund/comprobantes';

let configurado = false;

function estaConfigurado() {
  return Boolean(
    process.env.CLOUDINARY_CLOUD_NAME &&
      process.env.CLOUDINARY_API_KEY &&
      process.env.CLOUDINARY_API_SECRET
  );
}

function configurar() {
  if (configurado || !estaConfigurado()) return estaConfigurado();
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true
  });
  configurado = true;
  return true;
}

// Sube un archivo en memoria a Cloudinary.
// Devuelve { url, publicId, formato, bytes }.
function subirComprobante(buffer, { publicId, resourceType = 'auto' } = {}) {
  if (!configurar()) {
    const error = new Error('El almacenamiento de comprobantes no está configurado');
    error.status = 503;
    throw error;
  }

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: CARPETA,
        public_id: publicId || crypto.randomUUID(),
        resource_type: resourceType,
        overwrite: false,
        unique_filename: false,
        use_filename: false
      },
      (error, result) => {
        if (error || !result) {
          const fallo = new Error('No pudimos guardar el comprobante. Intenta de nuevo.');
          fallo.status = 502;
          return reject(fallo);
        }
        resolve({
          url: result.secure_url,
          publicId: result.public_id,
          formato: result.format || null,
          bytes: result.bytes || null
        });
      }
    );
    Readable.from(buffer).pipe(stream);
  });
}

// Borrado best-effort: si falla, no rompe la operación principal.
async function borrarComprobante(publicId, resourceType = 'image') {
  if (!publicId || !configurar()) return false;
  try {
    await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType,
      invalidate: true
    });
    return true;
  } catch (_) {
    return false;
  }
}

module.exports = {
  CARPETA,
  estaConfigurado,
  subirComprobante,
  borrarComprobante
};
