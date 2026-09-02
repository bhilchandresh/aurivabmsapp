const Client = require('../models/Client');
const Payment = require('../models/Payment');
const Invoice = require('../models/Invoice');
const logActivity = require('../utils/logger');
const { sendClientEmail, sendAccountSummaryEmail } = require('../utils/emailService');
const Tenant = require('../models/Tenant');

// 🔴 SMART GET CLIENTS (With Auto Financial Calculations)
exports.getClients = async (req, res) => {
  try {
    const matchQuery = { tenantId: req.user.tenantId };
    
    if (req.query.search) {
      const escapedSearch = req.query.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const searchRegex = new RegExp(escapedSearch, 'i');
      matchQuery.$or = [
        { name: searchRegex },
        { phone: searchRegex },
        { email: searchRegex }
      ];
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 1000;
    const skip = (page - 1) * limit;

    const clients = await Client.aggregate([
      { $match: matchQuery },

      // 1. Invoices ko jodo
      {
        $lookup: {
          from: 'invoices',
          localField: '_id',
          foreignField: 'client.clientId', // Dhyan rahe, ye invoices me use hota hai
          as: 'invoicesData'
        }
      },
      // 2. Payments ko jodo
      {
        $lookup: {
          from: 'payments',
          localField: '_id',
          foreignField: 'clientId',
          as: 'paymentsData'
        }
      },
      // 3. Total Billed aur Total Paid ka hisab lagao
      {
        $addFields: {
          totalBilled: { $sum: "$invoicesData.totalAmount" },
          totalPaid: { $sum: "$paymentsData.amount" }
        }
      },
      // 4. Balance nikalo
      {
        $addFields: {
          balance: { $subtract: ["$totalBilled", "$totalPaid"] }
        }
      },
      // 5. User kisne banaya uska data lao
      {
        $lookup: {
          from: 'users',
          localField: 'createdBy',
          foreignField: '_id',
          as: 'creator'
        }
      },
      {
        $unwind: {
          path: '$creator',
          preserveNullAndEmptyArrays: true
        }
      },
      // 6. Faltu data hata do taaki API fast rahe
      { 
        $project: { 
          invoicesData: 0, 
          paymentsData: 0,
          'creator.password': 0,
          'creator.role': 0
        } 
      },
      { $sort: getSortObj(req.query.sortBy) },
      { $skip: skip },
      { $limit: limit }
    ]);

    const total = await Client.countDocuments(matchQuery);

    res.status(200).json({ 
      success: true, 
      count: clients.length, 
      data: clients,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error("Get Clients Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

function getSortObj(sortBy) {
  if (sortBy === 'oldest') return { createdAt: 1 };
  if (sortBy === 'alpha_asc') return { name: 1 };
  if (sortBy === 'dues_high') return { balance: -1 };
  return { createdAt: -1 }; // default newest
}

// Get Single Client
exports.getClientById = async (req, res) => {
  try {
    const client = await Client.findOne({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!client) return res.status(404).json({ success: false, message: "Client not found" });
    res.status(200).json({ success: true, data: client });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Create Client
exports.createClient = async (req, res) => {
  try {
    const { name, email, phone, address, gstin, state } = req.body;
    
    if (email && email.trim() !== '') {
      const existing = await Client.findOne({ email, tenantId: req.user.tenantId });
      if (existing) return res.status(400).json({ success: false, message: "Client with this email already exists" });
    }

    const client = await Client.create({ 
      tenantId: req.user.tenantId, name, email, phone, address, gstin, state, 
      createdBy: req.user._id 
    });
    if (typeof logActivity === 'function') await logActivity(req, "CREATE_CLIENT", `Added client: ${name}`);
    res.status(201).json({ success: true, data: client });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// Bulk Import Clients
exports.bulkImportClients = async (req, res) => {
  try {
    const clientsData = req.body;
    if (!Array.isArray(clientsData)) {
      return res.status(400).json({ success: false, message: "Data must be an array" });
    }

    const tenantId = req.user.tenantId;
    let importedCount = 0;
    let skippedCount = 0;

    for (const client of clientsData) {
      if (!client.name) {
        skippedCount++;
        continue;
      }
      
      // Check for exact email match to avoid duplicates if email exists
      let existing = null;
      if (client.email && client.email.trim() !== '') {
        existing = await Client.findOne({ email: client.email, tenantId });
      } else if (client.phone && client.phone.trim() !== '') {
        existing = await Client.findOne({ phone: client.phone, tenantId });
      }

      if (existing) {
        skippedCount++;
        continue;
      }

      await Client.create({
        tenantId,
        name: client.name,
        email: client.email || '',
        phone: client.phone || '',
        address: client.address || '',
        gstin: client.gstin || '',
        state: client.state || '',
        createdBy: req.user._id
      });
      importedCount++;
    }

    if (typeof logActivity === 'function') {
      await logActivity(req, "BULK_IMPORT", `Imported ${importedCount} clients`);
    }

    res.status(200).json({ 
      success: true, 
      message: `Import complete. Added ${importedCount} new clients. Skipped ${skippedCount} duplicates/invalid.` 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Update Client
exports.updateClient = async (req, res) => {
  try {
    const client = await Client.findOneAndUpdate(
      { _id: req.params.id, tenantId: req.user.tenantId },
      req.body, { new: true, runValidators: true }
    );
    if (!client) return res.status(404).json({ success: false, message: "Client not found" });
    res.status(200).json({ success: true, data: client });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete Client
exports.deleteClient = async (req, res) => {
  try {
    const client = await Client.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!client) return res.status(404).json({ success: false, message: "Client not found" });
    res.status(200).json({ success: true, message: "Client Removed" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const syncLedgerForClient = async (clientId, tenantId) => {
  const allPayments = await Payment.find({ clientId, tenantId });
  
  // Separate tied payments and generic payments
  let genericPool = 0;
  const tiedPaymentsMap = {}; // invoiceId -> sum of tied payments

  for (let p of allPayments) {
    if (p.invoiceId) {
      const invIdStr = p.invoiceId.toString();
      tiedPaymentsMap[invIdStr] = (tiedPaymentsMap[invIdStr] || 0) + Number(p.amount);
    } else {
      genericPool += Number(p.amount);
    }
  }

  const allInvoices = await Invoice.find({
    'client.clientId': clientId,
    tenantId,
    status: { $ne: 'Cancelled' }
  }).sort({ date: 1, createdAt: 1 }); // Sort by date, then createdAt for stable sorting

  // Step 1: Apply tied payments first
  for (let inv of allInvoices) {
    const invIdStr = inv._id.toString();
    const billAmount = Number(inv.totalAmount);
    const tiedAmount = tiedPaymentsMap[invIdStr] || 0;

    if (tiedAmount >= billAmount) {
      // Overpaid or perfectly paid by tied payments
      inv.remainingAmount = 0;
      inv.status = 'Paid';
      // Spill over excess to generic pool
      genericPool += (tiedAmount - billAmount);
    } else {
      // Partially paid by tied payments
      inv.remainingAmount = billAmount - tiedAmount;
      inv.status = tiedAmount > 0 ? 'Partially Paid' : 'Pending';
    }
  }

  // Step 2: Apply generic pool (FIFO) to remaining amounts
  for (let inv of allInvoices) {
    if (inv.remainingAmount > 0) {
      if (genericPool >= inv.remainingAmount) {
        genericPool -= inv.remainingAmount;
        inv.remainingAmount = 0;
        inv.status = 'Paid';
      } else if (genericPool > 0) {
        inv.remainingAmount -= genericPool;
        inv.status = 'Partially Paid';
        genericPool = 0;
      }
    }
    
    // Fallback status check
    if (inv.remainingAmount > 0 && inv.status === 'Paid') {
      inv.status = 'Partially Paid';
    }
    if (inv.remainingAmount === Number(inv.totalAmount) && inv.status === 'Partially Paid') {
      inv.status = 'Pending';
    }
    
    await inv.save();
  }
};

exports.syncLedgerForClient = syncLedgerForClient;

// Record Payment & Auto-Settle Invoices
// 🔴 SMART FIFO PAYMENT LOGIC
// 🔴 THE REAL FIX FOR FIFO STATUS UPDATE
// 🔴 KHATABOOK STYLE FIFO LOGIC (100% BULLETPROOF)
// 🔴 THE MASTER SYNC LOGIC (100% Accuracy for Old & New Data)
exports.addPayment = async (req, res) => {
  try {
    const { amount, date, paymentMode, referenceNote } = req.body;

    const newPayment = await Payment.create({
      tenantId: req.user.tenantId,
      clientId: req.params.id,
      amount: Number(amount),
      date, paymentMode, referenceNote,
      createdBy: req.user._id
    });

    // 2. 🔴 MASTER SYNC: रन करें
    await syncLedgerForClient(req.params.id, req.user.tenantId);

    res.status(201).json({ success: true, data: newPayment });
  } catch (error) {
    console.error("MASTER SYNC ERROR:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 🔴 NEW: MANUAL SYNC LEDGER FUNCTION
exports.syncClientLedger = async (req, res) => {
  try {
    const clientId = req.params.id;
    const tenantId = req.user.tenantId;

    await syncLedgerForClient(clientId, tenantId);

    res.status(200).json({ success: true, message: "Ledger Synced Successfully!" });
  } catch (error) {
    console.error("SYNC ERROR:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get Payment History
exports.getClientPayments = async (req, res) => {
  try {
    const payments = await Payment.find({
      tenantId: req.user.tenantId,
      clientId: req.params.id
    }).sort({ date: -1 }).populate('createdBy', 'name email');
    res.status(200).json({ success: true, data: payments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Send Manual Email to Client
exports.sendClientEmail = async (req, res) => {
  try {
    const { id } = req.params;
    const { subject, message } = req.body;
    const client = await Client.findOne({ _id: id, tenantId: req.user.tenantId });
    if (!client || !client.email) return res.status(400).json({ success: false, message: "Client or email not found" });

    await sendClientEmail(client, subject, message);
    res.status(200).json({ success: true, message: "Email sent successfully" });
  } catch (error) {
    console.error("Manual Email Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 📧 NEW: Send Visual Account Summary Email
exports.sendAccountSummary = async (req, res) => {
  try {
    const { id } = req.params;
    const tenantId = req.user.tenantId;

    const [client, tenant, invoices, payments] = await Promise.all([
      Client.findOne({ _id: id, tenantId }),
      Tenant.findById(tenantId),
      Invoice.find({ 'client.clientId': id, tenantId, status: { $ne: 'Cancelled' } }).sort({ date: -1 }),
      Payment.find({ clientId: id, tenantId })
    ]);

    if (!client || !client.email) {
      return res.status(400).json({ success: false, message: "Client or email not found" });
    }

    const totalBilled = invoices.reduce((sum, inv) => sum + (inv.totalAmount || 0), 0);
    const totalPaid = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
    const balance = totalBilled - totalPaid;

    const stats = {
      billed: totalBilled,
      paid: totalPaid,
      balance: balance
    };

    const lastInvoice = invoices.length > 0 ? invoices[0] : null;

    await sendAccountSummaryEmail(client, stats, lastInvoice, tenant);

    if (typeof logActivity === 'function') await logActivity(req, "EMAIL_SUMMARY", `Sent account summary to ${client.name}`);

    res.status(200).json({ success: true, message: "Account summary email sent successfully" });
  } catch (error) {
    console.error("Summary Email Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};