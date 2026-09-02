module.exports = (invoice) => {
    const formatCurrency = (amount) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amount);
    const date = new Date(invoice.date).toLocaleDateString('en-IN');
    const dueDate = invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN') : 'N/A';
    const tenant = invoice.tenantId || {};
    const signatureImage = invoice.authorizedSignatoryImage || (invoice.salesPerson && invoice.salesPerson.signatureImage) || tenant.signatureImage;

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { font-family: 'Courier New', Courier, monospace; color: #000; padding: 40px; }
        .header { text-align: center; margin-bottom: 50px; border-bottom: 1px dashed #000; padding-bottom: 20px; }
        .logo { max-height: 60px; display: block; margin: 0 auto 10px auto; }
        h1 { font-size: 30px; margin: 0; text-transform: uppercase; letter-spacing: 5px; }
        .meta { margin-top: 10px; font-size: 12px; }
        
        .client-info { margin-bottom: 30px; }
        .section-title { font-size: 10px; font-weight: bold; text-transform: uppercase; border-bottom: 1px solid #000; display: inline-block; margin-bottom: 5px; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { text-align: left; border-bottom: 1px solid #000; padding: 10px 0; font-size: 12px; text-transform: uppercase; }
        td { padding: 10px 0; border-bottom: 1px solid #eee; font-size: 14px; }
        .text-right { text-align: right; }
        
        .totals { margin-top: 30px; float: right; width: 40%; text-align: right; }
        .total-row { padding: 5px 0; font-size: 14px; }
        .grand-total { font-size: 20px; font-weight: bold; border-top: 2px solid #000; margin-top: 10px; padding-top: 10px; }
        
        .signature-section { clear: both; margin-top: 60px; text-align: right; }
        .sign-img { max-height: 60px; display: inline-block; margin-bottom: 5px; }
        .sign-line { border-top: 1px solid #000; width: 200px; display: inline-block; margin-top: 5px; }
        .sign-text { font-size: 12px; margin-top: 5px; }
    </style>
    </head>
    <body>
        <div class="header">
            ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo" />` : ''}
            <h1>Invoice</h1>
            <div class="meta">#${invoice.invoiceNumber} | ${date}</div>
        </div>

        <div class="client-info">
            <div class="section-title">Billed To</div>
            <p style="margin: 5px 0; font-weight: bold;">${invoice.client.name}</p>
            <p style="margin: 0;">${invoice.client.email}</p>
        </div>

        <table>
            <thead>
                <tr>
                    <th>Description</th>
                    <th class="text-right">Qty</th>
                    <th class="text-right">Rate</th>
                                       ${isGst ? '<th class="text-right">GST</th>' : ''}
                    <th class="text-right">Total</th>
                </tr>
            </thead>
            <tbody>
                ${invoice.items.map(item => `
                <tr>
                    <td>${item.description}</td>
                    <td class="text-right">${item.quantity}</td>
                    <td class="text-right">${formatCurrency(item.rate)}</td>
                                       ${isGst ? `
                                       <td class="text-right">
                                          ${item.gstRate ? item.gstRate + '%' : '-'}
                                       </td>` : ''}
                    <td class="text-right">${formatCurrency(item.quantity * item.rate)}</td>
                </tr>`).join('')}
            </tbody>
        </table>

        <div class="totals">
            <div class="total-row">Subtotal: ${formatCurrency(invoice.subTotal)}</div>
            ${invoice.discountAmount > 0 ? `<div class="total-row">Discount: - ${formatCurrency(invoice.discountAmount)}</div>` : ''}
            
            ${invoice.gstEnabled ? `
                <div class="total-row">Total GST (${invoice.taxType || 'exclusive'}): + ${formatCurrency(invoice.gstAmount)}</div>
                ${invoice.gstBreakdown ? `
                    ${invoice.gstBreakdown.cgst > 0 ? `<div class="total-row">CGST: ${formatCurrency(invoice.gstBreakdown.cgst)}</div>` : ''}
                    ${invoice.gstBreakdown.sgst > 0 ? `<div class="total-row">SGST: ${formatCurrency(invoice.gstBreakdown.sgst)}</div>` : ''}
                    ${invoice.gstBreakdown.igst > 0 ? `<div class="total-row">IGST: ${formatCurrency(invoice.gstBreakdown.igst)}</div>` : ''}
                ` : ''}
            ` : ''}
            
            ${invoice.advancePayment > 0 ? `<div class="total-row">Advance Paid: - ${formatCurrency(invoice.advancePayment)}</div>` : ''}
            <div class="grand-total">Total Payable: ${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</div>
        </div>

        <div class="signature-section">
            <div>${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}</div>
            <div class="sign-line"></div>
            <div class="sign-text">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : (tenant.name || 'Authorized Signatory')}</div>
        </div>
    </body>
    </html>`;
};