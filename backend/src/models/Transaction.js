const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  razorpay_order_id: { type: String, required: true, unique: true },
  razorpay_payment_id: { type: String },
  amount: { type: Number, required: true },
  email: { type: String, required: true },
  couponCode: { type: String },
  planName: { type: String, required: true },
  planType: { type: String, required: true },
  status: { type: String, enum: ['pending', 'completed', 'failed'], default: 'pending' }
}, { timestamps: true });

module.exports = mongoose.model('Transaction', transactionSchema);
