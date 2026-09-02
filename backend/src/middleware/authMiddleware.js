const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Tenant = require('../models/Tenant'); // 🔴 NEW: Tenant model import kiya for plan checking

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // 1. Extract Token
      token = req.headers.authorization.split(' ')[1];

      // 2. DEFENSIVE FIX: Remove quotes if frontend sent them (e.g., "ey...")
      // Ye React/LocalStorage se aane wali common galti ko theek karta hai
      if (token && token.startsWith('"') && token.endsWith('"')) {
        token = token.slice(1, -1);
      }

      // 3. Verify Token
      if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is missing in .env file');
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // 4. Find User (Using 'id' from token payload)
      // Note: Hum '-passwordHash' karte hain taaki password memory me na aaye
      req.user = await User.findById(decoded.id).select('-passwordHash');

      if (!req.user) {
        return res.status(401).json({ success: false, message: 'User not found or deleted' });
      }

      // ==========================================
      // 🔴 NEW ADDITION: Check Plan Expiry Date
      // ==========================================
      if (req.user.tenantId) {
        const tenant = await Tenant.findById(req.user.tenantId);

        if (tenant) {
          // Block if account is deleted
          if (tenant.status === 'deleted') {
            return res.status(401).json({
              success: false,
              message: "Your account has been deleted. Please contact support to restore it."
            });
          }

          if (tenant.subscriptionEnd) {
            const currentDate = new Date();
            const expiryDate = new Date(tenant.subscriptionEnd);

          if (expiryDate < currentDate) {
            return res.status(403).json({
              success: false,
              message: "Your subscription plan has expired. Please renew your plan to continue using the services.",
              isPlanExpired: true // 👈 Flag for frontend to trigger auto-logout
            });
          }
        }
        }
      }

      // User & Plan dono valid hain, aage badho
      next();

    } catch (error) {
      console.error("Auth Middleware Error:", error.message);

      // Token Expired ya Malformed hone par 401 return karein
      return res.status(401).json({
        success: false,
        message: 'Not authorized, invalid token',
        error: error.message
      });
    }
  } else {
    // Agar Header hi nahi hai
    return res.status(401).json({ success: false, message: 'Not authorized, no token provided' });
  }
};

// Roles Check Middleware
const authorize = (...roles) => {
  return (req, res, next) => {
    // Agar user ka role allowed roles me nahi hai
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access Denied: User role '${req.user.role}' is not authorized to access this route.`
      });
    }
    next();
  };
};

module.exports = { protect, authorize };