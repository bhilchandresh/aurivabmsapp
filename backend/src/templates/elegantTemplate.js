module.exports = (invoice) => {
    // --- 1. IDENTIFY TYPE (Invoice or Quotation) ---
    const isInvoice = !!invoice.invoiceNumber;
    const number = invoice.invoiceNumber || invoice.quotationNumber;
    const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
    
    // Format Dates
    const date = new Date(invoice.date).toLocaleDateString('en-IN');
    const dueDate = invoice.dueDate 
        ? new Date(invoice.dueDate).toLocaleDateString('en-IN') 
        : invoice.validUntil 
            ? new Date(invoice.validUntil).toLocaleDateString('en-IN') 
            : 'N/A';

    // --- 2. FALLBACK LOGIC ---
    const tenant = invoice.tenantId || {};
    const client = invoice.client || {};
    
    // Bank Details Fallback
    const bankDetails = (invoice.bankDetailsSnapshot && invoice.bankDetailsSnapshot.accountNumber) 
                        ? invoice.bankDetailsSnapshot 
                        : (tenant.bankDetails || {});

    // Signature Fallback
    const signatureImage = invoice.authorizedSignatoryImage || 
                          (invoice.salesPerson && invoice.salesPerson.signatureImage) || 
                          tenant.signatureImage;

    // Currency Formatter
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
    };

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { 
            font-family: 'Georgia', 'Times New Roman', serif; /* Elegant Serif Font */
            margin: 0; 
            padding: 0; 
            color: #1f2937; 
            font-size: 14px; 
            -webkit-print-color-adjust: exact; 
            print-color-adjust: exact;
        }
        
        /* Layout */
        .container { position: relative; min-height: 100vh; padding-bottom: 120px; }
        .content { padding: 40px 50px; }
        
        /* Header */
        .header-top { border-bottom: 4px solid #c2a472; padding-bottom: 20px; display: flex; justify-content: space-between; align-items: flex-end; }
        .logo { max-height: 80px; margin-bottom: 15px; object-fit: contain; }
        .company-name { font-size: 32px; font-weight: bold; text-transform: uppercase; color: #111; margin: 0; letter-spacing: 1px; }
        
        .doc-title { font-size: 42px; font-weight: 300; color: #c2a472; letter-spacing: 4px; margin: 0; line-height: 1; }
        .doc-number { font-size: 18px; font-weight: bold; color: #374151; margin-top: 8px; text-align: right; letter-spacing: 1px; }
        
        .header-meta { display: flex; justify-content: space-between; margin-top: 15px; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #6b7280; font-family: 'Helvetica', sans-serif; }
        
        /* Grid Details */
        .info-grid { display: flex; justify-content: space-between; margin-top: 30px; margin-bottom: 40px; font-family: 'Helvetica', sans-serif; }
        .col-left { width: 48%; }
        .col-right { width: 48%; text-align: right; }
        
        .section-title { font-size: 10px; font-weight: bold; color: #c2a472; text-transform: uppercase; letter-spacing: 2px; border-bottom: 1px solid #f3f4f6; padding-bottom: 5px; margin-bottom: 12px; }
        
        .client-name { font-size: 20px; font-weight: bold; color: #111; margin: 0 0 6px 0; font-family: 'Georgia', serif; }
        .text-sm { font-size: 13px; color: #4b5563; margin: 0 0 4px 0; line-height: 1.4; }
        
        /* Table */
        table { width: 100%; border-collapse: collapse; margin-bottom: 40px; }
        th { font-family: 'Helvetica', sans-serif; font-size: 11px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; color: #c2a472; padding: 12px 10px; border-bottom: 2px solid #c2a472; text-align: left; }
        th.text-center { text-align: center; }
        th.text-right { text-align: right; }
        
        td { font-family: 'Helvetica', sans-serif; font-size: 13px; padding: 15px 10px; border-bottom: 1px solid #f3f4f6; color: #374151; vertical-align: top; }
        td.text-center { text-align: center; }
        td.text-right { text-align: right; }
        
        .item-name { font-weight: bold; color: #111; margin: 0; font-size: 14px; }
        .item-desc { font-size: 11px; color: #6b7280; margin: 4px 0 0 0; font-style: italic; }
        
        /* Totals */
        .totals-container { display: flex; justify-content: flex-end; font-family: 'Helvetica', sans-serif; page-break-inside: avoid; }
        .totals-box { width: 350px; }
        .total-row { display: flex; justify-content: space-between; font-size: 13px; color: #4b5563; margin-bottom: 10px; }
        
        .grand-total { border-top: 1px solid #d1d5db; border-bottom: 1px solid #d1d5db; padding: 10px 0; margin: 10px 0; display: flex; justify-content: space-between; font-size: 20px; font-weight: bold; color: #c2a472; font-family: 'Georgia', serif; }
        
        .balance-due { background: #f9fafb; padding: 10px; border-radius: 4px; display: flex; justify-content: space-between; font-size: 15px; font-weight: bold; color: #111; margin-top: 10px; }
        
        /* Footer */
        .footer-fixed { position: fixed; bottom: 0; left: 0; width: 100%; background: white; }
        .footer-content { padding: 0 50px 30px 50px; display: flex; justify-content: space-between; align-items: flex-end; page-break-inside: avoid; }
        
        .terms-box { width: 60%; font-family: 'Helvetica', sans-serif; }
        .terms-title { font-size: 11px; font-weight: bold; color: #9ca3af; text-transform: uppercase; margin-bottom: 6px; }
        .terms-text { font-size: 11px; color: #6b7280; white-space: pre-wrap; line-height: 1.5; margin: 0; }
        
        .sign-box { width: 30%; text-align: center; font-family: 'Helvetica', sans-serif; }
        .sign-img { max-height: 60px; object-fit: contain; margin: 0 auto 5px auto; display: block; mix-blend-mode: multiply; }
        .sign-line { border-top: 1px solid #d1d5db; padding-top: 4px; width: 180px; margin: 0 auto; }
        .sign-name { font-weight: bold; font-size: 12px; color: #1f2937; margin: 0; }
        .sign-title { font-size: 9px; color: #6b7280; text-transform: uppercase; letter-spacing: 1px; margin: 2px 0 0 0; font-weight: bold; }
        
        .bottom-bar { background-color: #c2a472; color: #fff; text-align: center; padding: 12px; font-size: 10px; font-family: 'Helvetica', sans-serif; font-weight: bold; text-transform: uppercase; letter-spacing: 2px; }
    </style>
    </head>
    <body>
        <div class="container">
            <div class="content">
                
                <div class="header-top">
                    <div style="width: 60%;">
                        ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo" />` : ''}
                        <h1 class="company-name">${tenant.name}</h1>
                    </div>
                    <div style="width: 40%; text-align: right;">
                        <h2 class="doc-title">${isInvoice ? "INVOICE" : "QUOTE"}</h2>
                        <p class="doc-number">#${number}</p>
                    </div>
                </div>
                
                <div class="header-meta">
                    <div>
                        ${tenant.email ? `<span>✉ ${tenant.email}</span> &nbsp;&nbsp;` : ''}
                        ${tenant.phone ? `<span>📞 ${tenant.phone}</span>` : ''}
                    </div>
                    <div>ISSUED: ${date}</div>
                </div>

                <div class="info-grid">
                    <div class="col-left">
                        <div class="section-title">Billed To</div>
                        <h3 class="client-name">${client.name}</h3>
                        <p class="text-sm">${client.email}</p>
                        ${client.phone ? `<p class="text-sm">${client.phone}</p>` : ''}
                        <p class="text-sm" style="white-space: pre-line;">${client.address || ''}</p>
                        ${invoice.gstEnabled ? `<p class="text-sm" style="margin-top:8px; font-weight:bold; color:#111;">GSTIN: ${client.gstin || client.gstNumber || '-'}</p>` : ''}
                    </div>
                    
                    <div class="col-right">
                        <div style="margin-bottom: 25px;">
                            <div class="section-title">Details</div>
                            <p class="text-sm"><span style="color:#6b7280;">Issued Date:</span> <strong style="color:#111;">${date}</strong></p>
                            <p class="text-sm"><span style="color:#6b7280;">${dueDateLabel}:</span> <strong style="color:#111;">${dueDate}</strong></p>
                            ${invoice.placeOfSupply ? `<p class="text-sm"><span style="color:#6b7280;">Place of Supply:</span> <strong style="color:#111;">${invoice.placeOfSupply}</strong></p>` : ''}
                        </div>
                        
                        ${bankDetails.accountNumber ? `
                        <div>
                            <div class="section-title">Pay To</div>
                            ${bankDetails.accountName ? `<p class="text-sm">${bankDetails.accountName}</p>` : ''}
                            <p class="text-sm"><strong style="color:#111;">${bankDetails.bankName}</strong></p>
                            <p class="text-sm" style="font-family:monospace;">A/C: ${bankDetails.accountNumber}</p>
                        </div>
                        ` : ''}
                        
                        ${invoice.gstEnabled && tenant.gstNumber ? `<p class="text-sm" style="margin-top:15px;"><span style="color:#6b7280;">Co. GSTIN:</span> <strong style="color:#111;">${tenant.gstNumber}</strong></p>` : ''}
                    </div>
                </div>

                <table>
                    <thead>
                        <tr>
                            <th>Description</th>
                            ${invoice.gstEnabled ? `<th class="text-center" style="width: 12%;">HSN/SAC</th>` : ''}
                            <th class="text-center" style="width: 10%;">Qty</th>
                            <th class="text-right" style="width: 15%;">Rate</th>
                            ${invoice.gstEnabled ? `<th class="text-right" style="width: 10%;">GST %</th>` : ''}
                            <th class="text-right" style="width: 20%;">Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${invoice.items.map(item => `
                        <tr>
                            <td>
                                <p class="item-name">${item.description}</p>
                                ${item.additionalDetails ? `<p class="item-desc">${item.additionalDetails}</p>` : ''}
                            </td>
                            ${invoice.gstEnabled ? `<td class="text-center font-mono" style="font-size:11px;">${item.hsnCode || item.sacCode || '-'}</td>` : ''}
                            <td class="text-center">${item.quantity}</td>
                            <td class="text-right">${formatCurrency(item.rate)}</td>
                            ${invoice.gstEnabled ? `<td class="text-right">${item.gstRate || 0}%</td>` : ''}
                            <td class="text-right" style="font-weight:bold; color:#111;">${formatCurrency(item.quantity * item.rate)}</td>
                        </tr>`).join('')}
                    </tbody>
                </table>

                <div class="totals-container">
                    <div class="totals-box">
                        <div class="total-row">
                            <span>Taxable Value</span>
                            <strong style="color:#111;">${formatCurrency(invoice.subTotal)}</strong>
                        </div>
                        
                        ${invoice.discountAmount > 0 ? `
                        <div class="total-row" style="color:#ef4444;">
                            <span>Discount</span>
                            <span>- ${formatCurrency(invoice.discountAmount)}</span>
                        </div>` : ''}
                        
                        ${invoice.gstEnabled ? `
                            <div style="border-top: 1px dashed #c2a472; margin: 8px 0; padding-top: 8px;">
                                ${invoice.gstBreakdown ? `
                                    ${invoice.gstBreakdown.cgst > 0 ? `
                                        <div class="total-row" style="font-size: 11px;">
                                            <span>CGST</span>
                                            <span>${formatCurrency(invoice.gstBreakdown.cgst)}</span>
                                        </div>
                                    ` : ''}
                                    ${invoice.gstBreakdown.sgst > 0 ? `
                                        <div class="total-row" style="font-size: 11px;">
                                            <span>SGST</span>
                                            <span>${formatCurrency(invoice.gstBreakdown.sgst)}</span>
                                        </div>
                                    ` : ''}
                                    ${invoice.gstBreakdown.igst > 0 ? `
                                        <div class="total-row" style="font-size: 11px;">
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
                            <span>Total</span>
                            <span>${formatCurrency(invoice.totalAmount)}</span>
                        </div>
                        
                        ${invoice.advancePayment > 0 ? `
                        <div class="total-row" style="color:#10b981; font-weight:bold; border-bottom: 1px solid #f3f4f6; padding-bottom: 10px;">
                            <span>Advance Paid</span>
                            <span>- ${formatCurrency(invoice.advancePayment)}</span>
                        </div>` : ''}
                        
                        <div class="balance-due">
                            <span>Balance Due</span>
                            <span>${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="footer-fixed">
                <div class="footer-content">
                    <div class="terms-box">
                        <div class="terms-title">Terms & Notes</div>
                        <p class="terms-text">${invoice.terms || tenant.defaultTerms || "Payment is due upon receipt."}</p>
                    </div>
                    
                    <div class="sign-box">
                        ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}
                        <div class="sign-line">
                            <p class="sign-name">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : tenant.name}</p>
                            <p class="sign-title">Authorized Signatory</p>
                        </div>
                    </div>
                </div>
                
                <div class="bottom-bar">
                    ${tenant.address ? tenant.address.split('\n')[0] : 'Thank you for your business'}
                </div>
            </div>
        </div>
    </body>
    </html>`;
};