const express = require('express');
const multer = require('multer');
const validateObjectId = require('../middleware/validateObjectId');
const { requireTesorero } = require('../middleware/auth');
const c = require('../controllers/contributionController');

const router = express.Router();

const comprobanteUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 }
});

// Convierte los errores de multer en respuestas JSON con el formato del API.
function subirComprobante(req, res, next) {
  comprobanteUpload.single('comprobante')(req, res, (error) => {
    if (error) return next(error);
    next();
  });
}

// Cualquier miembro activo del semillero puede consultar aportes.
router.get('/', c.list);

// Solo el tesorero puede registrar y pagar aportes.
router.post('/', requireTesorero, c.create);
router.post('/bulk', requireTesorero, c.bulkCreate);
router.patch('/:id/pay', validateObjectId, requireTesorero, c.pay);
// Cualquier integrante activo puede reportar su propio aporte.
router.patch('/:id/report', validateObjectId, c.report);
// Solo el tesorero puede rechazar un aporte reportado.
router.patch('/:id/reject', validateObjectId, requireTesorero, c.reject);

// Abonos parciales: el integrante reporta (o el tesorero registra) un abono.
router.post('/:id/payments', validateObjectId, c.addPayment);
router.patch('/:id/payments/:abonoId/approve', validateObjectId, requireTesorero, c.approvePayment);
router.patch('/:id/payments/:abonoId/reject', validateObjectId, requireTesorero, c.rejectPayment);
router.patch('/:id/payments/:abonoId/void', validateObjectId, requireTesorero, c.voidPayment);
// Comprobante del abono: lo sube el integrante dueño o el tesorero.
router.post('/:id/payments/:abonoId/comprobante', validateObjectId, subirComprobante, c.attachReceipt);

module.exports = router;
