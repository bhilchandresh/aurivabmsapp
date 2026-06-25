const axios = require('axios');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY;

/**
 * Send Push Notification using OneSignal REST API
 * @param {Array<String>} playerIds - Array of OneSignal device tokens
 * @param {String} title - Notification Title
 * @param {String} message - Notification Body
 * @param {Object} data - Additional metadata/deep-link info
 */
exports.sendPushNotification = async (playerIds, title, message, data = {}) => {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.warn("OneSignal credentials missing. Skipping push notification.");
    return false;
  }

  if (!playerIds || playerIds.length === 0) {
    return false;
  }

  try {
    const payload = {
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: playerIds,
      headings: { en: title },
      contents: { en: message },
      data: data
    };

    const response = await axios.post('https://onesignal.com/api/v1/notifications', payload, {
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`
      }
    });

    console.log("OneSignal push sent:", response.data);
    return true;
  } catch (error) {
    console.error("OneSignal Error:", error.response?.data || error.message);
    return false;
  }
};
