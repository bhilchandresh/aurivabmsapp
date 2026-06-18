const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  action: { type: String, required: true }, // e.g., "LOGIN", "CREATE_INVOICE", "DELETE_TENANT"
  details: { type: String }, // e.g., "User John logged in"
  tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', default: null }, // Null for system events
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  ip: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', auditLogSchema);