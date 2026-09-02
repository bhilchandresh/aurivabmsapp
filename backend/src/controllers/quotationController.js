const Quotation = require('../models/Quotation');
const Client = require('../models/Client');
const Invoice = require('../models/Invoice');
const User = require('../models/User');
const logActivity = require('../utils/logger');
const { chromium } = require('playwright');
const getTemplate = require('../templates/index');
const nodemailer = require('nodemailer');

// --- HELPER: Calculate Totals ---
const calculateTotals = (items, discountPercentage = 0, taxType = 'exclusive', gstEnabled = false, tenantState = '', clientState = '', advancePayment = 0) => {
  if (!Array.isArray(items)) return {};

  let subTotal = 0;
  let totalTaxAmount = 0;
  let cgst = 0;
  let sgst = 0;
  let igst = 0;

  const isInterState = tenantState && clientState && tenantState.trim().toLowerCase() !== clientState.trim().toLowerCase();

  const processedItems = items.map(item => {
    const qty = Number(item.quantity) || 0;
    const rate = Number(item.rate || item.price) || 0;
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

// --- HELPER: Generate PDF using Playwright ---
const generatePdfBuffer = async (htmlContent) => {
  let browser;
  try {
    browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    await page.setContent(htmlContent, { waitUntil: 'networkidle' });

    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '10mm', right: '10mm', bottom: '10mm', left: '10mm' }
    });

    await browser.close();
    return pdfBuffer;

  } catch (error) {
    if (browser) await browser.close();
    throw new Error("PDF Generation Failed: " + error.message);
  }
};

// ==========================================
// QUOTATION CONTROLLERS
// ==========================================

