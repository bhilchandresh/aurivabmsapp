module.exports = (invoice) => {
    // Helper to format currency
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amount);
    };

    const date = new Date(invoice.date).toLocaleDateString('en-IN');
    const dueDate = invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN') : 'N/A';
    const isGst = invoice.gstEnabled;
    const tenant = invoice.tenantId || {};
    const signatureImage = invoice.authorizedSignatoryImage || (invoice.salesPerson && invoice.salesPerson.signatureImage) || tenant.signatureImage;

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { font-family: 'Helvetica', sans-serif; color: #333; font-size: 13px; padding: 30px; }
        
        /* Header - Using Float for PDF compatibility */
        .header { overflow: hidden; margin-bottom: 40px; border-bottom: 2px solid #eee; padding-bottom: 20px; }
        .company-info { float: left; width: 50%; }
        .invoice-details { float: right; width: 40%; text-align: right; }
        
        h1 { font-size: 24px; color: #333; margin: 0 0 5px 0; letter-spacing: 1px; }
        h2 { font-size: 20px; color: #2563eb; margin: 0 0 5px 0; }
        p { margin: 2px 0; color: #555; }
        .logo { max-height: 60px; margin-bottom: 10px; display: block; }
        
        .bill-to { margin-bottom: 30px; clear: both; }
        .label { font-size: 10px; color: #888; font-weight: bold; text-transform: uppercase; margin-bottom: 5px; }
        
        /* Table */
        table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        th { background: #f8fafc; text-align: left; padding: 10px; border-bottom: 1px solid #e2e8f0; font-size: 11px; font-weight: bold; color: #475569; text-transform: uppercase; }
        td { padding: 12px 10px; border-bottom: 1px solid #f1f5f9; font-size: 12px; }
        .text-right { text-align: right; }
        
        /* Totals Section */
        .totals-container { overflow: hidden; page-break-inside: avoid; margin-bottom: 30px; }
        .totals-table { float: right; width: 45%; }
        .totals-table td { padding: 6px 0; border: none; }
        .grand-total-row td { border-top: 2px solid #333; padding-top: 10px; font-weight: bold; font-size: 15px; color: #000; }
        
        .footer { position: fixed; bottom: 20px; left: 0; right: 0; text-align: center; color: #94a3b8; font-size: 10px; border-top: 1px solid #f1f5f9; padding-top: 15px; }
        .signature-container { float: right; width: 30%; text-align: center; margin-top: 40px; page-break-inside: avoid; clear: both; }
        .sign-img { max-height: 60px; display: block; margin: 0 auto 5px auto; }
        .sign-line { border-top: 1px solid #94a3b8; width: 100%; margin-top: 5px; }
    </style>
    </head>
    <body>
        <div class="header">
            <div class="company-info">
                ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo" />` : ''}
                <h2>${tenant.name || 'Company Name'}</h2>
                <p>${tenant.address || ''}</p>
                <p>${tenant.email || ''} ${tenant.phone ? `| ${tenant.phone}` : ''}</p>
                ${tenant.gstNumber ? `<p>GSTIN: <strong>${tenant.gstNumber}</strong></p>` : ''}
            </div>
            <div class="invoice-details">
                <h1>INVOICE</h1>
                <p><strong>#${invoice.invoiceNumber}</strong></p>
                <p>Date: ${date}</p>
                <p>Due: ${dueDate}</p>
            </div>
        </div>

        <div class="bill-to">
            <div class="label">BILL TO</div>
            <p style="font-size: 14px; font-weight: bold; color: #000;">${invoice.client.name}</p>
            <p>${invoice.client.email}</p>
            <p>${invoice.client.address || ''}</p>
            ${invoice.client.gstNumber ? `<p>GST: ${invoice.client.gstNumber}</p>` : ''}
        </div>

        <table>
            <thead>
                <tr>
                    <th width="50%">Item Description</th>
                    <th class="text-right">Qty</th>
                    <th class="text-right">Rate</th>
                                       ${isGst ? '<th class="text-right">GST</th>' : ''}
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                ${invoice.items.map(item => `
                <tr>
                    <td>
                        <span style="font-weight:bold; color:#333;">${item.description}</span>
                        ${item.additionalDetails ? `<br><span style="color:#777; font-size:11px;">${item.additionalDetails}</span>` : ''}
                    </td>
                    <td class="text-right">${item.quantity}</td>
                    <td class="text-right">${formatCurrency(item.rate)}</td>
                                       ${isGst ? `
                                       <td class="text-right">
                                          ${item.gstRate ? item.gstRate + '%' : '-'}
                                       </td>` : ''}
                    <td class="text-right">${formatCurrency(item.quantity * item.rate)}</td>
                </tr>
                `).join('')}
            </tbody>
        </table>

        <div class="totals-container">
            <table class="totals-table">
                <tr>
                    <td>Subtotal:</td>
                    <td class="text-right">${formatCurrency(invoice.subTotal)}</td>
                </tr>
                <tr>
                    <td>Discount (${invoice.discountPercentage || 0}%):</td>
                    <td class="text-right text-red-500">- ${formatCurrency(invoice.discountAmount || 0)}</td>
                </tr>
                ${isGst ? `
                    <tr>
                        <td style="color: #444;">Total GST (${invoice.taxType || 'exclusive'}):</td>
                        <td class="text-right">+ ${formatCurrency(invoice.gstAmount)}</td>
                    </tr>
                    ${invoice.gstBreakdown ? `
                        ${invoice.gstBreakdown.cgst > 0 ? `
                        <tr>
                            <td>CGST:</td>
                            <td class="text-right">${formatCurrency(invoice.gstBreakdown.cgst)}</td>
                        </tr>
                        ` : ''}
                        ${invoice.gstBreakdown.sgst > 0 ? `
                        <tr>
                            <td>SGST:</td>
                            <td class="text-right">${formatCurrency(invoice.gstBreakdown.sgst)}</td>
                        </tr>
                        ` : ''}
                        ${invoice.gstBreakdown.igst > 0 ? `
                        <tr>
                            <td>IGST:</td>
                            <td class="text-right">${formatCurrency(invoice.gstBreakdown.igst)}</td>
                        </tr>
                        ` : ''}
                    ` : ''}
                ` : ''}
                <tr>
                    <td>Advance Paid:</td>
                    <td class="text-right">- ${formatCurrency(invoice.advancePayment || 0)}</td>
                </tr>
                <tr class="grand-total-row">
                    <td>Total Payable:</td>
                    <td class="text-right">${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</td>
                </tr>
            </table>
        </div>

        ${invoice.terms ? `
        <div style="margin-top: 40px; border-top: 1px solid #f1f5f9; padding-top: 15px; clear: both;">
            <div class="label">TERMS & CONDITIONS</div>
            <p style="font-size: 11px; line-height: 1.5;">${invoice.terms}</p>
        </div>` : ''}

        <div class="signature-container">
            ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}
            <div class="sign-line"></div>
            <p style="font-size: 12px; font-weight: bold; margin-top: 5px;">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : (tenant.name || 'Authorized Signatory')}</p>
            <p style="font-size: 10px; color: #888;">Authorized Signatory</p>
        </div>

        <div class="footer">
            Thank you for your business! | Computer Generated Invoice
        </div>
    </body>
    </html>
    `;
};