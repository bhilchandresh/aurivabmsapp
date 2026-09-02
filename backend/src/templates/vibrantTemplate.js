module.exports = (invoice) => {
    const isInvoice = !!invoice.invoiceNumber;
    const number = invoice.invoiceNumber || invoice.quotationNumber;
    const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
    
    const date = new Date(invoice.date).toLocaleDateString('en-IN');
    const dueDate = invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN') : invoice.validUntil ? new Date(invoice.validUntil).toLocaleDateString('en-IN') : 'N/A';

    const tenant = invoice.tenantId || {};
    const client = invoice.client || {};
    const bankDetails = (invoice.bankDetailsSnapshot && invoice.bankDetailsSnapshot.accountNumber) ? invoice.bankDetailsSnapshot : (tenant.bankDetails || {});
    const signatureImage = invoice.authorizedSignatoryImage || (invoice.salesPerson && invoice.salesPerson.signatureImage) || tenant.signatureImage;

    const formatCurrency = (amount) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { font-family: 'Helvetica', sans-serif; margin: 0; padding: 0; color: #1f2937; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        .container { min-height: 100vh; padding-bottom: 150px; position: relative; }
        
        .header-card { background: linear-gradient(135deg, #7c3aed, #c026d3); padding: 40px; margin: 30px; border-radius: 20px; color: white; display: flex; justify-content: space-between; }
        .header-left { width: 60%; }
        .header-right { width: 35%; text-align: right; }
        .logo { max-height: 60px; margin-bottom: 15px; display: block; }
        
        .info-grid { display: flex; justify-content: space-between; padding: 0 40px; margin-bottom: 30px; }
        .info-box { width: 45%; border: 2px solid #ede9fe; padding: 20px; border-radius: 16px; }
        .info-box.pink { border-color: #fae8ff; }
        .box-title { font-size: 11px; font-weight: bold; text-transform: uppercase; margin-bottom: 10px; color: #7c3aed; }
        .box-title.pink { color: #c026d3; }
        
        table { width: calc(100% - 80px); margin: 0 40px 30px 40px; border-collapse: collapse; border: 1px solid #f3f4f6; border-radius: 16px; overflow: hidden; }
        th { background: #f9fafb; padding: 15px; text-align: left; font-size: 12px; color: #6b7280; text-transform: uppercase; }
        td { padding: 15px; border-bottom: 1px solid #f3f4f6; font-size: 14px; }
        
        .totals-wrapper { display: flex; justify-content: flex-end; padding: 0 40px; page-break-inside: avoid; }
        .totals-box { width: 300px; }
        .calc-row { display: flex; justify-content: space-between; font-size: 13px; color: #4b5563; margin-bottom: 8px; }
        .gradient-total { background: linear-gradient(135deg, #7c3aed, #c026d3); color: white; padding: 20px; border-radius: 16px; margin-top: 15px; }
        
        .footer-fixed { position: fixed; bottom: 0; left: 0; width: 100%; background: white; padding: 20px 40px; border-top: 1px solid #f3f4f6; display: flex; justify-content: space-between; box-sizing: border-box; }
        .terms { width: 60%; background: #f9fafb; padding: 15px; border-radius: 12px; font-size: 11px; color: #6b7280; }
        .signature { width: 40%; text-align: center; }
        .sign-img { max-height: 60px; display: block; margin: 0 auto 5px auto; }
    </style>
    </head>
    <body>
        <div class="container">
            <div class="header-card">
                <div class="header-left">
                    ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo" />` : ''}
                    <h1 style="margin:0; font-size: 28px;">${tenant.name}</h1>
                    <p style="margin:5px 0 0 0; font-size: 12px; opacity: 0.9;">${tenant.address}</p>
                </div>
                <div class="header-right">
                    <div style="background: white; color: #7c3aed; padding: 5px 15px; border-radius: 20px; font-size: 11px; font-weight: bold; display: inline-block; margin-bottom: 10px; text-transform: uppercase;">${isInvoice ? "Invoice" : "Quotation"}</div>
                    <h2 style="margin:0; font-size: 24px;">#${number}</h2>
                    <p style="font-size: 12px; margin-top: 5px; opacity: 0.9;">Date: <strong>${date}</strong><br>${dueDateLabel}: <strong>${dueDate}</strong></p>
                </div>
            </div>

            <div class="info-grid">
                <div class="info-box">
                    <div class="box-title">Billed To</div>
                    <strong style="font-size:18px;">${client.name}</strong>
                    <div style="font-size:13px; color:#4b5563; margin-top:5px;">
                        ${client.email}<br>${client.phone || ''}<br>${client.address}
                    </div>
                </div>
                <div class="info-box pink">
                    <div class="box-title pink">Payment Details</div>
                    <div style="font-size:13px; color:#4b5563;">
                        ${bankDetails.accountNumber ? `
                            ${bankDetails.accountName ? `Name: <strong>${bankDetails.accountName}</strong><br>` : ''}
                            Bank: <strong>${bankDetails.bankName}</strong><br>
                            A/C: <strong style="background:#f3f4f6; padding:2px 4px; border-radius:4px;">${bankDetails.accountNumber}</strong><br>
                            IFSC: <strong style="background:#f3f4f6; padding:2px 4px; border-radius:4px;">${bankDetails.ifscCode}</strong>
                        ` : 'No payment details available.'}
                    </div>
                </div>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Description</th>
                        <th style="text-align:center">Qty</th>
                        <th style="text-align:right">Rate</th>
                                       ${isGstEnabled ? '<th class="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>' : ''}
                        <th style="text-align:right">Amount</th>
                    </tr>
                </thead>
                <tbody>
                    ${invoice.items.map(item => `
                    <tr>
                        <td><strong>${item.description}</strong>${item.additionalDetails ? `<br><span style="font-size:11px; color:#6b7280;">${item.additionalDetails}</span>` : ''}</td>
                        <td style="text-align:center">${item.quantity}</td>
                        <td style="text-align:right">${formatCurrency(item.rate)}</td>
                                       ${isGst ? `
                                       <td class="text-right">
                                          ${item.gstRate ? item.gstRate + '%' : '-'}
                                       </td>` : ''}
                        <td style="text-align:right; font-weight:bold;">${formatCurrency(item.quantity * item.rate)}</td>
                    </tr>`).join('')}
                </tbody>
            </table>

            <div class="totals-wrapper">
                <div class="totals-box">
                    <div class="calc-row"><span>Subtotal</span><strong>${formatCurrency(invoice.subTotal)}</strong></div>
                    ${invoice.discountAmount > 0 ? `<div class="calc-row" style="color:#c026d3;"><span>Discount</span><span>- ${formatCurrency(invoice.discountAmount)}</span></div>` : ''}
                    ${invoice.gstEnabled ? `
                        <div style="border-top: 1px dashed #ede9fe; margin: 8px 0; padding-top: 8px;">
                            <div class="calc-row" style="margin-bottom: 5px; color: #444;">
                                <span>Total GST (${invoice.taxType || 'exclusive'})</span>
                                <span>+ ${formatCurrency(invoice.gstAmount)}</span>
                            </div>
                            ${invoice.gstBreakdown ? `
                                ${invoice.gstBreakdown.cgst > 0 ? `
                                    <div class="calc-row" style="font-size: 11px;">
                                        <span>CGST</span>
                                        <span>${formatCurrency(invoice.gstBreakdown.cgst)}</span>
                                    </div>
                                ` : ''}
                                ${invoice.gstBreakdown.sgst > 0 ? `
                                    <div class="calc-row" style="font-size: 11px;">
                                        <span>SGST</span>
                                        <span>${formatCurrency(invoice.gstBreakdown.sgst)}</span>
                                    </div>
                                ` : ''}
                                ${invoice.gstBreakdown.igst > 0 ? `
                                    <div class="calc-row" style="font-size: 11px;">
                                        <span>IGST</span>
                                        <span>${formatCurrency(invoice.gstBreakdown.igst)}</span>
                                    </div>
                                ` : ''}
                            ` : ''}
                        </div>
                    ` : ''}
                    
                    ${invoice.advancePayment > 0 ? `
                    <div class="calc-row" style="font-size:12px; margin-top:5px; color:#555;">
                        <span>Advance Paid</span>
                        <span>- ${formatCurrency(invoice.advancePayment)}</span>
                    </div>` : ''}

                    <div class="gradient-total" style="margin-top: 15px;">
                        <div style="display:flex; justify-content:space-between; align-items:center;">
                            <span>Total Payable</span>
                            <span style="font-size:22px; font-weight:bold;">${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer-fixed">
            <div class="terms">
                <strong style="color:#7c3aed; text-transform:uppercase; font-size:10px;">Terms & Conditions</strong><br>
                ${invoice.terms || tenant.defaultTerms || "Payment is due upon receipt."}
            </div>
            <div class="signature">
                ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:40px;"></div>'}
                <div style="border-top:2px solid #e5e7eb; padding-top:5px; font-weight:bold; font-size:12px;">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : tenant.name}</div>
                <div style="font-size:9px; color:#9ca3af; text-transform:uppercase; margin-top:2px;">Authorized Signatory</div>
            </div>
        </div>
    </body>
    </html>`;
};