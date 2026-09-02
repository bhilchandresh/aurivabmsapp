import React from 'react';
import { Mail, Phone, Globe, MapPin, Building2, FileText, CreditCard, User } from 'lucide-react';

const VibrantTemplate = ({ data, tenant, type = 'invoice' }) => {
    if (!data || !tenant) return null;

    const isInvoice = type === 'invoice';
    const number = isInvoice ? data.invoiceNumber : data.quotationNumber;
    const date = data.date;
    const dueDate = isInvoice ? data.dueDate : data.validUntil;
    const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
    const isGstEnabled = data.gstEnabled !== undefined ? data.gstEnabled : (Number(data.taxRate) > 0);

    const bankDetails = (data?.bankDetailsSnapshot && data?.bankDetailsSnapshot?.accountNumber)
        ? data.bankDetailsSnapshot : tenant?.bankDetails;
    const signatureImage = data?.authorizedSignatoryImage || data?.salesPerson?.signatureImage || tenant?.signatureImage;

    // --- 1. CHECK IF HSN EXISTS IN ANY ITEM ---
    const showHsn = data.items && data.items.some(item => item.hsnCode && item.hsnCode.trim() !== "");

    // --- 2. NUMBER TO WORDS CONVERTER ---
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

    const formatCurrency = (amount) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);

    // Use backend calculated values or fallback
  const subTotal = Number(data.subTotal) || data.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0);
  const discountPercentage = Number(data.discountPercentage) || 0;
  const discountAmount = Number(data.discountAmount) || (subTotal * (discountPercentage / 100));
  const taxableAmount = Number(data.taxableAmount) || (subTotal - discountAmount);
  const taxRate = isGstEnabled ? (Number(data.taxRate) || 0) : 0;
  const taxAmount = Number(data.gstAmount) || (taxableAmount * (taxRate / 100));
  const cgst = data.gstBreakdown?.cgst || taxAmount / 2;
  const sgst = data.gstBreakdown?.sgst || taxAmount / 2;
  const igst = data.gstBreakdown?.igst || 0;
  const total = Number(data.totalAmount) || (taxableAmount + taxAmount);
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

          /* Force Background Colors & Gradients */
          .force-bg {
             -webkit-print-color-adjust: exact !important; 
             print-color-adjust: exact !important;
          }

          /* Hide Decorative Blobs in Print to avoid clutter */
          .decorative-blob { display: none !important; }

          /* Remove Backdrop Blur (Causes rendering issues in PDF) */
          .backdrop-blur-md, .backdrop-blur-sm { 
            backdrop-filter: none !important; 
            background: rgba(255, 255, 255, 0.2) !important; /* Fallback for transparency */
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

            <div className="bg-white w-full mx-auto text-gray-800 font-sans print-container relative overflow-hidden">

                {/* Background Decorative Blobs (Hidden in Print) */}
                <div className="decorative-blob absolute top-[-100px] left-[-100px] w-96 h-96 bg-fuchsia-100 rounded-full mix-blend-multiply filter blur-3xl opacity-50 z-0"></div>
                <div className="decorative-blob absolute top-[-50px] right-[-50px] w-72 h-72 bg-violet-100 rounded-full mix-blend-multiply filter blur-3xl opacity-50 z-0"></div>

                <div className="flex-1 z-10 relative">
                    <table className="main-table w-full border-separate border-spacing-0">

                        {/* --- HEADER --- */}
                        <thead>
                            <tr>
                                <td>
                                    <div className="p-8 pb-4">
                                        <div className="force-bg bg-gradient-to-br from-violet-600 to-fuchsia-600 rounded-3xl p-8 text-white"
                                            style={{ backgroundColor: '#7c3aed', background: 'linear-gradient(135deg, #7c3aed 0%, #c026d3 100%)', color: 'white' }}>

                                            <div className="flex flex-row justify-between items-start gap-0">
                                                <div className="w-[60%]">
                                                    {tenant.logoImage && (
                                                        <div className="bg-white/20 p-2 rounded-xl inline-block mb-3">
                                                            <img src={tenant.logoImage} alt="Logo" className="h-12 object-contain" />
                                                        </div>
                                                    )}
                                                    <h1 className="text-2xl font-black tracking-tight text-white">{tenant.name}</h1>
                                                    <p className="text-violet-50 text-[11px] mt-1 opacity-90 max-w-sm leading-relaxed">{tenant.address}</p>

                                                    <div className="flex flex-wrap gap-4 mt-3 text-[10px] font-medium text-white bg-white/20 w-fit px-3 py-1.5 rounded-lg border border-white/20">
                                                        {tenant.email && <span className="flex items-center gap-1"><Mail size={12} /> {tenant.email}</span>}
                                                        {tenant.phone && <span className="flex items-center gap-1"><Phone size={12} /> {tenant.phone}</span>}
                                                        {tenant.website && <span className="flex items-center gap-1"><Globe size={12} /> {tenant.website}</span>}
                                                    </div>
                                                    {isGstEnabled && tenant.gstNumber && (
                                                        <div className="mt-2 text-[9px] font-bold text-white bg-white/20 px-2 py-0.5 rounded-lg border border-white/20 inline-block">
                                                            GSTIN: {tenant.gstNumber}
                                                        </div>
                                                    )}
                                                </div>

                                                <div className="w-[40%] text-right  border-t border-white/20 border-none ">
                                                    <div className="bg-white text-violet-700 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest inline-block mb-3">
                                                        {isInvoice ? "Invoice" : "Quotation"}
                                                    </div>
                                                    <p className="text-2xl font-bold mb-2 text-white">#{number}</p>
                                                    <div className="bg-white/20 p-2 rounded-xl text-xs text-right inline-block border border-white/20">
                                                        <p className="text-violet-50 mb-0.5">Date: <span className="text-white font-bold">{new Date(date).toLocaleDateString()}</span></p>
                                                        <p className="text-violet-50">{dueDateLabel}: <span className="text-white font-bold">{new Date(dueDate).toLocaleDateString()}</span></p>
                                                    </div>
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

                        {/* --- BODY (SPLIT ROWS FOR PERFECT PAGINATION) --- */}
                        <tbody>

                            {/* ROW 1: Info Grid */}
                            <tr className="avoid-break">
                                <td className="px-8 align-top">
                                    <div className="flex flex-row justify-between gap-8 mb-6">
                                        {/* Billed To */}
                                        <div className="w-[50%] bg-white border-2 border-violet-100 rounded-2xl p-4 relative overflow-hidden">
                                            <div className="force-bg absolute top-0 left-0 w-1 h-full bg-violet-500" style={{ backgroundColor: '#8b5cf6' }}></div>
                                            <h3 className="text-[10px] font-bold text-violet-600 uppercase tracking-widest mb-2 flex items-center gap-1.5"><User size={12} /> {isInvoice ? "Billed To" : "Quote To"}</h3>
                                            <p className="text-lg font-black text-gray-900 mb-1">{data.client.name}</p>
                                            <div className="text-[11px] text-gray-600 space-y-0.5">
                                                <p>{data.client.email}</p>
                                                <p>{data.client.phone}</p>
                                                <p className="whitespace-pre-line leading-snug">{data.client.address}</p>
                                            </div>
                                            {isGstEnabled && data.client.gstNumber && (
                                                <div className="mt-2 text-[9px] font-bold text-gray-700 bg-gray-100 px-2 py-0.5 rounded inline-block">
                                                    GSTIN: {data.client.gstNumber}
                                                </div>
                                            )}
                                        </div>

                                        {/* Payment Info */}
                                        <div className="w-[50%] bg-white border-2 border-fuchsia-100 rounded-2xl p-4 relative overflow-hidden">
                                            <div className="force-bg absolute top-0 left-0 w-1 h-full bg-fuchsia-500" style={{ backgroundColor: '#d946ef' }}></div>
                                            <h3 className="text-[10px] font-bold text-fuchsia-600 uppercase tracking-widest mb-2 flex items-center gap-1.5"><CreditCard size={12} /> Payment Details</h3>
                                            {bankDetails && bankDetails.accountNumber ? (
                                                <div className="text-[11px] text-gray-600 space-y-1">
                                                    {bankDetails.accountName && <div className="flex justify-between border-b border-dashed border-gray-200 pb-0.5"><span>Name:</span> <span className="font-bold text-gray-900">{bankDetails.accountName}</span></div>}
                                                    <div className="flex justify-between border-b border-dashed border-gray-200 pb-0.5"><span>Bank:</span> <span className="font-bold text-gray-900">{bankDetails.bankName}</span></div>
                                                    <div className="flex justify-between border-b border-dashed border-gray-200 pb-0.5"><span>Account:</span> <span className="font-mono font-bold text-gray-900">{bankDetails.accountNumber}</span></div>
                                                    <div className="flex justify-between"><span>IFSC:</span> <span className="font-mono font-bold text-gray-900">{bankDetails.ifscCode}</span></div>
                                                </div>
                                            ) : <p className="text-[11px] text-gray-400 italic">No payment details added.</p>}
                                        </div>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 2: Items Table */}
                            <tr>
                                <td className="px-8 align-top">
                                    <div className="rounded-xl border border-gray-200 overflow-x-auto print:overflow-visible mb-6">
                                        <table className="w-full min-w-0 text-xs text-left table-fixed border-separate border-spacing-0">
                                            <thead className="bg-gray-100 text-gray-600 uppercase tracking-wider force-bg" style={{ backgroundColor: '#f3f4f6' }}>
                                                <tr>
                                                    <th className="py-3 pl-4 pr-2 font-bold text-[10px] w-[5%]">#</th>
                                                    <th className={`py-3 px-2 font-bold text-[10px] ${showHsn ? 'w-[35%]' : 'w-[50%]'}`}>Description</th>

                                                    {/* CONDITIONAL HSN HEADER */}
                                                    {showHsn && <th className="py-3 px-2 font-bold text-center text-[10px] w-[15%]">HSN/SAC</th>}

                                                    <th className="py-3 px-2 font-bold text-center text-[10px] w-[10%]">Qty</th>
                                                    <th className="py-3 px-2 font-bold text-right text-[10px] w-[15%]">Rate</th>
                                       {isGstEnabled && <th className="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>}
                                                    <th className="py-3 px-4 font-bold text-right text-[10px] w-[20%]">Amount</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {data.items.map((item, i) => (
                                                    <tr key={i} className={`hover:bg-gray-50/50 avoid-break ${i % 2 !== 0 ? 'bg-gray-50/30' : ''}`}>
                                                        <td className="py-4 pl-4 pr-2 align-top text-[11px] font-bold text-gray-500 border-b border-gray-200/80">{i + 1}</td>
                                                        <td className="py-4 px-2 align-top break-words pr-2 border-b border-gray-200/80">
                                                            <p className="font-bold text-gray-900 text-[13px]">{item.description}</p>
                                                            {item.additionalDetails && <p className="text-[10px] text-gray-500 mt-0.5 whitespace-pre-wrap leading-relaxed">{item.additionalDetails}</p>}
                                                        </td>

                                                        {/* CONDITIONAL HSN DATA */}
                                                        {showHsn && <td className="py-4 px-2 text-center text-gray-500 font-mono text-[11px] align-top break-words border-b border-gray-200/80">{item.hsnCode || "-"}</td>}

                                                        <td className="py-4 px-2 text-center text-gray-600 font-medium text-[11px] align-top break-words border-b border-gray-200/80">{item.quantity}</td>
                                                        <td className="py-4 px-2 text-right text-gray-600 font-medium text-[11px] align-top break-words border-b border-gray-200/80">{formatCurrency(item.rate)}</td>
                                                        {isGstEnabled && (
                                              <td className="py-4 px-2 text-center text-gray-600 align-top break-words">
                                                  {item.gstRate ? `${item.gstRate}%` : '-'}
                                              </td>
                                          )}
                                                        <td className="py-4 px-4 text-right font-black text-gray-900 text-[13px] align-top break-words border-b border-gray-200/80">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                </td>
                            </tr>

                            {/* ROW 3: Totals, Words & Signature */}
                            <tr className="avoid-break">
                                <td className="px-8 align-top pb-6">
                                    <div className="flex flex-row justify-between items-start w-full gap-6">

                                        {/* LEFT: AMOUNT IN WORDS */}
                                        <div className="w-[55%] mt-1">
                                            <div className="bg-fuchsia-50/50 p-4 border border-dashed border-fuchsia-200 rounded-xl force-bg" style={{ backgroundColor: '#fdf4ff' }}>
                                                <p className="text-[9px] font-bold text-fuchsia-400 uppercase tracking-widest mb-1.5 flex items-center gap-1">
                                                    Total Amount (In Words)
                                                </p>
                                                <p className="text-xs font-bold text-fuchsia-900 leading-snug">
                                                    {convertNumberToWords(total)}
                                                </p>
                                            </div>
                                        </div>

                                        {/* RIGHT: TOTALS BOX & SIGNATURE */}
                                        <div className="w-[40%] flex flex-col items-end">

                                            <div className="w-full space-y-3">
                                                <div className="bg-gray-50 p-4 rounded-xl border border-gray-200 space-y-1.5">
                                                    <div className="flex justify-between text-[11px] text-gray-600"><span>Subtotal</span> <span className="font-bold text-gray-900">{formatCurrency(subTotal)}</span></div>
                                                    {discountAmount > 0 && <div className="flex justify-between text-[11px] text-fuchsia-600 font-medium"><span>Discount</span> <span>- {formatCurrency(discountAmount)}</span></div>}
                                                    {isGstEnabled && (
                                                        <>
                                                            <div className="flex justify-between text-[11px] text-gray-600 pt-1.5 border-t border-gray-200"><span>Taxable Amount</span> <span>{formatCurrency(taxableAmount)}</span></div>
                                                            {data.gstBreakdown ? (
                                                                <>
                                                                    {data.gstBreakdown.cgst > 0 && (
                                                                        <div className="flex justify-between text-[10px] text-gray-500"><span>CGST</span> <span>{formatCurrency(data.gstBreakdown.cgst)}</span></div>
                                                                    )}
                                                                    {data.gstBreakdown.sgst > 0 && (
                                                                        <div className="flex justify-between text-[10px] text-gray-500"><span>SGST</span> <span>{formatCurrency(data.gstBreakdown.sgst)}</span></div>
                                                                    )}
                                                                    {data.gstBreakdown.igst > 0 && (
                                                                        <div className="flex justify-between text-[10px] text-gray-500"><span>IGST</span> <span>{formatCurrency(data.gstBreakdown.igst)}</span></div>
                                                                    )}
                                                                </>
                                                            ) : (
                                                                taxRate > 0 && (
                                                                    <div className="flex justify-between text-[10px] text-gray-500"><span>GST ({taxRate}%)</span> <span>{formatCurrency(taxAmount)}</span></div>
                                                                )
                                                            )}
                                                        </>
                                                    )}
                                                </div>

                                                {/* Gradient Total Box */}
                                                <div className="force-bg bg-gradient-to-r from-violet-600 to-fuchsia-600 text-white p-4 rounded-xl"
                                                    style={{ background: 'linear-gradient(135deg, #7c3aed 0%, #c026d3 100%)', color: 'white' }}>
                                                    <div className="flex justify-between items-center mb-1">
                                                        <span className="text-xs font-medium opacity-90 text-white">Total</span>
                                                        <span className="text-lg font-black text-white">{formatCurrency(total)}</span>
                                                    </div>
                                                    {advance > 0 && (
                                                        <>
                                                            <div className="flex justify-between items-center text-[10px] border-t border-white/20 pt-1.5 mt-1.5 text-white">
                                                                <span className="opacity-90">Advance</span>
                                                                <span>- {formatCurrency(advance)}</span>
                                                            </div>
                                                            <div className="flex justify-between items-center mt-1 text-white">
                                                                <span className="font-bold text-[11px] uppercase tracking-wider">Balance</span>
                                                                <span className="font-bold text-base">{formatCurrency(balance)}</span>
                                                            </div>
                                                        </>
                                                    )}
                                                </div>
                                            </div>

                                            {/* --- FIXED PERFECTLY CENTERED SIGNATURE --- */}
                                            <div className="mt-4 w-full flex justify-start justify-end">
                                                {/* Fixed w-36 container ensures Image & Text are aligned centrally to each other */}
                                                <div className="flex flex-col items-center w-36">
                                                    <div className="h-10 mb-1 flex items-end justify-center w-full">
                                                        {signatureImage ? (
                                                            <img src={signatureImage} alt="Sign" className="h-10 object-contain" />
                                                        ) : (
                                                            <div className="h-full w-28 border border-dashed border-gray-300 flex items-center justify-center text-[9px] text-gray-400">Sign Here</div>
                                                        )}
                                                    </div>
                                                    <div className="border-t border-gray-300 pt-1 w-full text-center">
                                                        <p className="font-bold text-gray-900 text-[10px] truncate">{data.salesPerson?.name || tenant.name}</p>
                                                        <p className="text-[8px] font-bold uppercase tracking-wider text-gray-400 mt-0.5">Authorized Signatory</p>
                                                    </div>
                                                </div>
                                            </div>

                                        </div>

                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                {/* --- FIXED FOOTER --- */}
                <div className="footer-fixed w-full bg-white mt-auto">
                    <div className="px-8 pb-6">
                        <div className="border-t border-gray-100 pt-4">
                            <h4 className="text-[10px] font-bold text-violet-600 uppercase tracking-widest mb-1.5 flex items-center gap-1.5"><FileText size={12} /> Terms & Conditions</h4>
                            <p className="text-[9px] text-gray-500 whitespace-pre-wrap leading-relaxed bg-gray-50 p-2.5 rounded-lg border border-gray-100 line-clamp-2">
                                {data.terms || tenant.defaultTerms || "Thank you for doing business with us."}
                            </p>
                            {data.placeOfSupply && (
                                <p className="text-[9px] text-gray-500 mt-2 font-semibold px-1">
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

export default VibrantTemplate;