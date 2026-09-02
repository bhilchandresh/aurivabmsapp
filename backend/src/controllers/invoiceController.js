const Invoice = require('../models/Invoice');
const Client = require('../models/Client');
const Payment = require('../models/Payment');
const Inventory = require('../models/Inventory');
const InventoryTransaction = require('../models/InventoryTransaction');
const Tenant = require('../models/Tenant');
const logActivity = require('../utils/logger');
const { sendInvoiceEmail, sendPaymentEmail } = require('../utils/emailService');
const { syncLedgerForClient } = require('./clientController');

const INDIAN_STATES = [
  "Andaman and Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", 
  "Chandigarh", "Chhattisgarh", "Dadra and Nagar Haveli and Daman and Diu", "Delhi", "Goa", 
  "Gujarat", "Haryana", "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka", 
  "Kerala", "Ladakh", "Lakshadweep", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", 
  "Mizoram", "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", 
  "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
];

// --- HELPER FUNCTION: Calculate Totals ---
const calculateInvoiceTotals = (items, discountPercentage = 0, taxType = 'exclusive', gstEnabled = false, tenantState = '', clientState = '', advancePayment = 0) => {
  if (!Array.isArray(items)) return {};

  let subTotal = 0;
  let totalTaxAmount = 0;
  let cgst = 0;
  let sgst = 0;
  let igst = 0;

  // 🔴 AGGRESSIVE LOGIC: Only CGST/SGST if states are explicitly EQUAL. 
  // If one is missing, we try to be smart based on business details.
  const isInterState = tenantState && clientState && tenantState.trim().toLowerCase() !== clientState.trim().toLowerCase();
  
  // Extra logging for debugging in production logs
  if (gstEnabled) {
    console.log(`[GST DEBUG] TenantState: "${tenantState}", ClientState: "${clientState}", isInterState: ${isInterState}`);
  }

  const processedItems = items.map(item => {
    const qty = Number(item.quantity) || 0;
    const rate = Number(item.rate) || 0;
    const itemGstRate = Number(item.gstRate) || 0;
    
    let lineTotal = qty * rate;
    let taxableAmount = lineTotal;
    let taxAmount = 0;

    if (gstEnabled) {
      if (taxType === 'inclusive') {
        taxableAmount = lineTotal / (1 + (itemGstRate / 100));
        taxAmount = lineTotal - taxableAmount;
      } else {
        taxAmount = lineTotal * (itemGstRate / 100);
        lineTotal = lineTotal + taxAmount;
      }

      if (isInterState) {
        igst += taxAmount;
      } else {
        cgst += taxAmount / 2;
        sgst += taxAmount / 2;
      }
    }

    subTotal += taxableAmount;
    totalTaxAmount += taxAmount;

    return {
      ...item,
      taxableAmount: Number(taxableAmount.toFixed(2)),
      taxAmount: Number(taxAmount.toFixed(2)),
      total: Number(lineTotal.toFixed(2))
    };
  });

  const discountAmount = subTotal * (Number(discountPercentage) / 100);
  
  // Calculate actual taxable value (only items with GST > 0)
  const taxableItemsSubTotal = processedItems.reduce((sum, item) => sum + ((Number(item.gstRate) > 0) ? Number(item.taxableAmount) : 0), 0);
  
  // Apply proportional discount to taxable amount
  const taxableTotal = gstEnabled ? (taxableItemsSubTotal * (1 - (Number(discountPercentage) / 100))) : (subTotal - discountAmount);
  
  // Recalculate tax if discount exists (pro-rata tax reduction)
  let finalTaxAmount = totalTaxAmount;
  let finalCgst = cgst;
  let finalSgst = sgst;
  let finalIgst = igst;

  if (discountPercentage > 0) {
    const discountFactor = (1 - Number(discountPercentage) / 100);
    finalTaxAmount = totalTaxAmount * discountFactor;
    finalCgst = cgst * discountFactor;
    finalSgst = sgst * discountFactor;
    finalIgst = igst * discountFactor;
  }

  const totalAfterDiscount = subTotal - discountAmount;
  const totalAmount = totalAfterDiscount + finalTaxAmount;
  const balanceDue = totalAmount - Number(advancePayment);

  return { 
    items: processedItems,
    subTotal: Number(subTotal.toFixed(2)), 
    discountAmount: Number(discountAmount.toFixed(2)), 
    taxableAmount: Number(taxableTotal.toFixed(2)), 
    gstAmount: Number(finalTaxAmount.toFixed(2)), 
    gstBreakdown: {
      cgst: Number(finalCgst.toFixed(2)),
      sgst: Number(finalSgst.toFixed(2)),
      igst: Number(finalIgst.toFixed(2))
    },
    totalAmount: Number(totalAmount.toFixed(2)), 
    balanceDue: Number(balanceDue.toFixed(2)) 
  };
};

