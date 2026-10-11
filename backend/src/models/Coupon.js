const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true, uppercase: true },
  discountType: { type: String, enum: ['percentage', 'fixed'], required: true },
  discountValue: { type: Number, required: true },
  maxUses: { type: Number, default: 0 },
  currentUses: { type: Number, default: 0 },
  expiryDate: { type: Date },
  active: { type: Boolean, default: true },
  isTrial: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Coupon', couponSchema);
