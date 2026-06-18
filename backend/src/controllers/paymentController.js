const Razorpay = require('razorpay');
const crypto = require('crypto');
const Tenant = require('../models/Tenant');
const Notification = require('../models/Notification');

let razorpay;

if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
  });
} else {
  console.warn("WARNING: Razorpay keys are missing in .env file. Payments will not work.");
}

// @desc    Create Razorpay Order
// @route   POST /api/v1/payments/create-order
// @access  Private/Admin
exports.createOrder = async (req, res) => {
  try {
    if (!razorpay) {
      return res.status(500).json({ success: false, message: 'Razorpay is not configured on the server. Please contact support.' });
    }
    const { plan } = req.body;
    
    // Define amounts for plans (in paise)
    const planAmounts = {
      'basic': 29900,      // ₹299
      'premium': 49900,    // ₹499
      'enterprise': 99900   // ₹999
    };

    const amount = planAmounts[plan];
    if (!amount) {
      return res.status(400).json({ success: false, message: 'Invalid plan selected' });
    }

    const options = {
      amount: amount,
      currency: "INR",
      receipt: `receipt_plan_${plan}_${Date.now()}`,
    };

    const order = await razorpay.orders.create(options);

    res.status(200).json({
      success: true,
      data: order
    });
  } catch (error) {
    console.error("Razorpay Order Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Verify Razorpay Payment
// @route   POST /api/v1/payments/verify
// @access  Private/Admin
exports.verifyPayment = async (req, res) => {
  try {
    const { 
      razorpay_order_id, 
      razorpay_payment_id, 
      razorpay_signature,
      plan
    } = req.body;

    const body = razorpay_order_id + "|" + razorpay_payment_id;

    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest("hex");

    const isAuthentic = expectedSignature === razorpay_signature;

    if (isAuthentic) {
      // Update Tenant Subscription
      const tenant = await Tenant.findById(req.user.tenantId);
      if (!tenant) {
        return res.status(404).json({ success: false, message: 'Tenant not found' });
      }

      // Add 1 year to current subscription end or today if already expired
      const currentEnd = new Date(tenant.subscriptionEnd);
      const today = new Date();
      const startDate = currentEnd > today ? currentEnd : today;
      
      const newEndDate = new Date(startDate);
      newEndDate.setFullYear(newEndDate.getFullYear() + 1);

      tenant.subscriptionEnd = newEndDate;
      tenant.subscriptionPlan = plan;
      tenant.status = 'active';
      await tenant.save();

      // Create a success notification
      await Notification.create({
        message: `Subscription renewed successfully for ${plan} plan until ${newEndDate.toLocaleDateString()}.`,
        type: 'success',
        target: 'specific_tenant',
        tenantId: req.user.tenantId,
        isSystemGenerated: true
      });

      res.status(200).json({
        success: true,
        message: 'Payment verified and subscription updated'
      });
    } else {
      res.status(400).json({ success: false, message: 'Invalid signature' });
    }
  } catch (error) {
    console.error("Razorpay Verification Error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
