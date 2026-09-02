import React from 'react';
import { Mail, Phone, MapPin, Globe, Calendar, CreditCard, User, Hash } from 'lucide-react';

const StandardTemplate = ({ data, tenant, type = 'invoice' }) => {
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
          .footer-space { height: 90px; } 
          
          .page-number:after { content: counter(page); }
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
         <div className="bg-white w-full mx-auto text-gray-900 font-sans  print-container">

            <div className="flex-1">
               <table className="main-table w-full border-separate border-spacing-0">

                  {/* --- HEADER --- */}
                  <thead>
                     <tr>
                        <td>
                           <div className="bg-white text-gray-900 p-10 pb-6 w-full border-b-4 border-gray-800">
                              <div className="flex flex-row justify-between items-start gap-4">

                                 {/* Company Info */}
                                 <div className="w-[60%]">
                                    {tenant.logoImage && (
                                       <img
                                          src={tenant.logoImage}
                                          alt="Logo"
                                          className="h-14 mb-3 object-contain"
                                       />
                                    )}
                                    <h1 className="text-xl font-extrabold tracking-wide uppercase mb-2">{tenant.name}</h1>

                                    <div className="text-sm text-gray-600 space-y-1">
                                       <div className="flex items-start gap-2">
                                          <MapPin className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                                          <p>{tenant.address}</p>
                                       </div>
                                       <div className="flex flex-wrap gap-4">
                                          <div className="flex items-center gap-2"><Mail className="w-4 h-4 text-gray-400" /> {tenant.email}</div>
                                          {tenant.phone && <div className="flex items-center gap-2"><Phone className="w-4 h-4 text-gray-400" /> {tenant.phone}</div>}
                                       </div>
                                       {tenant.website && <div className="flex items-center gap-2"><Globe className="w-4 h-4 text-gray-400" /> {tenant.website}</div>}
                                    </div>

                                    {isGstEnabled && tenant.gstNumber && (
                                       <div className="mt-3 inline-block font-bold text-xs bg-gray-100 px-2 py-1 rounded border border-gray-300">
                                          GSTIN: {tenant.gstNumber}
                                       </div>
                                    )}
                                 </div>

                                 {/* Meta Info */}
                                 <div className="w-[40%] text-right ">
                                    <h2 className="text-2xl font-black text-gray-200 uppercase tracking-tighter">
                                       {isInvoice ? "INVOICE" : "QUOTATION"}
                                    </h2>
                                    <div className="flex items-center justify-start justify-end gap-2 mt-1">
                                       <Hash className="w-5 h-5 text-gray-400" />
                                       <p className="text-lg font-bold">{number}</p>
                                    </div>

                                    <div className="mt-3 text-sm text-gray-600 space-y-1">
                                       <div className="flex items-center justify-start justify-end gap-2">
                                          <span className="font-semibold text-gray-500">Issued:</span>
                                          <span className="font-bold text-gray-800">{new Date(date).toLocaleDateString()}</span>
                                          <Calendar className="w-3 h-3 text-gray-400" />
                                       </div>
                                       <div className="flex items-center justify-start justify-end gap-2">
                                          <span className="font-semibold text-gray-500">{dueDateLabel}:</span>
                                          <span className="font-bold text-gray-800">{new Date(dueDate).toLocaleDateString()}</span>
                                          <Calendar className="w-3 h-3 text-gray-400" />
                                       </div>
                                    </div>
                                 </div>

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

                     {/* ROW 1: Client & Bank Info */}
                     <tr className="avoid-break">
                        <td className="px-10 align-top">
                           <div className="flex flex-row justify-between gap-8 mb-6">
                              {/* Bill To */}
                              <div className="w-[50%]">
                                 <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2 flex items-center gap-2 border-b border-gray-200 pb-1 w-fit">
                                    <User className="w-3 h-3" /> {isInvoice ? "Billed To" : "Quote To"}
                                 </h3>
                                 <h2 className="text-lg font-bold text-gray-900 mb-1">{data.client.name}</h2>
                                 <div className="text-sm text-gray-600 space-y-1">
                                    <p className="whitespace-pre-line leading-relaxed">{data.client.address}</p>
                                    <p>{data.client.email}</p>
                                    {data.client.phone && <p>{data.client.phone}</p>}
                                 </div>
                                 {isGstEnabled && data.client.gstNumber && (
                                    <p className="mt-2 text-xs font-bold text-gray-700">GSTIN: {data.client.gstNumber}</p>
                                 )}
                              </div>

                              {/* Bank Info */}
                              <div className="w-[40%] flex flex-col items-end ">
                                 <div className="w-full bg-gray-50 p-4 rounded border border-gray-200">
                                    <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2 flex items-center gap-2 border-b border-gray-200 pb-1.5">
                                       <CreditCard className="w-3 h-3" /> Payment Info
                                    </h3>
                                    {bankDetails && bankDetails.accountNumber ? (
                                       <div className="text-xs space-y-1.5">
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
                                             <span className="text-gray-500">Account:</span>
                                             <span className="font-mono font-bold text-gray-800">{bankDetails.accountNumber}</span>
                                          </div>
                                          <div className="flex justify-between">
                                             <span className="text-gray-500">IFSC:</span>
                                             <span className="font-mono font-bold text-gray-800">{bankDetails.ifscCode}</span>
                                          </div>
                                       </div>
                                    ) : (
                                       <p className="text-xs text-gray-400 italic">No bank details available.</p>
                                    )}
                                 </div>
                              </div>
                           </div>
                        </td>
                     </tr>

                     {/* ROW 2: ITEMS TABLE */}
                     <tr>
                        <td className="px-10 align-top">
                           <div className="mb-6 overflow-x-auto print:overflow-visible">
                              <table className="w-full min-w-0 text-sm table-fixed border-separate border-spacing-0">
                                 <thead className="bg-gray-100 text-gray-700 font-bold uppercase text-xs" style={{ WebkitPrintColorAdjust: 'exact' }}>
                                    <tr>
                                       <th className="py-3 px-2 text-center w-[5%] border-y border-gray-200">#</th>
                                       <th className={`py-3 px-2 text-left border-y border-gray-200 ${showHsn ? 'w-[35%]' : 'w-[50%]'}`}>Description</th>
                                       {showHsn && <th className="py-3 px-2 text-center w-[15%] border-y border-gray-200">HSN/SAC</th>}
                                       <th className="py-3 px-2 text-center w-[10%] border-y border-gray-200">Qty</th>
                                       <th className="py-3 px-2 text-right w-[15%] border-y border-gray-200">Rate</th>
                                       {isGstEnabled && <th className="py-3 px-2 text-center w-[10%] border-y border-gray-200">GST</th>}
                                       <th className="py-3 px-2 text-right w-[20%] border-y border-gray-200">Amount</th>
                                    </tr>
                                 </thead>
                                 <tbody className="divide-y divide-gray-100">
                                    {data.items.map((item, index) => (
                                       <tr key={index} className="avoid-break">
                                          <td className="py-4 px-2 text-center text-gray-400 align-top break-words">{index + 1}</td>
                                          <td className="py-4 px-2 align-top break-words pr-2">
                                             <p className="font-medium text-gray-800 text-[13px]">{item.description}</p>
                                             {item.additionalDetails && (
                                                <p className="text-[11px] text-gray-500 mt-1 whitespace-pre-wrap leading-relaxed">{item.additionalDetails}</p>
                                             )}
                                          </td>
                                          {showHsn && <td className="py-4 px-2 text-center text-gray-500 font-mono text-xs align-top break-words">{item.hsnCode || "-"}</td>}
                                          <td className="py-4 px-2 text-center text-gray-600 align-top break-words">{item.quantity}</td>
                                          <td className="py-4 px-2 text-right text-gray-600 align-top break-words">{formatCurrency(item.rate)}</td>
                                          {isGstEnabled && (
                                              <td className="py-4 px-2 text-center text-gray-600 align-top break-words">
                                                  {item.gstRate ? `${item.gstRate}%` : '-'}
                                              </td>
                                          )}
                                          <td className="py-4 px-2 text-right font-bold text-gray-900 align-top break-words">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
                                       </tr>
                                    ))}
                                 </tbody>
                              </table>
                           </div>
                        </td>
                     </tr>

                     {/* ROW 3: TOTALS & AMOUNT IN WORDS */}
                     <tr className="avoid-break">
                        <td className="px-10 align-top pb-6">
                           <div className="flex flex-row justify-between items-start w-full gap-6">

                              {/* LEFT: Amount in Words */}
                              <div className="w-[55%] mt-1 bg-gray-50/50 p-4 border border-dashed border-gray-200 rounded-lg">
                                 <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1.5 flex items-center gap-1">
                                    Total Amount (In Words)
                                 </p>
                                 <p className="text-sm font-bold text-gray-800 leading-snug">
                                    {convertNumberToWords(total)}
                                 </p>
                              </div>

                              {/* RIGHT: Financial Totals */}
                              <div className="w-[40%] flex flex-col items-end">
                                 <div className="w-full border-b border-gray-300 pb-3 mb-3">
                                    <div className="space-y-1.5 text-xs text-sm">
                                       <div className="flex justify-between text-gray-600">
                                          <span>Subtotal</span> <span className="font-medium text-gray-900">{formatCurrency(subTotal)}</span>
                                       </div>
                                       {discountAmount > 0 && (
                                          <div className="flex justify-between text-red-600">
                                             <span>Discount ({discountPercentage}%)</span> <span>- {formatCurrency(discountAmount)}</span>
                                          </div>
                                       )}
                                       {(isGstEnabled || discountAmount > 0) && (
                                          <div className="flex justify-between text-gray-500 pt-1 mt-1 border-t border-dashed border-gray-200">
                                             <span>Taxable Amount</span> <span>{formatCurrency(taxableAmount)}</span>
                                          </div>
                                       )}
                                       {isGstEnabled && (
                                          <>
                                             {data.gstBreakdown ? (
                                                <>
                                                   {data.gstBreakdown.cgst > 0 && (
                                                      <div className="flex justify-between text-gray-600 pt-1">
                                                         <span>CGST</span> <span>+ {formatCurrency(data.gstBreakdown.cgst)}</span>
                                                      </div>
                                                   )}
                                                   {data.gstBreakdown.sgst > 0 && (
                                                      <div className="flex justify-between text-gray-600">
                                                         <span>SGST</span> <span>+ {formatCurrency(data.gstBreakdown.sgst)}</span>
                                                      </div>
                                                   )}
                                                   {data.gstBreakdown.igst > 0 && (
                                                      <div className="flex justify-between text-gray-600 pt-1">
                                                         <span>IGST</span> <span>+ {formatCurrency(data.gstBreakdown.igst)}</span>
                                                      </div>
                                                   )}
                                                </>
                                             ) : (
                                                taxRate > 0 && (
                                                   <div className="flex justify-between text-gray-600 pt-1">
                                                      <span>GST ({taxRate}%)</span> <span>+ {formatCurrency(taxAmount)}</span>
                                                   </div>
                                                )
                                             )}
                                          </>
                                       )}

                                    </div>

                                    <div className="flex justify-between items-center py-2 mt-2 border-t-2 border-gray-800">
                                       <span className="text-base font-bold text-gray-900">Total</span>
                                       <span className="text-lg font-extrabold text-gray-900">{formatCurrency(total)}</span>
                                    </div>

                                    {advance > 0 && (
                                       <div className="flex justify-between text-xs text-green-600 font-bold mt-1">
                                          <span>Advance Paid</span> <span>- {formatCurrency(advance)}</span>
                                       </div>
                                    )}

                                    <div className="flex justify-between pt-2 mt-1 font-bold text-gray-800">
                                       <span>Balance Due</span> <span>{formatCurrency(balance)}</span>
                                    </div>
                                 </div>

                                 {/* Signature */}
                                 <div className="text-center mt-2 w-full flex flex-col items-end">
                                    {signatureImage ? (
                                       <img src={signatureImage} alt="Signature" className="h-14 object-contain mb-1" />
                                    ) : (
                                       <div className="h-12 w-32 border border-dashed border-gray-300 mb-1 rounded flex items-center justify-center text-[10px] text-gray-400">Sign Here</div>
                                    )}
                                    <div className="border-t border-gray-400 pt-1 w-40 text-center">
                                       <p className="font-bold text-gray-900 text-xs truncate">{data.salesPerson?.name || tenant?.name}</p>
                                       <p className="text-[9px] text-gray-500 uppercase tracking-wider font-medium">Authorized Signatory</p>
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
               <div className="px-10 pb-6">
                  <div className="border-t-2 border-gray-800 pt-4 flex flex-row justify-between items-end gap-0">
                     <div className="w-full w-3/4 pr-6">
                        <h4 className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Terms & Conditions</h4>
                        <p className="text-[10px] text-gray-600 leading-relaxed whitespace-pre-wrap line-clamp-2">
                           {data.terms || tenant.defaultTerms || "Payment is due within 15 days."}
                        </p>
                        {data.placeOfSupply && (
                           <p className="text-[9px] text-gray-500 mt-2 font-semibold">
                               Place of Supply: {data.placeOfSupply} &nbsp;|&nbsp; Dispatch State: {tenant.state || "Not set"}
                           </p>
                        )}

                     </div>
                     <div className="text-right text-[10px] text-gray-400">
                        <p className="font-bold text-gray-500">{tenant.name}</p>
                        <p className="print:block hidden after:content-[counter(page)] after:ml-1">Page</p>
                     </div>
                  </div>
               </div>
            </div>

         </div>
      </>
   );
};

export default StandardTemplate;