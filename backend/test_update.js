const mongoose = require('mongoose');
require('dotenv').config();
const Tenant = require('./src/models/Tenant');

async function testUpdate() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    const tenant = await Tenant.findOne();
    console.log("Found tenant:", tenant.name, tenant._id);
    
    // Simulate what the controller does
    const updated = await Tenant.findByIdAndUpdate(
      tenant._id,
      { subscriptionPlan: 'pro' },
      { new: true, runValidators: true }
    );
    console.log("Success:", updated.subscriptionPlan);
  } catch (e) {
    console.error("Error updating:", e.message);
  } finally {
    mongoose.disconnect();
  }
}

testUpdate();
