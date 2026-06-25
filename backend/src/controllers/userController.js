const User = require('../models/User');
const Tenant = require('../models/Tenant');
const bcrypt = require('bcryptjs');
const checkSubscription = require('../middleware/checkSubscription');

const getPlanLimits = (planName) => {
  return checkSubscription.PLANS[planName] || checkSubscription.PLANS['basic'];
};

// @desc    Get all users for the current Tenant
exports.getTeamMembers = async (req, res) => {
  try {
    const users = await User.find({ tenantId: req.user.tenantId, role: { $ne: 'super_admin' } })
      .select('-passwordHash')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Add a new Team Member
exports.addTeamMember = async (req, res) => {
  try {
    const { name, email, password, role, signatureImage } = req.body;

    // 1. PLAN LIMIT CHECK (req.tenant populated by checkSubscription middleware)
    const tenant = req.tenant;
    if (tenant) {
      const limits = getPlanLimits(tenant.subscriptionPlan);
      const currentCount = await User.countDocuments({ tenantId: req.user.tenantId });
      if (currentCount >= limits.maxUsers) {
        const planName = tenant.subscriptionPlan === 'basic' ? 'Starter' : tenant.subscriptionPlan === 'premium' ? 'Pro' : 'Business';
        return res.status(403).json({
          success: false,
          message: `Team member limit reached for the ${planName} plan (max ${limits.maxUsers} users). Please upgrade your plan.`
        });
      }
    }

    // 2. Check Global Uniqueness
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ success: false, message: 'User with this email already exists' });
    }

    // 3. SECURITY: Determine the Role
    let userRole = 'user';
    if (req.user.role === 'super_admin' && role) {
      userRole = role;
    } 
    else if (req.user.role === 'admin' && role) {
       if (role === 'super_admin') {
         return res.status(403).json({ success: false, message: "You cannot create a Super Admin" });
       }
       userRole = role;
    }

    // 4. Hash Password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // 5. Create User
    const user = await User.create({
      tenantId: req.user.tenantId,
      name,
      email,
      passwordHash,
      role: userRole,
      signatureImage: signatureImage || null
    });

    res.status(201).json({ 
      success: true, 
      data: { _id: user._id, name: user.name, email: user.email, role: user.role } 
    });

  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Remove a Team Member
exports.deleteTeamMember = async (req, res) => {
  try {
    if (req.params.id === req.user._id.toString()) {
      return res.status(400).json({ success: false, message: "You cannot delete your own account" });
    }

    const targetUser = await User.findById(req.params.id);
    if (!targetUser) return res.status(404).json({ success: false, message: "User not found" });

    if (targetUser.role === 'super_admin') {
      return res.status(403).json({ success: false, message: "Super Admin cannot be deleted" });
    }

    const user = await User.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    
    res.status(200).json({ success: true, message: "User removed" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update a User (Signature, Role, or Profile)
exports.updateTeamMember = async (req, res) => {
  try {
    const { signatureImage, role, name, email } = req.body; 

    // Build update object dynamically
    let updateData = {};
    if (name) updateData.name = name;
    if (email) updateData.email = email;
    if (signatureImage !== undefined) updateData.signatureImage = signatureImage; // ✅ Base64 handle करेगा

    // Only Allow Role Updates if Requester has permission
    if (role) {
        if (req.user.role === 'super_admin') {
            updateData.role = role;
        } else if (req.user.role === 'admin' && role !== 'super_admin') {
            updateData.role = role;
        }
    }

    const user = await User.findOneAndUpdate(
      { _id: req.params.id, tenantId: req.user.tenantId },
      updateData,
      { new: true, runValidators: true }
    ).select('-passwordHash');

    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    res.status(200).json({ success: true, data: user, message: "Profile updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Register a Device Token for Push Notifications
// @route   POST /api/v1/users/register-device
exports.registerDevice = async (req, res) => {
  try {
    const { token, platform } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: "Device token is required" });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // Check if token already exists to avoid duplicates
    const tokenExists = user.deviceTokens.find(dt => dt.token === token);
    
    if (!tokenExists) {
      user.deviceTokens.push({ token, platform: platform || 'android' });
      await user.save();
    }

    res.status(200).json({ success: true, message: "Device registered for push notifications" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};