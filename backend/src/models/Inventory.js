const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema({
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
  itemName: {
    type: String,
    required: [true, 'Item name is required'],
    trim: true
  },
  sku: {
    type: String,
    trim: true,
    default: ''
  },
  description: {
    type: String,
    trim: true,
    default: ''
  },
  purchasePrice: {
    type: Number,
    min: 0,
    default: 0
  },
  unitPrice: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  currentStock: {
    type: Number,
    required: true,
    min: 0,
    default: 0
  },
  status: {
    type: String,
    enum: ['active', 'inactive'],
    default: 'active'
  },
  reorderLevel: {
    type: Number,
    min: 0,
    default: 5
  }
}, { timestamps: true });

module.exports = mongoose.model('Inventory', inventorySchema);
