const mongoose = require('mongoose');

const invoiceSchema = new mongoose.Schema({
  tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true },

  // Invoice Metadata
  invoiceNumber: { type: String, required: true },
  date: { type: Date, required: true, default: Date.now },
  dueDate: { type: Date },

  // 🔴 FIX: Duplicate statuses are merged here to support FIFO & old logic
  status: {
    type: String,
    enum: ['Pending', 'Unpaid', 'Partially Paid', 'Paid', 'Overdue', 'Cancelled'],
    default: 'Unpaid'
  },

  // --- CLIENT STRUCTURE ---
  // Stores a snapshot of client data at the time of invoice creation
  client: {
    name: { type: String, required: true },
    email: { type: String },
    address: { type: String },
    phone: { type: String },
    gstin: { type: String },
    state: { type: String }, // For tax calculation persistence
    clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Client' }
  },

  // --- ITEMS ARRAY ---
  items: [{
    description: { type: String, required: true },
    additionalDetails: { type: String },
    hsnCode: { type: String }, // also used for SAC
    sacCode: { type: String },
    quantity: { type: Number, required: true, min: 1 },
    rate: { type: Number, required: true, min: 0 },
    gstRate: { type: Number, default: 0 }, // per item GST
    taxAmount: { type: Number, default: 0 }, // per item tax
    inventoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory' }
  }],

  // --- FINANCIALS ---
  subTotal: { type: Number, default: 0 },

  // Discount
  discountPercentage: { type: Number, default: 0 },
  discountAmount: { type: Number, default: 0 },

  // Tax Info
  gstEnabled: { type: Boolean, default: false },
  taxType: { type: String, enum: ['exclusive', 'inclusive'], default: 'exclusive' },
  taxRate: { type: Number, default: 0 }, // Global/Override rate
  gstAmount: { type: Number, default: 0 },
  
  // Breakdown
  gstBreakdown: {
    cgst: { type: Number, default: 0 },
    sgst: { type: Number, default: 0 },
    igst: { type: Number, default: 0 }
  },
  placeOfSupply: { type: String },

  // 🔴 FIX: Kept only one totalAmount. (Duplicate removed)
  totalAmount: { type: Number, required: true },

  // 🔴 FIFO Logic: Kitna paisa bacha hai is bill ka
  remainingAmount: { type: Number },

  advancePayment: { type: Number, default: 0 },
  balanceDue: { type: Number, default: 0 },

  // --- SNAPSHOTS & EXTRAS ---
  bankDetailsSnapshot: {
    accountName: String,
    bankName: String,
    accountNumber: String,
    ifscCode: String
  },
  authorizedSignatoryImage: { type: String },

  // Terms & Notes
  notes: { type: String },
  terms: { type: String },

  // Tracking
  salesPerson: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }

}, {
  timestamps: true // <--- ✅ AUTO-HANDLES createdAt & updatedAt
});

// ❌ REMOVED the pre('save') hook causing the error.

module.exports = mongoose.model('Invoice', invoiceSchema);