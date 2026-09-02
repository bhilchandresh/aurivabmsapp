const mongoose = require('mongoose');

const inventoryTransactionSchema = new mongoose.Schema({
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
  inventoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Inventory',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['Sale', 'Purchase', 'Adjustment', 'Return'],
    required: true
  },
  quantity: {
    type: Number,
    required: true
  },
  referenceId: {
    type: mongoose.Schema.Types.ObjectId,
    required: false // ID of Invoice or Purchase
  },
  description: {
    type: String,
    trim: true
  },
  date: {
    type: Date,
    default: Date.now
  }
}, { timestamps: true });

module.exports = mongoose.model('InventoryTransaction', inventoryTransactionSchema);
