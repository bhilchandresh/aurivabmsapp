const express = require('express');
const { getEmployees, getEmployee, createEmployee, updateEmployee, deleteEmployee, getEmployeeTransactions, addTransaction, deleteTransaction } = require('../controllers/employeeController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.route('/')
  .get(getEmployees)
  .post(createEmployee);

router.route('/:id')
  .get(getEmployee)
  .put(updateEmployee)
  .delete(deleteEmployee);

router.route('/:id/transactions')
  .get(getEmployeeTransactions)
  .post(addTransaction);

router.route('/:id/transactions/:txId')
  .delete(deleteTransaction);

module.exports = router;
