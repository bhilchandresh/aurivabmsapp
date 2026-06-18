const express = require('express');
const router = express.Router();
const { createOrder, verifyPayment } = require('../controllers/paymentController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

// Only Admins can manage payments/subscriptions for their tenant
router.post('/create-order', authorize('admin'), createOrder);
router.post('/verify', authorize('admin'), verifyPayment);

module.exports = router;
