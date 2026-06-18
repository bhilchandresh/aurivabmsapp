import React, { useRef, useState, useEffect, useContext } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../utils/api';
import toast from 'react-hot-toast';
import { useReactToPrint } from 'react-to-print';
import { renderToStaticMarkup } from 'react-dom/server';
import { 
  Download, ArrowLeft, Loader2, Printer, Mail, MessageCircle, Hexagon, Share2 
} from 'lucide-react';
import { AuthContext } from '../context/AuthContext';
import Layout from '../components/Layout';
import TemplateSelector from '../components/TemplateSelector'; 
import A4Wrapper from '../components/A4Wrapper'; 

const ViewQuotation = () => {
  const { id } = useParams();
  const { token } = useContext(AuthContext);
  
  const [quotation, setQuotation] = useState(null);
  const [tenant, setTenant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Track selected template
  const [selectedTemplate, setSelectedTemplate] = useState('standard');

  const [downloading, setDownloading] = useState(false);
  const [sendingEmail, setSendingEmail] = useState(false);

  const componentRef = useRef();

  // --- 1. DATA FETCHING ---
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [qRes, tRes] = await Promise.all([
           api.get(`/quotations/${id}`),
           api.get(`/auth/settings`)
        ]);
        setQuotation(qRes.data.data);
        setTenant(tRes.data.data || {}); 
        
        if (tRes.data.data.quotationTemplate) {
            setSelectedTemplate(tRes.data.data.quotationTemplate);
        }
      } catch (err) { 
        console.error("View Quote Error:", err);
        setError("Failed to load quotation data.");
      } finally { 
        setLoading(false); 
      }
    };
    if (token) fetchData();
  }, [id, token]);

  // --- ✅ 2. IMAGE COMPRESSOR (SIZE FIX) ---
  // Ye function image ko load karta hai, resize karta hai aur JPEG me badal deta hai.
  // Isse payload size chhota ho jata hai aur "Failed to load PDF" error nahi aata.
  const getCompressedBase64 = async (url) => {
    if (!url) return "";
    if (url.startsWith("data:")) return url; 

    try {
        const fullUrl = url.startsWith("http") ? url : `${API_URL}${url.startsWith("/") ? "" : "/"}${url}`;
        
        const response = await api.get(fullUrl, { 
            responseType: 'blob' 
        });

        const bitmap = await createImageBitmap(response.data);
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');

        // Resize Logic: Max Width 500px (PDF ke liye kaafi hai)
        const MAX_WIDTH = 500;
        let width = bitmap.width;
        let height = bitmap.height;

        if (width > MAX_WIDTH) {
            height = (height * MAX_WIDTH) / width;
            width = MAX_WIDTH;
        }

        canvas.width = width;
        canvas.height = height;

        // Draw & Compress (JPEG 60% Quality)
        ctx.drawImage(bitmap, 0, 0, width, height);
        return canvas.toDataURL('image/jpeg', 0.6); 

    } catch (e) {
        console.warn("Image load failed:", url);
        return ""; 
    }
  };

  // --- 3. DOWNLOAD PDF ACTION (LOGIC FIXED) ---
  const handleDownloadPDF = async () => {
    setDownloading(true);
    try {
      // Step A: Compress All Images
      const [logoB64, tenantSignB64, quoteSignB64, salesSignB64] = await Promise.all([
          getCompressedBase64(tenant?.logoImage),
          getCompressedBase64(tenant?.signatureImage), // Tenant Default
          getCompressedBase64(quotation?.authorizedSignatoryImage), // Quote Specific
          getCompressedBase64(quotation?.salesPerson?.signatureImage) // Sales Person
      ]);

      // ✅ FIX 1: DETERMINE FINAL SIGNATURE
      // Priority: Quote Specific > Sales Person > Tenant Default
      const finalSignature = quoteSignB64 || salesSignB64 || tenantSignB64;

      // ✅ FIX 2: DETERMINE FINAL NUMBER
      const finalNumber = quotation.quotationNumber || quotation.quoteNumber || "DRAFT";

      // Step B: Prepare Data for PDF Generation
      const pdfTenant = { 
          ...tenant, 
          logoImage: logoB64, 
          signatureImage: tenantSignB64 
      };

      const pdfQuotation = {
          ...quotation,
          
          // ⚠️ IMPORTANT: Map fields so Invoice Templates can read them
          invoiceNumber: finalNumber,      // Mapping for templates using 'invoiceNumber'
          quotationNumber: finalNumber,    // Original field
          
          dueDate: quotation.validUntil,   // Mapping for templates using 'dueDate'
          
          // Force Signature
          authorizedSignatoryImage: finalSignature,
          
          // Populate SalesPerson object correctly
          salesPerson: quotation.salesPerson ? {
              ...quotation.salesPerson,
              signatureImage: finalSignature
          } : { name: tenant.name, signatureImage: finalSignature }
      };

      // Step C: Generate HTML from Template
      const componentHtml = renderToStaticMarkup(
        <TemplateSelector data={pdfQuotation} tenant={pdfTenant} type="quotation" />
      );

      // Step D: Wrap HTML & CSS
      const fullHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <script src="https://cdn.tailwindcss.com"></script>
            <style>
                @page { size: A4; margin: 0; }
                body { margin: 0; padding: 0; font-family: sans-serif; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
                
                /* Layout Safety */
                .print-container { width: 100%; }
                thead { display: table-header-group; }
                
                /* Image Safety */
                img { max-width: 100%; display: block; } 
                td img, div img { min-height: 40px; }
            </style>
          </head>
          <body>
            <div class="print-container">
                ${componentHtml}
            </div>
          </body>
        </html>
      `;

      // Step E: Send HTML to Backend
      const res = await api.post(
        `/quotations/${id}/download`, 
        { html: fullHtml }, 
        { responseType: 'blob' }
      );

      // Step F: Check for Error Response (JSON hidden in Blob)
      if (res.headers['content-type'] && res.headers['content-type'].includes('application/json')) {
          const text = await res.data.text();
          const json = JSON.parse(text);
          toast.error("Server Error: " + (json.message || "Unknown error"));
          return;
      }

      // Step G: Download File
      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Quotation-${finalNumber}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      
    } catch (e) {
      console.error("Download Error:", e);
      toast.error("Failed to download PDF. Please try printing.");
    } finally {
      setDownloading(false);
    }
  };

  // --- OTHER ACTIONS ---
  const handlePrint = useReactToPrint({
    contentRef: componentRef,
    documentTitle: quotation ? `Quote-${quotation.quotationNumber}` : 'Quotation',
  });

  const handleEmail = async () => {
    if(!quotation.client?.email) return toast.error("Client email not found.");
    if(!window.confirm(`Send quotation to ${quotation.client.email}?`)) return;
    setSendingEmail(true);
    try {
        // Send selected template to backend for email generation
        await api.post(`/quotations/${id}/email?template=${selectedTemplate}`);
        toast.success(`Email sent successfully!`);
    } catch(e) {
        toast.error(e.response?.data?.message || "Failed to send email.");
    } finally { setSendingEmail(false); }
  };

  const handleWhatsApp = async () => {
    const text = encodeURIComponent(`*Quotation ${quotation.quotationNumber}* from ${tenant.name}\nTotal: ₹${quotation.totalAmount}`);
    window.open(`https://wa.me/${quotation.client.phone}?text=${text}`, '_blank');
  };

  if (loading) return <Layout><div className="flex h-screen items-center justify-center"><Loader2 className="animate-spin text-[#2563eb]"/></div></Layout>;
  if (error) return <Layout><div className="p-10 text-center text-red-500">{error}</div></Layout>;

  return (
    <Layout>
      <div className="max-w-6xl mx-auto mb-10 pb-20 px-4 font-sans">
        
        {/* Action Bar */}
        <div className="flex flex-col lg:flex-row justify-between items-center mb-8 gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm no-print">
           <div className="flex items-center gap-4">
               <Link to="/quotations" className="p-2.5 bg-slate-50 rounded-xl hover:bg-slate-100"><ArrowLeft size={20}/></Link>
               <div>
                  {/* DISPLAY NUMBER FIX IN UI */}
                  <h1 className="text-xl font-black text-slate-900 uppercase">
                    {quotation.quotationNumber || quotation.quoteNumber}
                  </h1>
                  <div className="flex items-center gap-1.5 mt-1">
                    <Hexagon size={10} className="text-blue-600" fill="currentColor" fillOpacity={0.2} />
                    <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Auriva Proposal</p>
                  </div>
               </div>
           </div>
           
           <div className="flex gap-2 flex-wrap">
             <button onClick={handleWhatsApp} className="px-4 py-2 bg-green-50 text-green-700 rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-green-100 border border-green-100"><MessageCircle size={16}/> WhatsApp</button>
             <button onClick={handleEmail} disabled={sendingEmail} className="px-4 py-2 bg-blue-50 text-blue-600 rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-blue-100 border border-blue-100 disabled:opacity-50">
               {sendingEmail ? <Loader2 size={16} className="animate-spin"/> : <Mail size={16}/>} Email
             </button>
             <div className="hidden lg:block w-[1px] bg-slate-200 mx-1"></div>

             <button 
              onClick={() => {
                const url = `${window.location.origin}/public/quotation/${id}`;
                navigator.clipboard.writeText(url);
                toast.success("Proposal link copied!");
              }}
              className="px-4 py-2 border rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-gray-50 text-slate-600"
            >
              <Share2 size={16} /> Copy Link
            </button>

             <button onClick={handlePrint} className="px-4 py-2 border rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-gray-50"><Printer size={16}/> Print</button>
             
             {/* DOWNLOAD BUTTON */}
             <button onClick={handleDownloadPDF} disabled={downloading} className="px-5 py-2 bg-slate-900 text-white rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-black shadow-lg shadow-slate-200 disabled:opacity-50">
               {downloading ? <Loader2 size={16} className="animate-spin"/> : <Download size={16}/>}
               {downloading ? "Compressing..." : "Download PDF"}
             </button>
           </div>
        </div>

        {/* Preview Container */}
        <div className="bg-slate-100 p-4 md:p-8 rounded-3xl border flex justify-center shadow-inner ring-8 ring-slate-50">
          <A4Wrapper>
            <div ref={componentRef}>
              <TemplateSelector data={quotation} tenant={tenant} type="quotation" />
            </div>
          </A4Wrapper>
        </div>
      </div>
    </Layout>
  );
};

export default ViewQuotation;