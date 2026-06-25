const Inventory = require('../models/Inventory');
const InventoryTransaction = require('../models/InventoryTransaction');
const Tenant = require('../models/Tenant');
const checkSubscription = require('../middleware/checkSubscription');
const logActivity = require('../utils/logger');

const getPlanLimits = (planName) => {
    return checkSubscription.PLANS[planName] || checkSubscription.PLANS['basic'];
};

exports.getItems = async (req, res) => {
  try {
    const items = await Inventory.find({ tenantId: req.user.tenantId }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: items.length, data: items });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createItem = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.user.tenantId);
    if (!tenant) return res.status(404).json({ success: false, message: "Tenant not found" });

    // Enforce limits
    const limits = getPlanLimits(tenant.subscriptionPlan);
    if (limits.maxInventory === 0) {
        return res.status(403).json({ success: false, message: "Inventory is not available on your current plan. Please upgrade to Pro or Business." });
    }

    const currentCount = await Inventory.countDocuments({ tenantId: req.user.tenantId });
    if (currentCount >= limits.maxInventory) {
        return res.status(403).json({ success: false, message: `Inventory limit reached (${limits.maxInventory}). Please upgrade your plan.` });
    }

    const newItem = await Inventory.create({
      ...req.body,
      tenantId: req.user.tenantId
    });

    if (newItem.currentStock > 0) {
      await InventoryTransaction.create({
        tenantId: req.user.tenantId,
        inventoryId: newItem._id,
        type: 'Adjustment',
        quantity: newItem.currentStock,
        description: 'Initial Stock',
        date: Date.now()
      });
    }

    if (typeof logActivity === 'function') await logActivity(req, "CREATE_INVENTORY", `Added item: ${req.body.itemName}`);
    
    res.status(201).json({ success: true, data: newItem });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateItem = async (req, res) => {
  try {
    // We omit tenantId updates because it is tied to account
    const { itemName, sku, description, unitPrice, currentStock, status, transactionDescription } = req.body;
    
    const oldItem = await Inventory.findOne({ _id: req.params.id, tenantId: req.user.tenantId });

    const item = await Inventory.findOneAndUpdate(
      { _id: req.params.id, tenantId: req.user.tenantId },
      { itemName, sku, description, unitPrice, currentStock, status },
      { new: true, runValidators: true }
    );
    
    if (!item) return res.status(404).json({ success: false, message: "Item not found" });
    
    // Handle manual stock adjustment tracking
    if (oldItem && currentStock !== undefined && Number(oldItem.currentStock) !== Number(currentStock)) {
      const difference = Number(currentStock) - Number(oldItem.currentStock);
      await InventoryTransaction.create({
        tenantId: req.user.tenantId,
        inventoryId: item._id,
        type: difference > 0 ? (transactionDescription ? 'Purchase' : 'Adjustment') : 'Adjustment',
        quantity: difference,
        description: transactionDescription || 'Manual Stock Adjustment',
        date: Date.now()
      });
    }

    if (typeof logActivity === 'function') await logActivity(req, "UPDATE_INVENTORY", `Updated item: ${item.itemName}`);
    
    res.status(200).json({ success: true, data: item });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteItem = async (req, res) => {
  try {
    const item = await Inventory.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!item) return res.status(404).json({ success: false, message: "Item not found" });
    
    if (typeof logActivity === 'function') await logActivity(req, "DELETE_INVENTORY", `Deleted item: ${item.itemName}`);
    
    res.status(200).json({ success: true, message: "Item deleted successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getItemTransactions = async (req, res) => {
  try {
    const transactions = await InventoryTransaction.find({
      tenantId: req.user.tenantId,
      inventoryId: req.params.id
    }).sort({ date: -1 });

    res.status(200).json({ success: true, count: transactions.length, data: transactions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.bulkImportInventory = async (req, res) => {
  try {
    const itemsData = req.body;
    if (!Array.isArray(itemsData)) {
      return res.status(400).json({ success: false, message: "Data must be an array" });
    }

    const tenantId = req.user.tenantId;
    const tenant = await Tenant.findById(tenantId);
    if (!tenant) return res.status(404).json({ success: false, message: "Tenant not found" });

    const limits = getPlanLimits(tenant.subscriptionPlan);
    if (limits.maxInventory === 0) {
        return res.status(403).json({ success: false, message: "Inventory is not available on your current plan." });
    }

    let importedCount = 0;
    let skippedCount = 0;
    let currentCount = await Inventory.countDocuments({ tenantId });

    for (const item of itemsData) {
      if (!item.itemName) {
        skippedCount++;
        continue;
      }
      
      if (currentCount >= limits.maxInventory) {
        break; // Stop importing if limit reached
      }

      // Check for exact sku match or name match to avoid duplicates
      let existing = null;
      if (item.sku && item.sku.trim() !== '') {
        existing = await Inventory.findOne({ sku: item.sku, tenantId });
      } else {
        existing = await Inventory.findOne({ itemName: item.itemName, tenantId });
      }

      if (existing) {
        skippedCount++;
        continue;
      }

      const newItem = await Inventory.create({
        tenantId,
        itemName: item.itemName,
        sku: item.sku || '',
        description: item.description || '',
        unitPrice: Number(item.unitPrice) || 0,
        currentStock: Number(item.currentStock) || 0,
        status: item.status || 'In Stock'
      });
      importedCount++;
      currentCount++;

      if (newItem.currentStock > 0) {
        await InventoryTransaction.create({
          tenantId,
          inventoryId: newItem._id,
          type: 'Adjustment',
          quantity: newItem.currentStock,
          description: 'Initial Stock (Bulk Import)',
          date: Date.now()
        });
      }
    }

    if (typeof logActivity === 'function') {
      await logActivity(req, "BULK_IMPORT", `Imported ${importedCount} inventory items`);
    }

    res.status(200).json({ 
      success: true, 
      message: `Import complete. Added ${importedCount} items. Skipped ${skippedCount} duplicates/invalid.` 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

