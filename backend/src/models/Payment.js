const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true },
    clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Client', required: true },
    invoiceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Invoice' },
    amount: { type: Number, required: true },
    date: { type: Date, default: Date.now },
    paymentMode: { type: String, enum: ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Other'], default: 'UPI' },
    referenceNote: { type: String },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, { timestamps: true });

module.exports = mongoose.model('Payment', paymentSchema);

