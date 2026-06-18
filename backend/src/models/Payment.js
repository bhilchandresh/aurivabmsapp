const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true },
    clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Client', required: true },
    amount: { type: Number, required: true },
    date: { type: Date, default: Date.now },
    paymentMode: { type: String, enum: ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Other'], default: 'UPI' },
    referenceNote: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('Payment', paymentSchema);

