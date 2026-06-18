module.exports = (invoice) => {
    const formatCurrency = (amount) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
    const formatDate = (date) => new Date(date).toLocaleDateString('en-IN', { day: '2-digit', month: '2-digit', year: 'numeric' });

    // Fallback Data Logic
    const tenant = invoice.tenantId || {};
    const client = invoice.client || {};
    const bankDetails = (invoice.bankDetailsSnapshot && invoice.bankDetailsSnapshot.accountNumber) 
                        ? invoice.bankDetailsSnapshot 
                        : (tenant.bankDetails || {});
    const signatureImage = invoice.authorizedSignatoryImage || tenant.signatureImage;

    return `
    <!DOCTYPE html>
    <html>
    <head>
        <link href="https://fonts.googleapis.com/css2?family=Merriweather:wght@300;400;700&display=swap" rel="stylesheet">
        <style>
            body { font-family: 'Merriweather', serif; color: #111; margin: 0; padding: 0; font-size: 14px; -webkit-print-color-adjust: exact; }
            
            .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #000; padding-bottom: 20px; margin-bottom: 30px; }
            .company-name { font-size: 28px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; }
            .company-details { font-size: 12px; color: #444; margin-top: 5px; line-height: 1.4; }
            
            .invoice-badge { text-align: right; }
            .invoice-title { font-size: 48px; font-weight: 700; color: #e5e7eb; line-height: 0.8; letter-spacing: -2px; }
            .invoice-meta { font-size: 14px; margin-top: 10px; text-align: right; }
            
            .row { display: flex; justify-content: space-between; margin-bottom: 40px; }
            .col { width: 48%; }
            
            .section-title { font-size: 11px; font-weight: 700; text-transform: uppercase; border-bottom: 1px solid #000; display: inline-block; margin-bottom: 8px; padding-bottom: 2px; letter-spacing: 0.5px; }
            .client-name { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
            .text-sm { font-size: 13px; line-height: 1.5; color: #333; }
            
            table { width: 100%; border-collapse: collapse; border: 2px solid #000; margin-bottom: 20px; }
            th { background: #f3f4f6; border-bottom: 2px solid #000; border-right: 1px solid #000; padding: 12px; text-align: left; font-size: 11px; text-transform: uppercase; font-weight: 700; }
            td { padding: 12px; border-bottom: 1px solid #ccc; border-right: 1px solid #000; font-size: 13px; vertical-align: top; }
            td:last-child, th:last-child { border-right: none; }
            .text-right { text-align: right; }
            .text-center { text-align: center; }
            
            .totals-section { display: flex; justify-content: flex-end; }
            .totals-box { width: 40%; border: 1px solid #000; padding: 15px; }
            .total-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
            .grand-total { border-top: 2px solid #000; margin-top: 10px; padding-top: 10px; font-weight: 700; font-size: 16px; display: flex; justify-content: space-between; }
            
            .balance-bar { background: #000; color: #fff; padding: 10px; margin-top: 10px; display: flex; justify-content: space-between; font-weight: 700; font-size: 14px; }

            .footer { position: fixed; bottom: 0; left: 0; right: 0; padding: 40px; display: flex; justify-content: space-between; align-items: flex-end; }
            .terms { width: 60%; font-size: 11px; text-align: justify; color: #555; }
            .signature { width: 40%; text-align: center; }
            .sign-img { height: 60px; object-fit: contain; filter: grayscale(100%) multiply; margin-bottom: 5px; display: block; margin-left: auto; }
        </style>
    </head>
    <body>
        <div class="header">
            <div>
                ${tenant.logoImage ? `<img src="${tenant.logoImage}" style="height: 60px; margin-bottom:10px;" />` : ''}
                <div class="company-name">${tenant.name}</div>
                <div class="company-details">
                    <div>${tenant.address || ''}</div>
                    <div>${tenant.email} ${tenant.phone ? `| ${tenant.phone}` : ''}</div>
                    ${tenant.gstNumber ? `<div>GSTIN: <strong>${tenant.gstNumber}</strong></div>` : ''}
                </div>
            </div>
            <div class="invoice-badge">
                <div class="invoice-title">INVOICE</div>
                <div class="invoice-meta">
                    <div><strong>#${invoice.invoiceNumber}</strong></div>
                    <div style="margin-top:5px;">Date: ${formatDate(invoice.date)}</div>
                    <div>Due: ${formatDate(invoice.dueDate)}</div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col">
                <div class="section-title">Bill To</div>
                <div class="client-name">${client.name}</div>
                <div class="text-sm">${client.address || ''}</div>
                <div class="text-sm">${client.state ? `State: ${client.state}` : ''}</div>
                <div class="text-sm">${client.email}</div>
                ${(client.gstin || client.gstNumber) ? `<div class="text-sm">GSTIN: <strong>${client.gstin || client.gstNumber}</strong></div>` : ''}
            </div>
            <div class="col" style="text-align: right;">
                <div class="section-title">Invoice Details</div>
                <div class="text-sm">
                    <div><strong>#${invoice.invoiceNumber}</strong></div>
                    <div>Date: ${formatDate(invoice.date)}</div>
                    <div>Due: ${formatDate(invoice.dueDate)}</div>
                    ${invoice.placeOfSupply ? `<div>Place of Supply: <strong>${invoice.placeOfSupply}</strong></div>` : ''}
                </div>
                <div class="section-title" style="margin-top: 15px;">Payment Details</div>
                <div class="text-sm">
                    ${bankDetails.bankName ? `
                        <div>Bank: <strong>${bankDetails.bankName}</strong></div>
                        <div>Acct: <span style="font-family:monospace; font-size:14px;">${bankDetails.accountNumber}</span></div>
                    ` : 'No bank details added.'}
                </div>
            </div>
        </div>

        <table>
            <thead>
                <tr>
                    <th style="width: 40%">Item Description</th>
                    ${invoice.gstEnabled ? `<th class="text-center" style="width: 10%">HSN/SAC</th>` : ''}
                    <th class="text-center">Qty</th>
                    <th class="text-right">Rate</th>
                    ${invoice.gstEnabled ? `<th class="text-center">GST %</th>` : ''}
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                ${invoice.items.map(item => `
                <tr>
                    <td>
                        <div style="font-weight: 700;">${item.description}</div>
                        ${item.additionalDetails ? `<div style="font-size:11px; color:#666; margin-top:2px;">${item.additionalDetails}</div>` : ''}
                    </td>
                    ${invoice.gstEnabled ? `<td class="text-center font-mono" style="font-size:11px;">${item.hsnCode || item.sacCode || '-'}</td>` : ''}
                    <td class="text-center">${item.quantity}</td>
                    <td class="text-right">${formatCurrency(item.rate)}</td>
                    ${invoice.gstEnabled ? `<td class="text-center">${item.gstRate || 0}%</td>` : ''}
                    <td class="text-right" style="font-weight: 700;">${formatCurrency(item.quantity * item.rate)}</td>
                </tr>`).join('')}
            </tbody>
        </table>

        <div class="totals-section">
            <div class="totals-box">
                <div class="total-row">
                    <span>Taxable Value</span>
                    <span>${formatCurrency(invoice.subTotal)}</span>
                </div>
                ${invoice.discountAmount > 0 ? `
                <div class="total-row" style="color: #ef4444;">
                    <span>Discount</span>
                    <span>- ${formatCurrency(invoice.discountAmount)}</span>
                </div>` : ''}
                
                ${invoice.gstEnabled ? `
                    <div style="border-top: 1px dashed #ccc; margin: 5px 0; padding-top: 5px;">
                        ${invoice.gstBreakdown ? `
                            ${invoice.gstBreakdown.cgst > 0 ? `
                                <div class="total-row" style="font-size: 11px; color: #666;">
                                    <span>CGST</span>
                                    <span>${formatCurrency(invoice.gstBreakdown.cgst)}</span>
                                </div>
                            ` : ''}
                            ${invoice.gstBreakdown.sgst > 0 ? `
                                <div class="total-row" style="font-size: 11px; color: #666;">
                                    <span>SGST</span>
                                    <span>${formatCurrency(invoice.gstBreakdown.sgst)}</span>
                                </div>
                            ` : ''}
                            ${invoice.gstBreakdown.igst > 0 ? `
                                <div class="total-row" style="font-size: 11px; color: #666;">
                                    <span>IGST</span>
                                    <span>${formatCurrency(invoice.gstBreakdown.igst)}</span>
                                </div>
                            ` : ''}
                        ` : `
                            <div class="total-row">
                                <span>GST (${invoice.taxRate}%)</span>
                                <span>${formatCurrency(invoice.gstAmount)}</span>
                            </div>
                        `}
                    </div>
                ` : ''}

                <div class="grand-total">
                    <span>Total Amount</span>
                    <span>${formatCurrency(invoice.totalAmount)}</span>
                </div>
                ${invoice.advancePayment > 0 ? `
                <div class="total-row" style="margin-top:5px; font-style:italic; font-size:12px;">
                    <span>Advance Payment</span>
                    <span>- ${formatCurrency(invoice.advancePayment)}</span>
                </div>` : ''}
                
                <div class="balance-bar">
                    <span>Balance Due</span>
                    <span>${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</span>
                </div>
            </div>
        </div>

        <div class="footer">
            <div class="terms">
                <div class="section-title">Terms & Conditions</div>
                <div>${invoice.terms || tenant.defaultTerms || "Payment is due upon receipt."}</div>
            </div>
            <div class="signature">
                ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}
                <div style="font-size:14px; font-weight:700; text-transform:uppercase;">${tenant.name}</div>
                <div style="font-size:10px; letter-spacing:1px; margin-top:2px;">AUTHORIZED SIGNATORY</div>
            </div>
        </div>
    </body>
    </html>`;
};