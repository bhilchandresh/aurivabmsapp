const AuditLog = require('../models/AuditLog');

const logActivity = async (req, action, details) => {
  try {
    // If req is just a plain object (manual log), handle it safely
    const tenantId = req.user?.tenantId || req.body?.tenantId || null;
    const userId = req.user?._id || null;
    const ip = req.ip || (req.connection && req.connection.remoteAddress) || 'Unknown';

    await AuditLog.create({
      action,
      details,
      tenantId,
      userId,
      ip
    });
  } catch (error) {
    // We log the error to console but don't crash the app if logging fails
    console.error("Logging Failed:", error.message);
  }
};

module.exports = logActivity;
