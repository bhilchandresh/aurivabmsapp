const Quotation = require('../models/Quotation');
const Expense = require('../models/Expense');
const Invoice = require('../models/Invoice'); // <--- Import Invoice Model at the top
const Purchase = require('../models/Purchase');
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
    let query = { tenantId: req.user.tenantId };
    
    // Filter by category
    if (req.query.category && req.query.category !== 'All') {
      query.category = req.query.category;
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

    // Sorting
    let sortObj = { date: -1, createdAt: -1 }; // default date-desc
    if (req.query.sortBy) {
      if (req.query.sortBy === 'date-asc') sortObj = { date: 1, createdAt: 1 };
      else if (req.query.sortBy === 'amount-desc') sortObj = { amount: -1 };
      else if (req.query.sortBy === 'amount-asc') sortObj = { amount: 1 };
    }

    // Pagination
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 1000;
    const skip = (page - 1) * limit;

    const expenses = await Expense.find(query)
      .sort(sortObj)
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'name email');

    const total = await Expense.countDocuments(query);

    res.status(200).json({ 
      success: true, 
      data: expenses,
      pagination: {
        total,
        page,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createExpense = async (req, res) => {
  try {
    const expense = await Expense.create({
      tenantId: req.user.tenantId,
      createdBy: req.user._id,
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

// @desc    Get aggregated dashboard stats
exports.getDashboardStats = async (req, res) => {
  try {
    const tenantId = req.user.tenantId;

    // 1. Fetch recent invoices and expenses (limit 5)
    const recentInvoices = await Invoice.find({ tenantId })
      .populate('client', 'name')
      .populate('createdBy', 'name email')
      .sort({ date: -1 })
      .limit(5);

    const recentExpenses = await Expense.find({ tenantId })
      .populate('createdBy', 'name email')
      .sort({ date: -1 })
      .limit(5);

    // 2. Aggregate totals
    const invoices = await Invoice.find({ tenantId });
    const expenses = await Expense.find({ tenantId });
    const purchases = await Purchase.find({ tenantId });

    let totalRevenue = 0;
    let totalPendingAmount = 0;
    let totalCogs = 0;
    let paidInvoices = 0;
    let pendingCount = 0;

    invoices.forEach(inv => {
      totalRevenue += (inv.totalAmount || 0);
      totalCogs += (inv.totalCogs || 0);
      if (inv.status === 'Pending' || inv.status === 'Overdue') {
        totalPendingAmount += (inv.totalAmount || 0);
        pendingCount++;
      }
      if (inv.status === 'Paid') {
        paidInvoices++;
      }
    });

    let totalExpenses = 0;
    expenses.forEach(exp => {
      totalExpenses += (Number(exp.amount) || 0);
    });

    let totalPurchases = 0;
    purchases.forEach(p => {
      totalPurchases += (p.totalAmount || 0);
    });

    const netProfit = totalRevenue - totalExpenses - totalCogs;

    // 3. Month and Year chart aggregation (simple map-reduce in memory since arrays are retrieved)
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const months = {};
    for (let i = 5; i >= 0; i--) {
        const d = new Date();
        d.setMonth(d.getMonth() - i);
        const m = monthNames[d.getMonth()];
        months[m] = { name: m, income: 0, expense: 0 };
    }

    invoices.forEach(inv => {
      if (!inv.date) return;
      const m = monthNames[new Date(inv.date).getMonth()];
      if (months[m]) months[m].income += (inv.totalAmount || 0);
    });

    expenses.forEach(exp => {
      if (!exp.date) return;
      const m = monthNames[new Date(exp.date).getMonth()];
      if (months[m]) months[m].expense += (Number(exp.amount) || 0);
    });

    const chartDataMonthly = Object.values(months);

    const yearNames = [];
    for (let i = 4; i >= 0; i--) {
        yearNames.push((new Date().getFullYear() - i).toString());
    }
    const years = {};
    yearNames.forEach(y => years[y] = { name: y, income: 0, expense: 0 });

    invoices.forEach(inv => {
      if (!inv.date) return;
      const y = new Date(inv.date).getFullYear().toString();
      if (years[y]) years[y].income += (inv.totalAmount || 0);
    });

    expenses.forEach(exp => {
      if (!exp.date) return;
      const y = new Date(exp.date).getFullYear().toString();
      if (years[y]) years[y].expense += (Number(exp.amount) || 0);
    });

    const chartDataYearly = Object.values(years);

    // 4. Extract unique expense categories
    const expenseCategories = [...new Set(expenses.map(exp => exp.category).filter(Boolean))].sort();

    res.status(200).json({
      success: true,
      data: {
        stats: {
          totalRevenue,
          totalExpenses,
          totalPurchases,
          netProfit,
          totalPendingAmount,
          totalInvoices: invoices.length,
          paidInvoices,
          pendingCount
        },
        recentInvoices,
        recentExpenses,
        expenseCategories,
        chartDataMonthly,
        chartDataYearly
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};