const Notification = require('../models/Notification');
const User = require('../models/User');

// @desc    Get notifications for the logged-in user
// @route   GET /api/v1/notifications
// @access  Private
exports.getNotifications = async (req, res) => {
  try {
    const { role, tenantId, _id: userId } = req.user;

    let query = {};

    if (role === 'super_admin') {
      // Superadmins see everything or maybe just system ones? 
      // For now, let's say they see all broadcasted ones.
      query = { target: 'all_admins' };
    } else if (role === 'admin') {
      // Admins see broadcasts + their specific tenant notifications
      query = {
        $or: [
          { target: 'all_admins' },
          { target: 'specific_tenant', tenantId: tenantId }
        ]
      };
    } else {
      // Regular users only see specific tenant notifications (if allowed)
      query = { target: 'specific_tenant', tenantId: tenantId };
    }

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(50);

    // Mark which ones are read by this specific user
    const formattedNotifications = notifications.map(notif => ({
      ...notif._doc,
      isRead: notif.readBy.includes(userId)
    }));

    res.status(200).json({
      success: true,
      data: formattedNotifications
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Create a broadcast notification (Super Admin only)
// @route   POST /api/v1/notifications
// @access  Private/SuperAdmin
exports.createNotification = async (req, res) => {
  try {
    const { message, type, target, tenantId, actionLink } = req.body;

    const notification = await Notification.create({
      message,
      type,
      target,
      tenantId,
      actionLink,
      isSystemGenerated: false
    });

    res.status(201).json({
      success: true,
      data: notification
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Mark notification as read
// @route   PUT /api/v1/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    if (!notification.readBy.includes(req.user._id)) {
      notification.readBy.push(req.user._id);
      await notification.save();
    }

    res.status(200).json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
