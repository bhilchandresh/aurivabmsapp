const mongoose = require('mongoose');

const blockedIPSchema = new mongoose.Schema({
  ipAddress: {
    type: String,
    required: [true, 'IP Address is required'],
    unique: true,
    trim: true
  },
  reason: {
    type: String,
    required: [true, 'Reason for blocking is required'],
    trim: true
  },
  blockedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  },
  autoBlocked: {
    type: Boolean,
    default: false
  },
  expiresAt: {
    type: Date,
    default: null
  }
}, { timestamps: true });

// TTL Index for auto-deletion. MongoDB will automatically delete documents where expiresAt is passed.
blockedIPSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('BlockedIP', blockedIPSchema);
