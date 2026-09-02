import React, { useState, useEffect, useContext, useRef } from "react";
import { useParams, Link } from "react-router-dom";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useReactToPrint } from 'react-to-print';
import { renderToStaticMarkup } from 'react-dom/server';
import { ArrowLeft, Download, Printer, Mail, MessageCircle, Loader2, Hexagon, Share2 } from "lucide-react";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import TemplateSelector from "../components/TemplateSelector";
import A4Wrapper from "../components/A4Wrapper";
import ConfirmModal from "../components/ConfirmModal";

const ViewInvoice = () => {
  const { id } = useParams();
  const { token } = useContext(AuthContext);

  const [invoice, setInvoice] = useState(null);
  const [tenant, setTenant] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [selectedTemplate, setSelectedTemplate] = useState('standard');
  const [downloading, setDownloading] = useState(false);
  const [sendingEmail, setSendingEmail] = useState(false);
  const [emailModalOpen, setEmailModalOpen] = useState(false);

  const invoiceRef = useRef(null);


  // --- 1. DATA FETCHING ---
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [resInvoice, resTenant] = await Promise.all([
          api.get(`/invoices/${id}`),
          api.get(`/auth/settings`)
        ]);
        setInvoice(resInvoice.data.data);
        setTenant(resTenant.data.data);

        if (resTenant.data.data.templatePreference) {
          setSelectedTemplate(resTenant.data.data.templatePreference);
        }
      } catch (err) {
        console.error("Error fetching data:", err);
        setError("Failed to load invoice data.");
      } finally {
        setLoading(false);
      }
    };
    if (token) fetchData();
  }, [id, token]);

  // --- ✅ 2. SMART IMAGE COMPRESSOR (Added for Safety) ---
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
      const MAX_WIDTH = 500;
      let width = bitmap.width;
      let height = bitmap.height;

      if (width > MAX_WIDTH) {
        height = (height * MAX_WIDTH) / width;
        width = MAX_WIDTH;
      }

      canvas.width = width;
      canvas.height = height;

      ctx.drawImage(bitmap, 0, 0, width, height);
      return canvas.toDataURL('image/jpeg', 0.6);

    } catch (e) {
      console.warn("Image load failed, skipping:", url);
      return "";
    }
  };

  // --- 3. ACTIONS ---

  const handlePrint = useReactToPrint({
    contentRef: invoiceRef,
    documentTitle: invoice ? `Invoice-${invoice.invoiceNumber}` : 'Invoice',
  });

  const handleDownloadPDF = async () => {
    setDownloading(true);
    try {
      const [logoB64, signatureB64, authSignB64, salesSignB64] = await Promise.all([
        getCompressedBase64(tenant?.logoImage),
        getCompressedBase64(tenant?.signatureImage),
        getCompressedBase64(invoice?.authorizedSignatoryImage),
        getCompressedBase64(invoice?.salesPerson?.signatureImage)
      ]);

      const pdfTenant = {
        ...tenant,
        logoImage: logoB64,
        signatureImage: signatureB64
      };

      const pdfInvoice = {
        ...invoice,
        authorizedSignatoryImage: authSignB64,
        salesPerson: invoice.salesPerson ? {
          ...invoice.salesPerson,
          signatureImage: salesSignB64
        } : null
      };

      const componentHtml = renderToStaticMarkup(
        <TemplateSelector
          data={pdfInvoice}
          tenant={pdfTenant}
          type="invoice"
        />
      );

      const fullHtml = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <title>Invoice-${invoice.invoiceNumber}</title>
            <script src="https://cdn.tailwindcss.com"></script>
            <style>
                @page {
                    size: A4;
                    margin: 0; 
                }
                body {
                    margin: 0; padding: 0; background: white;
                    font-family: sans-serif;
                    -webkit-print-color-adjust: exact; print-color-adjust: exact;
                }
                thead { display: table-header-group; }
                img { max-width: 100%; display: block; } 
                td img, div img { min-height: 50px; }
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
        `/invoices/${id}/download`,
        { html: fullHtml },
        {
          responseType: 'blob'
        }
      );

      if (res.headers['content-type'] && res.headers['content-type'].includes('application/json')) {
        const text = await res.data.text();
        const jsonError = JSON.parse(text);
        toast.error("Server Error: " + (jsonError.message || "Unknown Error"));
        return;
      }

      const url = window.URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Invoice-${invoice.invoiceNumber}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();

    } catch (e) {
      console.error("Download Error:", e);
      toast.error("Failed to download PDF.");
    } finally {
      setDownloading(false);
    }
  };

  const handleEmailClick = () => {
    if (!invoice.client?.email) return toast.error("Client email not found.");
    setEmailModalOpen(true);
  };

  const executeEmail = async () => {
    setSendingEmail(true);
    try {
      await api.post(`/invoices/${id}/email?template=${selectedTemplate}`);
      toast.success(`Email sent successfully!`);
    } catch (e) {
      toast.error(e.response?.data?.message || "Failed to send email.");
    } finally { setSendingEmail(false); }
  };

  const handleWhatsApp = async () => {
    try {
      const res = await api.post(`/invoices/${id}/whatsapp`);
      window.open(res.data.whatsappUrl, '_blank');
    } catch (e) { toast.error("Error generating WhatsApp link"); }
  };

  if (loading) return <Layout><div className="flex h-screen items-center justify-center"><Loader2 className="animate-spin text-blue-600" /></div></Layout>;
  if (error) return <Layout><div className="p-10 text-center text-red-500">{error}</div></Layout>;

  return (
    <Layout>
      <div className="max-w-6xl mx-auto mb-10 pb-20 px-4 font-sans">

        {/* Action Bar */}
        <div className="flex flex-col lg:flex-row justify-between items-center mb-8 gap-4 bg-white p-4 rounded-2xl border border-slate-200 shadow-sm no-print">
          <div className="flex items-center gap-4">
            <Link to="/invoices" className="p-2.5 bg-slate-50 rounded-xl hover:bg-slate-100"><ArrowLeft size={20} /></Link>
            <div>
              {/* DISPLAY NUMBER FIX IN UI */}
              <h1 className="text-xl font-black text-slate-900 uppercase">
                {invoice.invoiceNumber}
              </h1>
              <div className="flex items-center gap-1.5 mt-1">
                <Hexagon size={10} className="text-blue-600" fill="currentColor" fillOpacity={0.2} />
                <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Auriva Invoice</p>
              </div>
            </div>
          </div>

          <div className="flex gap-2 flex-wrap">
            <button onClick={handleWhatsApp} className="px-4 py-2 bg-green-50 text-green-700 rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-green-100 border border-green-100"><MessageCircle size={16} /> WhatsApp</button>
            <button 
              onClick={handleEmailClick}
              disabled={sendingEmail}
              className="flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl font-bold bg-white border border-gray-200 text-gray-700 hover:bg-gray-50 hover:text-blue-600 transition-all shadow-sm"
            >  {sendingEmail ? <Loader2 size={16} className="animate-spin" /> : <Mail size={16} />} Email
            </button>
            <div className="hidden lg:block w-[1px] bg-slate-200 mx-1"></div>
            
            <button 
              onClick={() => {
                const url = `https://app.aurivabms.in/public/invoice/${id}`;
                navigator.clipboard.writeText(url);
                toast.success("Public link copied to clipboard!");
              }}
              className="px-4 py-2 border rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-gray-50 text-slate-600"
            >
              <Share2 size={16} /> Copy Link
            </button>

            <button onClick={handlePrint} className="px-4 py-2 border rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-gray-50"><Printer size={16} /> Print</button>

            {/* DOWNLOAD BUTTON */}
            <button onClick={handleDownloadPDF} disabled={downloading} className="px-5 py-2 bg-slate-900 text-white rounded-xl flex items-center gap-2 font-bold text-xs hover:bg-black shadow-lg shadow-slate-200 disabled:opacity-50">
              {downloading ? <Loader2 size={16} className="animate-spin" /> : <Download size={16} />}
              {downloading ? "Compressing..." : "Download PDF"}
            </button>
          </div>

        </div>

        {/* Preview Container */}
        <div className="bg-slate-100 p-4 md:p-8 rounded-3xl border flex justify-center shadow-inner ring-8 ring-slate-50">
          <A4Wrapper>
            <div ref={invoiceRef}>
              <TemplateSelector data={invoice} tenant={tenant} type="invoice" />
            </div>
          </A4Wrapper>
        </div>
      </div>
      
      <ConfirmModal
        isOpen={emailModalOpen}
        onClose={() => setEmailModalOpen(false)}
        onConfirm={executeEmail}
        title="Send Invoice Email"
        message={`Are you sure you want to send this invoice to ${invoice?.client?.email}?`}
        confirmText="Yes, Send"
        type="info"
      />
    </Layout>
  );
};

export default ViewInvoice;