// --- HELPER FUNCTION: Sync Inventory ---
const syncInventoryForInvoice = async (tenantId, items, invoiceId, clientName, type = 'Sale') => {
  const { dispatchNotification } = require('../services/notificationDispatcher');

  for (const item of items) {
    if (item.inventoryId) {
      const quantity = Number(item.quantity);
      // Update Stock
      const updatedInv = await Inventory.findByIdAndUpdate(item.inventoryId, {
        $inc: { currentStock: type === 'Sale' ? -quantity : quantity }
      }, { new: true });

      // Create Transaction Record
      await InventoryTransaction.create({
        tenantId,
        inventoryId: item.inventoryId,
        type: type,
        quantity: type === 'Sale' ? -quantity : quantity,
        referenceId: invoiceId,
        description: type === 'Sale' ? `Sold to ${clientName}` : `Returned from ${clientName}`,
        date: Date.now()
      });

      // Check for Low Stock or Out of Stock Alerts
      if (updatedInv && type === 'Sale') {
        if (updatedInv.currentStock <= 0) {
          dispatchNotification({
            tenantId,
            type: 'stock_alert',
            message: `🚨 ${updatedInv.itemName} is out of stock!`,
            preferenceKey: 'inventoryOutOfStock',
            metadata: { entityId: updatedInv._id, entityModel: 'Inventory' }
          });
        } else if (updatedInv.currentStock <= (updatedInv.reorderLevel || 5)) {
          dispatchNotification({
            tenantId,
            type: 'stock_alert',
            message: `⚠️ ${updatedInv.itemName} stock is low. Only ${updatedInv.currentStock} units remaining.`,
            preferenceKey: 'inventoryLowStock',
            metadata: { entityId: updatedInv._id, entityModel: 'Inventory' }
          });
        }
      }
    }
  }
};

const revertInventoryForInvoice = async (tenantId, invoiceId) => {
  const transactions = await InventoryTransaction.find({ tenantId, referenceId: invoiceId });
  for (const tx of transactions) {
    // Reverse the stock change
    await Inventory.findByIdAndUpdate(tx.inventoryId, {
      $inc: { currentStock: -tx.quantity }
    });
  }
  // Delete the transactions
  await InventoryTransaction.deleteMany({ tenantId, referenceId: invoiceId });
};

// ==========================================
// CLIENT CONTROLLERS
// ==========================================

