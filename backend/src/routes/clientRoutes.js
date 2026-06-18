const express = require('express');
const router = express.Router();

const {
  getClients,
  createClient,
  getClientById,
  updateClient,
  deleteClient,
  addPayment,         // 🔴 Smart Settlement Logic Controller
  getClientPayments,  // 🔴 Ledger Fetch Controller
  syncClientLedger,   // 🔴 NEW: Sync Ledger Controller Import add kar diya gaya hai
  sendClientEmail,
  sendAccountSummary
} = require('../controllers/clientController');

const { protect } = require('../middleware/authMiddleware');

// सभी राउट्स सुरक्षित (Protected) हैं
router.use(protect);

// ---------------------------------------------------------
// 1. BASE ROUTES (/api/v1/clients)
// ---------------------------------------------------------
router.route('/')
  .get(getClients)
  .post(createClient);

// ---------------------------------------------------------
// 2. 🔴 SPECIFIC SUB-ROUTES (Must be ABOVE /:id)
// ---------------------------------------------------------
// यह राउट क्लाइंट की पेमेंट हिस्ट्री और नया पेमेंट ऐड करने के लिए है।
// एक्सप्रेस इसे पहले चेक करेगा, जिससे 404 Error नहीं आएगा।
router.route('/:id/payments')
  .get(getClientPayments)
  .post(addPayment);

// 🔴 Manual Sync Route - Pura hisab barabar karne ke liye
router.route('/:id/sync-ledger')
  .post(syncClientLedger);

// Send Email Route
router.route('/:id/mail')
  .post(sendClientEmail);

// Send Visual Account Summary
router.route('/:id/send-summary')
  .post(sendAccountSummary);

// ---------------------------------------------------------
// 3. GENERIC ID ROUTES (/api/v1/clients/:id)
// ---------------------------------------------------------
// यह राउट सबसे नीचे होना चाहिए क्योंकि यह किसी भी string को 'id' मान लेता है।
router.route('/:id')
  .get(getClientById)
  .put(updateClient)
  .delete(deleteClient);

module.exports = router;