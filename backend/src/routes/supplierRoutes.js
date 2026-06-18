const express = require('express');
const router = express.Router();
const supplierController = require('../controllers/supplierController');
const { protect } = require('../middleware/authMiddleware');
const checkSubscription = require('../middleware/checkSubscription');

router.use(protect);
router.use(checkSubscription);

// Core Supplier
router.route('/')
  .get(supplierController.getSuppliers)
  .post(supplierController.createSupplier);

router.route('/:id')
  .get(supplierController.getSupplierById)
  .put(supplierController.updateSupplier)
  .delete(supplierController.deleteSupplier);

// Purchases (Bills)
router.route('/purchases/all')
  .get(supplierController.getPurchases)
  .post(supplierController.createPurchase);

router.delete('/purchases/:billId', supplierController.deletePurchase);

// Payments (Ledger)
router.route('/:supplierId/payments')
  .get(supplierController.getPayments)
  .post(supplierController.createPayment);

router.delete('/payments/:paymentId', supplierController.deletePayment);

module.exports = router;
