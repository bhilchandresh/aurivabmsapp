const mongoose = require('mongoose');

const purchaseSchema = new mongoose.Schema({
  tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
  supplierId: { type: mongoose.Schema.Types.ObjectId, ref: 'Supplier', required: true, index: true },
  billNumber: { type: String, required: true, trim: true },
  date: { type: Date, required: true },
  dueDate: { type: Date },
  items: [{
    description: String,
    quantity: Number,
    rate: Number,
    amount: Number,
    addToInventory: { type: Boolean, default: false },
    sellingPrice: { type: Number, default: 0 },
    inventoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory' }
  }],
  subTotal: { type: Number, default: 0 },
  taxAmount: { type: Number, default: 0 },
  totalAmount: { type: Number, required: true },
  amountPaid: { type: Number, default: 0 },
  status: { type: String, enum: ['Unpaid', 'Partial', 'Paid'], default: 'Unpaid' },
  notes: { type: String },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Purchase', purchaseSchema);
