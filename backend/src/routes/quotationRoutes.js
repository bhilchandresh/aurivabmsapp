const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { 
  createQuotation, getQuotations, getQuotationById, updateQuotation, deleteQuotation, convertToInvoice, 
  downloadQuotationPDF, 
  emailQuotation,       
  whatsappQuotation,     
  getPublicQuotation // ✅ NEW
} = require('../controllers/quotationController');
const { downloadPublicQuotationPDF } = require('../controllers/pdfController'); // ✅ NEW

// --- PUBLIC ROUTES (No Auth) ---
router.get('/public/:id', getPublicQuotation);
router.post('/public/:id/download', downloadPublicQuotationPDF);

router.use(protect);

router.route('/').post(createQuotation).get(getQuotations);
router.route('/:id').get(getQuotationById).put(updateQuotation).delete(deleteQuotation);
router.post('/:id/convert', convertToInvoice);
router.post('/:id/download', downloadQuotationPDF);

// ✅ NEW ROUTES
router.post('/:id/email', emailQuotation);
router.post('/:id/whatsapp', whatsappQuotation);

module.exports = router;