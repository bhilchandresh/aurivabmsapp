const mongoose = require('mongoose');

const QuotationSchema = new mongoose.Schema({
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true
  },

  // --- IDENTIFIERS ---
  // We keep both to satisfy your DB Index (quoteNumber) and your Code Logic (quotationNumber)
  quotationNumber: {
    type: String,
    required: true
  },
  quoteNumber: {
    type: String
    // This field is added specifically to fix the "Duplicate Key Error"
    // The controller will save the same number in both fields.
  },

  // --- CONVERSION TRACKING ---
  convertedInvoiceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Invoice',
    default: null
  },

  // --- CLIENT SNAPSHOT ---
  client: {
    name: { type: String, required: true },
    email: { type: String },
    phone: { type: String },
    address: { type: String },
    gstNumber: { type: String },
    clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Client' }
  },

  // --- ITEMS ---
  items: [
    {
      description: { type: String, required: true },
      additionalDetails: { type: String },
      hsnCode: { type: String },
      quantity: { type: Number, required: true },
      rate: { type: Number, required: true },
      gstRate: { type: Number, default: 0 }, // per item GST
      taxAmount: { type: Number, default: 0 }, // per item tax
      total: { type: Number }
    }
  ],

  // --- FINANCIALS ---
  subTotal: { type: Number, default: 0 },
  taxableAmount: { type: Number, default: 0 }, // Amount on which tax is calculated
  discountPercentage: { type: Number, default: 0 },

  // Added gstEnabled flag for better UI handling
  gstEnabled: { type: Boolean, default: false },
  taxType: { type: String, enum: ['exclusive', 'inclusive'], default: 'exclusive' },
  taxRate: { type: Number, default: 0 }, // Global/Override rate
  gstAmount: { type: Number, default: 0 }, // Total GST Amount

  // Breakdown
  gstBreakdown: {
    cgst: { type: Number, default: 0 },
    sgst: { type: Number, default: 0 },
    igst: { type: Number, default: 0 }
  },
  placeOfSupply: { type: String },

  totalAmount: { type: Number, required: true, default: 0 },
  advancePayment: { type: Number, default: 0 },

  // --- META DATA ---
  status: {
    type: String,
    enum: ['Pending', 'Accepted', 'Rejected'],
    default: 'Pending'
  },
  date: {
    type: Date,
    default: Date.now
  },
  validUntil: {
    type: Date
  },

  // --- TEXT FIELDS ---
  notes: { type: String },
  terms: { type: String },

  // --- SNAPSHOTS (For Immutable History) ---
  bankDetailsSnapshot: {
    bankName: String,
    accountNumber: String,
    ifscCode: String,
    accountName: String // Added accountName
  },
  authorizedSignatoryImage: {
    type: String // Base64 or URL
  },

  // --- TRACKING ---
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  salesPerson: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Quotation', QuotationSchema);