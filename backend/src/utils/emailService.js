const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.hostinger.com',
  port: process.env.EMAIL_PORT || 465,
  secure: true, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

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
            <a href="${process.env.APP_URL || 'http://localhost:5173'}/public/invoice/${invoice._id}" class="button">View Online</a>
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
 * Premium HTML Template for Quotations (White-Labeled)
 */
const getQuotationEmailTemplate = (quotation, tenant = null) => {
  const formattedAmount = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR'
  }).format(quotation.totalAmount);

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
          <h1>New Quotation</h1>
          <p>${businessName}</p>
        </div>
        <div class="content">
          <div class="greeting">Dear ${quotation.client.name},</div>
          <p>Please find the details of your new quotation from <strong>${businessName}</strong> below. You can securely view and download your full quotation online.</p>
          
          <div class="invoice-card">
            <div class="amount-label">Quotation Amount</div>
            <div class="amount-value">${formattedAmount}</div>
            
            <div class="details-grid">
              <div class="detail-item">
                <div class="label">Quotation Number</div>
                <div class="value">${quotation.quotationNumber}</div>
              </div>
              <div class="detail-item">
                <div class="label">Valid Until</div>
                <div class="value">${new Date(quotation.validUntil || quotation.date).toLocaleDateString('en-IN')}</div>
              </div>
            </div>
          </div>
          
          <div style="text-align: center;">
            <a href="${process.env.APP_URL || 'https://app.aurivabms.in'}/public/quotation/${quotation._id}" class="button">View Online</a>
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
            <a href="${process.env.APP_URL || 'http://localhost:5173'}/public/invoice/${invoice._id}" 
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
                <div class="inv-amount">${new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(lastInvoice.totalAmount)}</div>
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

exports.sendQuotationEmail = async (quotation, tenant = null) => {
  if (!quotation.client || !quotation.client.email) {
    console.log(`Skipping email: No email for client ${quotation.client.name}`);
    return;
  }

  try {
    const businessName = tenant ? tenant.name : "Billing Manager";
    const mailOptions = {
      from: `"${businessName}" <${process.env.EMAIL_USER}>`,
      to: quotation.client.email,
      subject: `Quotation #${quotation.quotationNumber} from ${businessName}`,
      html: getQuotationEmailTemplate(quotation, tenant)
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`Quotation Email sent: ${info.messageId}`);
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

exports.sendClientEmail = async (client, subject, message) => {
  if (!client.email) throw new Error("Client has no email address");

  try {
    const mailOptions = {
      from: `"Billing Center" <${process.env.EMAIL_USER}>`,
      to: client.email,
      subject: subject || `Message for ${client.name}`,
      html: getClientEmailTemplate(client, subject) 
    };

    const info = await transporter.sendMail(mailOptions);
    return info;
  } catch (error) {
    console.error('Client Email Error:', error);
    throw error;
  }
};
