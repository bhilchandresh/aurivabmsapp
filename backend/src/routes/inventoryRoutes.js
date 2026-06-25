const express = require('express');
const router = express.Router();
const inventoryController = require('../controllers/inventoryController');
const { protect } = require('../middleware/authMiddleware');
const checkSubscription = require('../middleware/checkSubscription');

router.use(protect);
router.use(checkSubscription);

router.route('/')
  .get(inventoryController.getItems)
  .post(inventoryController.createItem);

router.route('/bulk')
  .post(inventoryController.bulkImportInventory);

router.route('/:id/transactions')
  .get(inventoryController.getItemTransactions);

router.route('/:id')
  .put(inventoryController.updateItem)
  .delete(inventoryController.deleteItem);

module.exports = router;
