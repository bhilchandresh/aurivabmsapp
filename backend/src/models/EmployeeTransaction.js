const mongoose = require('mongoose');

const employeeTransactionSchema = new mongoose.Schema({
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
    index: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  employeeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Employee',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['Salary Credit', 'Payment', 'Advance', 'Deduction'],
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  date: {
    type: Date,
    required: true,
    default: Date.now
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  // Used for Salary Credit to identify the month it applies to
  forMonth: {
    type: String, // e.g., '2023-08'
    trim: true
  }
}, { timestamps: true });

module.exports = mongoose.model('EmployeeTransaction', employeeTransactionSchema);
