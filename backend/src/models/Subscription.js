const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  company: { type: String },
  name: { type: String },
  planName: { type: String, required: true },
  planType: { type: String, required: true },
  startDate: { type: Date, default: Date.now },
  expiryDate: { type: Date, required: true },
  status: { type: String, enum: ['active', 'expired'], default: 'active' }
}, { timestamps: true });

module.exports = mongoose.model('Subscription', subscriptionSchema);
