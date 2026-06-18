import React from 'react';

const ClassicTemplate = ({ data, tenant, type = 'invoice' }) => {
  if (!data || !tenant) return null;

  const isInvoice = type === 'invoice';
  const number = isInvoice ? data.invoiceNumber : data.quotationNumber;
  const date = data.date;
  const dueDate = isInvoice ? data.dueDate : data.validUntil;
  const dueDateLabel = isInvoice ? "Due Date" : "Valid Until";
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

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(Number(amount) || 0);
  };

  const subTotal = data.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0);
  const discountAmount = subTotal * (Number(data.discountPercentage) / 100);
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

          .footer-space { height: 70px; }
          .footer-fixed { 
            position: fixed; 
            bottom: 0; 
            left: 0; 
            right: 0;
            width: 100%; 
            z-index: 10; 
            background: white; 
            border-top: 1px solid #000; 
          }
        }

        /* WEB DISPLAY */
        @media screen {
           .footer-space { display: none; }
           .footer-fixed { position: relative; margin-top: auto; border-top: 1px solid #000; }
           .print-container { 
             display: flex; 
             flex-direction: column; 
             min-height: 297mm; 
             background: white;
           }
        }
      `}</style>

      <div className="bg-white w-full mx-auto text-black font-serif print-container flex flex-col p-0 ">

        <div className="flex-1">
          <table className="main-table w-full border-separate border-spacing-0">

            {/* --- HEADER --- */}
            <thead>
              <tr>
                <td>
                  <div className="p-10 border-b-2 border-black">
                    <div className="flex flex-row justify-between items-start gap-0">
                      <div>
                        {/* LOGO */}
                        {tenant.logoImage && (
                          <img
                            src={tenant.logoImage}
                            alt="Logo"
                            className="h-20 mb-4 object-contain grayscale"
                          />
                        )}
                        <h1 className="text-xl font-bold uppercase tracking-wider">{tenant.name}</h1>
                        <div className="text-sm mt-2 space-y-1 font-medium text-gray-700">
                          <p>{tenant.address}</p>
                          <p>
                            {tenant.email} {tenant.phone && `| ${tenant.phone}`}
                            {tenant.website && ` | ${tenant.website}`}
                          </p>
                          {isGstEnabled && tenant.gstNumber && <p className="font-bold text-black">GSTIN: {tenant.gstNumber}</p>}
                        </div>
                      </div>
                      <div className="text-right  w-auto  ">
                        <h2 className="text-3xl font-bold text-gray-200 uppercase tracking-tighter">{isInvoice ? "INVOICE" : "QUOTE"}</h2>
                        <p className="text-lg font-bold mt-2">{number}</p>
                        <div className="mt-4 text-sm">
                          <p>Date: <strong>{new Date(date).toLocaleDateString()}</strong></p>
                          <p>{dueDateLabel}: <strong>{new Date(dueDate).toLocaleDateString()}</strong></p>
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

            {/* --- BODY (SPLIT INTO 4 ROWS FOR PERFECT PAGINATION) --- */}
            <tbody>

              {/* ROW 1: CLIENT & BANK INFO GRID */}
              <tr className="avoid-break">
                <td className="px-10 align-top">
                  <div className="flex flex-row justify-between items-start mb-8 gap-0">
                    {/* Bill To */}
                    <div className="w-[45%]">
                      <h3 className="text-xs font-bold uppercase border-b border-black w-fit mb-2 pb-1">{isInvoice ? "Bill To" : "Quote To"}</h3>
                      <p className="font-bold text-lg">{data.client.name}</p>
                      <p className="text-sm whitespace-pre-line leading-relaxed">{data.client.address}</p>
                      {isGstEnabled && data.client.gstNumber && <p className="text-sm font-bold mt-1">GSTIN: {data.client.gstNumber}</p>}
                    </div>

                    {/* Bank Info */}
                    <div className="w-[45%] text-right">
                      <div className="ml-auto w-fit">
                        <h3 className="text-xs font-bold uppercase border-b border-black w-fit mb-2 pb-1">Payment Details</h3>
                        {bankDetails && bankDetails.accountNumber ? (
                          <div className="text-sm space-y-1">
                            {bankDetails.accountName && (
                              <p><span className="text-gray-600">Name:</span> <strong>{bankDetails.accountName}</strong></p>
                            )}
                            <p><span className="text-gray-600">Bank:</span> <strong>{bankDetails.bankName}</strong></p>
                            <p><span className="text-gray-600">Account:</span> <strong className="font-mono">{bankDetails.accountNumber}</strong></p>
                            <p><span className="text-gray-600">IFSC:</span> <strong className="font-mono">{bankDetails.ifscCode}</strong></p>
                          </div>
                        ) : (
                          <p className="text-sm italic text-gray-500">No bank details available.</p>
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
                    <table className="w-full min-w-0 text-xs table-fixed border-separate border-spacing-0 border-2 border-black">
                      <thead className="bg-gray-100 text-black border-b-2 border-black" style={{ WebkitPrintColorAdjust: 'exact' }}>
                        <tr>
                          <th className="py-3 px-2 text-center border-r border-black w-[5%] font-bold uppercase tracking-wider text-[10px]">#</th>

                          <th className={`py-3 px-2 text-left border-r border-black ${showHsn ? 'w-[35%]' : 'w-[50%]'} font-bold uppercase tracking-wider text-[10px]`}>Description</th>

                          {showHsn && <th className="py-3 px-2 text-center border-r border-black w-[15%] font-bold uppercase tracking-wider text-[10px]">HSN/SAC</th>}

                          <th className="py-3 px-2 text-center border-r border-black w-[10%] font-bold uppercase tracking-wider text-[10px]">Qty</th>
                          <th className="py-3 px-2 text-right border-r border-black w-[15%] font-bold uppercase tracking-wider text-[10px]">Rate</th>
                          <th className="py-3 px-2 text-right w-[20%] font-bold uppercase tracking-wider text-[10px]">Amount</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-300">
                        {data.items.map((item, index) => (
                          <tr key={index} className="border-b border-gray-300 avoid-break">
                            <td className="py-4 px-2 text-center border-r border-black align-top break-words">{index + 1}</td>
                            <td className="py-4 px-2 border-r border-black align-top break-words pr-2">
                              <p className="font-bold text-sm">{item.description}</p>
                              {item.additionalDetails && (
                                <p className="text-[11px] text-gray-600 mt-1 whitespace-pre-wrap leading-relaxed">
                                  {item.additionalDetails}
                                </p>
                              )}
                            </td>

                            {showHsn && <td className="py-4 px-2 text-center border-r border-black font-mono text-xs align-top break-words">{item.hsnCode || "-"}</td>}

                            <td className="py-4 px-2 text-center border-r border-black font-medium align-top break-words">{item.quantity}</td>
                            <td className="py-4 px-2 text-right border-r border-black font-medium align-top break-words">{formatCurrency(item.rate)}</td>
                            <td className="py-4 px-2 text-right font-bold align-top break-words">{formatCurrency(Number(item.quantity) * Number(item.rate))}</td>
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

                    {/* LEFT: AMOUNT IN WORDS */}
                    <div className="w-[55%] border border-black p-4 mt-1">
                      <h3 className="text-xs font-bold uppercase border-b border-black w-fit mb-2 pb-1">Total Amount (In Words)</h3>
                      <p className="text-sm font-bold text-black leading-snug">
                        {convertNumberToWords(total)}
                      </p>
                    </div>

                    {/* RIGHT: TOTALS BOX */}
                    <div className="w-[40%] flex flex-col items-end">
                      <div className="w-full border border-black p-3 space-y-1.5">
                        <div className="flex justify-between text-sm">
                          <span>Subtotal</span>
                          <span>{formatCurrency(subTotal)}</span>
                        </div>

                        {discountAmount > 0 && (
                          <div className="flex justify-between text-sm text-gray-600">
                            <span>Discount ({data.discountPercentage}%)</span>
                            <span>- {formatCurrency(discountAmount)}</span>
                          </div>
                        )}

                        {isGstEnabled && (
                          <>
                             {data.gstBreakdown ? (
                                <>
                                   {data.gstBreakdown.cgst > 0 && (
                                     <div className="flex justify-between text-sm text-gray-600">
                                       <span>CGST</span><span>{formatCurrency(data.gstBreakdown.cgst)}</span>
                                     </div>
                                   )}
                                   {data.gstBreakdown.sgst > 0 && (
                                     <div className="flex justify-between text-sm text-gray-600">
                                       <span>SGST</span><span>{formatCurrency(data.gstBreakdown.sgst)}</span>
                                     </div>
                                   )}
                                   {data.gstBreakdown.igst > 0 && (
                                     <div className="flex justify-between text-sm text-gray-600">
                                       <span>IGST</span><span>{formatCurrency(data.gstBreakdown.igst)}</span>
                                     </div>
                                   )}
                                </>
                             ) : (
                                taxRate > 0 && (
                                   <div className="flex justify-between text-sm text-gray-600">
                                     <span>GST ({taxRate}%)</span><span>{formatCurrency(taxAmount)}</span>
                                   </div>
                                )
                             )}
                          </>
                        )}

                        <div className="flex justify-between border-t-2 border-black pt-1.5 mt-1.5 text-base font-bold">
                          <span>Total</span>
                          <span>{formatCurrency(total)}</span>
                        </div>

                        {advance > 0 && (
                          <div className="flex justify-between text-sm italic pt-1 text-gray-600">
                            <span>Advance Paid</span>
                            <span>- {formatCurrency(advance)}</span>
                          </div>
                        )}
                      </div>

                      <div className="w-full mt-2 flex justify-between bg-black text-white p-2 font-bold text-xs print:bg-black print:text-white" style={{ WebkitPrintColorAdjust: 'exact' }}>
                        <span>Balance Due</span>
                        <span>{formatCurrency(balance)}</span>
                      </div>
                    </div>
                  </div>
                </td>
              </tr>

              {/* ROW 4: SIGNATURE (Moved from footer) */}
              <tr className="avoid-break">
                <td className="px-10 pb-6">
                  <div className="flex justify-end mt-4">
                     <div className="w-[40%] flex justify-center">
                        <div className="text-center flex flex-col items-center">
                          {/* Signature Image */}
                          {signatureImage ? (
                            <img src={signatureImage} alt="Sign" className="h-14 mb-1 object-contain" />
                          ) : (
                            <div className="h-14 w-32 mb-1 border border-dashed border-gray-400 flex items-center justify-center text-[10px] text-gray-500">Sign Here</div>
                          )}
                          <p className="font-bold text-sm uppercase tracking-wide max-w-[180px] truncate">{data.salesPerson?.name || tenant.name}</p>
                          <p className="text-[10px] uppercase tracking-widest mt-1">Authorized Signatory</p>
                        </div>
                     </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        {/* Footer (Fixed at bottom of every page) */}
        <div className="footer-fixed w-full mt-auto bg-white">
          <div className="px-10 py-4">
            <div className="w-full">
              <h4 className="text-xs font-bold uppercase mb-1 border-b border-gray-400 w-fit">Terms & Conditions</h4>
              <p className="text-xs leading-relaxed whitespace-pre-wrap text-justify line-clamp-2">
                {data.terms || tenant.defaultTerms || "Payment is due upon receipt."}
              </p>
              {data.placeOfSupply && (
                  <p className="text-xs text-gray-600 mt-2 font-semibold">
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

export default ClassicTemplate;