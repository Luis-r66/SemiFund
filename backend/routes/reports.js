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

router.get(
  '/libro.xlsx',
  auth.requireAuth,
  auth.requireSemillero,
  auth.requireTesorero,
  c.libro
);

router.get(
  '/plantilla.xlsx',
  auth.requireAuth,
  auth.requireSemillero,
  auth.requireTesorero,
  c.plantilla
);

module.exports = router;
