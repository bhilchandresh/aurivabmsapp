const mongoose = require('mongoose');

const tenantSchema = new mongoose.Schema({
  // --- Basic Identity ---
  name: {
    type: String,
    required: true,
    trim: true
  },
  slug: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  email: { type: String, trim: true, required: true },
  
  // ❌ REMOVED: password field yahan nahi hona chahiye. 
  // Password sirf 'User' model me hota hai.
  
  // --- Business Contact Info ---
  phone: { type: String, trim: true },
  address: { type: String, trim: true },
  website: { type: String, trim: true },

  // --- Branding ---
  logoImage: { type: String },      // URL or Base64
  signatureImage: { type: String }, // URL or Base64

  // --- GST / Tax Info ---
  gstEnabled: { type: Boolean, default: false },
  gstNumber: { type: String, trim: true },
  state: { type: String, trim: true }, // For GST intra/inter state detection


  // --- Bank Details ---
  bankDetails: {
    accountName: { type: String, trim: true },
    bankName: { type: String, trim: true },
    accountNumber: { type: String, trim: true },
    ifscCode: { type: String, trim: true }
  },

  // --- Default Terms ---
  defaultTerms: { 
    type: String, 
    default: "1. Goods once sold will not be taken back.\n2. Interest @18% pa will be charged if payment is not made within the due date." 
  },
  
  // ==================================================
  // --- SUBSCRIPTION & STATUS ---
  // ==================================================
  
  status: {
    type: String,
    enum: ['active', 'inactive', 'suspended'],
    default: 'active'
  },

  subscriptionPlan: { 
    type: String, 
    enum: ['basic', 'premium', 'enterprise'], 
    default: 'basic' 
  },

  subscriptionStart: { type: Date, default: Date.now },
  subscriptionEnd: { 
    type: Date, 
    default: () => new Date(+new Date() + 365*24*60*60*1000) 
  },

  // ==================================================
  // --- TEMPLATE SETTINGS ---
  // ==================================================
  
  templatePreference: { 
    type: String, 
    enum: ['standard', 'modern', 'modern-blue', 'classic', 'minimalist','elegant','vibrant'], 
    default: 'standard' 
  },

  quotationTemplate: { 
    type: String, 
    enum: ['standard', 'modern', 'modern-blue', 'classic', 'minimalist','elegant','vibrant'], 
    default: 'standard' 
  },

  // --- LEGACY FIELDS ---
  selectedTemplate: { type: String }, 
  invoiceTemplateId: { type: String },
  
  // --- USAGE ---
  usage: {
    invoicesCount: { type: Number, default: 0 },
    lastResetDate: { type: Date, default: Date.now } 
  },

  // --- NOTIFICATION SETTINGS ---
  notificationPreferences: {
    invoiceDueToday: { type: Boolean, default: true },
    invoiceDueTomorrow: { type: Boolean, default: true },
    invoiceOverdue: { type: Boolean, default: true },
    paymentReceived: { type: Boolean, default: true },
    quotationExpiring: { type: Boolean, default: true },
    quotationAccepted: { type: Boolean, default: true },
    quotationRejected: { type: Boolean, default: true },
    inventoryLowStock: { type: Boolean, default: true },
    inventoryOutOfStock: { type: Boolean, default: true },
    supplierPaymentDue: { type: Boolean, default: true },
    recurringExpense: { type: Boolean, default: true },
    newDeviceLogin: { type: Boolean, default: true },
    morningSummary: { type: Boolean, default: true }
  }

}, { timestamps: true });

module.exports = mongoose.model('Tenant', tenantSchema);