const Supplier = require('../models/Supplier');
const Purchase = require('../models/Purchase');
const SupplierPayment = require('../models/SupplierPayment');
const Tenant = require('../models/Tenant');
const Inventory = require('../models/Inventory');
const InventoryTransaction = require('../models/InventoryTransaction');
const checkSubscription = require('../middleware/checkSubscription');
const logActivity = require('../utils/logger');

// Auto Sync Ledger Status (Khatabook Pattern)
const syncPurchaseStatus = async (supplierId, tenantId) => {
    let completedPayments = await SupplierPayment.find({ supplierId, tenantId });
    let totalPaid = completedPayments.reduce((sum, p) => sum + p.amount, 0);

    // Reset all bills FIRST
    await Purchase.updateMany({ supplierId, tenantId }, { $set: { amountPaid: 0, status: 'Unpaid' } });

    // Refetch the completely reset ones to distribute FIFO
    const allBills = await Purchase.find({ supplierId, tenantId }).sort({ date: 1 });

    for (let bill of allBills) {
        if (totalPaid <= 0) break;
        
        let pendingOnBill = bill.totalAmount;
        let cover = Math.min(totalPaid, pendingOnBill);
        
        bill.amountPaid = cover;
        
        // Tolerance up to 1 rupee
        if (bill.totalAmount - bill.amountPaid <= 1) {
            bill.status = 'Paid';
        } else if (bill.amountPaid > 0) {
            bill.status = 'Partial';
        } else {
            bill.status = 'Unpaid';
        }
        
        await bill.save();
        totalPaid -= cover;
    }
};

const getPlanLimits = (planName) => {
  return checkSubscription.PLANS[planName] || checkSubscription.PLANS['basic'];
};

// --- HELPER FUNCTION: Sync Inventory for Purchase ---
const syncInventoryForPurchase = async (tenantId, items, purchaseId, supplierName) => {
    for (const item of items) {
        if (item.inventoryId) {
            const quantity = Number(item.quantity);
            // Update Stock
            await Inventory.findByIdAndUpdate(item.inventoryId, {
                $inc: { currentStock: quantity }
            });

            // Create Transaction Record
            await InventoryTransaction.create({
                tenantId,
                inventoryId: item.inventoryId,
                type: 'Purchase',
                quantity: quantity,
                referenceId: purchaseId,
                description: `Purchased from ${supplierName}`,
                date: Date.now()
            });
        }
    }
};

const revertInventoryForPurchase = async (tenantId, purchaseId) => {
    const transactions = await InventoryTransaction.find({ tenantId, referenceId: purchaseId });
    for (const tx of transactions) {
        // Reverse the stock change (Purchase added stock, so we subtract it)
        await Inventory.findByIdAndUpdate(tx.inventoryId, {
            $inc: { currentStock: -tx.quantity }
        });
    }
    // Delete the transactions
    await InventoryTransaction.deleteMany({ tenantId, referenceId: purchaseId });
};

