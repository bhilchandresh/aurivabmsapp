const mongoose = require('mongoose');

const clientSchema = new mongoose.Schema({
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
    type: String
  },
  phone: {
    type: String
  },
  address: {
    type: String
  },
  gstin: {
    type: String,
    trim: true
  },
  state: {
    type: String,
    trim: true
  },

createdAt: {
     type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Client', clientSchema);