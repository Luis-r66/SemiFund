const express = require('express');
const c = require('../controllers/auditController');

const router = express.Router();

router.get('/', c.list);

module.exports = router;
