const express = require('express');
const router = express.Router();
const webhookController = require('../controllers/webhookController');

// Webhook endpoint to receive email bounce events
router.post('/email', webhookController.handleEmailWebhook);

module.exports = router;