// @desc    Get All Quotations
exports.getQuotations = async (req, res) => {
  try {
    let query = { tenantId: req.user.tenantId };

    if (req.query.clientId) {
      query.$or = [{ "client.clientId": req.query.clientId }, { "client": req.query.clientId }];
    }

    if (req.query.search) {
      const searchRegex = new RegExp(req.query.search, 'i');
      query.$or = [
        { quotationNumber: searchRegex },
        { quoteNumber: searchRegex },
        { "client.name": searchRegex }
      ];
    }

    if (req.query.status && req.query.status !== 'all') {
      query.status = new RegExp('^' + req.query.status + '$', 'i');
    }

    if (req.query.month) {
      const startDate = new Date(`${req.query.month}-01`);
      const endDate = new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0);
      query.date = {
        $gte: startDate.toISOString().split('T')[0],
        $lte: endDate.toISOString().split('T')[0]
      };
    }

    let sortObj = { createdAt: -1 };
    if (req.query.sortBy) {
      if (req.query.sortBy === 'newest') sortObj = { date: -1, createdAt: -1 };
      else if (req.query.sortBy === 'oldest') sortObj = { date: 1, createdAt: 1 };
      else if (req.query.sortBy === 'amount_high') sortObj = { totalAmount: -1 };
      else if (req.query.sortBy === 'amount_low') sortObj = { totalAmount: 1 };
    }

    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip = (page - 1) * limit;

    const quotations = await Quotation.find(query)
      .sort(sortObj)
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'name email');

    const total = await Quotation.countDocuments(query);

    res.status(200).json({ 
      success: true, 
      count: quotations.length, 
      data: quotations,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error("Get Quotes Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get Single Quotation
exports.getQuotationById = async (req, res) => {
  try {
    const quotation = await Quotation.findOne({ _id: req.params.id, tenantId: req.user.tenantId })
      .populate('salesPerson', 'name email signatureImage');

    if (!quotation) return res.status(404).json({ success: false, message: "Quotation not found" });
    res.status(200).json({ success: true, data: quotation });
  } catch (error) {
    console.error("Get Quote By ID Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Create Quotation (Updated with HSN Code)
exports.createQuotation = async (req, res) => {
  try {
    const {
      client,
      clientId,
      items,
      discountPercentage = 0,
      taxType = 'exclusive',
      taxRate = 0,
      gstEnabled = false,
      placeOfSupply,
      date,
      validUntil,
      notes,
      terms,
      bankDetailsSnapshot,
      advancePayment = 0
    } = req.body;

    const currentUser = await User.findById(req.user.id);
    const Tenant = require('../models/Tenant');
    const tenant = await Tenant.findById(req.user.tenantId);

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: "At least one item is required." });
    }

    // Calculate Items & Capture HSN
    const calculatedItems = items.map(item => ({
      description: item.description,
      additionalDetails: item.additionalDetails || "",
      hsnCode: item.hsnCode || "", // ✅ NEW: Capture HSN Code
      quantity: Number(item.quantity),
      rate: Number(item.rate || item.price || 0),
      gstRate: Number(item.gstRate || 0),
      total: Number(item.quantity) * Number(item.rate || item.price || 0)
    }));

    // If client is string, assume it's state, but normally we look up existingClient
    let tempClientState = client && client.state ? client.state : '';
    if (clientId) {
      const dbClient = await Client.findById(clientId);
      if (dbClient) tempClientState = dbClient.state || '';
    }

    const financials = calculateTotals(
      calculatedItems, 
      discountPercentage, 
      taxType, 
      gstEnabled, 
      tenant?.state || '', 
      placeOfSupply || tempClientState, 
      advancePayment
    );
    const advance = Number(advancePayment) || 0;
    const balanceDue = financials.totalAmount - advance;

    const lastQuote = await Quotation.findOne({ tenantId: req.user.tenantId })
      .sort({ createdAt: -1 })
      .collation({ locale: "en_US", numericOrdering: true });

    let nextNum = 1;
    const lastNumStr = lastQuote?.quotationNumber || lastQuote?.quoteNumber;

    if (lastNumStr) {
      const parts = lastNumStr.split('-');
      if (parts.length > 1 && !isNaN(parts[parts.length - 1])) {
        nextNum = parseInt(parts[parts.length - 1]) + 1;
      }
    }
    const generatedNumber = `QT-${String(nextNum).padStart(4, '0')}`;

    let clientData = {};
    if (clientId) {
      const dbClient = await Client.findById(clientId);
      if (dbClient) {
        clientData = {
          name: dbClient.name, email: dbClient.email, phone: dbClient.phone,
          address: dbClient.address, gstNumber: dbClient.gstNumber, clientId: dbClient._id
        };
      }
    } else if (client && client.name) {
      let existingClient = await Client.findOne({ tenantId: req.user.tenantId, name: client.name.trim() });
      if (!existingClient) {
        existingClient = await Client.create({
          tenantId: req.user.tenantId, name: client.name, email: client.email || "",
          phone: client.phone || "", address: client.address || "", gstNumber: client.gstNumber || ""
        });
      }
      clientData = {
        name: existingClient.name, email: existingClient.email, phone: existingClient.phone,
        address: existingClient.address, gstNumber: existingClient.gstNumber, clientId: existingClient._id
      };
    }

    if (!clientData.name) {
      return res.status(400).json({ success: false, message: "Client Name is required." });
    }

    const newQuotation = await Quotation.create({
      tenantId: req.user.tenantId,
      quoteNumber: generatedNumber,
      quotationNumber: generatedNumber,
      client: clientData,
      ...financials, // includes items with tax amounts
      discountPercentage,
      taxType,
      taxRate,
      gstEnabled,
      placeOfSupply: placeOfSupply || tempClientState,
      advancePayment: advance,
      balanceDue: balanceDue,
      date: date || Date.now(),
      validUntil: validUntil || new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      status: 'Pending',
      notes,
      terms: terms || "Valid for 7 days.",
      bankDetailsSnapshot,
      authorizedSignatoryImage: currentUser?.signatureImage || "",
      createdBy: req.user._id,
      salesPerson: req.user._id
    });

    if (typeof logActivity === 'function') {
      await logActivity(req, "CREATE_QUOTATION", `Created Quote ${generatedNumber} for ${clientData.name}`);
    }

    res.status(201).json({ success: true, data: newQuotation });
  } catch (error) {
    console.error("Create Quote Error:", error);
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Update Quotation (Updated with HSN Code)
exports.updateQuotation = async (req, res) => {
  try {
    const { id } = req.params;
    let updateData = { ...req.body };
    const existingQuotation = await Quotation.findOne({ _id: id, tenantId: req.user.tenantId });
    if (!existingQuotation) return res.status(404).json({ success: false, message: "Quotation not found" });

    if (updateData.items && Array.isArray(updateData.items)) {
      const calculatedItems = updateData.items.map(item => ({
        description: item.description,
        additionalDetails: item.additionalDetails || "",
        hsnCode: item.hsnCode || "", // ✅ NEW: Capture HSN Code on Update
        quantity: Number(item.quantity),
        rate: Number(item.rate || item.price || 0),
        gstRate: Number(item.gstRate || 0),
        total: Number(item.quantity) * Number(item.rate || item.price || 0)
      }));
      
      const Tenant = require('../models/Tenant');
      const tenant = await Tenant.findById(req.user.tenantId);

      const discPercent = updateData.discountPercentage !== undefined ? updateData.discountPercentage : existingQuotation.discountPercentage;
      const tType = updateData.taxType !== undefined ? updateData.taxType : existingQuotation.taxType;
      const gEnabled = updateData.gstEnabled !== undefined ? updateData.gstEnabled : existingQuotation.gstEnabled;
      const pos = updateData.placeOfSupply !== undefined ? updateData.placeOfSupply : existingQuotation.placeOfSupply;
      const advPayment = updateData.advancePayment !== undefined ? updateData.advancePayment : existingQuotation.advancePayment;
      
      const financials = calculateTotals(
        calculatedItems, 
        discPercent, 
        tType, 
        gEnabled, 
        tenant?.state || '', 
        pos || existingQuotation.client?.state || '', 
        advPayment
      );
      updateData = { ...updateData, ...financials };
    }

    const updatedQuotation = await Quotation.findByIdAndUpdate(id, updateData, { new: true, runValidators: true });
    if (typeof logActivity === 'function') await logActivity(req, "UPDATE_QUOTATION", `Updated Quote ${updatedQuotation.quotationNumber}`);

    // --- AUTOMATED IN-APP / PUSH NOTIFICATION ---
    if (updateData.status === 'Accepted' && existingQuotation.status !== 'Accepted') {
      const { dispatchNotification } = require('../services/notificationDispatcher');
      dispatchNotification({
        tenantId: req.user.tenantId,
        type: 'quotation_alert',
        message: `🎉 ${updatedQuotation.client.name} accepted your quotation ${updatedQuotation.quotationNumber}.`,
        preferenceKey: 'quotationAccepted',
        metadata: { entityId: updatedQuotation._id, entityModel: 'Quotation' }
      });
    }

    res.status(200).json({ success: true, data: updatedQuotation });
  } catch (error) {
    console.error("Update Quotation Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Delete Quotation
exports.deleteQuotation = async (req, res) => {
  try {
    const quote = await Quotation.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!quote) return res.status(404).json({ success: false, message: "Quotation not found" });
    if (typeof logActivity === 'function') await logActivity(req, "DELETE_QUOTATION", `Deleted Quote ${quote.quotationNumber}`);
    res.status(200).json({ success: true, message: "Quotation deleted" });
  } catch (error) {
    console.error("Delete Quotation Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Convert Quotation to Invoice (Updated to carry over HSN Code)
exports.convertToInvoice = async (req, res) => {
  try {
    const { id } = req.params;
    const quote = await Quotation.findOne({ _id: id, tenantId: req.user.tenantId });
    if (!quote) return res.status(404).json({ success: false, message: "Quotation not found" });
    if (quote.convertedInvoiceId) return res.status(400).json({ success: false, message: "Already converted." });

    const lastInvoice = await Invoice.findOne({ tenantId: req.user.tenantId }).sort({ createdAt: -1 }).collation({ locale: "en_US", numericOrdering: true });
    let nextNum = 1;
    if (lastInvoice && lastInvoice.invoiceNumber) {
      const parts = lastInvoice.invoiceNumber.split('-');
      if (parts.length > 1 && !isNaN(parts[parts.length - 1])) nextNum = parseInt(parts[parts.length - 1]) + 1;
    }
    const invoiceNumber = `INV-${String(nextNum).padStart(4, '0')}`;

    const newInvoice = await Invoice.create({
      tenantId: req.user.tenantId,
      invoiceNumber: invoiceNumber,
      client: quote.client,
      items: quote.items.map(item => ({
        description: item.description,
        additionalDetails: item.additionalDetails,
        hsnCode: item.hsnCode, // ✅ NEW: Carry over HSN to Invoice
        quantity: item.quantity,
        rate: item.rate,
        gstRate: item.gstRate,
        taxAmount: item.taxAmount,
        total: item.total
      })),
      subTotal: quote.subTotal,
      discountPercentage: quote.discountPercentage,
      taxType: quote.taxType,
      taxRate: quote.taxRate,
      gstAmount: quote.gstAmount,
      gstEnabled: quote.gstEnabled,
      gstBreakdown: quote.gstBreakdown,
      placeOfSupply: quote.placeOfSupply,
      totalAmount: quote.totalAmount,
      advancePayment: 0,
      balanceDue: quote.totalAmount,
      date: new Date(),
      dueDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
      status: 'Pending',
      notes: quote.notes,
      terms: quote.terms,
      bankDetailsSnapshot: quote.bankDetailsSnapshot,
      authorizedSignatoryImage: quote.authorizedSignatoryImage,
      salesPerson: req.user._id,
    });

    quote.status = 'Accepted';
    quote.convertedInvoiceId = newInvoice._id;
    await quote.save();

    if (typeof logActivity === 'function') await logActivity(req, "CONVERT_TO_INVOICE", `Converted Quote to Invoice ${invoiceNumber}`);

    res.status(201).json({ success: true, message: "Converted successfully", invoiceId: newInvoice._id });
  } catch (error) {
    console.error("Conversion Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.downloadQuotationPDF = async (req, res) => {
  try {
    const { html } = req.body;

    if (!html) return res.status(400).json({ message: "No HTML content" });

    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();

    await page.setContent(html, { waitUntil: 'networkidle' });

    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '0', bottom: '0', left: '0', right: '0' }
    });

    await browser.close();

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Length': pdfBuffer.length,
    });
    res.send(pdfBuffer);

  } catch (error) {
    console.error("PDF Error:", error);
    res.status(500).json({ message: "PDF Failed", error: error.message });
  }
};

// ✅ 1. SEND QUOTATION EMAIL
exports.emailQuotation = async (req, res) => {
  try {
    const { id } = req.params;
    const templateName = req.query.template || 'standard';

    const quotation = await Quotation.findOne({ _id: id, tenantId: req.user.tenantId });
    if (!quotation || !quotation.client.email) {
      return res.status(400).json({ message: "Client email not found" });
    }

    const htmlContent = getTemplate(templateName, quotation);
    const pdfBuffer = await generatePdfBuffer(htmlContent);

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS }
    });

    await transporter.sendMail({
      from: `"Auriva Proposals" <${process.env.EMAIL_USER}>`,
      to: quotation.client.email,
      subject: `Quotation #${quotation.quotationNumber} from Auriva`,
      html: `
            <p>Dear <strong>${quotation.client.name}</strong>,</p>
            <p>Please find attached the quotation <strong>#${quotation.quotationNumber}</strong>.</p>
            <p><strong>Total Amount: ₹${quotation.totalAmount}</strong></p>
            <p>Looking forward to your positive response.</p>
            <br>
            <p>Best Regards,<br>Auriva Solutions</p>
        `,
      attachments: [{ filename: `Quotation-${quotation.quotationNumber}.pdf`, content: pdfBuffer }]
    });

    res.json({ success: true, message: "Email sent successfully!" });

  } catch (error) {
    console.error("Email Error:", error);
    res.status(500).json({ message: "Email failed", error: error.message });
  }
};

// ✅ 2. WHATSAPP LINK FOR QUOTATION
exports.whatsappQuotation = async (req, res) => {
  try {
    const { id } = req.params;
    const quotation = await Quotation.findOne({ _id: id, tenantId: req.user.tenantId }).populate('tenantId');

    if (!quotation || !quotation.client || !quotation.client.phone) {
      return res.status(400).json({ message: "Client phone not found" });
    }

    const phone = quotation.client.phone.replace(/\D/g, '');
    const companyName = quotation.tenantId ? quotation.tenantId.name : 'Our Company';
    
    const frontendUrl = process.env.FRONTEND_URL || req.get('origin') || 'http://localhost:5173';
    const publicLink = `${frontendUrl}/public/quotation/${quotation._id}`;

    const text = `Hello ${quotation.client.name},\n\nHere is your quotation ${quotation.quotationNumber} from ${companyName} for the amount of ₹${quotation.totalAmount}.\nValid Until: ${new Date(quotation.validUntil).toLocaleDateString()}\n\nYou can view, download, or print your quotation online using the following link:\n${publicLink}\n\nThank you for your business!\n\nBest Regards,\n${companyName}`;

    const link = `https://wa.me/${phone}?text=${encodeURIComponent(text)}`;

    res.json({ success: true, whatsappUrl: link });

  } catch (error) {
    console.error("WhatsApp Error:", error);
    res.status(500).json({ message: "Error", error: error.message });
  }
};

// --- PUBLIC CONTROLLER: NO AUTH REQUIRED ---
exports.getPublicQuotation = async (req, res) => {
  try {
    const { id } = req.params;
    const Quotation = require('../models/Quotation');
    const Tenant = require('../models/Tenant');

    // 1. Fetch Quotation
    const quote = await Quotation.findById(id).populate('salesPerson', 'name email signatureImage');
    if (!quote) return res.status(404).json({ success: false, message: "Quotation not found or expired" });

    // 2. Fetch Corresponding Tenant (Business) Branding Data
    const tenant = await Tenant.findById(quote.tenantId).select(
      'name email phone address website logoImage signatureImage gstEnabled gstNumber bankDetails templatePreference quotationTemplate'
    );

    if (!tenant) return res.status(404).json({ success: false, message: "Business data not found" });

    res.status(200).json({ 
      success: true, 
      data: {
        quotation: quote,
        business: tenant
      }
    });

  } catch (error) {
    console.error("Public Quotation Access Error:", error);
    res.status(500).json({ success: false, message: "Error loading public proposal" });
  }
};