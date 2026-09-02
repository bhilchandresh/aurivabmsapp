const Client = require('../models/Client');
const Invoice = require('../models/Invoice');

/**
 * Handles incoming webhooks from Transactional Email Providers (e.g. Resend, SendGrid)
 * POST /api/webhooks/email
 */
exports.handleEmailWebhook = async (req, res) => {
  try {
    // Note: This is a generalized parser. 
    // Depending on whether SendGrid or Resend is chosen, the payload structure might vary slightly.
    // Usually, they send an array of events or a single event object.
    
    const events = Array.isArray(req.body) ? req.body : [req.body];
    console.log(`Received ${events.length} webhook event(s)`);

    for (const event of events) {
      // Extract the email address and event type
      // (Resend uses event.type, SendGrid uses event.event)
      const email = event.email || (event.data && event.data.to ? event.data.to[0] : null);
      const eventType = event.event || event.type;

      if (!email || !eventType) continue;

      const isBounce = ['bounce', 'dropped', 'bounced', 'spamreport', 'email.bounced'].includes(eventType.toLowerCase());
      const isDelivered = ['delivered', 'email.delivered'].includes(eventType.toLowerCase());

      if (isBounce) {
        console.log(`[Webhook] Bounce detected for email: ${email}`);
        
        // 1. Mark all clients with this email as bounced
        await Client.updateMany(
          { email: email },
          { $set: { emailDeliveryStatus: 'bounced' } }
        );

        // 2. Mark pending invoices sent to this client as bounced
        await Invoice.updateMany(
          { 'client.email': email, emailDeliveryStatus: 'sent' },
          { $set: { emailDeliveryStatus: 'bounced' } }
        );

      } else if (isDelivered) {
        console.log(`[Webhook] Delivery confirmed for email: ${email}`);
        
        // Mark client email as valid
        await Client.updateMany(
          { email: email, emailDeliveryStatus: { $ne: 'bounced' } },
          { $set: { emailDeliveryStatus: 'valid' } }
        );

        // Mark invoice email as delivered
        await Invoice.updateMany(
          { 'client.email': email, emailDeliveryStatus: 'sent' },
          { $set: { emailDeliveryStatus: 'delivered' } }
        );
      }
    }

    // Always respond with 200 OK so the ESP doesn't retry
    res.status(200).send('Webhook processed');
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).send('Webhook processing failed');
  }
};
