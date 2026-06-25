require('dotenv').config();
const mongoose = require('mongoose');
const Tenant = require('./src/models/Tenant');
const Invoice = require('./src/models/Invoice');
const Client = require('./src/models/Client');
const Inventory = require('./src/models/Inventory');
const Supplier = require('./src/models/Supplier');
const User = require('./src/models/User');

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected");
  const starters = await Tenant.countDocuments({ subscriptionPlan: 'basic' });
  const pros = await Tenant.countDocuments({ subscriptionPlan: 'premium' });
  const businesses = await Tenant.countDocuments({ subscriptionPlan: 'enterprise' });

  console.log("Starters:", starters, "Pros:", pros, "Businesses:", businesses);

  const tenantsUsingInventory = (await Inventory.distinct('tenantId')).length;
  const tenantsUsingSuppliers = (await Supplier.distinct('tenantId')).length;

  console.log("Inventory:", tenantsUsingInventory, "Suppliers:", tenantsUsingSuppliers);
  process.exit();
}
test();
