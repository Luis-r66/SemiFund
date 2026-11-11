const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const { requireTesorero } = require('../middleware/auth');
const c = require('../controllers/contributionController');

const router = express.Router();

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

module.exports = router;
