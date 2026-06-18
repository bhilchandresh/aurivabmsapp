import React, { useState, useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import { Download, Printer, Loader2, Hexagon, AlertCircle } from "lucide-react";
import TemplateSelector from "../components/TemplateSelector";
import { renderToStaticMarkup } from 'react-dom/server';
import A4Wrapper from "../components/A4Wrapper";

// Using axios directly or a simplified api instance for public requests
const publicApi = axios.create({
  baseURL: import.meta.env.VITE_API_URL 
    ? `${import.meta.env.VITE_API_URL}/api/v1` 
    : 'http://localhost:5001/api/v1',
  headers: { 'Content-Type': 'application/json' }
});

const PublicQuotation = () => {
  const { id } = useParams();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [downloading, setDownloading] = useState(false);
  const quotationRef = useRef(null);

  useEffect(() => {
    const fetchPublicData = async () => {
      try {
        const res = await publicApi.get(`/quotations/public/${id}`);
        setData(res.data.data);
      } catch (err) {
        console.error("Error fetching public quotation:", err);
        setError("This proposal link is invalid or has expired.");
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
      const { quotation, business } = data;
      
      const componentHtml = renderToStaticMarkup(
        <TemplateSelector data={quotation} tenant={business} type="quotation" />
      );

      const fullHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <title>Proposal-${quotation.quotationNumber}</title>
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

      const res = await publicApi.post(
        `/quotations/public/${id}/download`,
        { html: fullHtml },
        { responseType: 'blob' }
      );

      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Proposal-${quotation.quotationNumber}.pdf`);
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
        <p className="text-slate-500 font-medium">Securing your proposal connection...</p>
      </div>
    </div>
  );

  if (error) return (
    <div className="flex h-screen items-center justify-center bg-slate-50 p-4">
      <div className="max-w-md w-full bg-white p-8 rounded-3xl shadow-xl border border-red-100 text-center">
        <div className="w-16 h-16 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
          <AlertCircle className="text-red-500" size={32} />
        </div>
        <h1 className="text-2xl font-black text-slate-900 mb-2">Proposal Unavailable</h1>
        <p className="text-slate-500 mb-8">{error}</p>
        <button onClick={() => window.location.reload()} className="w-full py-3 bg-slate-900 text-white rounded-xl font-bold hover:bg-black transition-all">
          Try Again
        </button>
      </div>
    </div>
  );

  const { quotation, business } = data;

  return (
    <div className="min-h-screen bg-slate-50 py-10 px-4 font-sans print:bg-white print:py-0 print:px-0">
      <div className="max-w-5xl mx-auto">
        
        {/* Public Header - no-print */}
        <div className="flex flex-col md:flex-row justify-between items-center mb-8 gap-4 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm no-print">
          <div className="flex items-center gap-4">
            <div>
              <h1 className="text-lg font-black text-slate-900 uppercase leading-none">
                Proposal #{quotation.quotationNumber}
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
              <Printer size={16} /> Print
            </button>
            <button 
              onClick={handleDownloadPDF}
              disabled={downloading}
              className="px-6 py-2.5 bg-slate-900 text-white rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-black transition-all disabled:opacity-50"
            >
              {downloading ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />} 
              {downloading ? "Generating..." : "Download PDF"}
            </button>
          </div>
        </div>

        {/* Invoice Render Area */}
        <div className="bg-slate-100 p-0 md:p-4 rounded-xl flex justify-center w-full">
           <A4Wrapper>
             <div ref={quotationRef}>
                <TemplateSelector data={quotation} tenant={business} type="quotation" />
             </div>
           </A4Wrapper>
        </div>

        {/* Public Footer - no-print */}
        <div className="mt-12 text-center no-print">
          <p className="mt-4 text-[10px] text-slate-400 font-medium uppercase tracking-widest">
            Official Proposal • {business.name}
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

export default PublicQuotation;
