const express = require('express');
const { requireTesorero } = require('../middleware/auth');
const c = require('../controllers/expenseController');

const router = express.Router();

// Cualquier miembro activo del semillero puede consultar gastos.
router.get('/', c.list);

// Solo el tesorero puede registrar gastos.
router.post('/', requireTesorero, c.create);

module.exports = router;
