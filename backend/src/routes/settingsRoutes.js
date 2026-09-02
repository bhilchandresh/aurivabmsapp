const express = require('express');
const { protect, authorize } = require('../middleware/authMiddleware');
const { getSettings, updateSettings, getContactMessages } = require('../controllers/settingsController');

const router = express.Router();

// Settings routes are strictly for super admins
router.use(protect);
router.use(authorize('super_admin'));

router.route('/')
  .get(getSettings)
  .put(updateSettings);

router.route('/contact-messages')
  .get(getContactMessages);

module.exports = router;
