const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const c = require('../controllers/contributionController');

const router = express.Router();

router.get('/', c.list);
router.post('/', c.create);
router.patch('/:id/pay', validateObjectId, c.pay);

module.exports = router;
