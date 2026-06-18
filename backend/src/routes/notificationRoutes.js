const express = require('express');
const router = express.Router();
const { 
  getNotifications, 
  createNotification, 
  markAsRead 
} = require('../controllers/notificationController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/', getNotifications);
router.post('/', authorize('super_admin'), createNotification);
router.put('/:id/read', markAsRead);

module.exports = router;
