const SystemSettings = require('../models/SystemSettings');
const { refreshTransporter } = require('../utils/emailService');

// @desc    Get all system settings
// @route   GET /api/settings
// @access  Private/SuperAdmin
exports.getSettings = async (req, res) => {
  try {
    const settings = await SystemSettings.find();
    // Convert array of objects to a key-value object
    const settingsObj = {};
    settings.forEach(s => {
      settingsObj[s.key] = s.value;
    });

    res.status(200).json({ success: true, data: settingsObj });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update system settings
// @route   PUT /api/settings
// @access  Private/SuperAdmin
exports.updateSettings = async (req, res) => {
  try {
    const updates = req.body; // Expect an object of key-value pairs
    
    for (const [key, value] of Object.entries(updates)) {
      await SystemSettings.findOneAndUpdate(
        { key },
        { value },
        { upsert: true, new: true }
      );
    }
    
    // Check if SMTP settings were updated
    if (updates.SMTP_HOST || updates.SMTP_PORT || updates.SMTP_USER || updates.SMTP_PASS) {
      await refreshTransporter();
    }

    res.status(200).json({ success: true, message: 'Settings updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
