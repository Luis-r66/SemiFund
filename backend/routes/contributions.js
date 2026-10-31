const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const { requireTesorero } = require('../middleware/auth');
const c = require('../controllers/contributionController');

const router = express.Router();

// Cualquier miembro activo del semillero puede consultar aportes.
router.get('/', c.list);

// Solo el tesorero puede registrar y pagar aportes.
router.post('/', requireTesorero, c.create);
router.patch('/:id/pay', validateObjectId, requireTesorero, c.pay);
// Cualquier integrante activo puede reportar su propio aporte.
router.patch('/:id/report', validateObjectId, c.report);
// Solo el tesorero puede rechazar un aporte reportado.
router.patch('/:id/reject', validateObjectId, requireTesorero, c.reject);

module.exports = router;
