const express = require('express');
const multer = require('multer');
const validateObjectId = require('../middleware/validateObjectId');
const { requireProfesor } = require('../middleware/auth');
const c = require('../controllers/documentController');

const router = express.Router();

// Las plantillas .docx y .xlsx con logos pesan poco: 10 MB es holgado y
// evita que alguien suba un archivo enorme por error.
const plantillaUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 1 }
});

function subirPlantilla(req, res, next) {
  plantillaUpload.single('archivo')(req, res, (error) => {
    if (error) return next(error);
    next();
  });
}

// Catálogo de etiquetas que la app puede llenar.
router.get('/tags', requireProfesor, c.etiquetas);

// Plantillas del semillero.
router.get('/templates', requireProfesor, c.listar);
router.post('/templates', requireProfesor, subirPlantilla, c.subir);
router.put('/templates/:id', requireProfesor, validateObjectId, subirPlantilla, c.reemplazar);
router.delete('/templates/:id', requireProfesor, validateObjectId, c.eliminar);

// Genera el archivo lleno y lo devuelve como descarga.
router.post('/templates/:id/generate', requireProfesor, validateObjectId, c.generar);

module.exports = router;
