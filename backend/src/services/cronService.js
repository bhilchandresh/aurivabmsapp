const cron = require('node-cron');
const Invoice = require('../models/Invoice');
const Quotation = require('../models/Quotation');
const Purchase = require('../models/Purchase');
const Expense = require('../models/Expense');
const Tenant = require('../models/Tenant');
const { dispatchNotification } = require('./notificationDispatcher');

/**
 * START CRON JOBS
 */
exports.initCronJobs = () => {
  // Run every day at 8:00 AM (for Due Dates & Alerts)
  cron.schedule('0 8 * * *', async () => {
    console.log("Running Daily 8 AM Check (Invoices, Quotations, Purchases, Expenses)...");
    await checkInvoices();
    await checkQuotations();
    await checkPurchases();
    await checkExpenses();
  }, { timezone: "Asia/Kolkata" });

  // Run every day at 9:00 AM (Morning Business Summary)
  cron.schedule('0 9 * * *', async () => {
    console.log("Running Daily 9 AM Morning Summary...");
    await sendMorningSummary();
  }, { timezone: "Asia/Kolkata" });
};

const checkInvoices = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const invoices = await Invoice.find({ status: { $nin: ['Paid', 'Cancelled'] }, dueDate: { $exists: true } });

  for (const inv of invoices) {
    const dueDate = new Date(inv.dueDate);
    dueDate.setHours(0, 0, 0, 0);

    const diffTime = dueDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      // Due Tomorrow
      await dispatchNotification({
        tenantId: inv.tenantId,
        type: 'invoice_due',
        message: `⏳ Invoice ${inv.invoiceNumber} worth ₹${inv.totalAmount} is due tomorrow.`,
        preferenceKey: 'invoiceDueTomorrow',
        metadata: { entityId: inv._id, entityModel: 'Invoice' }
      });
    } else if (diffDays === 0) {
      // Due Today
      await dispatchNotification({
        tenantId: inv.tenantId,
        type: 'invoice_due',
        message: `⚠️ Payment expected today for ${inv.invoiceNumber} (₹${inv.totalAmount}).`,
        preferenceKey: 'invoiceDueToday',
        metadata: { entityId: inv._id, entityModel: 'Invoice' }
      });
    } else if (diffDays < 0 && inv.status !== 'Overdue') {
      // Overdue
      const overdueDays = Math.abs(diffDays);
      await dispatchNotification({
        tenantId: inv.tenantId,
        type: 'invoice_due',
        message: `🚨 Invoice ${inv.invoiceNumber} is overdue by ${overdueDays} days.`,
        preferenceKey: 'invoiceOverdue',
        metadata: { entityId: inv._id, entityModel: 'Invoice' }
      });
      // Auto-update status to Overdue if not already
      inv.status = 'Overdue';
      await inv.save();
    }
  }
};

const checkQuotations = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const quotes = await Quotation.find({ status: 'Pending', validUntil: { $exists: true } });

  for (const qt of quotes) {
    const expiry = new Date(qt.validUntil);
    expiry.setHours(0, 0, 0, 0);

    const diffTime = expiry - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 3) {
      await dispatchNotification({
        tenantId: qt.tenantId,
        type: 'quotation_alert',
        message: `⏱️ Quotation ${qt.quotationNumber} expires in 3 days.`,
        preferenceKey: 'quotationExpiring',
        metadata: { entityId: qt._id, entityModel: 'Quotation' }
      });
    } else if (diffDays < 0) {
      qt.status = 'Expired';
      await qt.save();
    }
  }
};

const checkPurchases = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const purchases = await Purchase.find({ status: { $ne: 'Paid' }, dueDate: { $exists: true } }).populate('supplierId');

  for (const pur of purchases) {
    const dueDate = new Date(pur.dueDate);
    dueDate.setHours(0, 0, 0, 0);

    const diffTime = dueDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      await dispatchNotification({
        tenantId: pur.tenantId,
        type: 'supplier_alert',
        message: `💸 Payment due to ${pur.supplierId?.name || 'Supplier'} tomorrow for Bill ${pur.billNumber}.`,
        preferenceKey: 'supplierPaymentDue',
        metadata: { entityId: pur._id, entityModel: 'Purchase' }
      });
    }
  }
};

const checkExpenses = async () => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const expenses = await Expense.find({ status: 'Pending', dueDate: { $exists: true } });

  for (const exp of expenses) {
    const dueDate = new Date(exp.dueDate);
    dueDate.setHours(0, 0, 0, 0);

    const diffTime = dueDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      await dispatchNotification({
        tenantId: exp.tenantId,
        type: 'expense_alert',
        message: `🗓️ Expense Reminder: ${exp.category} (₹${exp.amount}) due tomorrow.`,
        preferenceKey: 'recurringExpense',
        metadata: { entityId: exp._id, entityModel: 'Expense' }
      });
    }
  }
};

const sendMorningSummary = async () => {
  const tenants = await Tenant.find({ status: 'active' });

  for (const tenant of tenants) {
    if (tenant.notificationPreferences && tenant.notificationPreferences.morningSummary === false) continue;

    const [pendingInvoices, lowStock] = await Promise.all([
      Invoice.countDocuments({ tenantId: tenant._id, status: { $nin: ['Paid', 'Cancelled'] } }),
      // A quick check for low stock by aggregating or simply counting.
      // Since reorderLevel logic is complex in a query, we'll just count items with stock < 5
      // as a rough estimate for the summary.
      require('../models/Inventory').countDocuments({ tenantId: tenant._id, currentStock: { $lte: 5 } })
    ]);

    const message = `Good Morning! 👋 Today's Summary: You have ${pendingInvoices} pending invoices and ${lowStock} low stock items.`;

    await dispatchNotification({
      tenantId: tenant._id,
      type: 'summary',
      message: message,
      preferenceKey: 'morningSummary'
    });
  }
};