exports.getClients = async (req, res) => {
  try {
    let query = { tenantId: req.user.tenantId };
    
    if (req.query.search) {
      const searchRegex = new RegExp(req.query.search, 'i');
      query.$or = [
        { name: searchRegex },
        { email: searchRegex },
        { phone: searchRegex }
      ];
    }

    const clients = await Client.find(query)
      .sort({ createdAt: -1 })
      .limit(20);
      
    res.status(200).json({ success: true, data: clients });
  } catch (error) {
    console.error("Error getting clients:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createClient = async (req, res) => {
  try {
    const { name, email, phone, address, gstNumber } = req.body;
    const client = await Client.create({
      tenantId: req.user.tenantId, name, email, phone, address, gstNumber
    });
    res.status(201).json({ success: true, data: client });
  } catch (error) {
    console.error("Error creating client:", error);
    res.status(400).json({ success: false, message: error.message });
  }
};

// ==========================================
// INVOICE CONTROLLERS
// ==========================================

exports.getInvoices = async (req, res) => {
  try {
    let query = { tenantId: req.user.tenantId };

    if (req.query.clientId) {
      query.$or = [
        { "client.clientId": req.query.clientId },
        { "client": req.query.clientId }
      ];
    }

    if (req.query.search) {
      const searchRegex = new RegExp(req.query.search, 'i');
      query.$and = [
        {
          $or: [
            { invoiceNumber: searchRegex },
            { "client.name": searchRegex }
          ]
        }
      ];
    }

    // Filter by month (YYYY-MM)
    if (req.query.month) {
      const startDate = new Date(`${req.query.month}-01`);
      const endDate = new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0);
      query.date = {
        $gte: startDate.toISOString().split('T')[0],
        $lte: endDate.toISOString().split('T')[0]
      };
    }

    if (req.query.status && req.query.status !== 'all') {
       query.status = new RegExp('^' + req.query.status + '$', 'i');
    }

    // Sorting
    let sortObj = { createdAt: -1 };
    if (req.query.sortBy) {
      if (req.query.sortBy === 'newest') sortObj = { date: -1, createdAt: -1 };
      else if (req.query.sortBy === 'oldest') sortObj = { date: 1, createdAt: 1 };
      else if (req.query.sortBy === 'amount_high') sortObj = { totalAmount: -1 };
      else if (req.query.sortBy === 'amount_low') sortObj = { totalAmount: 1 };
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20; // Changed default to 20 since UI now supports pagination
    const skip = (page - 1) * limit;

    const invoices = await Invoice.find(query)
      .sort(sortObj)
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'name email');

    const total = await Invoice.countDocuments(query);

    res.status(200).json({ 
      success: true, 
      count: invoices.length, 
      data: invoices,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error("Error getting invoices:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getInvoiceById = async (req, res) => {
  try {
    const invoice = await Invoice.findOne({ _id: req.params.id, tenantId: req.user.tenantId })
      .populate('salesPerson', 'name email signatureImage');

    if (!invoice) return res.status(404).json({ success: false, message: 'Invoice not found' });
    res.status(200).json({ success: true, data: invoice });
  } catch (error) {
    console.error("Error getting invoice:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createInvoice = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.user.tenantId);
    let tenantState = tenant ? tenant.state : "";
    
    // BACKEND FALLBACK: If state is missing, try to detect from address
    if (!tenantState && tenant && tenant.address) {
       const foundState = INDIAN_STATES.find(s => 
           tenant.address.toLowerCase().includes(s.toLowerCase())
       );
       if (foundState) tenantState = foundState;
    }

    const {
      client, clientId, items, discountPercentage = 0, taxRate = 18, gstEnabled = false,
      taxType = 'exclusive', placeOfSupply,
      advancePayment = 0, date, dueDate, notes, terms, bankDetailsSnapshot, authorizedSignatoryImage
    } = req.body;

    const rawItems = items.map(item => ({
      ...item,
      gstRate: item.gstRate !== undefined ? Number(item.gstRate) : Number(taxRate)
    }));

    // --- INVENTORY VALIDATION & COGS CALCULATION ---
    let totalCogs = 0;
    for (let i = 0; i < rawItems.length; i++) {
       const item = rawItems[i];
       if (item.inventoryId) {
          const invItem = await Inventory.findById(item.inventoryId);
          if (invItem) {
             if (Number(item.quantity) > invItem.currentStock) {
                 return res.status(400).json({ 
                     success: false, 
                     message: `Insufficient stock for ${invItem.itemName}. Available: ${invItem.currentStock}, Requested: ${item.quantity}` 
                 });
             }
             rawItems[i].purchasePrice = invItem.purchasePrice || 0;
             totalCogs += (invItem.purchasePrice || 0) * Number(item.quantity);
          }
       }
    }

    const financials = calculateInvoiceTotals(
      rawItems, 
      discountPercentage, 
      taxType, 
      gstEnabled, 
      tenantState, 
      placeOfSupply || (client ? client.state : ""), 
      advancePayment
    );

    const lastInvoice = await Invoice.findOne({ tenantId: req.user.tenantId })
      .sort({ createdAt: -1 })
      .collation({ locale: "en_US", numericOrdering: true });

    let nextNum = 1;
    if (lastInvoice && lastInvoice.invoiceNumber) {
      const parts = lastInvoice.invoiceNumber.split('-');
      if (parts.length > 1 && !isNaN(parts[parts.length - 1])) {
        nextNum = parseInt(parts[parts.length - 1]) + 1;
      }
    }
    const invoiceNumber = `INV-${String(nextNum).padStart(4, '0')}`;

    let clientData = {};
    if (clientId) {
      const dbClient = await Client.findById(clientId);
      if (dbClient) {
        clientData = {
          name: dbClient.name, email: dbClient.email, phone: dbClient.phone,
          address: dbClient.address, gstin: dbClient.gstin, state: dbClient.state, clientId: dbClient._id
        };
      }
    } else if (client && client.name) {
      let existingClient = await Client.findOne({ tenantId: req.user.tenantId, name: client.name.trim() });
      if (!existingClient) {
        existingClient = await Client.create({
          tenantId: req.user.tenantId, name: client.name, email: client.email || "",
          phone: client.phone || "", address: client.address || "", gstin: client.gstin || "", state: client.state || ""
        });
      }
      clientData = {
        name: existingClient.name, email: existingClient.email, phone: existingClient.phone,
        address: existingClient.address, gstin: existingClient.gstin, state: existingClient.state, clientId: existingClient._id
      };
    }

    let initialStatus = 'Pending';
    let initialRemainingAmount = financials.balanceDue;
    if (initialRemainingAmount <= 0) {
      initialStatus = 'Paid';
      initialRemainingAmount = 0;
    } else if (advancePayment > 0) {
      initialStatus = 'Partially Paid';
    }

    const invoice = await Invoice.create({
      tenantId: req.user.tenantId, invoiceNumber, client: clientData, items: financials.items,
      ...financials, discountPercentage, taxRate, gstEnabled, taxType, placeOfSupply: placeOfSupply || clientData.state, advancePayment,
      date: date || Date.now(), dueDate, notes, terms, bankDetailsSnapshot,
      authorizedSignatoryImage, status: initialStatus, remainingAmount: initialRemainingAmount,
      totalCogs: totalCogs, salesPerson: req.user._id, createdBy: req.user._id
    });

    // --- HANDLE ADVANCE PAYMENT LEDGER SYNC ---
    if (advancePayment > 0 && clientData && clientData.clientId) {
      await Payment.create({
        tenantId: req.user.tenantId,
        clientId: clientData.clientId,
        invoiceId: invoice._id,
        amount: advancePayment,
        date: date || Date.now(),
        paymentMode: 'Other',
        referenceNote: `Advance payment for Invoice ${invoiceNumber}`,
        createdBy: req.user._id
      });
      // Run sync in the background so it doesn't block
      syncLedgerForClient(clientData.clientId, req.user.tenantId).catch(err => console.error("Sync Ledger Failed on Create:", err));
    }

    if (typeof logActivity === 'function') await logActivity(req, "CREATE_INVOICE", `Created Invoice ${invoiceNumber}`);

    // --- SYNC INVENTORY ---
    await syncInventoryForInvoice(req.user.tenantId, financials.items, invoice._id, clientData.name);

    // --- AUTOMATED EMAIL ---
    if (invoice.client && invoice.client.email) {
      // Fetch tenant for branding
      Tenant.findById(req.user.tenantId).then(tenant => {
        sendInvoiceEmail(invoice, null, tenant).catch(err => console.error("Auto Email Failed:", err));
      }).catch(err => console.error("Tenant Fetch Failed for Email:", err));
    }

    res.status(201).json({ success: true, data: invoice });

  } catch (error) {
    console.error("Create Invoice Error:", error);
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    let updateData = { ...req.body };

    const existingInvoice = await Invoice.findOne({ _id: id, tenantId: req.user.tenantId });
    if (!existingInvoice) return res.status(404).json({ success: false, message: "Invoice not found" });

    let paymentDetected = false;
    let detectedPaidAmount = 0;

    // 🔴 1. Ledger Auto-Inject Logic: If user marks as 'Paid' from the Invoice List
    if (updateData.status === 'Paid' && existingInvoice.status !== 'Paid') {
      detectedPaidAmount = existingInvoice.remainingAmount !== undefined ? existingInvoice.remainingAmount : existingInvoice.totalAmount;

      if (detectedPaidAmount > 0 && existingInvoice.client && existingInvoice.client.clientId) {
        // Create a silent payment record so the Master Sync doesn't overwrite this status later
        await Payment.create({
          tenantId: req.user.tenantId,
          clientId: existingInvoice.client.clientId,
          invoiceId: existingInvoice._id,
          amount: detectedPaidAmount,
          date: Date.now(),
          paymentMode: 'Other',
          referenceNote: `Auto-generated: Marked as Paid from Invoice List (${existingInvoice.invoiceNumber})`
        });
        paymentDetected = true;
      }
      updateData.remainingAmount = 0; // Balance clear

    } else if (updateData.status === 'Pending' || updateData.status === 'Overdue' || updateData.status === 'Unpaid') {
      // 🔴 2. If user manually reverts status, reset the remaining amount
      updateData.remainingAmount = existingInvoice.totalAmount;
    }

    if (updateData.items && Array.isArray(updateData.items)) {
      const tenant = await Tenant.findById(req.user.tenantId);
      let tenantState = tenant ? tenant.state : "";

      // BACKEND FALLBACK: If state is missing, try to detect from address
      if (!tenantState && tenant && tenant.address) {
         const foundState = INDIAN_STATES.find(s => 
             tenant.address.toLowerCase().includes(s.toLowerCase())
         );
         if (foundState) tenantState = foundState;
      }

      const discPercent = updateData.discountPercentage !== undefined ? updateData.discountPercentage : existingInvoice.discountPercentage;
      const taxR = updateData.taxRate !== undefined ? updateData.taxRate : existingInvoice.taxRate;
      const advPay = updateData.advancePayment !== undefined ? updateData.advancePayment : existingInvoice.advancePayment;
      const tType = updateData.taxType !== undefined ? updateData.taxType : (existingInvoice.taxType || 'exclusive');
      const gEnabled = updateData.gstEnabled !== undefined ? updateData.gstEnabled : existingInvoice.gstEnabled;
      const pSupply = updateData.placeOfSupply !== undefined ? updateData.placeOfSupply : (existingInvoice.placeOfSupply || (existingInvoice.client ? existingInvoice.client.state : ""));

      const rawItems = updateData.items.map(item => ({
        ...item,
        gstRate: item.gstRate !== undefined ? Number(item.gstRate) : Number(taxR)
      }));

      // --- INVENTORY VALIDATION & COGS CALCULATION FOR UPDATE ---
      let totalCogs = 0;
      for (let i = 0; i < rawItems.length; i++) {
         const item = rawItems[i];
         if (item.inventoryId) {
            const invItem = await Inventory.findById(item.inventoryId);
            if (invItem) {
               const prevTxs = await InventoryTransaction.find({ referenceId: id, inventoryId: item.inventoryId });
               const previouslyAllocated = prevTxs.reduce((sum, tx) => sum + Math.abs(tx.quantity), 0);
               const availablePool = invItem.currentStock + previouslyAllocated;
               
               if (Number(item.quantity) > availablePool) {
                   return res.status(400).json({ 
                       success: false, 
                       message: `Insufficient stock for ${invItem.itemName}. Available: ${availablePool}, Requested: ${item.quantity}` 
                   });
               }
               rawItems[i].purchasePrice = invItem.purchasePrice || 0;
               totalCogs += (invItem.purchasePrice || 0) * Number(item.quantity);
            }
         }
      }

      const financials = calculateInvoiceTotals(rawItems, discPercent, tType, gEnabled, tenantState, pSupply, advPay);

      updateData = { ...updateData, items: financials.items, ...financials, totalCogs };
      // Also update remainingAmount if items changed and it's not Paid
      if (updateData.status !== 'Paid') {
        updateData.remainingAmount = financials.totalAmount;
      }
    }

    const updatedInvoice = await Invoice.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });

    // --- HANDLE ADVANCE PAYMENT LEDGER SYNC ON UPDATE ---
    if (updateData.advancePayment !== undefined && updatedInvoice.client && updatedInvoice.client.clientId) {
        if (updateData.advancePayment > 0) {
            const existingPayment = await Payment.findOne({ invoiceId: id, tenantId: req.user.tenantId });
            if (existingPayment) {
                existingPayment.amount = updateData.advancePayment;
                await existingPayment.save();
            } else {
                await Payment.create({
                   tenantId: req.user.tenantId,
                   clientId: updatedInvoice.client.clientId,
                   invoiceId: id,
                   amount: updateData.advancePayment,
                   date: Date.now(),
                   paymentMode: 'Other',
                   referenceNote: `Advance payment for Invoice ${updatedInvoice.invoiceNumber}`
                });
            }
        } else {
            await Payment.deleteOne({ invoiceId: id, tenantId: req.user.tenantId });
        }
    }
    
    // Always sync ledger after updates to recalculate remainingAmount and status
    if (updatedInvoice.client && updatedInvoice.client.clientId) {
        await syncLedgerForClient(updatedInvoice.client.clientId, req.user.tenantId);
        Object.assign(updatedInvoice, await Invoice.findById(id));
    }

    // --- AUTOMATED PAYMENT EMAIL ---
    if (paymentDetected && detectedPaidAmount > 0 && updatedInvoice.client && updatedInvoice.client.email) {
      Tenant.findById(req.user.tenantId).then(tenant => {
        sendPaymentEmail(updatedInvoice, detectedPaidAmount, tenant).catch(err => console.error("Payment Email Failed:", err));
      }).catch(err => console.error("Tenant Fetch Failed for Payment Email:", err));
    }

    // --- AUTOMATED IN-APP / PUSH NOTIFICATION ---
    if (paymentDetected && detectedPaidAmount > 0) {
      const { dispatchNotification } = require('../services/notificationDispatcher');
      dispatchNotification({
        tenantId: req.user.tenantId,
        type: 'payment_received',
        message: `Payment of ₹${detectedPaidAmount} received from ${updatedInvoice.client.name}.`,
        preferenceKey: 'paymentReceived',
        metadata: { entityId: updatedInvoice._id, entityModel: 'Invoice' }
      });
    }

    // --- SYNC INVENTORY ON UPDATE ---
    // Revert old inventory changes first (if items were changed)
    if (updateData.items) {
      await revertInventoryForInvoice(req.user.tenantId, id);
      await syncInventoryForInvoice(req.user.tenantId, updatedInvoice.items, id, updatedInvoice.client.name);
    }

    if (typeof logActivity === 'function') {
      const actionType = updateData.status && Object.keys(updateData).length === 1 ? "UPDATE_STATUS" : "UPDATE_INVOICE";
      await logActivity(req, actionType, `Updated Invoice ${updatedInvoice.invoiceNumber}`);
    }

    res.status(200).json({ success: true, data: updatedInvoice });
  } catch (error) {
    console.error("Update Invoice Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteInvoice = async (req, res) => {
  try {
    const invoice = await Invoice.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!invoice) return res.status(404).json({ success: false, message: "Invoice not found" });

    // --- CLEANUP PAYMENT RECORD AND SYNC LEDGER ---
    if (invoice.advancePayment > 0 && invoice.client && invoice.client.clientId) {
      await Payment.deleteOne({ invoiceId: req.params.id, tenantId: req.user.tenantId });
      syncLedgerForClient(invoice.client.clientId, req.user.tenantId).catch(err => console.error("Sync Ledger Failed on Delete:", err));
    }

    // --- SYNC INVENTORY: REVERT STOCK ---
    await revertInventoryForInvoice(req.user.tenantId, req.params.id);

    if (typeof logActivity === 'function') await logActivity(req, "DELETE_INVOICE", `Deleted Invoice ${invoice.invoiceNumber}`);
    res.status(200).json({ success: true, message: "Invoice deleted" });
  } catch (error) {
    console.error("Delete Invoice Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// --- PUBLIC CONTROLLER: NO AUTH REQUIRED ---
exports.getPublicInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    
    // 1. Fetch Invoice
    const invoice = await Invoice.findById(id).populate('salesPerson', 'name email signatureImage');
    if (!invoice) return res.status(404).json({ success: false, message: "Invoice not found or expired" });

    // 2. Fetch Corresponding Tenant (Business) Branding Data
    const tenant = await Tenant.findById(invoice.tenantId).select(
      'name email phone address website logoImage signatureImage gstEnabled gstNumber bankDetails templatePreference'
    );

    if (!tenant) return res.status(404).json({ success: false, message: "Business data not found" });

    res.status(200).json({ 
      success: true, 
      data: {
        invoice,
        business: tenant
      }
    });

  } catch (error) {
    console.error("Public Invoice Access Error:", error);
    res.status(500).json({ success: false, message: "Error loading public invoice page" });
  }
};

exports.bulkImportInvoices = async (req, res) => {
  try {
    const invoicesData = req.body;
    if (!Array.isArray(invoicesData)) {
      return res.status(400).json({ success: false, message: "Data must be an array" });
    }

    const tenantId = req.user.tenantId;
    const tenant = await Tenant.findById(tenantId);
    let tenantState = tenant ? tenant.state : "";
    if (!tenantState && tenant && tenant.address) {
       const foundState = INDIAN_STATES.find(s => 
           tenant.address.toLowerCase().includes(s.toLowerCase())
       );
       if (foundState) tenantState = foundState;
    }

    let importedCount = 0;
    let skippedCount = 0;
    const importedClientIds = new Set();

    for (const invData of invoicesData) {
      if (!invData.clientName || !invData.items || !Array.isArray(invData.items)) {
        skippedCount++;
        continue;
      }

      // Smart Resolution: Find or Create Client
      let client = await Client.findOne({ tenantId, name: new RegExp('^' + invData.clientName.trim() + '$', 'i') });
      if (!client) {
        client = await Client.create({
          tenantId,
          name: invData.clientName.trim(),
          email: invData.clientEmail || "",
          phone: invData.clientPhone || "",
          address: invData.clientAddress || ""
        });
      }

      const clientData = {
        name: client.name, email: client.email, phone: client.phone,
        address: client.address, gstin: client.gstin, state: client.state, clientId: client._id
      };

      const taxRate = Number(invData.taxRate) || 0;
      const rawItems = invData.items.map(item => ({
        ...item,
        gstRate: item.gstRate !== undefined ? Number(item.gstRate) : Number(taxRate)
      }));

      const discountPercentage = Number(invData.discountPercentage) || 0;
      const advancePayment = Number(invData.advancePayment) || 0;

      const financials = calculateInvoiceTotals(
        rawItems, 
        discountPercentage, 
        invData.taxType || 'exclusive', 
        invData.gstEnabled === true || invData.gstEnabled === 'true', 
        tenantState, 
        invData.placeOfSupply || clientData.state, 
        advancePayment
      );

      // Resolve Invoice Number
      let invoiceNumber = invData.invoiceNumber;
      if (!invoiceNumber) {
        const lastInvoice = await Invoice.findOne({ tenantId })
          .sort({ createdAt: -1 })
          .collation({ locale: "en_US", numericOrdering: true });

        let nextNum = 1;
        if (lastInvoice && lastInvoice.invoiceNumber) {
          const parts = lastInvoice.invoiceNumber.split('-');
          if (parts.length > 1 && !isNaN(parts[parts.length - 1])) {
            nextNum = parseInt(parts[parts.length - 1]) + 1;
          }
        }
        invoiceNumber = `INV-${String(nextNum).padStart(4, '0')}`;
      }

      // Resolve Status
      let status = invData.status || 'Pending';
      let remainingAmount = financials.totalAmount;
      if (status === 'Paid') {
        remainingAmount = 0;
      } else if (status === 'Partially Paid' && advancePayment > 0) {
        remainingAmount = financials.totalAmount - advancePayment;
      }

      const invoice = await Invoice.create({
        tenantId,
        invoiceNumber,
        client: clientData,
        items: financials.items,
        ...financials,
        discountPercentage,
        taxRate,
        gstEnabled: invData.gstEnabled === true || invData.gstEnabled === 'true',
        taxType: invData.taxType || 'exclusive',
        placeOfSupply: invData.placeOfSupply || clientData.state,
        advancePayment,
        date: invData.date || Date.now(),
        dueDate: invData.dueDate,
        notes: invData.notes || '',
        status,
        remainingAmount,
        salesPerson: req.user._id
      });

      // Since these are historical imports, we won't deduct inventory automatically 
      // unless items explicitly have inventoryId mapped from frontend.
      if (financials.items.some(i => i.inventoryId)) {
        await syncInventoryForInvoice(tenantId, financials.items, invoice._id, clientData.name);
      }

      if (advancePayment > 0 && clientData && clientData.clientId) {
          await Payment.create({
             tenantId,
             clientId: clientData.clientId,
             invoiceId: invoice._id,
             amount: advancePayment,
             date: invData.date || Date.now(),
             paymentMode: 'Other',
             referenceNote: `Advance payment for imported Invoice ${invoiceNumber}`
          });
          importedClientIds.add(clientData.clientId.toString());
      } else if (status === 'Paid') {
          // If marked as Paid but no advance payment, maybe it was fully paid historically.
          importedClientIds.add(clientData.clientId.toString());
      }

      importedCount++;
    }

    // Sync ledgers for affected clients
    for (const cid of importedClientIds) {
       syncLedgerForClient(cid, tenantId).catch(err => console.error("Sync Ledger Failed on Bulk Import:", err));
    }

    if (typeof logActivity === 'function') {
      await logActivity(req, "BULK_IMPORT", `Imported ${importedCount} historical invoices`);
    }

    res.status(200).json({ 
      success: true, 
      message: `Import complete. Added ${importedCount} invoices. Skipped ${skippedCount} invalid rows.` 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};