const nodemailer = require('nodemailer');

let transporter;

const refreshTransporter = async () => {
  try {
    const SystemSettings = require('../models/SystemSettings');
    const settings = await SystemSettings.find();
    const config = {};
    settings.forEach(s => config[s.key] = s.value);

    transporter = nodemailer.createTransport({
      host: config.SMTP_HOST || process.env.EMAIL_HOST || 'smtp.hostinger.com',
      port: config.SMTP_PORT || process.env.EMAIL_PORT || 465,
      secure: true, // true for 465, false for other ports
      auth: {
        user: config.SMTP_USER || process.env.EMAIL_USER,
        pass: config.SMTP_PASS || process.env.EMAIL_PASS
      }
    });
    console.log("Email Transporter Initialized with Dynamic Settings");
  } catch (err) {
    console.error("Failed to initialize transporter", err);
  }
};

// Initialize on boot
refreshTransporter();

/**
 * Premium HTML Template for Invoices (White-Labeled)
 */
const getInvoiceEmailTemplate = (invoice, tenant = null) => {
  const formattedAmount = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR'
  }).format(invoice.totalAmount);

  const businessName = tenant ? tenant.name : "Business Manager";
  const businessAddress = tenant ? tenant.address : "";
  const businessPhone = tenant ? tenant.phone : "";
  const businessEmail = tenant ? tenant.email : "";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 0; background-color: #f8fafc; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); }
        .header { background: #1e293b; padding: 50px 40px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.025em; }
        .header p { margin: 5px 0 0; opacity: 0.8; font-weight: 500; font-size: 14px; }
        .logo { max-width: 150px; margin-bottom: 20px; }
        .content { padding: 40px; }
        .greeting { font-size: 18px; font-weight: 700; margin-bottom: 24px; color: #0f172a; }
        .invoice-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 32px; margin: 32px 0; text-align: center; }
        .amount-label { font-size: 13px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 8px; }
        .amount-value { font-size: 42px; font-weight: 900; color: #1e293b; margin-bottom: 24px; }
        .details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; text-align: left; border-top: 1px solid #e2e8f0; padding-top: 24px; }
        .detail-item .label { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; margin-bottom: 4px; }
        .detail-item .value { font-size: 14px; font-weight: 700; color: #334155; }
        .button { display: inline-block; background: #0f172a; color: white !important; text-decoration: none; padding: 16px 32px; border-radius: 12px; font-weight: 700; font-size: 15px; margin-top: 32px; transition: all 0.2s; }
        .footer { padding: 40px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; background: #ffffff; }
        .footer b { color: #475569; display: block; margin-bottom: 5px; }
        @media (max-width: 600px) {
          .container { margin: 0; border-radius: 0; }
          .header { padding: 40px 20px; }
          .content { padding: 30px 20px; }
          .details-grid { grid-template-columns: 1fr; gap: 15px; }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          ${businessLogo ? `<img src="${businessLogo}" alt="${businessName}" class="logo">` : ''}
          <h1>New Invoice</h1>
          <p>${businessName}</p>
        </div>
        <div class="content">
          <div class="greeting">Dear ${invoice.client.name},</div>
          <p>Please find the details of your new invoice from <strong>${businessName}</strong> below. You can securely view and download your full invoice online.</p>
          
          <div class="invoice-card">
            <div class="amount-label">Amount Due</div>
            <div class="amount-value">${formattedAmount}</div>
            
            <div class="details-grid">
              <div class="detail-item">
                <div class="label">Invoice Number</div>
                <div class="value">${invoice.invoiceNumber}</div>
              </div>
              <div class="detail-item">
                <div class="label">Due Date</div>
                <div class="value">${new Date(invoice.dueDate || invoice.date).toLocaleDateString('en-IN')}</div>
              </div>
            </div>
          </div>
          
          <div style="text-align: center;">
            <a href="https://app.aurivabms.in/public/invoice/${invoice._id}" class="button">View Online</a>
          </div>
        </div>
        <div class="footer">
          <b>${businessName}</b>
          ${businessAddress ? `${businessAddress}<br>` : ''}
          ${businessPhone ? `Phone: ${businessPhone}  ` : ''}${businessEmail ? `| Email: ${businessEmail}` : ''}
          <p style="margin-top: 20px; font-size: 10px; opacity: 0.6;">&copy; ${new Date().getFullYear()} ${businessName}. Professional Document Delivery.</p>
        </div>
      </div>
    </body>
    </html>
  `;
};

/**
 * Payment Confirmation Template (White-Labeled)
 */
const getPaymentEmailTemplate = (invoice, amountPaid, tenant = null) => {
  const formattedPaid = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amountPaid);
  const formattedBalance = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(invoice.remainingAmount || 0);
  const businessName = tenant ? tenant.name : "Billing Manager";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 0; background-color: #f8fafc; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        .header { background: #0f172a; padding: 40px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
        .logo { max-width: 120px; margin-bottom: 20px; }
        .content { padding: 40px; }
        .payment-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 25px; margin: 25px 0; }
        .row { display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 14px; }
        .row .label { color: #64748b; font-weight: 600; }
        .row .value { color: #0f172a; font-weight: 700; }
        .total-row { border-top: 1px solid #e2e8f0; margin-top: 15px; padding-top: 15px; }
        .paid-amount { color: #10b981 !important; font-size: 18px; }
        .footer { padding: 30px; text-align: center; font-size: 12px; color: #94a3b8; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          ${businessLogo ? `<img src="${businessLogo}" alt="${businessName}" class="logo">` : ''}
          <h1>Payment Received</h1>
        </div>
        <div class="content">
          <p>Hi <strong>${invoice.client.name}</strong>,</p>
          <p>We've successfully received a payment for invoice <strong>#${invoice.invoiceNumber}</strong> from <strong>${businessName}</strong>. Thank you!</p>
          
          <div class="payment-box">
            <div class="row">
              <span class="label">Invoice Number</span>
              <span class="value">${invoice.invoiceNumber}</span>
            </div>
            <div class="row">
              <span class="label">Amount Received</span>
              <span class="value paid-amount">${formattedPaid}</span>
            </div>
            <div class="total-row row">
              <span class="label">Remaining Balance</span>
              <span class="value">${formattedBalance}</span>
            </div>
          </div>
          
          <div style="text-align: center; margin-top: 30px;">
            <a href="https://app.aurivabms.in/public/invoice/${invoice._id}" 
               style="background: #0f172a; color: white; text-decoration: none; padding: 12px 24px; border-radius: 10px; font-weight: 700; font-size: 14px;">
               View Updated Invoice
            </a>
          </div>
        </div>
        <div class="footer">
          Regards, <b>${businessName}</b>
        </div>
      </div>
    </body>
    </html>
  `;
};

/**
 * Client Account Summary Template (Premium Visual Style)
 */
const getAccountSummaryTemplate = (client, stats, lastInvoice, tenant = null) => {
  const businessName = tenant ? tenant.name : "Billing Manager";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;

  const formattedBilled = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(stats.billed);
  const formattedPaid = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(stats.paid);
  const formattedBalance = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(Math.abs(stats.balance));

  const balanceLabel = stats.balance > 0 ? "Outstanding Due" : stats.balance < 0 ? "Advance Amount" : "Account Settled";
  const balanceColor = stats.balance > 0 ? "#e11d48" : stats.balance < 0 ? "#2563eb" : "#059669";
  const balanceBg = stats.balance > 0 ? "#fff1f2" : stats.balance < 0 ? "#eff6ff" : "#f0fdf4";

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 0; background-color: #f8fafc; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        .header { background: #0f172a; padding: 40px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
        .logo { max-width: 120px; margin-bottom: 20px; }
        .content { padding: 40px; }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 30px 0; }
        .stat-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 20px; text-align: center; }
        .stat-label { font-size: 11px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 5px; }
        .stat-value { font-size: 20px; font-weight: 800; color: #1e293b; }
        .balance-hero { background: ${balanceBg}; border: 1px solid ${balanceColor}20; border-radius: 16px; padding: 30px; text-align: center; margin-bottom: 30px; }
        .balance-hero .stat-label { color: ${balanceColor}; opacity: 0.8; }
        .balance-hero .stat-value { font-size: 32px; color: ${balanceColor}; }
        .invoice-section { border-top: 1px solid #f1f5f9; padding-top: 30px; }
        .invoice-section h2 { font-size: 14px; font-weight: 800; color: #475569; text-transform: uppercase; margin-bottom: 20px; letter-spacing: 0.05em; }
        .invoice-row { display: flex; justify-content: space-between; align-items: center; background: #fafafa; padding: 15px 20px; rounded: 12px; margin-bottom: 10px; border-radius: 12px; }
        .inv-info { font-size: 14px; font-weight: 700; color: #1e293b; }
        .inv-date { font-size: 12px; color: #94a3b8; display: block; font-weight: 500; }
        .inv-amount { font-size: 14px; font-weight: 800; color: #1e293b; }
        .footer { padding: 40px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; }
        @media (max-width: 600px) {
          .stats-grid { grid-template-columns: 1fr; }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          ${businessLogo ? `<img src="${businessLogo}" alt="${businessName}" class="logo">` : ''}
          <h1>Account Summary</h1>
          <p style="margin: 5px 0 0; opacity: 0.7; font-size: 13px;">Overview of your transactions with ${businessName}</p>
        </div>
        <div class="content">
          <p>Hi <strong>${client.name}</strong>,</p>
          <p>Here is your current financial standing in our records as of today.</p>
          
          <div class="balance-hero">
            <div class="stat-label">${balanceLabel}</div>
            <div class="stat-value">${formattedBalance}</div>
          </div>

          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-label">Total Billed</div>
              <div class="stat-value">${formattedBilled}</div>
            </div>
            <div class="stat-card">
              <div class="stat-label">Total Paid</div>
              <div class="stat-value">${formattedPaid}</div>
            </div>
          </div>

          ${lastInvoice ? `
            <div class="invoice-section">
              <h2>Last Invoice Details</h2>
              <div class="invoice-row">
                <div>
                  <span class="inv-info">#${lastInvoice.invoiceNumber}</span>
                  <span class="inv-date">${new Date(lastInvoice.date).toLocaleDateString('en-IN')}</span>
                </div>
                <div style="text-align: right;">
                  <div class="inv-amount">${new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(lastInvoice.totalAmount)}</div>
                  <a href="${process.env.FRONTEND_URL || 'http://localhost:5173'}/public/invoice/${lastInvoice._id}" style="display: inline-block; margin-top: 8px; font-size: 11px; font-weight: 700; color: #2563eb; text-decoration: none; border: 1px solid #bfdbfe; background: #eff6ff; padding: 4px 10px; border-radius: 6px;">View Invoice ↗</a>
                </div>
              </div>
            </div>
          ` : ''}

          <p style="margin-top: 40px; font-size: 14px; color: #64748b; text-align: center;">If you have any questions regarding your account status, please reach out to us.</p>
        </div>
        <div class="footer">
          Regards, <b>${businessName}</b>
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendInvoiceEmail = async (invoice, pdfBuffer = null, tenant = null) => {
  if (!invoice.client || !invoice.client.email) {
    console.log(`Skipping email: No email for client ${invoice.client.name}`);
    return;
  }

  try {
    const businessName = tenant ? tenant.name : "Billing Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: invoice.client.email,
      subject: `Invoice #${invoice.invoiceNumber} from ${businessName}`,
      html: getInvoiceEmailTemplate(invoice, tenant)
    };

    // Removed PDF Attachment as per requirement

    const info = await transporter.sendMail(mailOptions);
    console.log(`Invoice Email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error('Email Error:', error);
    throw error;
  }
};

exports.sendPaymentEmail = async (invoice, amountPaid, tenant = null) => {
  if (!invoice.client || !invoice.client.email) return;

  try {
    const businessName = tenant ? tenant.name : "Billing Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: invoice.client.email,
      subject: `Payment Received: Invoice #${invoice.invoiceNumber}`,
      html: getPaymentEmailTemplate(invoice, amountPaid, tenant)
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`Payment Email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error('Payment Email Error:', error);
  }
};

exports.sendAccountSummaryEmail = async (client, stats, lastInvoice, tenant = null) => {
  if (!client.email) return;

  try {
    const businessName = tenant ? tenant.name : "Billing Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: client.email,
      subject: `Account Summary from ${businessName}`,
      html: getAccountSummaryTemplate(client, stats, lastInvoice, tenant)
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`Account Summary Email sent: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error('Account Summary Email Error:', error);
    throw error;
  }
};

/**
 * Generic Client Communication Template
 */
const getClientEmailTemplate = (client, subject, message, tenant = null) => {
  const businessName = tenant ? tenant.name : "Billing Center";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 0; background-color: #f8fafc; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        .header { background: #0f172a; padding: 40px; text-align: center; color: white; }
        .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
        .logo { max-width: 120px; margin-bottom: 20px; }
        .content { padding: 40px; }
        .message-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 25px; margin: 25px 0; color: #334155; font-size: 15px; }
        .footer { padding: 30px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          ${businessLogo ? `<img src="${businessLogo}" alt="${businessName}" class="logo">` : ''}
          <h1>${subject || 'Important Message'}</h1>
        </div>
        <div class="content">
          <p>Hi <strong>${client.name}</strong>,</p>
          <div class="message-box">
            ${message}
          </div>
          <p style="margin-top: 20px; font-size: 14px; color: #64748b; text-align: center;">If you have any questions, please reply directly to this email.</p>
        </div>
        <div class="footer">
          Regards, <b>${businessName}</b>
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendClientEmail = async (client, subject, message) => {
  if (!client.email) throw new Error("Client has no email address");

  try {
    const mailOptions = {
      from: `"Billing Center" <${process.env.EMAIL_USER}>`,
      to: client.email,
      subject: subject || `Message for ${client.name}`,
      html: getClientEmailTemplate(client, subject, message)
    };

    const info = await transporter.sendMail(mailOptions);
    return info;
  } catch (error) {
    console.error('Client Email Error:', error);
    throw error;
  }
};

exports.refreshTransporter = refreshTransporter;

const getWelcomeEmailTemplate = (user, rawPassword, tenant = null, resetUrl) => {
  const businessName = tenant ? tenant.name : "System Manager";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;
  const loginUrl = 'https://app.aurivabms.in/login';

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; background-color: #f8fafc; margin: 0; padding: 0; }
        .wrapper { padding: 40px 20px; display: flex; justify-content: center; }
        .login-panel { background: white; max-width: 420px; width: 100%; border-radius: 16px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1); overflow: hidden; margin: 0 auto; border: 1px solid #e2e8f0; }
        .panel-header { background: #0f172a; padding: 30px 20px; text-align: center; color: white; }
        .panel-header h2 { margin: 0; font-size: 20px; font-weight: 700; }
        .logo { max-width: 120px; margin-bottom: 15px; }
        .panel-body { padding: 30px; }
        .greeting { font-size: 16px; color: #1e293b; margin-bottom: 20px; text-align: center; }
        .form-group { margin-bottom: 20px; }
        .label { display: block; font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.05em; }
        .input-box { background: #f1f5f9; padding: 14px; border-radius: 10px; font-size: 15px; color: #0f172a; font-weight: 600; border: 1px solid #e2e8f0; }
        .password-box { letter-spacing: 1px; }
        .login-btn { display: block; width: 100%; background: #2563eb; color: white !important; text-align: center; padding: 14px; border-radius: 10px; text-decoration: none; font-weight: 700; font-size: 15px; margin-top: 10px; box-sizing: border-box; }
        .reset-link-container { text-align: center; margin-top: 20px; border-top: 1px solid #e2e8f0; padding-top: 20px; }
        .reset-link { color: #ef4444; font-size: 13px; font-weight: 600; text-decoration: none; }
      </style>
    </head>
    <body>
      <div class="wrapper">
        <div class="login-panel">
          <div class="panel-header">
            ${businessLogo ? `<img src="${businessLogo}" alt="${businessName}" class="logo">` : ''}
            <h2>Welcome to ${businessName}</h2>
          </div>
          <div class="panel-body">
            <div class="greeting">Hi <strong>${user.name}</strong>, your account has been created. Here are your login details:</div>
            
            <div class="form-group">
              <label class="label">Email ID (Username)</label>
              <div class="input-box">${user.email}</div>
            </div>
            
            <div class="form-group">
              <label class="label">Password</label>
              <div class="input-box password-box">${rawPassword}</div>
            </div>
            
            <a href="${loginUrl}" class="login-btn">Log In to Your Account</a>
            
            <div class="reset-link-container">
              <a href="${resetUrl}" class="reset-link">Want to change your password? Reset it here</a>
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
};

const getPasswordResetTemplate = (user, resetUrl, tenant = null) => {
  const businessName = tenant ? tenant.name : "AURIVA BMS";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; margin: 0; padding: 0; }
        .wrapper { padding: 40px 20px; display: flex; justify-content: center; }
        .container { max-width: 550px; width: 100%; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; margin: 0 auto; }
        
        .header { 
          background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%); 
          padding: 40px 30px; 
          text-align: center; 
          color: white; 
        }
        .logo { max-width: 140px; margin-bottom: 20px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.1)); }
        .header h2 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em; }
        .header p { margin: 8px 0 0; opacity: 0.9; font-size: 14px; font-weight: 500; }
        
        .content { padding: 40px 30px; text-align: center; }
        .icon-box { 
          width: 64px; height: 64px; 
          background: #eff6ff; 
          border-radius: 50%; 
          display: flex; align-items: center; justify-content: center; 
          margin: 0 auto 20px; 
        }
        
        .greeting { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 15px; }
        .text { color: #475569; font-size: 15px; line-height: 1.6; margin-bottom: 30px; }
        
        .btn { 
          display: inline-block; 
          background: #2563eb; 
          color: white !important; 
          padding: 16px 36px; 
          border-radius: 12px; 
          text-decoration: none; 
          font-weight: 700; 
          font-size: 16px; 
          box-shadow: 0 4px 14px 0 rgba(37, 99, 235, 0.39);
          transition: all 0.2s;
        }
        
        .footer { 
          background: #f8fafc; 
          padding: 25px 30px; 
          text-align: center; 
          border-top: 1px solid #e2e8f0; 
        }
        .muted { color: #64748b; font-size: 12px; line-height: 1.5; margin: 0; }
        .brand { font-weight: 700; color: #1e293b; font-size: 13px; margin-top: 10px; }
      </style>
    </head>
    <body>
      <div class="wrapper">
        <div class="container">
          <div class="header">
            ${businessLogo
      ? `<img src="${businessLogo}" alt="${businessName}" class="logo">`
      : `<div style="font-size: 28px; font-weight: 900; letter-spacing: -1px; margin-bottom: 10px;">${businessName}</div>`
    }
            <h2>Secure Password Reset</h2>
            <p>Account Security Verification</p>
          </div>
          
          <div class="content">
            <div class="icon-box">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
              </svg>
            </div>
            
            <div class="greeting">Hi ${user.name},</div>
            <p class="text">We received a request to reset the password for your account associated with <strong>${businessName}</strong>. This password reset link is valid for the next 1 hour.</p>
            
            <a href="${resetUrl}" class="btn">Reset My Password</a>
          </div>
          
          <div class="footer">
            <p class="muted">If you did not request a password reset, no further action is required and your password will remain unchanged. Please ensure your account is secure.</p>
            <div class="brand">Powered by AURIVA BMS</div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendWelcomeWithPasswordEmail = async (user, rawPassword, resetUrl, tenant = null) => {
  if (!user.email) return;
  try {
    const businessName = tenant ? tenant.name : "System Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `Welcome to ${businessName} - Your Account Details`,
      html: getWelcomeEmailTemplate(user, rawPassword, tenant, resetUrl)
    };
    const info = await transporter.sendMail(mailOptions);
    return info;
  } catch (error) {
    console.error('Welcome Email Error:', error);
  }
};

exports.sendPasswordResetEmail = async (user, resetUrl, tenant = null) => {
  if (!user.email) return;
  try {
    const businessName = tenant ? tenant.name : "System Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `Password Reset Request - ${businessName}`,
      html: getPasswordResetTemplate(user, resetUrl, tenant)
    };
    const info = await transporter.sendMail(mailOptions);
    return info;
  } catch (error) {
    console.error('Password Reset Email Error:', error);
  }
};

const getPasswordResetSuccessTemplate = (user, tenant = null) => {
  const businessName = tenant ? tenant.name : "AURIVA BMS";
  const businessLogo = tenant && tenant.logoImage ? tenant.logoImage : null;
  const loginUrl = 'https://app.aurivabms.in/login';

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; margin: 0; padding: 0; }
        .wrapper { padding: 40px 20px; display: flex; justify-content: center; }
        .container { max-width: 550px; width: 100%; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; margin: 0 auto; }
        
        .header { 
          background: linear-gradient(135deg, #10b981 0%, #059669 100%); 
          padding: 40px 30px; 
          text-align: center; 
          color: white; 
        }
        .logo { max-width: 140px; margin-bottom: 20px; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.1)); }
        .header h2 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: -0.025em; }
        .header p { margin: 8px 0 0; opacity: 0.9; font-size: 14px; font-weight: 500; }
        
        .content { padding: 40px 30px; text-align: center; }
        .icon-box { 
          width: 64px; height: 64px; 
          background: #ecfdf5; 
          border-radius: 50%; 
          display: flex; align-items: center; justify-content: center; 
          margin: 0 auto 20px; 
        }
        
        .greeting { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 15px; }
        .text { color: #475569; font-size: 15px; line-height: 1.6; margin-bottom: 30px; }
        
        .btn { 
          display: inline-block; 
          background: #10b981; 
          color: white !important; 
          padding: 16px 36px; 
          border-radius: 12px; 
          text-decoration: none; 
          font-weight: 700; 
          font-size: 16px; 
          box-shadow: 0 4px 14px 0 rgba(16, 185, 129, 0.39);
          transition: all 0.2s;
        }
        
        .footer { 
          background: #f8fafc; 
          padding: 25px 30px; 
          text-align: center; 
          border-top: 1px solid #e2e8f0; 
        }
        .muted { color: #64748b; font-size: 12px; line-height: 1.5; margin: 0; }
        .brand { font-weight: 700; color: #1e293b; font-size: 13px; margin-top: 10px; }
      </style>
    </head>
    <body>
      <div class="wrapper">
        <div class="container">
          <div class="header">
            ${businessLogo
      ? `<img src="${businessLogo}" alt="${businessName}" class="logo">`
      : `<div style="font-size: 28px; font-weight: 900; letter-spacing: -1px; margin-bottom: 10px;">${businessName}</div>`
    }
            <h2>Password Updated</h2>
            <p>Your account is secure</p>
          </div>
          
          <div class="content">
            <div class="icon-box">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
              </svg>
            </div>
            
            <div class="greeting">Hi ${user.name},</div>
            <p class="text">The password for your account associated with <strong>${businessName}</strong> has been successfully reset. You can now log in using your new password.</p>
            
            <a href="${loginUrl}" class="btn">Go to Login</a>
          </div>
          
          <div class="footer">
            <p class="muted">If you did not make this change, please contact your administrator immediately.</p>
            <div class="brand">Powered by AURIVABMS</div>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendPasswordResetSuccessEmail = async (user, tenant = null) => {
  if (!user.email) return;
  try {
    const businessName = tenant ? tenant.name : "System Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `Password Reset Successful - ${businessName}`,
      html: getPasswordResetSuccessTemplate(user, tenant)
    };
    const info = await transporter.sendMail(mailOptions);
    return info;
  } catch (error) {
    console.error('Password Reset Success Email Error:', error);
  }
};

const getSystemBroadcastTemplate = (user, subject, message) => {
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; margin: 0; padding: 0; background-color: #f8fafc; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 24px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); border: 1px solid #e2e8f0; }
        .header { background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%); padding: 40px 30px; text-align: center; color: white; }
        .logo-text { font-size: 28px; font-weight: 900; letter-spacing: -1px; margin-bottom: 15px; }
        .header h1 { margin: 0; font-size: 22px; font-weight: 800; }
        .content { padding: 40px; }
        .greeting { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 20px; }
        .message-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 25px; margin: 25px 0; color: #334155; font-size: 15px; }
        .footer { padding: 30px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #f1f5f9; background: #ffffff; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo-text">AURIVA BMS</div>
          <h1>${subject}</h1>
        </div>
        <div class="content">
          <div class="greeting">Hello ${user.name},</div>
          <p>We have an important update for you:</p>
          <div class="message-box">
            ${message}
          </div>
          <p style="margin-top: 30px; font-size: 14px; color: #64748b; text-align: center;">Thank you for being a valued part of our platform.</p>
        </div>
        <div class="footer">
          Regards, <b>AurivaBMS Team</b>
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendSystemBroadcastEmail = async (users, subject, message) => {
  if (!users || users.length === 0) return;
  try {
    const promises = users.map(user => {
      if (!user.email) return Promise.resolve();
      const mailOptions = {
        from: `"AurivaBMS Team" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: subject || `Important System Update`,
        html: getSystemBroadcastTemplate(user, subject, message)
      };
      return transporter.sendMail(mailOptions);
    });
    
    const results = await Promise.allSettled(promises);
    console.log('Broadcast Emails sent. Success Count:', results.filter(r => r.status === 'fulfilled').length);
    return results;
  } catch (error) {
    console.error('Broadcast Email Error:', error);
  }
};

/**
 * Account Deletion OTP Email Template
 */
const getDeletionOtpTemplate = (user, otp, tenant) => {
  const businessName = tenant ? tenant.name : "Your Business";
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; background-color: #f8fafc; margin: 0; padding: 20px; }
        .container { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); text-align: center; }
        .logo-text { font-size: 20px; font-weight: 800; color: #dc2626; letter-spacing: 2px; margin-bottom: 20px; }
        h2 { color: #dc2626; font-size: 22px; margin-top: 0; }
        p { font-size: 15px; color: #475569; margin-bottom: 20px; }
        .otp-box { background: #fef2f2; border: 1px dashed #f87171; border-radius: 12px; padding: 20px; margin: 30px 0; }
        .otp-code { font-size: 32px; font-weight: 900; color: #b91c1c; letter-spacing: 5px; }
        .warning { font-size: 12px; color: #64748b; background: #f1f5f9; padding: 15px; border-radius: 8px; text-align: left; margin-top: 30px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo-text">ACCOUNT DELETION</div>
        <h2>Verification Code</h2>
        <p>Hi ${user.name},</p>
        <p>We received a request to permanently delete the account and all associated data for <strong>${businessName}</strong>.</p>
        <div class="otp-box">
          <div style="font-size: 12px; color: #ef4444; text-transform: uppercase; font-weight: 700; margin-bottom: 10px;">Your 6-Digit OTP</div>
          <div class="otp-code">${otp}</div>
        </div>
        <p>This code is valid for <strong>15 minutes</strong>. If you did not request this, please ignore this email and change your password immediately.</p>
        
        <div class="warning">
          <strong>Warning:</strong> Deleting your account will immediately revoke your access to the system. While your data is soft-deleted to prevent accidental loss, you will not be able to log in or use any services.
        </div>
      </div>
    </body>
    </html>
  `;
};

exports.sendDeletionOtpEmail = async (user, otp, tenant) => {
  if (!user || !user.email) return;
  try {
    const mailOptions = {
      from: `"AurivaBMS Security" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `[URGENT] Account Deletion OTP - ${tenant.name}`,
      html: getDeletionOtpTemplate(user, otp, tenant)
    };
    await transporter.sendMail(mailOptions);
    console.log(`Account Deletion OTP sent to ${user.email}`);
  } catch (error) {
    console.error('Account Deletion OTP Email Error:', error);
    throw error;
  }
};

/**
 * Account Deletion Confirmation Email Template
 */
const getAccountDeletionConfirmationTemplate = (user, tenant) => {
  const businessName = tenant ? tenant.name : "Your Business";
  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; background-color: #f8fafc; margin: 0; padding: 20px; }
        .container { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); text-align: center; }
        .logo-text { font-size: 20px; font-weight: 800; color: #64748b; letter-spacing: 2px; margin-bottom: 20px; }
        h2 { color: #0f172a; font-size: 22px; margin-top: 0; }
        p { font-size: 15px; color: #475569; margin-bottom: 20px; }
        .info-box { background: #f1f5f9; border-radius: 12px; padding: 20px; margin: 30px 0; text-align: left; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo-text">AURIVA BMS</div>
        <h2>Account Deleted Successfully</h2>
        <p>Hi ${user.name},</p>
        <p>This email is to confirm that the account for <strong>${businessName}</strong> has been successfully deleted from our system as per your request.</p>
        
        <div class="info-box">
          <p style="margin-top: 0; color: #b45309;"><strong>Crucial Business Data Retained for 30 Days</strong></p>
          <p style="margin-bottom: 0; font-size: 14px;">Because business data is highly sensitive and crucial, we securely retain your data in our archives for <strong>30 days</strong> after deletion. If this deletion was a mistake, or if you want to recover your account within this timeframe, please contact the AurivaBMS Support Team immediately.</p>
        </div>
        
        <p style="font-size: 14px;">We're sorry to see you go! Thank you for trying AurivaBMS.</p>
      </div>
    </body>
    </html>
  `;
};

exports.sendAccountDeletionConfirmationEmail = async (user, tenant) => {
  if (!user || !user.email) return;
  try {
    const mailOptions = {
      from: `"AurivaBMS Support" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `Account Deleted - ${tenant.name}`,
      html: getAccountDeletionConfirmationTemplate(user, tenant)
    };
    await transporter.sendMail(mailOptions);
    console.log(`Account Deletion Confirmation sent to ${user.email}`);
  } catch (error) {
    console.error('Account Deletion Confirmation Email Error:', error);
    throw error;
  }
};

/**
 * Account Status Change Email Template (Recovered / Suspended / Deleted)
 */
const getAccountStatusChangeTemplate = (user, tenant, newStatus) => {
  const businessName = tenant ? tenant.name : "Your Business";
  
  let statusTitle = "";
  let statusMessage = "";
  let themeColor = "";
  let iconUrl = ""; // Can be ignored if no icon is preferred

  if (newStatus === 'active') {
    statusTitle = "Account Reactivated";
    statusMessage = "Good news! Your account has been successfully recovered and reactivated. You can now log in and access all your business data.";
    themeColor = "#16a34a"; // Green
  } else if (newStatus === 'suspended') {
    statusTitle = "Account Suspended";
    statusMessage = "Your account has been temporarily suspended by the administration. Please contact the AurivaBMS Support Team for further assistance.";
    themeColor = "#ea580c"; // Orange
  } else if (newStatus === 'deleted') {
    statusTitle = "Account Deactivated";
    statusMessage = "Your account has been deactivated. Your data is currently archived but you will not be able to log in. Please contact support if this was a mistake.";
    themeColor = "#dc2626"; // Red
  }

  return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: 'Inter', sans-serif; line-height: 1.6; color: #1e293b; background-color: #f8fafc; margin: 0; padding: 20px; }
        .container { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); text-align: center; border-top: 6px solid ${themeColor}; }
        .logo-text { font-size: 20px; font-weight: 800; color: #64748b; letter-spacing: 2px; margin-bottom: 20px; }
        h2 { color: ${themeColor}; font-size: 24px; margin-top: 0; font-weight: 800; }
        p { font-size: 15px; color: #475569; margin-bottom: 20px; }
        .info-box { background: #f1f5f9; border-radius: 12px; padding: 20px; margin: 30px 0; text-align: left; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo-text">AURIVA BMS</div>
        <h2>${statusTitle}</h2>
        <p>Hi ${user.name},</p>
        <p>This email is to inform you that the status of your account for <strong>${businessName}</strong> has been updated.</p>
        
        <div class="info-box">
          <p style="margin: 0; font-weight: 500; color: #334155;">${statusMessage}</p>
        </div>
        
        <p style="font-size: 14px; margin-top: 30px;">Regards,<br/><strong>AurivaBMS Team</strong></p>
      </div>
    </body>
    </html>
  `;
};

exports.sendAccountStatusChangeEmail = async (user, tenant, newStatus) => {
  if (!user || !user.email) return;
  try {
    const mailOptions = {
      from: `"AurivaBMS Support" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: `Account Status Update - ${tenant.name}`,
      html: getAccountStatusChangeTemplate(user, tenant, newStatus)
    };
    await transporter.sendMail(mailOptions);
    console.log(`Account Status Update (${newStatus}) sent to ${user.email}`);
  } catch (error) {
    console.error('Account Status Update Email Error:', error);
    throw error;
  }
};
