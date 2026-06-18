const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware'); // ✅ Correct Import
const { downloadInvoicePDF, emailInvoice, whatsappInvoice, downloadPublicInvoicePDF } = require('../controllers/pdfController'); // ✅ Correct Import
const checkSubscription = require('../middleware/checkSubscription');
// Import Controller Functions
const { 
  getInvoices, 
  getInvoiceById, 
  createInvoice, 
  updateInvoice, 
  deleteInvoice,
  getPublicInvoice 
} = require('../controllers/invoiceController');

// Debugging: Check if functions are imported correctly
if (!createInvoice || !updateInvoice) {
  console.error("❌ Error: Controller functions not found! Check invoiceController.js exports.");
}

// Public Route (No Auth Required)
router.get('/public/:id', getPublicInvoice);
router.post('/public/:id/download', downloadPublicInvoicePDF); // ✅ NEW: Public PDF Download

// Apply Auth Middleware to all routes (Saare routes ab protected hain)
router.use(protect);

// Route: /api/v1/invoices
router.route('/')
  .get(getInvoices)      // Get all invoices
  .post(createInvoice);  // Create new invoice

// Route: /api/v1/invoices/:id
router.route('/:id')
  .get(getInvoiceById)   // Get single invoice
  .put(updateInvoice)    // Update invoice (Full edit OR Status update)
  .delete(deleteInvoice);// Delete invoice

// --- PDF Routes ---
// ✅ FIX: Used 'protect' instead of 'authMiddleware'
// ✅ FIX: Used 'downloadInvoicePDF' directly instead of 'pdfController.downloadInvoicePDF'
router.post('/:id/download', protect, downloadInvoicePDF);
router.post('/:id/email', protect, emailInvoice);
router.post('/:id/whatsapp', protect, whatsappInvoice);




// Sirf Create, Update, Delete par lagayein
router.post('/', checkSubscription, createInvoice);
router.put('/:id', checkSubscription, updateInvoice);
router.delete('/:id', checkSubscription, deleteInvoice);

module.exports = router;