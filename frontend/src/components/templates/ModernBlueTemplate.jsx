import React from 'react';
import { Mail, Phone, MapPin, Globe, FileText, CreditCard, User } from 'lucide-react';

const ModernBlueTemplate = ({ data, tenant, type = 'invoice' }) => {
    if (!data || !tenant) return null;

    // --- DATA MAPPING ---
    const isInvoice = type === 'invoice';
    const docNumber = data.invoiceNumber || data.quotationNumber || "DRAFT";

    const date = data.date ? new Date(data.date).toLocaleDateString('en-IN') : '';
    const dueDate = data.dueDate ? new Date(data.dueDate).toLocaleDateString('en-IN') :
        (data.validUntil ? new Date(data.validUntil).toLocaleDateString('en-IN') : '');

    const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
    const isGstEnabled = data.gstEnabled !== undefined ? data.gstEnabled : (Number(data.taxRate) > 0);

    // Bank & Signature Fallbacks
    const bankDetails = (data?.bankDetailsSnapshot && data?.bankDetailsSnapshot?.accountNumber)
        ? data.bankDetailsSnapshot
        : tenant?.bankDetails;

    const signatureImage = data?.authorizedSignatoryImage ||
        (data?.salesPerson && data?.salesPerson?.signatureImage) ||
        tenant?.signatureImage;

    // --- 1. CHECK IF HSN EXISTS IN ANY ITEM ---
    const showHsn = data.items && data.items.some(item => item.hsnCode && item.hsnCode.trim() !== "");

    // --- NUMBER TO WORDS CONVERTER ---
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

    // Calculations
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
          .footer-space { height: 100px; } 
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

            {/* --- DOCUMENT CONTAINER --- */}
            <div className="bg-white w-full mx-auto font-sans  print-container text-slate-800">

                <div className="flex-1">
                    <table className="main-table w-full border-separate border-spacing-0">

                        {/* --- HEADER --- */}
                        <thead>
                            <tr>
                                <td>
                                    <div
                                        className="p-8 w-full"
                                        style={{
                                            background: 'linear-gradient(90deg, #0f172a 0%, #1e40af 100%)',
                                            backgroundColor: '#0f172a',
                                            color: 'white'
                                        }}
                                    >
                                        <div className="flex justify-between items-start">
                                            <div className="w-[60%] pr-4">
                                                {tenant.logoImage && (
                                                    <img
                                                        src={tenant.logoImage}
                                                        alt="Logo"
                                                        className="h-12 mb-3 object-contain"
                                                        style={{ maxWidth: '180px', display: 'block' }}
                                                    />
                                                )}
                                                <h1 className="text-2xl font-bold uppercase tracking-wide leading-tight mb-2 text-white" style={{ color: 'white' }}>{tenant.name}</h1>
                                                <div className="text-[11px] text-blue-100 opacity-90 leading-relaxed max-w-sm space-y-1">
                                                    <div className="flex items-start gap-2">
                                                        <MapPin className="w-3.5 h-3.5 mt-0.5 shrink-0" />
                                                        <span>{tenant.address}</span>
                                                    </div>
                                                    <div className="flex flex-wrap gap-3 mt-1 font-medium text-blue-50">
                                                        <span className="flex items-center gap-1"><Mail className="w-3 h-3" /> {tenant.email}</span>
                                                        {tenant.phone && <span className="flex items-center gap-1"><Phone className="w-3 h-3" /> {tenant.phone}</span>}
                                                        {tenant.website && <span className="flex items-center gap-1"><Globe className="w-3 h-3" /> {tenant.website}</span>}
                                                    </div>
                                                </div>
                                                {isGstEnabled && tenant.gstNumber && (
                                                    <div className="mt-2 inline-block border border-blue-400/50 px-2 py-0.5 rounded text-[9px] text-blue-100 font-semibold" style={{ borderColor: 'rgba(96, 165, 250, 0.5)', color: '#dbeafe' }}>
                                                        GSTIN: {tenant.gstNumber}
                                                    </div>
                                                )}
                                            </div>

                                            <div className="w-[40%] text-right">
                                                <div className="inline-block px-3 py-1 rounded text-[10px] font-bold uppercase tracking-[0.2em] mb-2"
                                                    style={{ backgroundColor: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)', color: 'white' }}>
                                                    {isInvoice ? "Invoice" : "Quotation"}
                                                </div>
                                                <p className="text-2xl font-mono font-bold tracking-tighter mb-2 opacity-95 text-white" style={{ color: 'white' }}>{docNumber}</p>
                                                <div className="text-blue-100 text-[11px] space-y-1">
                                                    <div className="flex justify-end gap-2">
                                                        <span className="opacity-70">Issued:</span>
                                                        <span className="text-white font-bold">{date}</span>
                                                    </div>
                                                    <div className="flex justify-end gap-2">
                                                        <span className="opacity-70">{dueDateLabel}:</span>
                                                        <span className="text-white font-bold">{dueDate}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    {/* Reduced spacer gap here */}
                                    <div className="h-4"></div>
                                </td>
                            </tr>
                        </thead>

                        {/* --- FOOTER SPACER --- */}
                        <tfoot>
                            <tr><td><div className="footer-space"></div></td></tr>
                        </tfoot>

                        {/* --- BODY (SPLIT INTO 3 ROWS FOR PERFECT PAGINATION) --- */}
                        <tbody>

                            {/* ROW 1: INFO GRID */}
                            <tr className="avoid-break">
                                <td className="px-8 align-top">
                                    <div className="flex justify-between gap-10 mb-6">

                                        {/* Billed To */}
                                        <div className="w-[50%]">
                                            <h3 className="text-[10px] font-bold text-blue-700 uppercase tracking-widest mb-2 flex items-center gap-2 border-b-2 border-blue-100 pb-1 w-fit">
                                                <User className="w-3 h-3" /> {isInvoice ? "Billed To" : "Quote To"}
                                            </h3>
                                            <h2 className="text-lg font-bold text-slate-900 mb-1">{data.client.name}</h2>
                                            <div className="text-[11px] text-slate-600 space-y-0.5 leading-relaxed">
                                                {data.client.address && <p className="whitespace-pre-line">{data.client.address}</p>}
                                                <p>{data.client.email}</p>
                                                {data.client.phone && <p>{data.client.phone}</p>}
                                            </div>
                                            {isGstEnabled && data.client.gstNumber && (
                                                <div className="mt-1.5 text-[10px] font-bold text-slate-800">
                                                    GSTIN: {data.client.gstNumber}
                                                </div>
                                            )}
                                        </div>

                                        {/* Payment Info */}
                                        <div className="w-[50%]">
                                            <h3 className="text-[10px] font-bold text-emerald-700 uppercase tracking-widest mb-2 flex items-center gap-2 border-b-2 border-emerald-100 pb-1 w-fit">
                                                <CreditCard className="w-3 h-3" /> Payment Info
                                            </h3>
                                            <div className="text-[11px] space-y-1 text-slate-700">
                                                {bankDetails && bankDetails.accountNumber ? (
                                                    <>
                                                        {bankDetails.accountName && (
                                                            <div className="flex items-center gap-2">
                                                                <span className="text-slate-500 w-16">Name:</span>
                                                                <span className="font-bold text-slate-900">{bankDetails.accountName}</span>
                                                            </div>
                                                        )}
                                                        <div className="flex items-center gap-2">
                                                            <span className="text-slate-500 w-16">Bank:</span>
                                                            <span className="font-bold text-slate-900">{bankDetails.bankName}</span>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="text-slate-500 w-16">Acc No:</span>
                                                            <span className="font-mono font-bold text-slate-900">{bankDetails.accountNumber}</span>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="text-slate-500 w-16">IFSC:</span>
                                                            <span className="font-mono font-bold text-slate-900">{bankDetails.ifscCode}</span>
                                                        </div>
                                                    </>
                                                ) : (
                                                    <p className="text-[11px] text-slate-400 italic">No bank details added.</p>
                                                )}
                                            </div>

                                            {isGstEnabled && tenant.gstNumber && (
                                                <div className="mt-2 text-[10px] pt-1.5 border-t border-slate-100 inline-block">
                                                    <span className="text-slate-500">Co. GSTIN:</span> <span className="font-bold text-slate-900">{tenant.gstNumber}</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 2: ITEMS TABLE */}
                            <tr>
                                <td className="px-8 align-top">
                                    <div className="border border-slate-200 rounded-lg overflow-hidden mb-4">
                                        <table className="w-full text-xs table-fixed border-separate border-spacing-0">
                                            <thead style={{ backgroundColor: '#f8fafc', color: '#0f172a' }}>
                                                <tr>
                                                    <th className="py-2 px-2 text-center border-b border-slate-200 w-[5%] font-bold uppercase tracking-wider text-[9px]">#</th>

                                                    <th className={`py-2 px-2 text-left border-b border-slate-200 font-bold uppercase tracking-wider text-[9px] ${showHsn ? 'w-[35%]' : 'w-[50%]'}`}>Description</th>

                                                    {showHsn && <th className="py-2 px-2 text-center border-b border-slate-200 w-[15%] font-bold uppercase tracking-wider text-[9px]">HSN/SAC</th>}

                                                    <th className="py-2 px-2 text-center border-b border-slate-200 w-[10%] font-bold uppercase tracking-wider text-[9px]">Qty</th>
                                                    <th className="py-2 px-2 text-right border-b border-slate-200 w-[15%] font-bold uppercase tracking-wider text-[9px]">Rate</th>
                                                    <th className="py-2 px-2 text-right border-b border-slate-200 w-[20%] font-bold uppercase tracking-wider text-[9px]">Amount</th>
                                                </tr>
                                            </thead>
                                            <tbody className="divide-y divide-slate-100">
                                                {data.items.map((item, index) => (
                                                    <tr key={index} className="bg-white avoid-break">
                                                        <td className="py-3 px-2 text-center text-slate-400 align-top break-words">{index + 1}</td>
                                                        <td className="py-3 px-2 text-slate-800 align-top break-words pr-2">
                                                            <p className="font-bold text-[11px]">{item.description}</p>
                                                            {item.additionalDetails && (
                                                                <p className="text-[9px] text-slate-500 mt-0.5 whitespace-pre-wrap leading-relaxed">
                                                                    {item.additionalDetails}
                                                                </p>
                                                            )}
                                                        </td>

                                                        {showHsn && <td className="py-3 px-2 text-center text-slate-500 font-mono text-[10px] align-top break-words">{item.hsnCode || "-"}</td>}

                                                        <td className="py-3 px-2 text-center text-slate-600 font-medium text-[11px] align-top break-words">{item.quantity}</td>
                                                        <td className="py-3 px-2 text-right text-slate-600 font-medium text-[11px] align-top break-words">{formatCurrency(item.rate)}</td>
                                                        <td className="py-3 px-2 text-right font-bold text-slate-900 text-[11px] align-top break-words">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 3: TOTALS, WORDS & SIGNATURE (COMPACTED) */}
                            <tr className="avoid-break">
                                <td className="px-8 align-top pb-4">
                                    <div className="flex justify-between items-start w-full gap-4">

                                        {/* LEFT: AMOUNT IN WORDS */}
                                        <div className="w-[55%] mt-1 bg-slate-50 p-3 border border-slate-200 rounded-lg" style={{ backgroundColor: '#f8fafc' }}>
                                            <p className="text-[9px] text-slate-500 uppercase tracking-widest font-bold mb-1">Total Amount (In Words)</p>
                                            <p className="text-[11px] font-bold text-slate-800 leading-snug">
                                                {convertNumberToWords(total)}
                                            </p>
                                        </div>

                                        {/* RIGHT: TOTALS BOX */}
                                        <div className="w-[40%] flex flex-col items-end">

                                            {/* Totals Box */}
                                            <div className="w-full rounded-lg border border-slate-200 p-3" style={{ backgroundColor: '#f8fafc' }}>
                                                <div className="space-y-1.5 text-[10px] pb-2">
                                                    <div className="flex justify-between text-slate-600"><span>Subtotal</span> <span className="font-medium text-slate-900">{formatCurrency(subTotal)}</span></div>

                                                    {discountAmount > 0 && (
                                                        <div className="flex justify-between text-red-600 font-medium">
                                                            <span>Discount ({discountPercentage}%)</span>
                                                            <span>- {formatCurrency(discountAmount)}</span>
                                                        </div>
                                                    )}

                                                    {isGstEnabled && (
                                                        <>
                                                            <div className="flex justify-between text-slate-600">
                                                                <span>Taxable</span> <span>{formatCurrency(taxableAmount)}</span>
                                                            </div>
                                                            {data.gstBreakdown ? (
                                                                <>
                                                                    {data.gstBreakdown.cgst > 0 && (
                                                                        <div className="flex justify-between text-slate-500">
                                                                            <span>CGST</span> <span>{formatCurrency(data.gstBreakdown.cgst)}</span>
                                                                        </div>
                                                                    )}
                                                                    {data.gstBreakdown.sgst > 0 && (
                                                                        <div className="flex justify-between text-slate-500">
                                                                            <span>SGST</span> <span>{formatCurrency(data.gstBreakdown.sgst)}</span>
                                                                        </div>
                                                                    )}
                                                                    {data.gstBreakdown.igst > 0 && (
                                                                        <div className="flex justify-between text-slate-500">
                                                                            <span>IGST</span> <span>{formatCurrency(data.gstBreakdown.igst)}</span>
                                                                        </div>
                                                                    )}
                                                                </>
                                                            ) : (
                                                                taxRate > 0 && (
                                                                    <div className="flex justify-between text-slate-500">
                                                                        <span>GST ({taxRate}%)</span> <span>{formatCurrency(taxAmount)}</span>
                                                                    </div>
                                                                )
                                                            )}
                                                        </>
                                                    )}
                                                </div>

                                                {/* Bold Total Line */}
                                                <div className="flex justify-between items-center py-1.5 border-y border-slate-200 my-1">
                                                    <span className="text-[10px] font-bold uppercase tracking-widest text-slate-900">Total</span>
                                                    <span className="text-base font-black text-blue-700">{formatCurrency(total)}</span>
                                                </div>

                                                {advance > 0 && (
                                                    <div className="flex justify-between text-[10px] text-green-700 font-bold pt-1">
                                                        <span>Advance Paid</span> <span>- {formatCurrency(advance)}</span>
                                                    </div>
                                                )}

                                                {advance > 0 && (
                                                    <div className="flex justify-between pt-1">
                                                        <span className="text-[11px] font-bold text-slate-900">Balance Due</span>
                                                        <span className="text-[11px] font-bold text-slate-900">{formatCurrency(balance)}</span>
                                                    </div>
                                                )}
                                            </div>

                                            {/* Signature Area EXACTLY below Totals */}
                                            <div className="mt-3 w-full flex flex-col items-center">
                                                {signatureImage ? (
                                                    <img
                                                        src={signatureImage}
                                                        alt="Sign"
                                                        className="h-10 object-contain"
                                                        style={{ display: 'block' }}
                                                    />
                                                ) : (
                                                    <div className="h-10 w-28 border border-dashed border-gray-300 mb-1 flex items-center justify-center text-[9px] text-gray-400">Sign Here</div>
                                                )}
                                                <div className="border-t border-slate-300 pt-1 w-40 text-center">
                                                    <p className="font-bold text-slate-900 text-[10px] truncate">{data.salesPerson?.name || tenant.name}</p>
                                                    <p className="text-[8px] text-slate-400 uppercase tracking-widest font-bold mt-0.5">Authorized Signatory</p>
                                                </div>
                                            </div>

                                        </div>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                {/* --- FIXED FOOTER (Terms are now here at the bottom) --- */}
                <div className="footer-fixed w-full bg-white mt-auto">
                    <div className="px-8 pb-4">
                        {/* Terms Section */}
                        <div className="border-t border-slate-200 pt-2 mb-2">
                            <h4 className="text-[9px] font-bold text-slate-500 uppercase tracking-widest mb-1 flex items-center gap-1">
                                <FileText size={10} /> Terms & Conditions
                            </h4>
                            <p className="text-[9px] text-slate-600 leading-relaxed whitespace-pre-wrap line-clamp-2">
                                {data.terms || tenant.defaultTerms || "Payment is due upon receipt."}
                            </p>
                            {data.placeOfSupply && (
                                <p className="text-[9px] text-slate-500 mt-2 font-semibold">
                                    Place of Supply: {data.placeOfSupply} &nbsp;|&nbsp; Dispatch State: {tenant.state || "Not set"}
                                </p>
                            )}
                        </div>

                        {/* Bottom Brand Bar */}
                        <div className="h-1 w-full rounded-full" style={{ background: 'linear-gradient(90deg, #0f172a 0%, #1e40af 100%)', WebkitPrintColorAdjust: 'exact' }}></div>

                        <p className="text-center text-[8px] text-slate-400 mt-1.5 font-bold uppercase tracking-widest">
                            {tenant.address ? tenant.address.replace(/\n/g, ', ') : 'Thank you for your business'}
                        </p>
                    </div>
                </div>

            </div>
        </>
    );
};

export default ModernBlueTemplate;