const express = require('express');
const { getBlockedIPs, blockIP, unblockIP, getActiveTrafficController } = require('../controllers/securityController');
const { protect, authorize } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all security routes and restrict to super admin
router.use(protect);
router.use(authorize('super_admin'));

router.get('/active-traffic', getActiveTrafficController);
router.get('/blocked-ips', getBlockedIPs);
router.post('/block-ip', blockIP);
router.delete('/unblock-ip/:ip', unblockIP);

module.exports = router;
