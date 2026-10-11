const express = require('express');
const {
  getSubscriptions,
  getTransactions,
  getCoupons,
  createCoupon,
  updateCoupon,
  deleteCoupon,
  getMessages,
  updateMessageStatus,
  assignPlan
} = require('../controllers/superadminController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes require authentication and super_admin role
router.use(protect);
router.use(authorize('super_admin'));

router.get('/subscriptions', getSubscriptions);
router.post('/assign-plan', assignPlan);

router.get('/transactions', getTransactions);

router.route('/coupons')
  .get(getCoupons)
  .post(createCoupon);
  
router.route('/coupons/:id')
  .put(updateCoupon)
  .delete(deleteCoupon);

router.route('/messages')
  .get(getMessages);
  
router.route('/messages/:id')
  .put(updateMessageStatus);

module.exports = router;
