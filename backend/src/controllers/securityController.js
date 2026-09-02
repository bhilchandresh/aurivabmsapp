const BlockedIP = require('../models/BlockedIP');
const { getActiveTraffic } = require('../middleware/trafficMonitor');

// @desc    Get all active IP traffic
// @route   GET /api/v1/security/active-traffic
// @access  Private/SuperAdmin
exports.getActiveTrafficController = async (req, res) => {
  try {
    const traffic = getActiveTraffic();
    res.status(200).json({
      success: true,
      data: traffic
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get all blocked IPs
// @route   GET /api/v1/security/blocked-ips
// @access  Private/SuperAdmin
exports.getBlockedIPs = async (req, res) => {
  try {
    const blockedIPs = await BlockedIP.find().sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      data: blockedIPs
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Block an IP Address
// @route   POST /api/v1/security/block-ip
// @access  Private/SuperAdmin
exports.blockIP = async (req, res) => {
  try {
    const { ipAddress, reason } = req.body;

    if (!ipAddress) {
      return res.status(400).json({ success: false, message: 'IP Address is required' });
    }

    // Convert IPv6-mapped IPv4 to standard IPv4 if needed
    const cleanIp = ipAddress.includes('::ffff:') ? ipAddress.split('::ffff:')[1] : ipAddress;

    let blockedIP = await BlockedIP.findOne({ ipAddress: cleanIp });

    if (blockedIP) {
      return res.status(400).json({ success: false, message: 'IP is already blocked' });
    }

    blockedIP = await BlockedIP.create({
      ipAddress: cleanIp,
      reason: reason || 'Blocked by Admin via SOC',
      blockedBy: req.user._id,
      autoBlocked: false
    });

    res.status(201).json({
      success: true,
      data: blockedIP,
      message: `IP ${cleanIp} has been successfully blocked.`
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Unblock an IP Address
// @route   DELETE /api/v1/security/unblock-ip/:ip
// @access  Private/SuperAdmin
exports.unblockIP = async (req, res) => {
  try {
    // Decoding just in case the IP is passed in URL like %3A
    const ipAddress = decodeURIComponent(req.params.ip);

    const blockedIP = await BlockedIP.findOneAndDelete({ ipAddress });

    if (!blockedIP) {
      return res.status(404).json({ success: false, message: 'IP not found in blocked list' });
    }

    res.status(200).json({
      success: true,
      message: `IP ${ipAddress} has been successfully unblocked.`
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
