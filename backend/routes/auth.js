const express = require('express');
const auth = require('../middleware/auth');
const c = require('../controllers/authController');

const router = express.Router();

router.post('/register', c.register);
router.post('/login', c.login);
router.post('/logout', auth.requireAuth, c.logout);
router.get('/me', auth.requireAuth, c.me);

module.exports = router;
