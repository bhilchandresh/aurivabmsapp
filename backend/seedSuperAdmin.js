const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./src/models/User');
const Tenant = require('./src/models/Tenant');
require('dotenv').config();

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to DB...");

    // 1. Create a "System" Tenant for You (The Platform Owner)
    // This tenant holds the Super Admin user
    let masterTenant = await Tenant.findOne({ slug: 'super-admin-system' });
    
    if (!masterTenant) {
      masterTenant = await Tenant.create({
        name: 'Platform HQ',
        slug: 'super-admin-system',
        status: 'active',
        invoiceTemplateId: 'template_standard'
      });
      console.log('Master Tenant Created');
    }

    // 2. Create Your Super Admin User
    const email = 'Riva@auriva.in'; // <--- CHANGE THIS TO YOUR EMAIL
    const password = 'Riva@CEO'; // <--- CHANGE THIS

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log('Super Admin user already exists');
      process.exit();
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    await User.create({
      tenantId: masterTenant._id,
      name: 'Super Admin',
      email,
      passwordHash,
      role: 'super_admin'
    });

    console.log(`Super Admin Created! \nLogin: ${email} \nPassword: ${password}`);
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

seed();