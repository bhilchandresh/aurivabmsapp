const mongoose = require('mongoose');

const supplierPaymentSchema = new mongoose.Schema({
  tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
  supplierId: { type: mongoose.Schema.Types.ObjectId, ref: 'Supplier', required: true, index: true },
  amount: { type: Number, required: true, min: 1 },
  paymentDate: { type: Date, default: Date.now },
  paymentMode: { type: String, enum: ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Other'], default: 'Bank Transfer' },
  referenceNumber: { type: String, trim: true },
  notes: { type: String, trim: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('SupplierPayment', supplierPaymentSchema);
