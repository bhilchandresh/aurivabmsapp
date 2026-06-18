import React from 'react';

const ElegantTemplate = ({ data, tenant, type = 'invoice' }) => {
    // 1. DATA SAFE CHECK
    if (!data || !tenant) return null;

    const isInvoice = type === 'invoice';
    const number = isInvoice ? data.invoiceNumber : data.quotationNumber;
    const date = data.date;
    const dueDate = isInvoice ? data.dueDate : data.validUntil;
    const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
    const isGstEnabled = data.gstEnabled !== undefined ? data.gstEnabled : (Number(data.taxRate) > 0);

    // --- 2. FETCH BANK DETAILS (Fallback Logic) ---
    const bankDetails = (data?.bankDetailsSnapshot && data?.bankDetailsSnapshot?.accountNumber)
        ? data.bankDetailsSnapshot
        : tenant?.bankDetails;

    // --- 3. FETCH SIGNATURE (Fallback Logic) ---
    const signatureImage = data?.authorizedSignatoryImage || data?.salesPerson?.signatureImage || tenant?.signatureImage;

    // --- 4. CHECK IF HSN EXISTS IN ANY ITEM ---
    const showHsn = data.items && data.items.some(item => item.hsnCode && item.hsnCode.trim() !== "");

    // --- 5. NUMBER TO WORDS CONVERTER ---
    const convertNumberToWords = (amount) => {
        if (!amount || isNaN(amount)) return "Zero";
        const words = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
        const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

        const numToWords = (n) => {
            if (n === 0) return "";
            if (n < 20) return words[n];
            if (n < 100) return tens[Math.floor(n / 10)] + (n % 10 !== 0 ? " " + words[n % 10] : "");
            if (n < 1000) return words[Math.floor(n / 100)] + " Hundred" + (n % 100 !== 0 ? " and " + numToWords(n % 100) : "");
            if (n < 100000) return numToWords(Math.floor(n / 1000)) + " Thousand" + (n % 1000 !== 0 ? " " + numToWords(n % 1000) : "");
            if (n < 10000000) return numToWords(Math.floor(n / 100000)) + " Lakh" + (n % 100000 !== 0 ? " " + numToWords(n % 100000) : "");
            return numToWords(Math.floor(n / 10000000)) + " Crore" + (n % 10000000 !== 0 ? " " + numToWords(n % 10000000) : "");
        };

        const [rupees, paise] = Number(amount).toFixed(2).split('.');
        let res = "Rupees " + (Number(rupees) === 0 ? "Zero" : numToWords(Number(rupees)));
        if (Number(paise) > 0) {
            res += " and " + numToWords(Number(paise)) + " Paise";
        }
        return res + " Only";
    };

    // CALCULATIONS
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
    };

    const subTotal = data.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0);
    const discountPercentage = Number(data.discountPercentage) || 0;
    const discountAmount = subTotal * (discountPercentage / 100);
    const taxableAmount = subTotal - discountAmount;
    const taxRate = isGstEnabled ? (Number(data.taxRate) || 0) : 0;
    const taxAmount = taxableAmount * (taxRate / 100);
    const total = taxableAmount + taxAmount;
    const cgst = taxAmount / 2;
    const sgst = taxAmount / 2;
    const advance = Number(data.advancePayment) || 0;
    const balance = total - advance;

    return (
        <>
            <style>{`
        /* --- SMART PAGING & PRINT SETTINGS --- */
        @media print {
          @page { 
            size: A4; 
            margin: 0 !important; 
          }
          
          body, html { 
            margin: 0 !important; 
            padding: 0 !important; 
            background: white !important;
            -webkit-print-color-adjust: exact !important; 
            print-color-adjust: exact !important;
            font-family: 'Garamond', 'Georgia', serif; 
          }

          /* CRITICAL: Disable ALL shadows and filters that cause page-end leak */
          * { 
             box-shadow: none !important; 
             text-shadow: none !important; 
             -webkit-filter: none !important;
             filter: none !important;
          }

          .print-container { 
             width: 210mm !important; 
             margin: 0 auto;
             padding: 0;
             border: none !important;
             box-shadow: none !important;
             display: block !important;
          }

          /* Table Structure for Paging */
          table.main-table { 
            width: 100%; 
            border-collapse: separate; 
            border-spacing: 0; 
            table-layout: fixed;
          }
          thead { display: table-header-group; }
          tfoot { display: table-footer-group; }
          tbody { display: table-row-group; }
          
          /* Prevent breaks inside rows we want to keep together */
          tr { page-break-inside: auto; }
          .avoid-break { 
             page-break-inside: avoid !important; 
             break-inside: avoid !important;
          }

          /* Fixed footer logic */
          .footer-fixed { 
            position: fixed; 
            bottom: 0; 
            left: 0; 
            right: 0;
            width: 100%; 
            z-index: 10; 
            background: white; 
          }
          .footer-space { height: 60px; } 
        }

        /* WEB DISPLAY */
        @media screen {
           .footer-space { display: none; }
           .footer-fixed { position: relative; margin-top: auto; }
           .print-container { 
             display: flex; 
             flex-direction: column; 
             min-height: 297mm; 
             background: white;
           }
        }
      `}</style>

            {/* Main Container */}
            <div className="bg-white w-full mx-auto text-gray-800 font-serif  print-container">

                <div className="flex-1">
                    <table className="main-table w-full border-separate border-spacing-0">

                        {/* --- HEADER --- */}
                        <thead>
                            <tr>
                                <td>
                                    {/* Reduced Padding from p-12 pb-6 to p-8 pb-4 */}
                                    <div className="p-8 pb-4">
                                        {/* Reduced margin and padding here */}
                                        <div className="text-center border-b-2 border-gray-800 pb-4 mb-4">
                                            {tenant.logoImage && (
                                                <img
                                                    src={tenant.logoImage}
                                                    alt="Logo"
                                                    className="h-14 mx-auto mb-2 object-contain"
                                                />
                                            )}
                                            {/* Reduced font size slightly to save space */}
                                            <h1 className="text-xl font-bold tracking-widest uppercase text-gray-900">{tenant.name}</h1>
                                            <div className="text-[12px] text-gray-500 mt-1 space-y-0.5 uppercase tracking-wide font-medium">
                                                <p>{tenant.address}</p>
                                                <p>
                                                    {tenant.email} &bull; {tenant.phone}
                                                    {tenant.website && ` &bull; ${tenant.website}`}
                                                </p>
                                                {isGstEnabled && tenant.gstNumber && <p>GSTIN: {tenant.gstNumber}</p>}
                                            </div>
                                        </div>

                                        {/* Document Title & Meta */}
                                        <div className="flex flex-row justify-between items-end mb-2 gap-0">
                                            <div className="text-left">
                                                <h2 className="text-2xl font-thin text-gray-300 uppercase tracking-tighter -ml-1">
                                                    {isInvoice ? "Invoice" : "Quote"}
                                                </h2>
                                            </div>
                                            <div className="text-right w-auto">
                                                <p className="text-base font-bold text-gray-900">#{number}</p>
                                                <div className="text-xs text-gray-500 mt-1 flex flex-col items-end">
                                                    <p>
                                                        <span className="inline-block w-20">Date:</span>
                                                        <span className="font-semibold text-gray-800">{new Date(date).toLocaleDateString()}</span>
                                                    </p>
                                                    <p>
                                                        <span className="inline-block w-20">{dueDateLabel}:</span>
                                                        <span className="font-semibold text-gray-800">{new Date(dueDate).toLocaleDateString()}</span>
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        </thead>

                        {/* --- FOOTER SPACER --- */}
                        <tfoot>
                            <tr><td><div className="footer-space"></div></td></tr>
                        </tfoot>

                        {/* --- BODY --- */}
                        <tbody>

                            {/* ROW 1: Client & Bank Grid */}
                            <tr className="avoid-break">
                                {/* Padding reduced to px-8 */}
                                <td className="px-8 align-top">
                                    <div className="flex flex-row justify-between gap-8 mb-6">
                                        {/* Billed To */}
                                        <div className="w-[50%]">
                                            <h3 className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2 border-b border-gray-200 pb-1 w-fit">To</h3>
                                            <h2 className="text-lg font-bold text-gray-900 mb-1">{data.client.name}</h2>
                                            <div className="text-[12px] text-gray-600 space-y-0.5 leading-relaxed">
                                                <p className="whitespace-pre-line">{data.client.address}</p>
                                                <p>{data.client.email}</p>
                                                {data.client.phone && <p>{data.client.phone}</p>}
                                            </div>
                                            {isGstEnabled && data.client.gstNumber && (
                                                <p className="mt-2 text-[11px] font-bold text-gray-800 border border-gray-300 px-2 py-0.5 inline-block">GSTIN: {data.client.gstNumber}</p>
                                            )}
                                        </div>

                                        {/* Payment Info */}
                                        <div className="w-[50%] text-right ">
                                            <h3 className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2 border-b border-gray-200 pb-1 w-fit ml-auto">Pay To</h3>
                                            {bankDetails && bankDetails.accountNumber ? (
                                                <div className="text-[12px] text-gray-600 space-y-1">
                                                    {bankDetails.accountName && <p><span className="text-gray-400">Name:</span> <span className="font-bold text-gray-900">{bankDetails.accountName}</span></p>}
                                                    <p><span className="text-gray-400">Bank:</span> <span className="font-bold text-gray-900">{bankDetails.bankName}</span></p>
                                                    <p><span className="text-gray-400">A/C:</span> <span className="font-mono font-bold text-gray-900">{bankDetails.accountNumber}</span></p>
                                                    <p><span className="text-gray-400">IFSC:</span> <span className="font-mono font-bold text-gray-900">{bankDetails.ifscCode}</span></p>
                                                </div>
                                            ) : (
                                                <p className="text-xs text-gray-400 italic">Payment details not provided.</p>
                                            )}
                                        </div>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 2: Items Table */}
                            <tr>
                                <td className="px-8 align-top">
                                    <div className="mb-6 overflow-x-auto print:overflow-visible">
                                        <table className="w-full min-w-0 text-sm border-t-2 border-b-2 border-gray-800 table-fixed border-separate border-spacing-0">
                                            <thead>
                                                <tr className="text-gray-500 text-[11px] uppercase tracking-widest">
                                                    <th className="py-2 px-2 text-left font-normal w-[5%] border-b border-gray-200">No.</th>

                                                    {/* Description adjusts based on HSN */}
                                                    <th className={`py-2 px-2 text-left font-normal border-b border-gray-200 ${showHsn ? 'w-[35%]' : 'w-[50%]'}`}>Description</th>

                                                    {/* CONDITIONAL HSN HEADER */}
                                                    {showHsn && <th className="py-2 px-2 text-center font-normal w-[15%] border-b border-gray-200">HSN/SAC</th>}

                                                    <th className="py-2 px-2 text-center font-normal w-[10%] border-b border-gray-200">Qty</th>
                                                    <th className="py-2 px-2 text-right font-normal w-[15%] border-b border-gray-200">Price</th>
                                                    <th className="py-2 px-2 text-right font-normal w-[20%] border-b border-gray-200">Amount</th>
                                                </tr>
                                            </thead>
                                            <tbody className="divide-y divide-gray-100">
                                                {data.items.map((item, index) => (
                                                    <tr key={index} className="avoid-break">
                                                        <td className="py-3 px-2 text-gray-400 border-b border-gray-100 align-top break-words pt-3">0{index + 1}</td>
                                                        <td className="py-3 px-2 text-gray-800 border-b border-gray-100 align-top break-words pr-2 pt-3">
                                                            <p className="font-bold text-[13px]">{item.description}</p>
                                                            {item.additionalDetails && (
                                                                <p className="text-[10px] text-gray-500 mt-1 italic leading-relaxed">
                                                                    {item.additionalDetails}
                                                                </p>
                                                            )}
                                                        </td>

                                                        {/* CONDITIONAL HSN DATA */}
                                                        {showHsn && <td className="py-3 px-2 text-center text-gray-600 font-mono text-[11px] border-b border-gray-100 align-top break-words pt-3">{item.hsnCode || "-"}</td>}

                                                        <td className="py-3 px-2 text-center text-gray-600 border-b border-gray-100 align-top break-words pt-3">{item.quantity}</td>
                                                        <td className="py-3 px-2 text-right text-gray-600 border-b border-gray-100 align-top break-words pt-3">{formatCurrency(item.rate)}</td>
                                                        <td className="py-3 px-2 text-right font-bold text-gray-900 border-b border-gray-100 align-top break-words pt-3">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 3: Totals & Words */}
                            <tr className="avoid-break">
                                <td className="px-8 align-top pb-6">
                                    <div className="flex flex-row justify-between items-start w-full gap-8">

                                        {/* LEFT: AMOUNT IN WORDS */}
                                        <div className="w-[55%] mt-1">
                                            <h4 className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-1.5 border-b border-gray-200 w-fit pb-1">Amount In Words</h4>
                                            <p className="text-sm font-bold text-gray-800 leading-snug italic">
                                                {convertNumberToWords(total)}
                                            </p>
                                        </div>

                                        {/* RIGHT: TOTALS BOX */}
                                        <div className="w-[40%] flex flex-col items-end">
                                            <div className="w-full">
                                                {/* Subtotals */}
                                                <div className="space-y-1.5 text-xs text-gray-600 border-b border-gray-200 pb-3 mb-3">
                                                    <div className="flex justify-between"><span>Subtotal</span> <span className="font-medium text-gray-900">{formatCurrency(subTotal)}</span></div>

                                                    {discountAmount > 0 && (
                                                        <div className="flex justify-between text-red-500"><span>Discount ({discountPercentage}%)</span> <span>- {formatCurrency(discountAmount)}</span></div>
                                                    )}

                                                    {(isGstEnabled || discountAmount > 0) && (
                                                        <div className="flex justify-between text-gray-400 text-[10px] uppercase tracking-wider pt-1 border-t border-dashed border-gray-200">
                                                            <span>Taxable Value</span> <span>{formatCurrency(taxableAmount)}</span>
                                                        </div>
                                                    )}

                                                    {isGstEnabled && (
                                                        <div className="space-y-1">
                                                         {data.gstBreakdown ? (
                                                            <>
                                                               {data.gstBreakdown.cgst > 0 && (
                                                                  <div className="flex justify-between"><span>CGST</span><span>{formatCurrency(data.gstBreakdown.cgst)}</span></div>
                                                               )}
                                                               {data.gstBreakdown.sgst > 0 && (
                                                                  <div className="flex justify-between"><span>SGST</span><span>{formatCurrency(data.gstBreakdown.sgst)}</span></div>
                                                               )}
                                                               {data.gstBreakdown.igst > 0 && (
                                                                  <div className="flex justify-between"><span>IGST</span><span>{formatCurrency(data.gstBreakdown.igst)}</span></div>
                                                               )}
                                                            </>
                                                         ) : (
                                                            taxRate > 0 && (
                                                               <div className="flex justify-between"><span>GST ({taxRate}%)</span> <span>{formatCurrency(taxAmount)}</span></div>
                                                            )
                                                         )}
                                                        </div>
                                                    )}
                                                </div>

                                                {/* Grand Total */}
                                                <div className="flex justify-between items-center py-1">
                                                    <span className="text-base font-serif font-bold text-gray-900 uppercase tracking-widest">Total</span>
                                                    <span className="text-lg font-bold text-gray-900">{formatCurrency(total)}</span>
                                                </div>

                                                {advance > 0 && (
                                                    <div className="flex justify-between text-xs text-green-600 font-medium mt-1 border-b border-gray-200 pb-1">
                                                        <span>Less: Advance</span> <span>- {formatCurrency(advance)}</span>
                                                    </div>
                                                )}

                                                <div className="flex justify-between mt-2 bg-gray-900 text-white p-2.5 font-bold text-base shadow-lg" style={{ WebkitPrintColorAdjust: 'exact', backgroundColor: '#111827', color: 'white' }}>
                                                    <span>Balance Due</span> <span>{formatCurrency(balance)}</span>
                                                </div>
                                            </div>
                                        </div>

                                    </div>
                                </td>
                            </tr>

                            {/* ROW 4: Signature (Moved from footer) */}
                            <tr className="avoid-break">
                                <td className="px-8 pb-6">
                                    <div className="flex justify-end mt-4">
                                        <div className="text-right w-full w-1/3">
                                            <div className="h-14 mb-1 flex flex-col justify-end items-end">
                                                {signatureImage ? (
                                                    <img
                                                        src={signatureImage}
                                                        alt="Signature"
                                                        className="h-10 object-contain"
                                                    />
                                                ) : (
                                                    <div className="h-full w-28 border-b border-gray-300 flex items-end justify-center pb-1 text-[9px] text-gray-400 italic">Sign Here</div>
                                                )}
                                            </div>
                                            <p className="font-bold text-xs text-gray-900 uppercase tracking-wide">{tenant.name}</p>
                                            <p className="text-[9px] text-gray-400 uppercase tracking-widest mt-0.5">Authorized Signatory</p>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                {/* --- FOOTER --- */}
                <div className="footer-fixed px-8 pb-6 w-full bg-white mt-auto">
                    <div className="flex justify-between items-center border-t-4 border-double border-gray-200 pt-4">

                        {/* Terms Only */}
                        <div className="w-full pr-10">
                            <h4 className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-1.5">Terms & Conditions</h4>
                            <p className="text-[10px] text-gray-600 leading-relaxed whitespace-pre-wrap line-clamp-2">
                                {data.terms || tenant.defaultTerms || "Payment is due within 15 days. Please include invoice number on your check."}
                            </p>
                            {data.placeOfSupply && (
                                <p className="text-[10px] text-gray-500 mt-2 font-semibold">
                                    Place of Supply: {data.placeOfSupply} &nbsp;|&nbsp; Dispatch State: {tenant.state || "Not set"}
                                </p>
                            )}
                        </div>
                    </div>
                </div>

            </div>
        </>
    );
};

export default ElegantTemplate;