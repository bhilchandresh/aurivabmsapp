const express = require('express');
const { submitContactForm, getLegalDocument } = require('../controllers/publicController');

const router = express.Router();

router.post('/contact', submitContactForm);
router.get('/legal/:type', getLegalDocument);

module.exports = router;
