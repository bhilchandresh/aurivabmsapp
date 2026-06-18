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
      // 5. Faltu data hata do taaki API fast rahe
      { $project: { invoicesData: 0, paymentsData: 0 } },
      { $sort: { createdAt: -1 } }
    ]);

    res.status(200).json({ success: true, count: clients.length, data: clients });
  } catch (error) {
    console.error("Get Clients Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

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

    const client = await Client.create({ tenantId: req.user.tenantId, name, email, phone, address, gstin, state });
    if (typeof logActivity === 'function') await logActivity(req, "CREATE_CLIENT", `Added client: ${name}`);
    res.status(201).json({ success: true, data: client });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
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

// Record Payment & Auto-Settle Invoices
// 🔴 SMART FIFO PAYMENT LOGIC
// 🔴 THE REAL FIX FOR FIFO STATUS UPDATE
// 🔴 KHATABOOK STYLE FIFO LOGIC (100% BULLETPROOF)
// 🔴 THE MASTER SYNC LOGIC (100% Accuracy for Old & New Data)
exports.addPayment = async (req, res) => {
  try {
    const { amount, date, paymentMode, referenceNote } = req.body;

    // 1. सबसे पहले नया पेमेंट डेटाबेस में सेव करें
    const newPayment = await Payment.create({
      tenantId: req.user.tenantId,
      clientId: req.params.id,
      amount: Number(amount),
      date, paymentMode, referenceNote
    });

    // 2. 🔴 MASTER SYNC: क्लाइंट का 'आज तक का सारा पैसा' (Total Pool) जोड़ लें
    const allPayments = await Payment.find({
      clientId: req.params.id,
      tenantId: req.user.tenantId
    });

    let totalPaidPool = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);

    // 3. क्लाइंट के 'आज तक के सारे बिल' निकालें (Cancelled को छोड़कर), पुराने सबसे पहले
    const allInvoices = await Invoice.find({
      'client.clientId': req.params.id,
      tenantId: req.user.tenantId,
      status: { $ne: 'Cancelled' }
    }).sort({ date: 1 });

    // 4. पूरे लेजर को शुरू से रीसेट (Recalculate) करें
    for (let inv of allInvoices) {
      const billAmount = Number(inv.totalAmount);

      if (totalPaidPool >= billAmount) {
        // अगर हमारे पास पूल में बिल से ज़्यादा या बराबर पैसा है -> FULL PAID
        inv.remainingAmount = 0;
        inv.status = 'Paid';
        totalPaidPool -= billAmount; // पूल में से बिल का पैसा काट लें

      } else if (totalPaidPool > 0) {
        // पूल में पैसा तो है, लेकिन पूरे बिल के लिए काफी नहीं है -> PARTIALLY PAID
        inv.remainingAmount = billAmount - totalPaidPool;
        inv.status = 'Partially Paid';
        totalPaidPool = 0; // पूल अब खाली हो गया

      } else {
        // पूल में पैसा जीरो हो चुका है -> UNPAID
        inv.remainingAmount = billAmount;
        // अगर आपके सिस्टम में डिफ़ॉल्ट 'Pending' है तो 'Pending' लिखें, वर्ना 'Unpaid'
        inv.status = 'Pending';
      }

      // अपडेटेड बिल को सेव करें
      await inv.save();
    }

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

    // 1. Total Paid Pool nikaalo
    const allPayments = await Payment.find({ clientId, tenantId });
    let totalPaidPool = allPayments.reduce((sum, p) => sum + Number(p.amount), 0);

    // 2. Saare Invoices nikaalo (Oldest First)
    const allInvoices = await Invoice.find({
      'client.clientId': clientId,
      tenantId,
      status: { $ne: 'Cancelled' }
    }).sort({ date: 1 });

    // 3. FIFO Logic Run Karo
    for (let inv of allInvoices) {
      const billAmount = Number(inv.totalAmount);

      if (totalPaidPool >= billAmount) {
        inv.remainingAmount = 0;
        inv.status = 'Paid';
        totalPaidPool -= billAmount;
      } else if (totalPaidPool > 0) {
        inv.remainingAmount = billAmount - totalPaidPool;
        inv.status = 'Partially Paid';
        totalPaidPool = 0;
      } else {
        inv.remainingAmount = billAmount;
        inv.status = 'Pending';
      }
      await inv.save();
    }

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
    }).sort({ date: -1 });
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