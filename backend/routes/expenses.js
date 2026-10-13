const express = require('express');
const c = require('../controllers/expenseController');

const router = express.Router();

router.get('/', c.list);
router.post('/', c.create);

module.exports = router;
