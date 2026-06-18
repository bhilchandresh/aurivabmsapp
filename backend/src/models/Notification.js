const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  message: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['info', 'warning', 'success', 'error', 'renewal'],
    default: 'info'
  },
  target: {
    type: String,
    enum: ['all_admins', 'specific_tenant'],
    default: 'all_admins'
  },
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: function() { return this.target === 'specific_tenant'; }
  },
  readBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  actionLink: {
    type: String,
    default: null
  },
  isSystemGenerated: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

notificationSchema.index({ target: 1 });
notificationSchema.index({ tenantId: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
