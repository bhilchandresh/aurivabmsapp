module.exports = (invoice) => {
    // 1. Formatters
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
    };
    const formatDate = (date) => new Date(date).toLocaleDateString('en-IN');

    // 2. Data Fallbacks
    const tenant = invoice.tenantId || {};
    const client = invoice.client || {};
    const isInvoice = !!invoice.invoiceNumber;
    const docNumber = invoice.invoiceNumber || invoice.quotationNumber || "DRAFT";
    const title = isInvoice ? "INVOICE" : "QUOTATION";
    const dateLabel = isInvoice ? "Due Date" : "Valid Until";
    
    const issueDate = invoice.date ? formatDate(invoice.date) : '';
    const dueDate = invoice.dueDate ? formatDate(invoice.dueDate) : (invoice.validUntil ? formatDate(invoice.validUntil) : '');

    const bankDetails = (invoice.bankDetailsSnapshot && invoice.bankDetailsSnapshot.accountNumber) 
                        ? invoice.bankDetailsSnapshot : (tenant.bankDetails || {});
    
    const signatureImage = invoice.authorizedSignatoryImage || 
                          (invoice.salesPerson && invoice.salesPerson.signatureImage) || 
                          tenant.signatureImage;

    // Calculations
    const subTotal = invoice.subTotal || 0;
    const discountAmount = invoice.discountAmount || 0;
    const taxAmount = invoice.gstAmount || invoice.taxAmount || 0;
    const total = invoice.totalAmount || 0;
    const advance = Number(invoice.advancePayment) || 0;
    const balance = total - advance;

    return `
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        @page { size: A4; margin: 0; }
        
        body { 
            font-family: 'Helvetica', sans-serif; 
            margin: 0; 
            padding: 0; 
            color: #333; 
            -webkit-print-color-adjust: exact !important; 
            print-color-adjust: exact !important; 
        }

        * {
            -webkit-print-color-adjust: exact !important; 
            print-color-adjust: exact !important;
        }

        .container { padding-bottom: 150px; width: 100%; }
        .content-padding { padding: 0 40px; }

        /* HEADER */
        .header {
            background: linear-gradient(90deg, #0f172a 0%, #1e40af 100%) !important;
            color: white !important;
            padding: 40px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }

        .header * { color: white !important; }
        .logo { height: 60px; margin-bottom: 15px; object-fit: contain; }
        .company-name { font-size: 28px; font-weight: bold; text-transform: uppercase; margin: 0; }
        .doc-badge {
            background: rgba(255,255,255,0.15) !important;
            border: 1px solid rgba(255,255,255,0.3);
            padding: 5px 15px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
            display: inline-block;
            margin-bottom: 10px;
        }
        .doc-number { font-size: 32px; font-weight: bold; margin: 0; font-family: monospace; }

        /* INFO GRID */
        .info-grid { display: flex; justify-content: space-between; margin-top: 30px; margin-bottom: 30px; }
        .info-box { 
            width: 48%; 
            background-color: #f8fafc !important; 
            border: 1px solid #e2e8f0; 
            border-radius: 8px; 
            padding: 15px; 
        }
        .box-title { font-size: 10px; font-weight: bold; color: #64748b; text-transform: uppercase; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; margin-bottom: 8px; }
        .client-name { font-size: 16px; font-weight: bold; color: #0f172a; margin: 0 0 3px 0; }
        .text-sm { font-size: 12px; color: #475569; line-height: 1.4; }

        /* TABLE */
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 12px; border: 1px solid #e2e8f0; }
        th { 
            background-color: #eff6ff !important; 
            color: #1e3a8a !important; 
            padding: 12px; 
            text-align: left; 
            font-weight: bold; 
            text-transform: uppercase; 
            border-bottom: 1px solid #bfdbfe; 
        }
        td { padding: 12px; border-bottom: 1px solid #f1f5f9; color: #333; vertical-align: top; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }

        /* --- RIGHT ALIGNED STACK (TOTALS + SIGN) --- */
        .right-stack-container {
            display: flex;
            justify-content: flex-end; /* Push to right */
            margin-top: 20px;
            page-break-inside: avoid;
        }

        .right-stack {
            width: 45%; /* Control width of total & sign */
            display: flex;
            flex-direction: column;
            gap: 40px; /* Space between Total box and Signature */
        }

        /* Total Box */
        .total-box { 
            background-color: #f8fafc !important; 
            border: 1px solid #e2e8f0; 
            border-radius: 8px; 
            padding: 15px; 
        }
        .total-row { display: flex; justify-content: space-between; font-size: 12px; color: #64748b; margin-bottom: 6px; }
        .grand-total { border-top: 1px solid #cbd5e1; padding-top: 8px; margin-top: 8px; font-size: 16px; font-weight: bold; color: #1e3a8a; display: flex; justify-content: space-between; }
        .balance-due { background-color: #fff !important; border: 1px solid #cbd5e1; padding: 5px; border-radius: 4px; font-weight: bold; color: #000; margin-top: 8px; display: flex; justify-content: space-between; }

        /* Signature Box */
        .signature-box { 
            text-align: center; 
            margin-top: 20px;
        }
        .sign-img { height: 70px; object-fit: contain; mix-blend-mode: multiply; margin-bottom: 5px; }
        .sign-line { border-top: 1px solid #94a3b8; width: 100%; margin-top: 5px; }
        .sign-text { font-size: 10px; font-weight: bold; text-transform: uppercase; color: #64748b; margin-top: 5px; }
        .sign-name { font-size: 12px; font-weight: bold; color: #0f172a; }

        /* Footer Fixed at Bottom */
        .footer { 
            position: fixed; 
            bottom: 0; 
            left: 0; 
            width: 100%; 
            background: white; 
            z-index: 10; 
            border-top: 1px solid #e2e8f0; 
        }
        .footer-content { 
            padding: 20px 40px; 
        }
        .terms-title { font-size: 11px; font-weight: bold; color: #64748b; text-transform: uppercase; margin-bottom: 5px; }
        .terms-text { font-size: 10px; color: #475569; text-align: justify; line-height: 1.4; white-space: pre-wrap; }
        
        .brand-bar { 
            height: 6px; 
            background: linear-gradient(90deg, #0f172a 0%, #1e40af 100%) !important; 
            width: 100%; 
        }
        .footer-address { text-align: center; font-size: 10px; color: #94a3b8; padding: 8px; }

    </style>
    </head>
    <body>
        <div class="container">
            
            <!-- Header -->
            <div class="header">
                <div style="width: 60%;">
                    ${tenant.logoImage ? `<img src="${tenant.logoImage}" class="logo" />` : ''}
                    <h1 class="company-name">${tenant.name}</h1>
                    <div class="company-details">
                        <div>${tenant.address}</div>
                        <div>${tenant.email} | ${tenant.phone}</div>
                    </div>
                </div>
                <div style="width: 40%; text-align: right;">
                    <div class="doc-badge">${title}</div>
                    <h2 class="doc-number">#${docNumber}</h2>
                    <div class="doc-dates">
                        <div>Issued: <strong>${issueDate}</strong></div>
                        <div>${dateLabel}: <strong>${dueDate}</strong></div>
                    </div>
                </div>
            </div>

            <div class="content-padding">
                
                <!-- Info Grid -->
                <div class="info-grid">
                    <div class="info-box">
                        <div class="box-title">Billed To</div>
                        <div class="client-name">${client.name}</div>
                        <div class="text-sm">
                            ${client.email}<br>
                            ${client.phone}<br>
                            ${client.address}
                        </div>
                        ${invoice.gstEnabled && client.gstNumber ? `<div style="margin-top:5px; font-weight:bold; font-size:11px;">GSTIN: ${client.gstNumber}</div>` : ''}
                    </div>

                    <div class="info-box">
                        <div class="box-title">Payment Info</div>
                        <div class="text-sm">
                            ${bankDetails.accountNumber ? `
                                ${bankDetails.accountName ? `<div>Name: <strong>${bankDetails.accountName}</strong></div>` : ''}
                                <div>Bank: <strong>${bankDetails.bankName}</strong></div>
                                <div>A/C: <span style="font-family:monospace;">${bankDetails.accountNumber}</span></div>
                                <div>IFSC: <span style="font-family:monospace;">${bankDetails.ifscCode}</span></div>
                            ` : 'No bank details added.'}
                        </div>
                        ${tenant.gstNumber ? `<div style="margin-top:8px; font-size:11px;"><strong>Co. GSTIN:</strong> ${tenant.gstNumber}</div>` : ''}
                    </div>
                </div>

                <!-- Items Table -->
                <table>
                    <thead>
                        <tr>
                            <th width="45%">Description</th>
                            <th class="text-center">Qty</th>
                            <th class="text-right">Rate</th>
                                       ${isGstEnabled ? '<th class="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>' : ''}
                            <th class="text-right">Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${invoice.items.map(item => `
                        <tr>
                            <td>
                                <strong>${item.description}</strong>
                                ${item.additionalDetails ? `<br><span style="color:#666; font-size:10px;">${item.additionalDetails}</span>` : ''}
                            </td>
                            <td class="text-center">${item.quantity}</td>
                            <td class="text-right">${formatCurrency(item.rate)}</td>
                            <td class="text-right"><strong>${formatCurrency(item.quantity * item.rate)}</strong></td>
                        </tr>`).join('')}
                    </tbody>
                </table>

                <!-- RIGHT ALIGNED STACK (TOTALS -> THEN SIGNATURE) -->
                <div class="right-stack-container">
                    <div class="right-stack">
                        
                        <!-- 1. Totals Box -->
                        <div class="total-box">
                            <div class="total-row">
                                <span>Subtotal</span>
                                <span>${formatCurrency(invoice.subTotal)}</span>
                            </div>
                            ${discountAmount > 0 ? `
                            <div class="total-row" style="color: #ef4444;">
                                <span>Discount (${invoice.discountPercentage}%)</span>
                                <span>- ${formatCurrency(discountAmount)}</span>
                            </div>` : ''}
                            
                            ${invoice.gstEnabled ? `
                            <div style="border-top: 1px dashed #cbd5e1; margin: 8px 0; padding-top: 8px;">
                                <div class="total-row" style="margin-bottom: 5px; color: #444;">
                                    <span>Total GST (${invoice.taxType || 'exclusive'})</span>
                                    <span>+ ${formatCurrency(invoice.gstAmount)}</span>
                                </div>
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

                            ${invoice.advancePayment > 0 ? `
                            <div class="total-row" style="margin-top:5px; font-style:italic; font-size:12px; color:#64748b;">
                                <span>Advance Paid</span>
                                <span>- ${formatCurrency(invoice.advancePayment)}</span>
                            </div>` : ''}
                        </div>
                        
                        <!-- 2. Final Amount Box -->
                        <div class="grand-total-box">
                            <span>Total Payable</span>
                            <span>${formatCurrency(invoice.totalAmount - (invoice.advancePayment || 0))}</span>
                        </div>

                        <!-- 2. Signature Box (Placed Directly Below Totals) -->
                        <div class="signature-box">
                            ${signatureImage ? `<img src="${signatureImage}" class="sign-img" />` : '<div style="height:60px;"></div>'}
                            <div class="sign-line"></div>
                            <div class="sign-name">${(invoice.salesPerson && invoice.salesPerson.name) ? invoice.salesPerson.name : tenant.name}</div>
                            <div class="sign-text">Authorized Signatory</div>
                        </div>

                    </div>
                </div>

            </div>

            <!-- Footer (Fixed at Bottom with Terms) -->
            <div class="footer">
                <div class="footer-content">
                    <div class="terms-title">Terms & Conditions</div>
                    <div class="terms-text">
                        ${invoice.terms || tenant.defaultTerms || "Payment is due upon receipt."}
                    </div>
                </div>
                <div class="brand-bar"></div>
                <div class="footer-address">
                    ${tenant.address ? tenant.address.split('\n')[0] : 'Thank you for your business'}
                </div>
            </div>
        </div>
    </body>
    </html>`;
};