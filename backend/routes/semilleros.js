const express = require('express');
const auth = require('../middleware/auth');
const c = require('../controllers/semilleroController');

const router = express.Router();

// Rutas de usuario (sin X-Semillero-Id)
router.get('/', auth.requireAuth, c.listarMisSemilleros);          // GET /api/semilleros  -> mis membresías
router.post('/', auth.requireAuth, c.crear);                        // POST /api/semilleros -> crear semillero
router.post('/join', auth.requireAuth, c.unirse);                   // POST /api/semilleros/join -> unirse con código

// Rutas del semillero ACTIVO (requieren X-Semillero-Id)
router.get('/me', auth.requireAuth, auth.requireSemillero, c.detalle);           // GET /api/semilleros/me
router.patch('/me', auth.requireAuth, auth.requireSemillero, auth.requireTesorero, c.renombrar); // PATCH /api/semilleros/me
router.post('/me/code/rotate', auth.requireAuth, auth.requireSemillero, auth.requireTesorero, c.rotarCodigo); // POST /api/semilleros/me/code/rotate
router.get('/me/accounts', auth.requireAuth, auth.requireSemillero, auth.requireTesorero, c.listarCuentas); // GET /api/semilleros/me/accounts
router.patch('/me/accounts/:membershipId', auth.requireAuth, auth.requireSemillero, auth.requireTesorero, c.actualizarCuenta); // PATCH /api/semilleros/me/accounts/:id

module.exports = router;
