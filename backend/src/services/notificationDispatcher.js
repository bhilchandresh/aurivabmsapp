const Notification = require('../models/Notification');
const User = require('../models/User');
const Tenant = require('../models/Tenant');
const { sendPushNotification } = require('./oneSignalService');

/**
 * Dispatch an internal notification (In-App DB + OneSignal Push)
 * @param {Object} options
 * @param {String} options.tenantId
 * @param {String} options.type
 * @param {String} options.message
 * @param {String} options.actionLink (optional)
 * @param {Object} options.metadata (optional)
 * @param {String} options.preferenceKey (The key in tenant.notificationPreferences to check)
 */
exports.dispatchNotification = async ({ tenantId, type, message, actionLink, metadata, preferenceKey }) => {
  try {
    const tenant = await Tenant.findById(tenantId);
    if (!tenant) return false;

    // 1. Check if the tenant has disabled this notification
    if (preferenceKey && tenant.notificationPreferences && tenant.notificationPreferences[preferenceKey] === false) {
      return false; // User opted out of this specific notification
    }

    // 2. Save In-App Notification to DB
    const notification = await Notification.create({
      message,
      type,
      target: 'specific_tenant',
      tenantId,
      actionLink,
      metadata,
      isSystemGenerated: true
    });

    // 3. Find all users in this tenant to send Push Notifications
    const users = await User.find({ tenantId, isActive: true });
    let playerIds = [];
    
    users.forEach(user => {
      if (user.deviceTokens && user.deviceTokens.length > 0) {
        user.deviceTokens.forEach(dt => playerIds.push(dt.token));
      }
    });

    // 4. Dispatch to OneSignal
    if (playerIds.length > 0) {
      // Don't await the push so it doesn't block the API response
      sendPushNotification(playerIds, "AurivaBMS Alert", message, {
        notificationId: notification._id,
        ...metadata
      }).catch(err => console.error("Push dispatcher error:", err));
    }

    return notification;
  } catch (error) {
    console.error("dispatchNotification Error:", error);
    return false;
  }
};
