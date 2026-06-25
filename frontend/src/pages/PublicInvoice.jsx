import React, { useState, useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import { renderToStaticMarkup } from 'react-dom/server';
import TemplateSelector from "../components/TemplateSelector";
import A4Wrapper from "../components/A4Wrapper";
import { Hexagon as HexagonIcon, Printer as PrinterIcon, Download as DownloadIcon, Loader2, AlertCircle } from "lucide-react";
import api from "../utils/api";

const PublicInvoice = () => {
  const { id } = useParams();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [downloading, setDownloading] = useState(false);
  const invoiceRef = useRef(null);

  useEffect(() => {
    const fetchPublicData = async () => {
      try {
        const res = await api.get(`/invoices/public/${id}`);
        setData(res.data.data);
      } catch (err) {
        console.error("Error fetching public invoice:", err);
        setError("This invoice link is invalid or has expired.");
      } finally {
        setLoading(false);
      }
    };
    fetchPublicData();
  }, [id]);

  const handlePrint = () => {
    window.print();
  };

  const handleDownloadPDF = async () => {
    if (!data) return;
    setDownloading(true);
    try {
      const { invoice, business } = data;
      
      const componentHtml = renderToStaticMarkup(
        <TemplateSelector data={invoice} tenant={business} type="invoice" />
      );

      const fullHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <title>Invoice-${invoice.invoiceNumber}</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <style>
                @page { size: A4; margin: 0; }
                body { margin: 0; padding: 0; background: white; font-family: sans-serif; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
                thead { display: table-header-group; }
                img { max-width: 100%; display: block; } 
            </style>
          </head>
          <body>
            <div style="width: 100%; max-width: 100%;">
                ${componentHtml}
            </div>
          </body>
        </html>
      `;

      const res = await api.post(
        `/invoices/public/${id}/download`,
        { html: fullHtml },
        { responseType: 'blob' }
      );

      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Invoice-${invoice.invoiceNumber}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();

    } catch (e) {
      console.error("Download Error:", e);
      alert("Failed to download PDF.");
    } finally {
      setDownloading(false);
    }
  };

  if (loading) return (
    <div className="flex h-screen items-center justify-center bg-slate-50">
      <div className="text-center">
        <Loader2 className="animate-spin text-blue-600 mx-auto mb-4" size={40} />
        <p className="text-slate-500 font-medium">Securing your invoice connection...</p>
      </div>
    </div>
  );

  if (error) return (
    <div className="flex h-screen items-center justify-center bg-slate-50 p-4">
      <div className="max-w-md w-full bg-white p-8 rounded-3xl shadow-xl border border-red-100 text-center">
        <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
          <AlertCircle className="text-red-500" size={32} />
        </div>
        <h1 className="text-2xl font-black text-slate-900 mb-2">Access Denied</h1>
        <p className="text-slate-500 mb-8">{error}</p>
        <button onClick={() => window.location.reload()} className="w-full py-3 bg-slate-900 text-white rounded-xl font-bold hover:bg-black transition-all">
          Try Again
        </button>
      </div>
    </div>
  );

  const { invoice, business } = data;

  return (
    <div className="min-h-screen bg-slate-50 py-10 px-4 font-sans print:bg-white print:py-0 print:px-0">
      <div className="max-w-5xl mx-auto">
        
        {/* Public Header - no-print */}
        <div className="flex flex-col md:flex-row justify-between items-center mb-8 gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm no-print">
          <div className="flex items-center gap-4">
            <div>
              <h1 className="text-lg font-black text-slate-900 uppercase leading-none">
                Invoice #{invoice.invoiceNumber}
              </h1>
              <p className="text-[11px] text-slate-400 font-bold uppercase tracking-widest mt-1">
                From {business.name}
              </p>
            </div>
          </div>

          <div className="flex gap-3">
            <button 
              onClick={handlePrint}
              className="px-4 py-2.5 bg-slate-100 text-slate-700 rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-slate-200 transition-colors"
            >
              <PrinterIcon size={16} /> Print
            </button>
            <button 
              onClick={handleDownloadPDF}
              disabled={downloading}
              className="px-6 py-2.5 bg-slate-900 text-white rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-black transition-all disabled:opacity-50"
            >
              {downloading ? <Loader2 className="animate-spin" size={16} /> : <DownloadIcon size={16} />} 
              {downloading ? "Generating..." : "Download PDF"}
            </button>
          </div>
        </div>

        {/* Invoice Render Area */}
        <div className="bg-slate-100 p-0 md:p-4 rounded-xl flex justify-center w-full">
           <A4Wrapper>
             <div ref={invoiceRef}>
                <TemplateSelector data={invoice} tenant={business} type="invoice" />
             </div>
           </A4Wrapper>
        </div>

        {/* Public Footer - no-print */}
        <div className="mt-12 text-center no-print">
          <p className="mt-4 text-[10px] text-slate-400 font-medium uppercase tracking-widest">
            Secure Digital Invoice • {business.name}
          </p>
        </div>

      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        @media print {
          .no-print { display: none !important; }
          body { background: white !important; }
          .min-h-screen { min-height: auto !important; padding: 0 !important; }
        }
      `}} />
    </div>
  );
};

export default PublicInvoice;
