const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const { requireTesorero } = require('../middleware/auth');
const c = require('../controllers/memberController');

const router = express.Router();

// Cualquier miembro activo del semillero puede consultar.
router.get('/', c.list);
router.get('/:id', validateObjectId, c.getById);

// Solo el tesorero puede crear, editar o desactivar integrantes.
router.post('/', requireTesorero, c.create);
router.put('/:id', validateObjectId, requireTesorero, c.update);
router.delete('/:id', validateObjectId, requireTesorero, c.remove);

module.exports = router;
