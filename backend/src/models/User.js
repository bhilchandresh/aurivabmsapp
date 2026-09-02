const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true
  },
  name: {
    type: String,
    required: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  passwordHash: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['super_admin', 'admin', 'user'], 
    default: 'user'
  },
  signatureImage: { 
    type: String, 
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  hasCompletedTour: {
    type: Boolean,
    default: false
  },
  deviceTokens: [{
    token: { type: String, required: true },
    platform: { type: String, enum: ['android', 'ios', 'web'], default: 'android' }
  }],
  resetPasswordToken: String,
  resetPasswordExpire: Date,
  deletionOtp: String,
  deletionOtpExpire: Date
}, { timestamps: true });


userSchema.index({ tenantId: 1 });
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });

module.exports = mongoose.model('User', userSchema);