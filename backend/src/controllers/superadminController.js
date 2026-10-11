const Subscription = require('../models/Subscription');
const Transaction = require('../models/Transaction');
const Coupon = require('../models/Coupon');
const ContactMessage = require('../models/ContactMessage');
const Tenant = require('../models/Tenant');

// @desc    Get all subscriptions
// @route   GET /api/v1/superadmin/subscriptions
// @access  Private/SuperAdmin
exports.getSubscriptions = async (req, res, next) => {
  try {
    const subscriptions = await Subscription.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: subscriptions });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all transactions
// @route   GET /api/v1/superadmin/transactions
// @access  Private/SuperAdmin
exports.getTransactions = async (req, res, next) => {
  try {
    const transactions = await Transaction.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: transactions });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all coupons
// @route   GET /api/v1/superadmin/coupons
// @access  Private/SuperAdmin
exports.getCoupons = async (req, res, next) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: coupons });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a coupon
// @route   POST /api/v1/superadmin/coupons
// @access  Private/SuperAdmin
exports.createCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.create(req.body);
    res.status(201).json({ success: true, data: coupon });
  } catch (error) {
    next(error);
  }
};

// @desc    Update a coupon
// @route   PUT /api/v1/superadmin/coupons/:id
// @access  Private/SuperAdmin
exports.updateCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    res.status(200).json({ success: true, data: coupon });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a coupon
// @route   DELETE /api/v1/superadmin/coupons/:id
// @access  Private/SuperAdmin
exports.deleteCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    res.status(200).json({ success: true, data: {} });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all contact messages
// @route   GET /api/v1/superadmin/messages
// @access  Private/SuperAdmin
exports.getMessages = async (req, res, next) => {
  try {
    const messages = await ContactMessage.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: messages });
  } catch (error) {
    next(error);
  }
};

// @desc    Update message status
// @route   PUT /api/v1/superadmin/messages/:id
// @access  Private/SuperAdmin
exports.updateMessageStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const message = await ContactMessage.findByIdAndUpdate(req.params.id, { status }, {
      new: true,
      runValidators: true
    });
    if (!message) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }
    res.status(200).json({ success: true, data: message });
  } catch (error) {
    next(error);
  }
};

// @desc    Assign or renew a plan manually
// @route   POST /api/v1/superadmin/assign-plan
// @access  Private/SuperAdmin
exports.assignPlan = async (req, res, next) => {
  try {
    const { email, name, phone, company, planName, planType, amountPaid = 0 } = req.body;
    
    if (!email || !planName || !planType) {
      return res.status(400).json({ success: false, message: 'Email, planName, and planType are required.' });
    }

    const expiryDateObj = new Date();
    if (planType === 'Yearly') {
      expiryDateObj.setFullYear(expiryDateObj.getFullYear() + 1);
    } else if (planType === 'Trial') {
      expiryDateObj.setDate(expiryDateObj.getDate() + 14);
    } else {
      expiryDateObj.setMonth(expiryDateObj.getMonth() + 1);
    }

    // 1. Update Landing Page Subscription Model
    const subscription = await Subscription.findOneAndUpdate(
      { email },
      {
        email,
        phone: phone || '',
        company: company || '',
        name: name || '',
        planName,
        planType,
        expiryDate: expiryDateObj,
        status: 'active'
      },
      { upsert: true, new: true }
    );

    // 2. Create Internal Transaction
    await Transaction.create({
      razorpay_order_id: `internal_${Date.now()}`,
      razorpay_payment_id: `admin_assigned_${Date.now()}`,
      amount: amountPaid,
      email,
      planName,
      planType,
      status: 'completed'
    });

    // 3. Update SaaS Tenant if exists
    // SaaS limits are checked based on Tenant model
    const tenant = await Tenant.findOne({ email: email.toLowerCase() });
    if (tenant) {
      tenant.subscriptionPlan = planName.toLowerCase().includes('business') ? 'business' : 
                                planName.toLowerCase().includes('pro') ? 'pro' : 'freelance';
      tenant.subscriptionEnd = expiryDateObj;
      tenant.status = 'active';
      await tenant.save();
    }

    res.status(200).json({ success: true, message: 'Plan assigned successfully', data: subscription });
  } catch (error) {
    next(error);
  }
};
