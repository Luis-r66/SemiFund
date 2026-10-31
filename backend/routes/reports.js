const express = require('express');
const auth = require('../middleware/auth');
const c = require('../controllers/reportController');

const router = express.Router();

router.get(
  '/movimientos.csv',
  auth.requireAuth,
  auth.requireSemillero,
  auth.requireTesorero,
  c.movimientos
);

module.exports = router;
