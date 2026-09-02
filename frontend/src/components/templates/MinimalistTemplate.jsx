import React from 'react';
import { Mail, Phone, MapPin, Globe } from 'lucide-react';

const MinimalistTemplate = ({ data, tenant, type = 'invoice' }) => {
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
    ? data.bankDetailsSnapshot : tenant?.bankDetails;

  const signatureImage = data?.authorizedSignatoryImage ||
    (data?.salesPerson && data?.salesPerson?.signatureImage) ||
    tenant?.signatureImage;

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

  // Calculations
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
            font-family: 'Inter', sans-serif;
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

      <div className="bg-white w-full mx-auto font-sans  print-container text-black">

        <div className="flex-1">
          <table className="main-table w-full border-separate border-spacing-0">

            {/* --- HEADER --- */}
            <thead>
              <tr>
                <td>
                  <div className="p-10 pb-4">
                    <div className="flex flex-row justify-between items-start border-b-2 border-black pb-6 gap-0">

                      {/* Left: Logo & Company */}
                      <div className="w-[60%]">
                        {tenant.logoImage && (
                          <img
                            src={tenant.logoImage}
                            alt="Logo"
                            className="h-12 mb-3 object-contain"
                          />
                        )}
                        <h1 className="text-xl font-bold uppercase tracking-widest">{tenant.name}</h1>
                        <div className="text-[11px] mt-1.5 space-y-0.5 text-gray-600">
                          <p>{tenant.address}</p>
                          <div className="flex flex-wrap gap-4">
                            {tenant.email && <span className="flex items-center gap-1"><Mail size={10} /> {tenant.email}</span>}
                            {tenant.phone && <span className="flex items-center gap-1"><Phone size={10} /> {tenant.phone}</span>}
                            {tenant.website && <span className="flex items-center gap-1"><Globe size={10} /> {tenant.website}</span>}
                          </div>
                          {isGstEnabled && tenant.gstNumber && <p className="font-bold text-black mt-1">GSTIN: {tenant.gstNumber}</p>}
                        </div>
                      </div>

                      {/* Right: Invoice Meta */}
                      <div className="text-right w-auto ">
                        <h2 className="text-2xl font-black tracking-tighter text-gray-200 uppercase">
                          {isInvoice ? "INVOICE" : "QUOTE"}
                        </h2>
                        <p className="text-lg font-bold mt-[-8px]">#{docNumber}</p>

                        <div className="mt-3 text-[11px] font-mono">
                          <div className="flex justify-end gap-3">
                            <span className="text-gray-500">ISSUED:</span>
                            <span className="font-bold">{date}</span>
                          </div>
                          <div className="flex justify-end gap-3">
                            <span className="text-gray-500 uppercase">{dueDateLabel}:</span>
                            <span className="font-bold">{dueDate}</span>
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

              {/* ROW 1: Info Section */}
              <tr className="avoid-break">
                <td className="px-10 align-top">
                  <div className="flex flex-row justify-between gap-10 mb-6">
                    {/* To */}
                    <div className="w-[50%]">
                      <p className="text-[9px] font-bold uppercase tracking-widest text-gray-400 mb-1.5">{isInvoice ? "Billed To" : "Quote To"}</p>
                      <p className="text-base font-bold">{data.client.name}</p>
                      <p className="text-[11px] text-gray-600 mt-0.5 whitespace-pre-line leading-snug">{data.client.address}</p>
                      <p className="text-[11px] text-gray-600">{data.client.email}</p>
                      {isGstEnabled && data.client.gstNumber && (
                        <p className="text-[10px] font-bold mt-1">GSTIN: {data.client.gstNumber}</p>
                      )}
                    </div>

                    {/* Payment */}
                    <div className="w-[50%] text-right ">
                      <p className="text-[9px] font-bold uppercase tracking-widest text-gray-400 mb-1.5">Payment Info</p>
                      {bankDetails && bankDetails.accountNumber ? (
                        <div className="text-[11px] text-gray-600 space-y-0.5">
                          {bankDetails.accountName && <p><span className="text-gray-400 text-[10px]">NAME:</span> <strong className="text-black">{bankDetails.accountName}</strong></p>}
                          <p><span className="text-gray-400 text-[10px]">BANK:</span> <strong className="text-black">{bankDetails.bankName}</strong></p>
                          <p><span className="text-gray-400 text-[10px]">A/C:</span> <strong className="font-mono text-black">{bankDetails.accountNumber}</strong></p>
                          <p><span className="text-gray-400 text-[10px]">IFSC:</span> <strong className="font-mono text-black">{bankDetails.ifscCode}</strong></p>
                        </div>
                      ) : <p className="text-[10px] text-gray-400 italic">No details available</p>}
                    </div>
                  </div>
                </td>
              </tr>

              {/* ROW 2: Items Table */}
              <tr>
                <td className="px-10 align-top">
                  <div className="mb-6 overflow-x-auto print:overflow-visible">
                    <table className="w-full min-w-0 text-xs table-fixed border-separate border-spacing-0">
                      <thead style={{ backgroundColor: '#000', color: '#fff' }}>
                        <tr>
                          {/* Description Adjusts Based on HSN */}
                          <th className={`py-2 px-3 text-left font-bold uppercase tracking-wider ${showHsn ? 'w-[40%]' : 'w-[55%]'}`}>Item Description</th>

                          {/* CONDITIONAL HSN HEADER */}
                          {showHsn && <th className="py-2 px-3 text-center font-bold uppercase tracking-wider w-[15%]">HSN/SAC</th>}

                          <th className="py-2 px-3 text-center font-bold uppercase tracking-wider w-[10%]">Qty</th>
                          <th className="py-2 px-3 text-right font-bold uppercase tracking-wider w-[15%]">Rate</th>
                                       {isGstEnabled && <th className="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>}
                          <th className="py-2 px-3 text-right font-bold uppercase tracking-wider w-[20%]">Amount</th>
                        </tr>
                      </thead>
                      <tbody>
                        {data.items.map((item, i) => (
                          <tr key={i} className="border-b border-gray-200 avoid-break">
                            <td className="py-3 px-3 align-top break-words pr-2">
                              <p className="font-bold text-[13px]">{item.description}</p>
                              {item.additionalDetails && <p className="text-[10px] text-gray-500 mt-0.5 whitespace-pre-wrap leading-relaxed">{item.additionalDetails}</p>}
                            </td>

                            {/* CONDITIONAL HSN DATA */}
                            {showHsn && <td className="py-3 px-3 text-center font-mono text-[11px] text-gray-600 align-top break-words">{item.hsnCode || "-"}</td>}

                            <td className="py-3 px-3 text-center align-top break-words">{item.quantity}</td>
                            <td className="py-3 px-3 text-right align-top break-words">{formatCurrency(item.rate)}</td>
                            {isGstEnabled && (
                                              <td className="py-4 px-2 text-center text-gray-600 align-top break-words">
                                                  {item.gstRate ? `${item.gstRate}%` : '-'}
                                              </td>
                                          )}
                            <td className="py-3 px-3 text-right font-bold align-top break-words">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </td>
              </tr>

              {/* ROW 3: Totals & Words */}
              <tr className="avoid-break">
                <td className="px-10 align-top pb-6">
                  <div className="flex flex-row justify-between items-start w-full gap-6">

                    {/* LEFT: AMOUNT IN WORDS */}
                    <div className="w-[55%] mt-1">
                      <p className="text-[9px] font-bold uppercase tracking-widest text-gray-400 mb-1">Total Amount (In Words)</p>
                      <p className="text-[11px] font-bold text-black leading-snug">
                        {convertNumberToWords(total)}
                      </p>
                    </div>

                    {/* RIGHT: TOTALS BOX */}
                    <div className="w-[40%] flex flex-col items-end">
                      <div className="w-full">
                        <div className="space-y-1.5 text-[11px] pb-2 border-b-2 border-black">
                          <div className="flex justify-between"><span>Subtotal</span> <span>{formatCurrency(subTotal)}</span></div>
                          {discountAmount > 0 && <div className="flex justify-between text-gray-500"><span>Discount</span> <span>- {formatCurrency(discountAmount)}</span></div>}
                          {isGstEnabled && (
                            <>
                               {data.gstBreakdown ? (
                                  <>
                                     {data.gstBreakdown.cgst > 0 && (
                                       <div className="flex justify-between text-gray-500">
                                         <span>CGST</span><span>{formatCurrency(data.gstBreakdown.cgst)}</span>
                                       </div>
                                     )}
                                     {data.gstBreakdown.sgst > 0 && (
                                       <div className="flex justify-between text-gray-500">
                                         <span>SGST</span><span>{formatCurrency(data.gstBreakdown.sgst)}</span>
                                       </div>
                                     )}
                                     {data.gstBreakdown.igst > 0 && (
                                       <div className="flex justify-between text-gray-500">
                                         <span>IGST</span><span>{formatCurrency(data.gstBreakdown.igst)}</span>
                                       </div>
                                     )}
                                  </>
                               ) : (
                                  taxRate > 0 && (
                                     <div className="flex justify-between text-gray-500">
                                       <span>GST ({taxRate}%)</span><span>{formatCurrency(taxAmount)}</span>
                                     </div>
                                  )
                               )}
                            </>
                          )}
                        </div>

                        <div className="flex justify-between items-center py-2">
                          <span className="text-base font-bold">Total</span>
                          <span className="text-lg font-black">{formatCurrency(total)}</span>
                        </div>

                        {advance > 0 && (
                          <div className="flex justify-between text-[10px] text-gray-500 mb-1.5">
                            <span>Advance Paid</span> <span>- {formatCurrency(advance)}</span>
                          </div>
                        )}

                        <div className="bg-black text-white p-2.5 flex justify-between font-bold text-base mt-1" style={{ backgroundColor: '#000', color: '#fff' }}>
                          <span>Balance Due</span>
                          <span>{formatCurrency(balance)}</span>
                        </div>
                      </div>
                    </div>

                  </div>
                </td>
              </tr>

              {/* ROW 4: Signature (Moved from footer) */}
              <tr className="avoid-break">
                <td className="px-10 pb-6">
                  <div className="flex justify-end mt-4 text-right w-full">
                    <div className="w-36">
                      <div className="h-12 mb-1 flex flex-col justify-end items-center">
                        {signatureImage ? (
                          <img src={signatureImage} alt="Sign" className="h-10 object-contain" />
                        ) : (
                          <div className="h-full w-full border border-dashed border-gray-300 flex items-center justify-center text-[9px] text-gray-400">Sign Here</div>
                        )}
                      </div>
                      <p className="text-[11px] font-bold truncate">{data.salesPerson?.name || tenant.name}</p>
                      <p className="text-[8px] uppercase tracking-widest text-gray-400 mt-0.5 text-center">Authorized Signatory</p>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* --- FOOTER --- */}
        <div className="footer-fixed w-full bg-white mt-auto">
          <div className="px-10 pb-6">
            <div className="flex justify-between items-center border-t border-gray-200 pt-4 text-center">
              <div className="w-full">
                <p className="text-[9px] uppercase tracking-widest font-bold mb-1">Terms & Conditions</p>
                <p className="text-[10px] text-gray-600 leading-relaxed whitespace-pre-wrap">
                  {data.terms || tenant.defaultTerms || "Payment is due upon receipt."}
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

      </div>
    </>
  );
};

export default MinimalistTemplate;