const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema({
  tenantId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Tenant', 
    required: true 
  },
  
  // --- Core Details ---
  category: { 
    type: String, 
    required: true, 
    trim: true 
  }, // e.g. "Rent", "Server", "Travel", "Salary"

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
  
  dueDate: {
    type: Date
  },

  // --- Additional Context ---
  description: { 
    type: String, 
    trim: true 
  },

  vendor: { 
    type: String, 
    trim: true 
  }, // Who was paid? (e.g., "AWS", "Landlord")

  paymentMethod: { 
    type: String, 
    enum: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Cheque', 'Other'],
    default: 'Other'
  },

  status: {
    type: String,
    enum: ['Paid', 'Pending', 'Reimbursed'],
    default: 'Paid'
  },

  // --- Attachments ---
  receiptImage: { 
    type: String 
  }, // URL or Base64 string of the bill

  // --- Audit ---
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User' 
  } // Track which employee added this expense

}, { timestamps: true });


expenseSchema.index({ tenantId: 1 });
expenseSchema.index({ category: 1 });
expenseSchema.index({ date: -1 });

module.exports = mongoose.model('Expense', expenseSchema);