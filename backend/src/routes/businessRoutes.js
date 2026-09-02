const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { 
  getQuotations, 
  createQuotation, 
  getQuotationById,       // <--- Must exist in controller
  updateQuotationStatus,  // <--- Must exist in controller
  getExpenses, 
  createExpense,
  deleteExpense,
  convertQuoteToInvoice,
  getDashboardStats
} = require('../controllers/businessController');

// All routes here are protected
router.use(protect);

// Dashboard Route
router.route('/dashboard-stats')
  .get(getDashboardStats);

// Quotation Routes
router.route('/quotations')
  .get(getQuotations)
  .post(createQuotation);

// Single Quotation Operations
router.route('/quotations/:id')
  .get(getQuotationById);

router.route('/quotations/:id/status')
  .put(updateQuotationStatus);

// Expense Routes
router.route('/expenses')
  .get(getExpenses)
  .post(createExpense);

router.route('/expenses/:id')
  .delete(deleteExpense);
//quotation to invoice
  router.route('/quotations/:id/convert')
  .post(convertQuoteToInvoice);

module.exports = router;