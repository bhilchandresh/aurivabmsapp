module.exports = (invoice) => {
    // Helper for currency formatting
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amount);
    };

    const date = new Date(invoice.date).toLocaleDateString('en-IN');
    const dueDate = invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN') : 'N/A';
    const tenant = invoice.tenantId || {};
    const signatureImage = invoice.authorizedSignatoryImage || (invoice.salesPerson && invoice.salesPerson.signatureImage) || tenant.signatureImage;

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { font-family: 'Helvetica', sans-serif; margin: 0; padding: 0; color: #333; font-size: 14px; }
        
        /* Modern Header - Dark Background */
        .header-bg { background-color: #1f2937; color: #fff; padding: 40px; overflow: hidden; }
        .logo { float: left; font-size: 26px; font-weight: bold; letter-spacing: 1px; }
        .logo-img { max-height: 60px; display: block; margin-bottom: 10px; }
        .invoice-title { float: right; font-size: 36px; font-weight: bold; opacity: 0.3; letter-spacing: 2px; }
        
        .content { padding: 40px; }
        
        /* Info Section */
        .info-row { overflow: hidden; margin-bottom: 40px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
        .col-left { float: left; width: 40%; }
        .col-right { float: right; width: 40%; text-align: right; }
        
        .label { font-size: 10px; color: #888; font-weight: bold; text-transform: uppercase; margin-bottom: 5px; }
        h3 { margin: 0 0 5px 0; font-size: 18px; color: #111; }
        /* Table */
        table { width: 100%; border-collapse: separate; border-spacing: 0; margin-top: 20px; border: 1px solid #d1d5db; border-radius: 8px; overflow: hidden; }
        th { background: #f3f4f6; color: #1f2937; padding: 12px 10px; text-align: left; font-size: 11px; font-weight: bold; text-transform: uppercase; border-bottom: 1px solid #d1d5db; border-right: 1px solid #d1d5db; }
        th:last-child { border-right: none; }
        td { padding: 12px 10px; border-bottom: 1px solid #d1d5db; border-right: 1px solid #d1d5db; color: #4b5563; }
        td:last-child { border-right: none; }
        tr:last-child td { border-bottom: none; }
        .text-right { text-align: right; }
        
        /* Totals */
        .totals-container { overflow: hidden; margin-top: 30px; }
        .totals-table { float: right; width: 40%; }
        .totals-table td { padding: 8px 0; border-bottom: 1px solid #f3f4f6; }
        .totals-table .last-row td { border-bottom: none; border-top: 2px solid #1f2937; color: #000; font-weight: bold; font-size: 16px; padding-top: 15px; }
        
        /* Footer */
        .footer { margin-top: 60px; text-align: center; color: #9ca3af; font-size: 11px; clear: both; }
        
        .signature-box { float: right; width: 40%; text-align: center; margin-top: 40px; }
        .sign-img { max-height: 60px; display: block; margin: 0 auto 5px auto; }
        .sign-line { border-top: 1px solid #333; width: 100%; margin-top: 5px; }
        .sign-name { font-size: 12px; font-weight: bold; color: #111; margin-top: 5px; }
    </style>
    </head>
    <body>
        <div class="header-bg">
            <div class="logo">
                ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo-img" />` : ''}
                ${tenant.name || 'Auriva BMS'}
            </div>
            <div class="invoice-title">INVOICE</div>
        </div>
        
        <div class="content">
            <div class="info-row">
                <div class="col-left">
                    <div class="label">Billed To</div>
                    <h3>${invoice.client.name}</h3>
                    <p>${invoice.client.address || ''}</p>
                    ${invoice.client.state ? `<p>State: ${invoice.client.state}</p>` : ''}
                    <p>${invoice.client.email}</p>
                    ${(invoice.client.gstin || invoice.client.gstNumber) ? `<p>GSTIN: <strong>${invoice.client.gstin || invoice.client.gstNumber}</strong></p>` : ''}
                </div>
                <div class="col-right">
                    <div class="label">Invoice Details</div>
                    <p><strong>Invoice #:</strong> ${invoice.invoiceNumber}</p>
                    <p><strong>Date:</strong> ${date}</p>
                    <p><strong>Due Date:</strong> ${dueDate}</p>
                    ${invoice.placeOfSupply ? `<p><strong>Place of Supply:</strong> ${invoice.placeOfSupply}</p>` : ''}
                </div>
            </div>

            <table>
                <thead>
                    <tr>
                        <th width="40%">Description</th>
                        ${invoice.gstEnabled ? `<th class="text-right">HSN/SAC</th>` : ''}
                        <th class="text-right">Qty</th>
                        <th class="text-right">Rate</th>
                        ${invoice.gstEnabled ? `<th class="text-right">GST %</th>` : ''}
                        <th class="text-right">Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${invoice.items.map(item => `
                    <tr>
                        <td>
                            <strong style="color:#111;">${item.description}</strong>
                            ${item.additionalDetails ? `<br><span style="font-size:11px; color:#888;">${item.additionalDetails}</span>` : ''}
                        </td>
                        ${invoice.gstEnabled ? `<td class="text-right font-mono" style="font-size:11px;">${item.hsnCode || item.sacCode || '-'}</td>` : ''}
                        <td class="text-right">${item.quantity}</td>
                        <td class="text-right">${formatCurrency(item.rate)}</td>
                        ${invoice.gstEnabled ? `<td class="text-right">${item.gstRate || 0}%</td>` : ''}
                        <td class="text-right">${formatCurrency(item.quantity * item.rate)}</td>
                    </tr>`).join('')}
                </tbody>
            </table>

            <div class="totals-container">
                <table class="totals-table">
                    <tr>
                        <td>Subtotal</td>
                        <td class="text-right">${formatCurrency(invoice.subTotal)}</td>
                    </tr>
                    ${invoice.discountAmount > 0 ? `
                    <tr>
                        <td>Discount</td>
                        <td class="text-right" style="color:#ef4444;">- ${formatCurrency(invoice.discountAmount || 0)}</td>
                    </tr>` : ''}

                    ${invoice.gstEnabled ? `
                        <tr>
                            <td>Total GST (${invoice.taxType || 'exclusive'})</td>
                            <td class="text-right">+ ${formatCurrency(invoice.gstAmount)}</td>
                        </tr>
                        ${invoice.gstBreakdown ? `
                            ${invoice.gstBreakdown.cgst > 0 ? `
                                <tr>
                                    <td style="font-size:11px; color:#888;">CGST</td>
                                    <td class="text-right" style="font-size:11px; color:#888;">${formatCurrency(invoice.gstBreakdown.cgst)}</td>
                                </tr>
                            ` : ''}
                            ${invoice.gstBreakdown.sgst > 0 ? `
                                <tr>
                                    <td style="font-size:11px; color:#888;">SGST</td>
                                    <td class="text-right" style="font-size:11px; color:#888;">${formatCurrency(invoice.gstBreakdown.sgst)}</td>
                                </tr>
                            ` : ''}
                            ${invoice.gstBreakdown.igst > 0 ? `
                                <tr>
                                    <td style="font-size:11px; color:#888;">IGST</td>
                                    <td class="text-right" style="font-size:11px; color:#888;">${formatCurrency(invoice.gstBreakdown.igst)}</td>
                                </tr>
                            ` : ''}
                        ` : `
                            <tr>
                                <td>GST (${invoice.taxRate}%)</td>
                                <td class="text-right">${formatCurrency(invoice.gstAmount)}</td>
                            </tr>
                        `}` : ''}
                    
                    <tr>
                        <td>Advance Paid</td>
                        <td class="text-right">- ${formatCurrency(invoice.advancePayment || 0)}</td>
                    </tr>
                    <tr class="last-row">
                        <td>Total Payable</td>
                        <td class="text-right">${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</td>
                    </tr>
                </table>
            </div>

            ${invoice.terms ? `
            <div style="margin-top: 50px; border-top: 1px solid #eee; padding-top: 20px; clear: both;">
                <div class="label">Terms & Conditions</div>
                <p>${invoice.terms}</p>
            </div>` : ''}
            
            <div class="signature-box">
                ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}
                <div class="sign-line"></div>
                <div class="sign-name">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : (tenant.name || 'Authorized Signatory')}</div>
                <div class="label" style="margin-top: 2px;">Authorized Signatory</div>
            </div>

            <div class="footer">
                Thank you for your business
            </div>
        </div>
    </body>
    </html>`;
};