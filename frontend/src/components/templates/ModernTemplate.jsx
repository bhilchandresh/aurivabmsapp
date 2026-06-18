import React from 'react';
import { Mail, Phone, Globe, MapPin, Building2, FileText, Calendar, CreditCard, Hash, User } from 'lucide-react';

const ModernTemplate = ({ data, tenant, type = 'invoice' }) => {
   const isInvoice = type === 'invoice';
   const number = isInvoice ? data.invoiceNumber : data.quotationNumber;
   const date = data.date;
   const dueDate = isInvoice ? data.dueDate : data.validUntil;
   const dueDateLabel = isInvoice ? "Due" : "Valid Until";

   // --- GST CHECK ---
   const isGstEnabled = data.gstEnabled !== undefined ? data.gstEnabled : (Number(data.taxRate) > 0);

   // --- 1. FETCH BANK DETAILS (Fallback Logic) ---
   const bankDetails = (data?.bankDetailsSnapshot && data?.bankDetailsSnapshot?.accountNumber)
      ? data.bankDetailsSnapshot
      : tenant?.bankDetails;

   // --- 2. FETCH SIGNATURE (Fallback Logic) ---
   const signatureImage = data?.authorizedSignatoryImage || data?.salesPerson?.signatureImage || tenant?.signatureImage;

   // --- 3. CHECK IF HSN EXISTS IN ANY ITEM ---
   const showHsn = data.items && data.items.some(item => item.hsnCode && item.hsnCode.trim() !== "");

   // --- 4. NUMBER TO WORDS CONVERTER ---
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

   // --- CALCULATIONS ---
   const formatCurrency = (amount) => {
      return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
   };

   const subTotal = data.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0);
   const discountPercentage = Number(data.discountPercentage) || 0;
   const discountAmount = subTotal * (discountPercentage / 100);
   const taxableAmount = subTotal - discountAmount;
   const taxRate = isGstEnabled ? (Number(data.taxRate) || 0) : 0;
   const taxAmount = isGstEnabled ? (data.gstAmount !== undefined ? Number(data.gstAmount) : taxableAmount * (taxRate / 100)) : 0;
   const cgst = taxAmount / 2;
   const sgst = taxAmount / 2;
   const total = data.totalAmount !== undefined ? Number(data.totalAmount) : (taxableAmount + taxAmount);
   const advance = Number(data.advancePayment) || 0;
   const balance = data.balanceDue !== undefined ? Number(data.balanceDue) : (total - advance);

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

          /* CRITICAL: Disable ALL shadows and borders that cause page-end leak */
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

          /* Fix Colors */
          .bg-slate-900 { background-color: #0f172a !important; color: white !important; }
          .text-white { color: white !important; }

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

         <div className="bg-white w-full mx-auto text-gray-800 font-sans relative flex flex-col print-container">

            <div className="flex-1">
               <table className="main-table w-full border-separate border-spacing-0">

                  {/* --- HEADER --- */}
                  <thead>
                     <tr>
                        <td>
                           <div className="bg-gray-900 text-white p-10 flex flex-row justify-between items-center gap-0" style={{ WebkitPrintColorAdjust: 'exact' }}>
                              <div className="w-auto">
                                 {/* --- LOGO ADDED HERE --- */}
                                 {tenant.logoImage && (
                                    <img
                                       src={tenant.logoImage}
                                       alt="Logo"
                                       className="h-12 mb-3 object-contain"
                                    />
                                 )}
                                 <h1 className="text-2xl font-bold tracking-tight mb-2">{tenant.name}</h1>
                                 <div className="text-gray-400 text-xs space-y-1">
                                    {tenant.website && <p className="flex items-center gap-1"><Globe size={12} /> {tenant.website}</p>}
                                    <p className="flex items-center gap-1"><Mail size={12} /> {tenant.email}</p>
                                    <p className="flex items-center gap-1"><Phone size={12} /> {tenant.phone}</p>
                                    {isGstEnabled && tenant.gstNumber && (
                                       <p className="text-[10px] font-bold mt-1 text-gray-300">GSTIN: {tenant.gstNumber}</p>
                                    )}
                                 </div>
                              </div>
                              <div className="text-right w-auto  ">
                                 <div className="bg-gray-800 px-3 py-1 rounded text-[10px] font-bold uppercase tracking-widest text-gray-400 mb-2 inline-block">{isInvoice ? "Invoice No" : "Quote No"}</div>
                                 <p className="text-2xl font-mono mb-1">{number}</p>
                                 <p className="text-xs text-gray-400 mt-2">Date: <strong className="text-white">{new Date(date).toLocaleDateString()}</strong></p>
                                 <p className="text-xs text-gray-400 mt-1">{dueDateLabel}: <strong className="text-white">{new Date(dueDate).toLocaleDateString()}</strong></p>
                              </div>
                           </div>
                           <div className="h-6"></div>
                        </td>
                     </tr>
                  </thead>

                  {/* --- FOOTER SPACER --- */}
                  <tfoot>
                     <tr><td><div className="footer-space"></div></td></tr>
                  </tfoot>

                  {/* --- BODY (SPLIT INTO ROWS FOR PRINT SAFETY) --- */}
                  <tbody>

                     {/* ROW 1: INFO GRID */}
                     <tr className="avoid-break">
                        <td className="px-10 align-top">
                           <div className="flex flex-row justify-between gap-12 mb-8">
                              {/* Left: Bill To */}
                              <div className="w-[50%]">
                                 <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2 flex items-center gap-1">
                                    <User size={12} /> {isInvoice ? "Billed To" : "Quote To"}
                                 </h3>
                                 <p className="font-bold text-lg text-gray-900 mb-1">{data.client.name}</p>
                                 <div className="text-gray-600 text-xs space-y-0.5">
                                    <p>{data.client.email}</p>
                                    <p>{data.client.phone}</p>
                                    <p className="whitespace-pre-line mt-1">{data.client.address}</p>
                                 </div>
                                 {isGstEnabled && data.client.gstNumber && (
                                    <p className="text-[11px] font-bold mt-2 text-gray-800 bg-gray-100 px-2 py-0.5 inline-block rounded">GSTIN: {data.client.gstNumber}</p>
                                 )}
                              </div>

                              {/* Right: Payment Info */}
                              <div className="w-[40%] flex flex-col items-end">
                                 <div className="w-full bg-gray-50 p-4 rounded border border-gray-200">
                                    <h3 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-2 flex items-center gap-1.5 border-b border-gray-200 pb-1.5">
                                       <CreditCard className="w-3 h-3 text-gray-500" /> Payment Details
                                    </h3>
                                    {bankDetails && bankDetails.accountNumber ? (
                                       <div className="space-y-1 text-xs">
                                          {bankDetails.accountName && (
                                             <div className="flex justify-between">
                                                <span className="text-gray-500">Name:</span>
                                                <span className="font-bold text-gray-800">{bankDetails.accountName}</span>
                                             </div>
                                          )}
                                          <div className="flex justify-between">
                                             <span className="text-gray-500">Bank:</span>
                                             <span className="font-bold text-gray-800">{bankDetails.bankName}</span>
                                          </div>
                                          <div className="flex justify-between">
                                             <span className="text-gray-500">Acc No:</span>
                                             <span className="font-mono font-bold text-gray-800">{bankDetails.accountNumber}</span>
                                          </div>
                                          <div className="flex justify-between">
                                             <span className="text-gray-500">IFSC:</span>
                                             <span className="font-mono font-bold text-gray-800">{bankDetails.ifscCode}</span>
                                          </div>
                                       </div>
                                    ) : (
                                       <p className="text-[10px] text-gray-400 italic">No payment details available.</p>
                                    )}
                                 </div>

                                 {isGstEnabled && tenant.gstNumber && (
                                    <div className="mt-3 text-[11px] text-right">
                                       <span className="text-gray-500">Co. GSTIN:</span> <span className="font-bold text-gray-900">{tenant.gstNumber}</span>
                                    </div>
                                 )}
                              </div>
                           </div>
                        </td>
                     </tr>

                     {/* ROW 2: ITEMS TABLE (Converted to proper table-fixed for alignment) */}
                     <tr>
                        <td className="px-10 align-top">
                           <div className="mb-6 rounded-lg border border-gray-300 overflow-hidden print:overflow-visible print:border-collapse">
                              <table className="w-full min-w-0 text-xs table-fixed">
                                 <thead className="bg-gray-100 text-gray-900 border-b border-gray-300" style={{ WebkitPrintColorAdjust: 'exact' }}>
                                    <tr className="divide-x divide-gray-300">
                                       <th className="py-3 px-2 text-center font-bold uppercase tracking-widest text-[9px] w-[5%]">#</th>
                                       <th className={`py-3 px-3 text-left font-bold uppercase tracking-widest text-[9px] ${showHsn ? 'w-[35%]' : 'w-[50%]'}`}>Description</th>
                                       {showHsn && <th className="py-3 px-2 text-center font-bold uppercase tracking-widest text-[9px] w-[15%]">HSN/SAC</th>}
                                       <th className="py-3 px-2 text-center font-bold uppercase tracking-widest text-[9px] w-[10%]">Qty</th>
                                       <th className="py-3 px-2 text-right font-bold uppercase tracking-widest text-[9px] w-[15%]">Rate</th>
                                       <th className="py-3 px-3 text-right font-bold uppercase tracking-widest text-[9px] w-[20%]">Total</th>
                                    </tr>
                                 </thead>
                                 <tbody className="divide-y divide-gray-300">
                                    {data.items.map((item, index) => (
                                       <tr key={index} className="avoid-break hover:bg-gray-50 transition divide-x divide-gray-300">
                                          <td className="py-4 px-2 text-center text-gray-600 font-medium align-top break-words">{index + 1}</td>
                                          <td className="py-4 px-3 align-top break-words">
                                             <p className="font-bold text-gray-900 text-[13px]">{item.description}</p>
                                             {item.additionalDetails && (
                                                <p className="text-[10px] text-gray-500 mt-1 whitespace-pre-wrap leading-relaxed">{item.additionalDetails}</p>
                                             )}
                                          </td>
                                          {showHsn && <td className="py-4 px-2 text-center text-gray-600 font-mono text-[11px] align-top break-words">{item.hsnCode || "-"}</td>}
                                          <td className="py-4 px-2 text-center text-gray-700 font-medium align-top break-words">{item.quantity}</td>
                                          <td className="py-4 px-2 text-right text-gray-700 font-medium align-top break-words">{formatCurrency(item.rate)}</td>
                                          <td className="py-4 px-3 text-right font-black text-gray-900 align-top break-words">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                                       </tr>
                                    ))}
                                 </tbody>
                              </table>
                           </div>
                        </td>
                     </tr>

                     {/* ROW 3: TOTALS & WORDS */}
                     <tr className="avoid-break">
                        <td className="px-10 align-top pb-6">
                           <div className="flex flex-row justify-between items-start w-full gap-6">

                              {/* LEFT: Amount in Words */}
                              <div className="w-[55%] mt-1">
                                 <div className="bg-gray-50 p-4 border border-dashed border-gray-200 rounded-lg">
                                    <p className="text-[9px] font-bold text-gray-400 uppercase tracking-widest mb-1.5">
                                       Total Amount (In Words)
                                    </p>
                                    <p className="text-xs font-bold text-gray-800 leading-snug">
                                       {convertNumberToWords(total)}
                                    </p>
                                 </div>
                              </div>

                              {/* RIGHT: Financial Totals */}
                              <div className="w-[40%] flex flex-col items-end">
                                 <div className="w-full bg-gray-50 p-4 rounded border border-gray-200">

                                    <div className="space-y-1.5 text-[11px] text-gray-600 border-b border-gray-200 pb-2.5 mb-2.5">
                                       <div className="flex justify-between">
                                          <span>Subtotal</span> <span className="font-medium text-gray-900">{formatCurrency(subTotal)}</span>
                                       </div>

                                       {discountAmount > 0 && (
                                          <div className="flex justify-between text-red-500">
                                             <span>Discount ({discountPercentage}%)</span> <span>- {formatCurrency(discountAmount)}</span>
                                          </div>
                                       )}

                                       {(isGstEnabled || discountAmount > 0) && (
                                          <div className="flex justify-between font-bold text-gray-700 pt-1 border-t border-dashed border-gray-300">
                                             <span>Taxable Amount</span> <span>{formatCurrency(taxableAmount)}</span>
                                          </div>
                                       )}

                                       {isGstEnabled && (
                                          <>
                                             {data.gstBreakdown ? (
                                                <>
                                                   {data.gstBreakdown.cgst > 0 && (
                                                      <div className="flex justify-between pt-1">
                                                         <span>CGST</span> <span>+ {formatCurrency(data.gstBreakdown.cgst)}</span>
                                                      </div>
                                                   )}
                                                   {data.gstBreakdown.sgst > 0 && (
                                                      <div className="flex justify-between">
                                                         <span>SGST</span> <span>+ {formatCurrency(data.gstBreakdown.sgst)}</span>
                                                      </div>
                                                   )}
                                                   {data.gstBreakdown.igst > 0 && (
                                                      <div className="flex justify-between pt-1">
                                                         <span>IGST</span> <span>+ {formatCurrency(data.gstBreakdown.igst)}</span>
                                                      </div>
                                                   )}
                                                </>
                                             ) : (
                                                taxRate > 0 && (
                                                   <div className="flex justify-between pt-1">
                                                      <span>GST ({taxRate}%)</span> <span>+ {formatCurrency(taxAmount)}</span>
                                                   </div>
                                                )
                                             )}
                                          </>
                                       )}
                                    </div>

                                    <div className="flex justify-between items-center text-sm font-black text-gray-900">
                                       <span className="uppercase tracking-widest text-xs">Total</span>
                                       <span className="text-lg">{formatCurrency(total)}</span>
                                    </div>

                                    {advance > 0 && (
                                       <div className="flex justify-between mt-1.5 text-[10px] text-green-600 font-bold">
                                          <span>Advance Paid</span> <span>- {formatCurrency(advance)}</span>
                                       </div>
                                    )}

                                    <div className="flex justify-between border-t border-gray-900 pt-2 mt-2 text-xs font-bold text-gray-900">
                                       <span>Balance Due</span> <span>{formatCurrency(balance)}</span>
                                    </div>
                                 </div>
                              </div>

                           </div>
                        </td>
                     </tr>
                     
                     {/* ROW 4: SIGNATURE (Moved here from footer) */}
                     <tr className="avoid-break">
                        <td className="px-10 pb-6">
                           <div className="flex justify-end mt-4">
                              <div className="w-[40%] flex justify-center">
                                 <div className="text-center flex flex-col items-center">
                                    {signatureImage ? (
                                       <img src={signatureImage} alt="Signature" className="h-14 mb-1 object-contain" />
                                    ) : (
                                       <div className="h-12 w-28 border border-dashed border-gray-300 flex items-center justify-center text-[9px] text-gray-400 mb-1">Sign Here</div>
                                    )}

                                    <p className="font-bold text-gray-900 text-xs truncate max-w-[150px]">{data.salesPerson?.name || tenant.name}</p>
                                    <p className="text-[9px] text-gray-500 uppercase tracking-widest mt-0.5">Authorized Signatory</p>
                                 </div>
                              </div>
                           </div>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>

            {/* --- FIXED FOOTER --- */}
            <div className="footer-fixed w-full mt-auto">

               <div className="bg-gray-50 px-10 py-4 border-t border-gray-200">
                  <div className="w-full">
                     <h4 className="font-bold text-[10px] uppercase text-gray-500 mb-1 tracking-widest flex items-center gap-1">
                        <FileText size={12} /> Terms & Conditions
                     </h4>
                     <p className="text-[10px] text-gray-500 whitespace-pre-wrap leading-relaxed">
                        {data.terms || tenant.defaultTerms}
                     </p>
                     {data.placeOfSupply && (
                         <p className="text-[10px] text-gray-500 mt-2 font-semibold">
                             Place of Supply: {data.placeOfSupply} &nbsp;|&nbsp; Dispatch State: {tenant.state || "Not set"}
                         </p>
                     )}
                  </div>
               </div>

               {/* Address Bar */}
               <div className="bg-gray-900 text-gray-400 text-[10px] font-medium tracking-wide text-center py-2" style={{ WebkitPrintColorAdjust: 'exact' }}>
                  <p>{tenant.address ? tenant.address.replace(/\n/g, ', ') : 'Thank you for your business!'}</p>
               </div>

            </div>
         </div>
      </>
   );
};

export default ModernTemplate;