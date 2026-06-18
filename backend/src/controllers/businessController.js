const Quotation = require('../models/Quotation');
const Expense = require('../models/Expense');
const Invoice = require('../models/Invoice'); // <--- Import Invoice Model at the top

// --- QUOTATIONS ---

// @desc    Get all quotations
exports.getQuotations = async (req, res) => {
  try {
    const quotes = await Quotation.find({ tenantId: req.user.tenantId })
      .populate('client', 'name email')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: quotes });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get Single Quotation (FIX FOR YOUR ERROR)
exports.getQuotationById = async (req, res) => {
  try {
    const quote = await Quotation.findOne({ 
      _id: req.params.id, 
      tenantId: req.user.tenantId 
    }).populate('client');

    if (!quote) return res.status(404).json({ success: false, message: 'Quotation not found' });

    res.status(200).json({ success: true, data: quote });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Create a new quotation
exports.createQuotation = async (req, res) => {
  try {
    const { clientId, items, validUntil } = req.body;
    
    const calculatedItems = items.map(item => ({
      ...item,
      total: item.quantity * item.price
    }));

    const totalAmount = calculatedItems.reduce((acc, item) => acc + item.total, 0);

    const lastQuote = await Quotation.findOne({ tenantId: req.user.tenantId }).sort({ createdAt: -1 });
    let nextNum = 1;
    if (lastQuote && lastQuote.quoteNumber) {
      const parts = lastQuote.quoteNumber.split('-');
      if (parts.length > 1) nextNum = parseInt(parts[1]) + 1;
    }
    const quoteNumber = `QT-${String(nextNum).padStart(3, '0')}`;

    const quote = await Quotation.create({
      tenantId: req.user.tenantId,
      client: clientId,
      quoteNumber,
      items: calculatedItems,
      totalAmount,
      validUntil
    });

    res.status(201).json({ success: true, data: quote });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Update Quotation Status (FIX FOR YOUR ERROR)
exports.updateQuotationStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const quote = await Quotation.findOneAndUpdate(
      { _id: req.params.id, tenantId: req.user.tenantId },
      { status },
      { new: true }
    );
    res.status(200).json({ success: true, data: quote });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// --- EXPENSES ---

exports.getExpenses = async (req, res) => {
  try {
    const expenses = await Expense.find({ tenantId: req.user.tenantId }).sort({ date: -1 });
    res.status(200).json({ success: true, data: expenses });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createExpense = async (req, res) => {
  try {
    const expense = await Expense.create({
      tenantId: req.user.tenantId,
      ...req.body
    });
    res.status(201).json({ success: true, data: expense });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteExpense = async (req, res) => {
  try {
    const expense = await Expense.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!expense) return res.status(404).json({ success: false, message: 'Expense not found' });
    res.status(200).json({ success: true, message: 'Expense deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Convert Quotation to Invoice
exports.convertQuoteToInvoice = async (req, res) => {
  try {
    const quote = await Quotation.findOne({ 
      _id: req.params.id, 
      tenantId: req.user.tenantId 
    });

    if (!quote) return res.status(404).json({ success: false, message: 'Quotation not found' });

    // 1. Generate new Invoice Number
    const lastInvoice = await Invoice.findOne({ tenantId: req.user.tenantId }).sort({ createdAt: -1 });
    let nextNum = 1;
    if (lastInvoice && lastInvoice.invoiceNumber) {
      const parts = lastInvoice.invoiceNumber.split('-');
      if (parts.length > 1) nextNum = parseInt(parts[1]) + 1;
    }
    const invoiceNumber = `INV-${String(nextNum).padStart(3, '0')}`;

    // 2. Create Invoice using Quote data
    const newInvoice = await Invoice.create({
      tenantId: req.user.tenantId,
      client: quote.client,
      invoiceNumber: invoiceNumber,
      items: quote.items,        // Copy items
      totalAmount: quote.totalAmount,
      status: 'pending',         // Default to pending
      date: new Date()
    });

    // 3. Update Quote status to 'accepted' (if not already)
    quote.status = 'accepted';
    await quote.save();

    res.status(201).json({ success: true, data: newInvoice });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};