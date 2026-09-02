const BlockedIP = require('../models/BlockedIP');

const ipBlocker = async (req, res, next) => {
  try {
    // Get client IP address
    const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress || req.ip;
    
    // Convert IPv6-mapped IPv4 to standard IPv4 if needed
    const cleanIp = clientIp.includes('::ffff:') ? clientIp.split('::ffff:')[1] : clientIp;

    // Fast check (you could implement Redis caching here for extreme performance)
    const blocked = await BlockedIP.findOne({ ipAddress: cleanIp }).lean();

    if (blocked) {
      return res.status(403).json({
        success: false,
        message: `Your IP (${cleanIp}) has been blocked by the administrator. Reason: ${blocked.reason}`
      });
    }

    next();
  } catch (error) {
    console.error('IP Blocker Error:', error);
    next(); // Fail-open: if DB check fails, let request through rather than taking down the whole app
  }
};

module.exports = ipBlocker;
