const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const c = require('../controllers/memberController');

const router = express.Router();

router.get('/', c.list);
router.get('/:id', validateObjectId, c.getById);
router.post('/', c.create);
router.put('/:id', validateObjectId, c.update);
router.delete('/:id', validateObjectId, c.remove);

module.exports = router;
