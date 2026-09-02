const User = require('../models/User');
const Tenant = require('../models/Tenant');
const Invoice = require('../models/Invoice');
const Client = require('../models/Client');
const Quotation = require('../models/Quotation');
const AuditLog = require('../models/AuditLog');
const Inventory = require('../models/Inventory');
const Supplier = require('../models/Supplier');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const logActivity = require('../utils/logger');
const crypto = require('crypto');

// ==========================================
// PUBLIC ROUTES (Register & Login & Reset Password)
// ==========================================

// @desc    Forgot Password
exports.forgotPassword = async (req, res) => {
  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'There is no user with that email' });
    }

    // Get reset token
    const resetToken = crypto.randomBytes(20).toString('hex');

    // Hash token and set to resetPasswordToken field
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    // Set expire
    user.resetPasswordExpire = Date.now() + 60 * 60 * 1000; // 1 hour

    await user.save({ validateBeforeSave: false });

    // Send email
    const baseUrl = 'https://app.aurivabms.in';
    const resetUrl = `${baseUrl}/reset-password?token=${resetToken}`;

    const { sendPasswordResetEmail } = require('../utils/emailService');
    const tenant = await Tenant.findById(user.tenantId);

    try {
      await sendPasswordResetEmail(user, resetUrl, tenant);
      res.status(200).json({ success: true, message: 'Password reset email sent' });
    } catch (err) {
      user.resetPasswordToken = undefined;
      user.resetPasswordExpire = undefined;
      await user.save({ validateBeforeSave: false });
      return res.status(500).json({ success: false, message: 'Email could not be sent' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Reset Password
exports.resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      return res.status(400).json({ success: false, message: 'Token and password are required' });
    }

    // Get hashed token
    const resetPasswordToken = crypto.createHash('sha256').update(token).digest('hex');

    const user = await User.findOne({
      resetPasswordToken,
      resetPasswordExpire: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired token' });
    }

    // Set new password
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(password, salt);

    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    res.status(200).json({ success: true, message: 'Password reset successful' });

    // Send Success Email (Fire and forget)
    try {
      const { sendPasswordResetSuccessEmail } = require('../utils/emailService');
      const tenant = await require('../models/Tenant').findById(user.tenantId);
      await sendPasswordResetSuccessEmail(user, tenant);
    } catch (emailErr) {
      console.error("Failed to send password reset success email:", emailErr);
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Register a new Tenant (Public Sign Up)
exports.registerTenant = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { companyName, slug, name, email, password } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) throw new Error('User with this email already exists');

    const slugExists = await Tenant.findOne({ slug });
    if (slugExists) throw new Error('Company slug is already taken');

    // Default Subscription: 1 Year from now
    const defaultExpiry = new Date();
    defaultExpiry.setFullYear(defaultExpiry.getFullYear() + 1);

    // Create Tenant with Defaults
    const tenant = await Tenant.create([{
      name: companyName,
      slug: slug,
      email: email,
      status: 'active',
      subscriptionPlan: 'basic',
      subscriptionEnd: defaultExpiry, // ✅ Added Default 1 Year
      templatePreference: 'standard',
      quotationTemplate: 'standard'
    }], { session });

    // Hash Password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create Admin User
    const user = await User.create([{
      tenantId: tenant[0]._id,
      name,
      email,
      passwordHash: hashedPassword,
      role: 'admin'
    }], { session });

    // LOG ACTIVITY
    await logActivity({
      user: { _id: user[0]._id, tenantId: tenant[0]._id },
      ip: req.ip
    }, "REGISTER_TENANT", `New Company Registered: ${companyName}`);

    // Send Welcome Email
    try {
      const { sendWelcomeWithPasswordEmail } = require('../utils/emailService');
      const baseUrl = 'https://app.aurivabms.in';
      const resetUrl = `${baseUrl}/forgot-password`;
      await sendWelcomeWithPasswordEmail(user[0], password, resetUrl, tenant[0]);
    } catch (err) {
      console.error("Failed to send welcome email:", err);
    }

    await session.commitTransaction();
    session.endSession();

    res.status(201).json({ success: true, message: 'Tenant registered successfully' });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Login User & Generate Token
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Find User
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    // 2. Check Password
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    // 3. Check Active Status (User Level)
    if (user.isActive === false) {
      return res.status(403).json({ success: false, message: 'Account deactivated' });
    }

    // 4. Check Tenant Status (Company Level)
    const tenant = await Tenant.findById(user.tenantId);
    if (tenant && tenant.status === 'suspended') {
      return res.status(403).json({ success: false, message: 'Your company account is suspended. Contact Support.' });
    }
    if (tenant && tenant.status === 'deleted') {
      return res.status(403).json({ success: false, message: 'Your account has been deleted. Please contact the AurivaBMS team to recover it.' });
    }

    // ==========================================
    // 🔴 NEW ADDITION: Check Plan Expiry Date
    // ==========================================
    let expiryWarning = false;
    let daysLeft = null;

    if (tenant && tenant.subscriptionEnd) {
      const currentDate = new Date();
      const expiryDate = new Date(tenant.subscriptionEnd);

      const diffTime = expiryDate - currentDate;
      daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (expiryDate < currentDate) {
        return res.status(403).json({
          success: false,
          message: "Your subscription plan has expired. Please renew your plan to continue using the services.",
          isPlanExpired: true // Flag for frontend to trigger specific UI
        });
      }

      // If 5 or fewer days left, set warning
      if (daysLeft <= 5) {
        expiryWarning = true;
      }
    }

    // 5. Generate Token
    if (!process.env.JWT_SECRET) throw new Error("JWT_SECRET is missing in .env");

    const payload = {
      id: user._id.toString(),
      tenantId: user.tenantId.toString(),
      role: user.role
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '30d' });

    // LOG ACTIVITY
    req.user = user;
    await logActivity(req, "LOGIN", `${user.name} logged in successfully`);


    // 6. Send Response
    res.status(200).json({
      success: true,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        signatureImage: user.signatureImage,
        tenantId: user.tenantId,
        hasCompletedTour: user.hasCompletedTour
      },
      subscription: {
        plan: tenant?.subscriptionPlan || 'basic',
        daysLeft,
        expiryWarning,
        expiryDate: tenant?.subscriptionEnd
      }
    });

  } catch (error) {
    console.error("Login Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==========================================
// TENANT SETTINGS (For Business Owners)
// ==========================================

// @desc    Get Current Tenant Settings
exports.getTenantSettings = async (req, res) => {
  try {
    const tenant = await Tenant.findById(req.user.tenantId);
    res.status(200).json({ success: true, data: tenant });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update Tenant Settings (RESTRICTED)
exports.updateTenantSettings = async (req, res) => {
  try {
    const {
      name, gstEnabled, gstNumber, state, address, phone, email, website,
      signatureImage, logoImage,
      bankDetails,
      defaultTerms
    } = req.body;

    // Tenants CANNOT update subscription details or templates here
    const tenant = await Tenant.findByIdAndUpdate(
      req.user.tenantId,
      {
        name, gstEnabled, gstNumber, state, address, phone, email, website,
        signatureImage, logoImage,
        bankDetails,
        defaultTerms
      },
      { new: true, runValidators: true }
    );

    await logActivity(req, "UPDATE_SETTINGS", "Business settings updated");

    res.status(200).json({ success: true, data: tenant, message: "Settings updated" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==========================================
// SUPER ADMIN ROUTES (Platform Control)
// ==========================================

// @desc    Get All Tenants
exports.getAllTenants = async (req, res) => {
  try {
    const tenants = await Tenant.find({ slug: { $ne: 'super-admin-system' } }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: tenants });
  } catch (error) {
    console.error("Fetch Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Create Tenant Manually (Super Admin)
exports.createTenantByAdmin = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { companyName, slug, name, email, password, plan, subscriptionEnd, templatePreference, quotationTemplate } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) throw new Error('User email already exists');

    const slugExists = await Tenant.findOne({ slug });
    if (slugExists) throw new Error('Slug already taken');

    // Calculate Default Expiry if not provided (1 Year)
    let expiryDate = subscriptionEnd ? new Date(subscriptionEnd) : new Date();
    if (!subscriptionEnd) expiryDate.setFullYear(expiryDate.getFullYear() + 1);

    // Create Tenant
    const tenant = await Tenant.create([{
      name: companyName,
      slug,
      email,
      subscriptionPlan: plan || 'basic',
      subscriptionEnd: expiryDate, // ✅ Set Expiry
      status: 'active',
      templatePreference: templatePreference || 'standard',
      quotationTemplate: quotationTemplate || 'standard'
    }], { session });

    // Create Admin User
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = await User.create([{
      tenantId: tenant[0]._id,
      name,
      email,
      passwordHash: hashedPassword,
      role: 'admin'
    }], { session });

    await logActivity(req, "ADMIN_CREATE_COMPANY", `Super Admin created company: ${companyName}`);

    // Send Welcome Email
    try {
      const { sendWelcomeWithPasswordEmail } = require('../utils/emailService');
      const baseUrl = 'https://app.aurivabms.in';
      const resetUrl = `${baseUrl}/forgot-password`;
      await sendWelcomeWithPasswordEmail(user[0], password, resetUrl, tenant[0]);
    } catch (err) {
      console.error("Failed to send welcome email:", err);
    }

    await session.commitTransaction();
    session.endSession();

    res.status(201).json({ success: true, message: 'Company created successfully' });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Update Tenant By Super Admin (Includes Subscription & Templates)
exports.updateTenantBySuperAdmin = async (req, res) => {
  try {
    const {
      name, email, phone, address, website,
      gstEnabled, gstNumber, state,
      status,
      subscriptionPlan,
      subscriptionEnd,
      templatePreference,
      quotationTemplate
    } = req.body;

    const updateData = {
      name, email, phone, address, website,
      gstEnabled, gstNumber, state,
      status,
      subscriptionPlan,
      templatePreference,
      quotationTemplate
    };

    // Only update date if provided
    if (subscriptionEnd) {
      updateData.subscriptionEnd = new Date(subscriptionEnd);
    }

    // Fetch old tenant to check if status changed
    const oldTenant = await Tenant.findById(req.params.id);
    if (!oldTenant) return res.status(404).json({ success: false, message: "Tenant not found" });

    const tenant = await Tenant.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    // If status changed, send email
    if (status && oldTenant.status !== status) {
      try {
        const user = await User.findOne({ tenantId: tenant._id, role: 'admin' });
        if (user) {
          const { sendAccountStatusChangeEmail } = require('../utils/emailService');
          await sendAccountStatusChangeEmail(user, tenant, status);
        }
      } catch (emailErr) {
        console.error("Failed to send status change email:", emailErr);
      }
    }

    await logActivity(req, "ADMIN_UPDATE_COMPANY", `Updated settings for ${tenant.name}`);

    res.status(200).json({ success: true, data: tenant, message: "Tenant Updated Successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Reset Tenant Admin Password (Super Admin)
exports.resetAdminPassword = async (req, res) => {
  try {
    const { password } = req.body;
    const { id } = req.params; // Tenant ID

    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, message: "Password must be at least 6 characters" });
    }

    // 1. Find the admin user for this tenant
    const user = await User.findOne({ tenantId: id, role: 'admin' });
    if (!user) return res.status(404).json({ success: false, message: "Admin user not found for this company" });

    // 2. Hash and Save
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(password, salt);
    await user.save();

    await logActivity(req, "ADMIN_RESET_PASSWORD", `Super Admin reset password for ${user.email}`);

    res.status(200).json({ success: true, message: "Password reset successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};


// @desc    Delete Tenant & All Data
exports.deleteTenant = async (req, res) => {
  try {
    const { id } = req.params;

    const tenant = await Tenant.findById(id);
    if (!tenant) return res.status(404).json({ success: false, message: "Tenant not found" });

    // Protect Super Admin
    if (tenant.slug === 'super-admin-system') {
      return res.status(403).json({ success: false, message: "Super Admin system cannot be deleted" });
    }

    await Tenant.findByIdAndDelete(id);

    // Cascade Delete
    await User.deleteMany({ tenantId: id });
    await Invoice.deleteMany({ tenantId: id });
    await Client.deleteMany({ tenantId: id });
    await Quotation.deleteMany({ tenantId: id });

    await logActivity(req, "ADMIN_DELETE_COMPANY", `Deleted company: ${tenant.name} and all data`);

    res.status(200).json({ success: true, message: `Deleted ${tenant.name} and all associated data.` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get System Stats (Updated Revenue Logic)
exports.getSystemStats = async (req, res) => {
  try {
    const totalTenants = await Tenant.countDocuments();
    const activeTenants = await Tenant.countDocuments({ status: 'active' });
    const totalUsers = await User.countDocuments();

    // Calculate Estimated Revenue (INR Logic)
    // Freelancer: 199, Pro: 299, Business: 599
    const starters = await Tenant.countDocuments({ subscriptionPlan: 'basic' }); // 'basic' is used for Freelancer
    const pros = await Tenant.countDocuments({ subscriptionPlan: 'premium' }); // 'premium' is used for Pro
    const businesses = await Tenant.countDocuments({ subscriptionPlan: 'enterprise' }); // 'enterprise' is used for Business

    const estRevenue = (starters * 199) + (pros * 299) + (businesses * 599); // ✅ Updated Formula with new prices

    // --- NEW: PLATFORM KPIs ---
    const platformInvoicesCount = await Invoice.countDocuments();
    const platformClientsCount = await Client.countDocuments();

    // Calculate Platform GMV (Gross Merchandise Value)
    const gmvAggr = await Invoice.aggregate([
      { $group: { _id: null, totalGMV: { $sum: "$totalAmount" } } }
    ]);
    const platformGMV = gmvAggr.length > 0 ? gmvAggr[0].totalGMV : 0;

    // --- NEW: FEATURE ADOPTION ---
    const tenantsUsingInventory = (await Inventory.distinct('tenantId')).length;
    const tenantsUsingSuppliers = (await Supplier.distinct('tenantId')).length;

    // Aggregate Historical Data for the last 6 months
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
    sixMonthsAgo.setDate(1); // start of the month

    const tenantsAggr = await Tenant.aggregate([
      { $match: { createdAt: { $gte: sixMonthsAgo } } },
      {
        $group: {
          _id: { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } },
          count: { $sum: 1 },
          starters: { $sum: { $cond: [{ $eq: ["$subscriptionPlan", "basic"] }, 1, 0] } },
          pros: { $sum: { $cond: [{ $eq: ["$subscriptionPlan", "premium"] }, 1, 0] } },
          businesses: { $sum: { $cond: [{ $eq: ["$subscriptionPlan", "enterprise"] }, 1, 0] } }
        }
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } }
    ]);

    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const growthData = tenantsAggr.map(item => ({
      month: `${monthNames[item._id.month - 1]} ${item._id.year}`,
      newTenants: item.count,
      mrr: (item.starters * 199) + (item.pros * 299) + (item.businesses * 599)
    }));

    res.status(200).json({
      success: true,
      data: {
        totalTenants,
        activeTenants,
        suspendedTenants: totalTenants - activeTenants,
        totalUsers,
        estRevenue,
        growthData,
        // New data for dashboard
        planDistribution: [
          { name: 'Freelancer', value: starters },
          { name: 'Pro', value: pros },
          { name: 'Business', value: businesses }
        ],
        platformInvoicesCount,
        platformClientsCount,
        platformGMV,
        featureAdoption: [
          { name: 'Inventory', users: tenantsUsingInventory },
          { name: 'Suppliers', users: tenantsUsingSuppliers }
        ]
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc Get System Activity Logs
exports.getAuditLogs = async (req, res) => {
  try {
    const logs = await AuditLog.find()
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('tenantId', 'name')
      .populate('userId', 'name email');

    res.status(200).json({ success: true, data: logs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get Usage Stats
exports.getTenantUsage = async (req, res) => {
  try {
    const { id } = req.params;

    const [
      invoiceCount,
      quotationCount,
      clientCount,
      userCount,
      paidInvoices,
      inventoryCount,
      supplierCount
    ] = await Promise.all([
      Invoice.countDocuments({ tenantId: id }),
      Quotation.countDocuments({ tenantId: id }),
      Client.countDocuments({ tenantId: id }),
      User.countDocuments({ tenantId: id }),
      Invoice.countDocuments({ tenantId: id, status: 'Paid' }),
      Inventory.countDocuments({ tenantId: id }),
      Supplier.countDocuments({ tenantId: id })
    ]);

    const successRate = invoiceCount > 0 ? Math.round((paidInvoices / invoiceCount) * 100) : 0;

    res.status(200).json({
      success: true,
      data: {
        invoiceCount,
        quotationCount,
        clientCount,
        userCount,
        successRate,
        inventoryCount,
        supplierCount
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==========================================
// ACCOUNT DELETION (TENANT OWNER)
// ==========================================

// @desc    Request Account Deletion (Sends OTP)
exports.requestAccountDeletion = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only account administrators can request deletion' });
    }

    const tenant = await Tenant.findById(user.tenantId);
    if (!tenant) return res.status(404).json({ success: false, message: 'Tenant not found' });

    // Generate 6-digit OTP
    const crypto = require('crypto');
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash OTP
    user.deletionOtp = crypto.createHash('sha256').update(otp).digest('hex');
    user.deletionOtpExpire = Date.now() + 15 * 60 * 1000; // 15 mins
    await user.save({ validateBeforeSave: false });

    // Send Email
    const { sendDeletionOtpEmail } = require('../utils/emailService');
    await sendDeletionOtpEmail(user, otp, tenant);

    res.status(200).json({ success: true, message: 'OTP sent to your email' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Confirm Account Deletion (Verify OTP & Soft Delete)
exports.confirmAccountDeletion = async (req, res) => {
  try {
    const { otp } = req.body;
    if (!otp) {
      return res.status(400).json({ success: false, message: 'OTP is required' });
    }

    const user = await User.findById(req.user.id);
    if (!user || user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only account administrators can confirm deletion' });
    }

    // Verify OTP
    const crypto = require('crypto');
    const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');

    if (user.deletionOtp !== hashedOtp || user.deletionOtpExpire < Date.now()) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    const tenant = await Tenant.findById(user.tenantId);
    if (!tenant) return res.status(404).json({ success: false, message: 'Tenant not found' });

    // Protect Super Admin
    if (tenant.slug === 'super-admin-system') {
      return res.status(403).json({ success: false, message: "Super Admin system cannot be deleted" });
    }

    // Perform Soft Delete
    tenant.status = 'deleted';
    await tenant.save();

    // Clear OTP
    user.deletionOtp = undefined;
    user.deletionOtpExpire = undefined;
    await user.save({ validateBeforeSave: false });

    // Send Deletion Confirmation Email
    const { sendAccountDeletionConfirmationEmail } = require('../utils/emailService');
    try {
      await sendAccountDeletionConfirmationEmail(user, tenant);
    } catch (err) {
      console.error("Failed to send account deletion confirmation email:", err);
    }

    res.status(200).json({ success: true, message: 'Your account has been successfully deleted.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};