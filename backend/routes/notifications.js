const express = require('express');
const validateObjectId = require('../middleware/validateObjectId');
const c = require('../controllers/notificationController');

const router = express.Router();

router.get('/', c.list);
router.get('/unread-count', c.unreadCount);
router.post('/read-all', c.markAllRead);
router.patch('/:id/read', validateObjectId, c.markRead);

module.exports = router;
