const express = require('express');
const rateLimit = require('express-rate-limit');
const auth = require('../middleware/auth');
const c = require('../controllers/authController');

const router = express.Router();

function limiter(windowMs, limit, mensaje) {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: mensaje }
  });
}

const loginLimiter = limiter(15 * 60 * 1000, 10, 'Demasiados intentos de inicio de sesión. Intenta más tarde.');
const registerLimiter = limiter(60 * 60 * 1000, 5, 'Demasiados registros desde esta conexión. Intenta más tarde.');
const forgotLimiter = limiter(15 * 60 * 1000, 5, 'Demasiadas solicitudes de recuperación. Intenta más tarde.');
const resetLimiter = limiter(15 * 60 * 1000, 10, 'Demasiados intentos de recuperación. Intenta más tarde.');
const passwordLimiter = limiter(15 * 60 * 1000, 5, 'Demasiados cambios de contraseña. Intenta más tarde.');

router.post('/register', registerLimiter, c.register);
router.post('/login', loginLimiter, c.login);
router.post('/logout', auth.requireAuth, c.logout);
router.get('/me', auth.requireAuth, c.me);

router.patch('/me', auth.requireAuth, c.updateMe);
router.patch('/password', auth.requireAuth, passwordLimiter, c.changePassword);

router.post('/forgot-password', forgotLimiter, c.forgotPassword);
router.post('/reset-password', resetLimiter, c.resetPassword);

module.exports = router;