// --- SUPPLIERS --- //
exports.getSuppliers = async (req, res) => {
    try {
        const suppliers = await Supplier.find({ tenantId: req.user.tenantId }).sort({ createdAt: -1 });
        res.json({ success: true, count: suppliers.length, data: suppliers });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

exports.createSupplier = async (req, res) => {
    try {
        const tenant = req.tenant; 
        const limits = getPlanLimits(tenant.subscriptionPlan);
        
        if (limits.maxSuppliers === 0) {
            return res.status(403).json({ success: false, message: "Suppliers feature is restricted on the Starter plan. Please upgrade." });
        }
        const count = await Supplier.countDocuments({ tenantId: req.user.tenantId });
        if (count >= limits.maxSuppliers) {
            return res.status(403).json({ success: false, message: `Supplier limit reached (${limits.maxSuppliers}). Please upgrade.` });
        }
        
        const supp = await Supplier.create({ ...req.body, tenantId: req.user.tenantId });
        if(typeof logActivity === 'function') await logActivity(req, 'CREATE_SUPPLIER', `Added supplier: ${supp.name}`);
        res.status(201).json({ success: true, data: supp });
    } catch (e) {
        res.status(400).json({ success: false, message: e.message });
    }
};

exports.getSupplierById = async (req, res) => {
    try {
        const supp = await Supplier.findOne({ _id: req.params.id, tenantId: req.user.tenantId });
        if (!supp) return res.status(404).json({ success: false, message: "Not found" });
        res.json({ success: true, data: supp });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

exports.updateSupplier = async (req, res) => {
    try {
        const supp = await Supplier.findOneAndUpdate({ _id: req.params.id, tenantId: req.user.tenantId }, req.body, { new: true });
        res.json({ success: true, data: supp });
    } catch (e) {
        res.status(400).json({ success: false, message: e.message });
    }
};

exports.deleteSupplier = async (req, res) => {
    try {
        await Purchase.deleteMany({ supplierId: req.params.id, tenantId: req.user.tenantId });
        await SupplierPayment.deleteMany({ supplierId: req.params.id, tenantId: req.user.tenantId });
        await Supplier.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
        res.json({ success: true, message: "Supplier and all related ledgers deleted." });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

// --- PURCHASES (BILLS) --- //
exports.getPurchases = async (req, res) => {
    try {
        const { supplierId } = req.query;
        let query = { tenantId: req.user.tenantId };
        if (supplierId) query.supplierId = supplierId;
        const bills = await Purchase.find(query).populate('supplierId', 'name email phone').sort({ date: -1 });
        res.json({ success: true, data: bills });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

exports.createPurchase = async (req, res) => {
    try {
        const { supplierId, items } = req.body;
        const supplier = await Supplier.findById(supplierId);
        if (!supplier) return res.status(404).json({ success: false, message: "Supplier not found" });

        const bill = await Purchase.create({ ...req.body, tenantId: req.user.tenantId });
        await syncPurchaseStatus(bill.supplierId, req.user.tenantId);

        // --- SYNC INVENTORY ---
        if (items && Array.isArray(items)) {
            await syncInventoryForPurchase(req.user.tenantId, items, bill._id, supplier.name);
        }

        res.status(201).json({ success: true, data: bill });
    } catch (e) {
        res.status(400).json({ success: false, message: e.message });
    }
};

exports.deletePurchase = async (req, res) => {
    try {
        const billId = req.params.billId;
        const bill = await Purchase.findOneAndDelete({ _id: billId, tenantId: req.user.tenantId });
        
        if (bill) {
            await syncPurchaseStatus(bill.supplierId, req.user.tenantId);
            // --- SYNC INVENTORY: REVERT STOCK ---
            await revertInventoryForPurchase(req.user.tenantId, billId);
        }
        res.json({ success: true, message: "Deleted" });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

// --- PAYMENTS --- //
exports.getPayments = async (req, res) => {
    try {
        const { supplierId } = req.params;
        const payments = await SupplierPayment.find({ supplierId, tenantId: req.user.tenantId }).sort({ paymentDate: -1 });
        res.json({ success: true, data: payments });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};

exports.createPayment = async (req, res) => {
    try {
        const pay = await SupplierPayment.create({ ...req.body, supplierId: req.params.supplierId, tenantId: req.user.tenantId });
        await syncPurchaseStatus(req.params.supplierId, req.user.tenantId);
        res.status(201).json({ success: true, data: pay });
    } catch (e) {
        res.status(400).json({ success: false, message: e.message });
    }
};

exports.deletePayment = async (req, res) => {
    try {
        const pay = await SupplierPayment.findOneAndDelete({ _id: req.params.paymentId, tenantId: req.user.tenantId });
        if (pay) await syncPurchaseStatus(pay.supplierId, req.user.tenantId);
        res.json({ success: true, message: "Deleted" });
    } catch (e) {
        res.status(500).json({ success: false, message: e.message });
    }
};
