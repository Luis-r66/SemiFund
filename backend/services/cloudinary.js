const crypto = require('crypto');
const { Readable } = require('stream');
const cloudinary = require('cloudinary').v2;

const CARPETA = 'semifund/comprobantes';
const CARPETA_PLANTILLAS = 'semifund/plantillas';

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
function subirArchivo(buffer, { carpeta = CARPETA, publicId, resourceType = 'auto' } = {}) {
  if (!configurar()) {
    const error = new Error('El almacenamiento de archivos no está configurado');
    error.status = 503;
    throw error;
  }

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: carpeta,
        public_id: publicId || crypto.randomUUID(),
        resource_type: resourceType,
        overwrite: false,
        unique_filename: false,
        use_filename: false
      },
      (error, result) => {
        if (error || !result) {
          const fallo = new Error('No pudimos guardar el archivo. Intenta de nuevo.');
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

function subirComprobante(buffer, { publicId, resourceType = 'auto' } = {}) {
  return subirArchivo(buffer, { carpeta: CARPETA, publicId, resourceType });
}

// Las plantillas son .docx y .xlsx: Cloudinary los guarda como "raw" para no
// reinterpretarlos como imagen.
function subirPlantilla(buffer, { publicId, extension }) {
  const nombre = extension ? `${publicId}.${extension}` : publicId;
  return subirArchivo(buffer, {
    carpeta: CARPETA_PLANTILLAS,
    publicId: nombre,
    resourceType: 'raw'
  });
}

// Borrado best-effort: si falla, no rompe la operación principal.
async function borrarArchivo(publicId, resourceType = 'image') {
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

function borrarComprobante(publicId, resourceType = 'image') {
  return borrarArchivo(publicId, resourceType);
}

function borrarPlantilla(publicId) {
  return borrarArchivo(publicId, 'raw');
}

// Descarga los bytes de una plantilla guardada (URL segura de Cloudinary).
async function descargarPlantilla(url) {
  const respuesta = await fetch(url);
  if (!respuesta.ok) {
    const error = new Error('No pudimos leer la plantilla guardada. Vuelve a subirla.');
    error.status = 502;
    throw error;
  }
  return Buffer.from(await respuesta.arrayBuffer());
}

module.exports = {
  CARPETA,
  CARPETA_PLANTILLAS,
  estaConfigurado,
  subirComprobante,
  subirPlantilla,
  descargarPlantilla,
  borrarComprobante,
  borrarPlantilla
};
