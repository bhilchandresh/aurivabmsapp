import { useState, useEffect, useContext } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useForm } from "react-hook-form";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import { ArrowLeft, Mail, Phone, MapPin, Edit, Trash2, IndianRupee, RefreshCw, Loader2, ArrowUpDown, AlertTriangle } from "lucide-react";
import { getLocalDateString } from "../utils/dateUtils";

const ClientProfile = () => {
   const { id } = useParams();
   const navigate = useNavigate();
   const { token } = useContext(AuthContext);

   const [client, setClient] = useState(null);
   const [invoices, setInvoices] = useState([]);
   const [quotations, setQuotations] = useState([]);
   const [payments, setPayments] = useState([]);
   const [tenant, setTenant] = useState(null);
   const [loading, setLoading] = useState(true);
    const [syncing, setSyncing] = useState(false); // 🔴 Sync Loader
    const [sendingEmail, setSendingEmail] = useState(false); // 📧 Email Loader
   const [activeTab, setActiveTab] = useState('invoices');
   const [sortOrder, setSortOrder] = useState('desc'); // 'desc' = newest first, 'asc' = oldest first

   const [ledgerStartDate, setLedgerStartDate] = useState('');
   const [ledgerEndDate, setLedgerEndDate] = useState('');

   const [isSubmittingPayment, setIsSubmittingPayment] = useState(false);

   const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
   const [isEditModalOpen, setIsEditModalOpen] = useState(false);
   const [clientToDelete, setClientToDelete] = useState(false);

   const [stats, setStats] = useState({ revenue: 0, received: 0, balance: 0 });

   const { register, handleSubmit, setValue } = useForm();
   const [payAmount, setPayAmount] = useState("");
   const [payMode, setPayMode] = useState("UPI");
   const [payDate, setPayDate] = useState(getLocalDateString());
   const [payNote, setPayNote] = useState("");


   const fetchData = async () => {
      setLoading(true);
      try {
         const [resC, resI, resQ, resP, resT] = await Promise.all([
            api.get(`/clients/${id}`),
            api.get(`/invoices?clientId=${id}`).catch(() => ({ data: { data: [] } })),
            api.get(`/quotations?clientId=${id}`).catch(() => ({ data: { data: [] } })),
            api.get(`/clients/${id}/payments`).catch(() => ({ data: { data: [] } })),
            api.get(`/auth/settings`).catch(() => ({ data: { data: null } }))
         ]);

         const clientData = resC.data.data;
         setClient(clientData);
         setInvoices(resI.data.data || []);
         setQuotations(resQ.data.data || []);
         setPayments(resP.data.data || []);
         setTenant(resT.data.data);

         const billed = (resI.data.data || []).reduce((s, i) => s + Number(i.totalAmount || 0), 0);
         const paid = (resP.data.data || []).reduce((s, p) => s + Number(p.amount || 0), 0);
         setStats({ revenue: billed, received: paid, balance: billed - paid });

         setValue("name", clientData.name);
         setValue("email", clientData.email);
         setValue("phone", clientData.phone);
         setValue("address", clientData.address);
         setValue("gstNumber", clientData.gstNumber);

      } catch (err) { console.error(err); }
      finally { setLoading(false); }
   };

   useEffect(() => { if (token && id) fetchData(); }, [id, token]);

   // 🔴 NEW: Sync Ledger Handler
   const handleSyncLedger = async () => {
      setSyncing(true);
      try {
         await api.post(`/clients/${id}/sync-ledger`);
         await fetchData(); // Refresh fresh data from DB
      } catch (error) {
         toast.error("Failed to sync ledger.");
      } finally {
         setSyncing(false);
      }
   };

   const handleCollectPayment = async (e) => {
      e.preventDefault();
      if (Number(payAmount) <= 0) return toast.error("Amount must be greater than 0");
      if (isSubmittingPayment) return;

      setIsSubmittingPayment(true);
      try {
         await api.post(`/clients/${id}/payments`, {
            amount: Number(payAmount), date: payDate, paymentMode: payMode, referenceNote: payNote
         });
         toast.success("Payment collected successfully");

         setIsPaymentModalOpen(false);
         setPayAmount(""); setPayNote("");
         fetchData();
      } catch (err) { 
         toast.error("Payment Failed"); 
      } finally {
         setIsSubmittingPayment(false);
      }
   };

   const onEditSubmit = async (data) => {
      try {
         await api.put(`/clients/${id}`, data);
         setIsEditModalOpen(false);
         toast.success("Client updated successfully");
         fetchData();
      } catch (error) { toast.error("Update Failed"); }
   };

   const handleSendEmailSummary = async () => {
      setSendingEmail(true);
      try {
         await api.post(`/clients/${id}/send-summary`);
         toast.success("Account summary email sent!");
      } catch (error) {
         toast.error("Failed to send email summary.");
         console.error(error);
      } finally {
         setSendingEmail(false);
      }
   };

   const handleSendWhatsApp = () => {
      if (!client) return;

      const balanceText = stats.balance > 0 
         ? `*Outstanding Due:* ₹${stats.balance.toLocaleString('en-IN')}`
         : stats.balance < 0 
            ? `*Advance (Jama):* ₹${Math.abs(stats.balance).toLocaleString('en-IN')}`
            : `*Outstanding Due:* Nil (Account Settled)`;

      // Find the last invoice
      let lastInvoiceText = "";
      if (invoices && invoices.length > 0) {
         const lastInv = [...invoices].sort((a,b) => new Date(b.date) - new Date(a.date))[0];
         const due = (lastInv.remainingAmount === undefined || lastInv.remainingAmount === null) ? lastInv.totalAmount : lastInv.remainingAmount;
         lastInvoiceText = `\n\n*Last Invoice Details:*\nInvoice No: #${lastInv.invoiceNumber}\nDate: ${new Date(lastInv.date).toLocaleDateString()}\nBill Amount: ₹${lastInv.totalAmount.toLocaleString('en-IN')}\nUnpaid on this bill: ₹${due.toLocaleString('en-IN')}`;
      }

      let companySignoff = "\n\nThank you!";
      if (tenant) {
         companySignoff = `\n\n*Regards,*\n*${tenant.name}*\n${tenant.phone ? `${tenant.phone}\n` : ''}${tenant.website ? `${tenant.website}` : ''}`;
      }

      const message = `Hello ${client.name},\n\nHere is your current account summary with us:\n\n*Total Billed:* ₹${stats.revenue.toLocaleString('en-IN')}\n*Total Paid:* ₹${stats.received.toLocaleString('en-IN')}\n${balanceText}${lastInvoiceText}\n\nPlease let us know if you have any questions.${companySignoff}`;

      const encodedMessage = encodeURIComponent(message);
      
      const phoneNo = client.phone ? client.phone.replace(/[^0-9]/g, '') : '';
      let whatsappUrl = `https://wa.me/?text=${encodedMessage}`;
      
      if (phoneNo && phoneNo.length >= 10) {
         // Standardize Indian Numbers just in case
         const finalPhone = phoneNo.length === 10 ? `91${phoneNo}` : phoneNo;
         whatsappUrl = `https://wa.me/${finalPhone}?text=${encodedMessage}`;
      }

      window.open(whatsappUrl, '_blank');
   };

   const handleDeleteClient = async () => {
      await api.delete(`/clients/${id}`);
      toast.success("Client deleted");
      navigate('/clients');
   };

   if (loading) return <Layout><div className="flex justify-center p-20 font-bold text-gray-400">Loading...</div></Layout>;

   return (
      <Layout>
         <div className="max-w-6xl mx-auto p-6 space-y-6">

            <Link to="/clients" className="text-gray-500 hover:text-blue-600 font-medium text-sm flex items-center gap-2 w-fit transition">
               <ArrowLeft size={16} /> Back to Clients List
            </Link>

            {/* TOP CLIENT DETAILS CARD (Redesigned & Responsive) */}
            <div className="bg-white rounded-2xl border border-gray-200 p-5 md:p-8 flex flex-col xl:flex-row justify-between items-start xl:items-center gap-6 shadow-sm">
               
               <div className="flex flex-col sm:flex-row gap-5 items-start sm:items-center w-full xl:w-auto">
                  <div className="h-16 w-16 md:h-24 md:w-24 bg-blue-600 rounded-full flex items-center justify-center text-white text-3xl md:text-4xl font-extrabold shrink-0 shadow-inner">
                     {client.name.charAt(0).toUpperCase()}
                  </div>
                  <div className="space-y-1.5 w-full">
                     <h1 className="text-2xl md:text-3xl font-black text-gray-900 leading-tight tracking-tight">{client.name}</h1>
                     
                     <div className="flex flex-col sm:flex-row sm:flex-wrap gap-2 sm:gap-5 mt-2">
                        <div className="flex items-center gap-2">
                           <p className="flex items-center gap-2 text-sm text-gray-600 font-medium">
                              <Mail size={16} className="text-blue-500 shrink-0" /> {client.email}
                           </p>
                           {client.emailDeliveryStatus === 'bounced' && (
                              <span className="flex items-center gap-1 bg-red-100 text-red-700 text-xs font-bold px-2 py-0.5 rounded-md border border-red-200">
                                 <AlertTriangle size={12} /> Undeliverable
                              </span>
                           )}
                        </div>
                        {client.phone && (
                           <p className="flex items-center gap-2 text-sm text-gray-600 font-medium">
                              <Phone size={16} className="text-emerald-500 shrink-0" /> {client.phone}
                           </p>
                        )}
                        {client.gstNumber && (
                           <p className="flex items-center gap-1.5 text-xs font-bold text-purple-700 bg-purple-50 px-2.5 py-1 rounded-md border border-purple-100 uppercase tracking-wider w-fit">
                              GST: {client.gstNumber}
                           </p>
                        )}
                     </div>

                     <p className="flex items-start gap-2 text-sm text-gray-500 mt-2 max-w-xl">
                        <MapPin size={16} className="text-rose-400 shrink-0 mt-0.5" /> 
                        <span className="leading-snug">{client.address || "No address provided"}</span>
                     </p>
                  </div>
               </div>
               
               {/* ACTION BUTTONS */}
               <div className="grid grid-cols-2 sm:flex sm:flex-wrap sm:justify-end gap-3 w-full xl:w-auto mt-4 xl:mt-0 border-t xl:border-t-0 pt-5 xl:pt-0 border-gray-100">
                  
                  <button onClick={handleSendWhatsApp} className="col-span-1 flex items-center justify-center gap-2 px-3 py-2.5 bg-[#25D366] text-white rounded-xl font-bold hover:bg-[#1DA851] hover:-translate-y-0.5 transition-all shadow-sm border border-[#1DA851] text-sm whitespace-nowrap">
                     <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4 sm:w-5 sm:h-5 shrink-0"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.412z"/></svg> 
                     <span>WhatsApp</span>
                  </button>

                  <button onClick={handleSendEmailSummary} disabled={sendingEmail} className="col-span-1 flex items-center justify-center gap-2 px-3 py-2.5 bg-blue-50 text-blue-700 rounded-xl font-bold hover:bg-blue-100 transition-all shadow-sm border border-blue-200 disabled:opacity-50 text-sm whitespace-nowrap">
                     {sendingEmail ? <Loader2 size={16} className="animate-spin shrink-0" /> : <Mail size={16} className="shrink-0" />}
                     <span>Email</span>
                  </button>

                  <button onClick={() => setIsEditModalOpen(true)} className="col-span-1 flex items-center justify-center gap-2 px-3 py-2.5 border border-gray-300 rounded-xl font-bold text-gray-700 hover:bg-gray-50 transition-all shadow-sm text-sm bg-white whitespace-nowrap">
                     <Edit size={16} className="shrink-0" /> <span>Edit</span>
                  </button>
                  
                  <button onClick={() => setClientToDelete(true)} className="col-span-1 flex items-center justify-center gap-2 px-3 py-2.5 bg-red-50 text-red-600 border border-red-200 rounded-xl font-bold hover:bg-red-100 transition-all shadow-sm text-sm whitespace-nowrap" title="Delete Client">
                     <Trash2 size={16} className="shrink-0" /> <span>Delete</span>
                  </button>
                  
                  <button onClick={() => setIsPaymentModalOpen(true)} className="col-span-2 sm:col-span-1 flex items-center justify-center gap-2 px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 hover:shadow-lg hover:-translate-y-0.5 transition-all shadow-md text-sm ring-2 ring-transparent focus:ring-blue-300 focus:outline-none whitespace-nowrap">
                     <IndianRupee size={16} className="shrink-0" /> Collect Payment
                  </button>

               </div>
            </div>

            {/* STATS ROW (Khatabook Style) */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
               <div className="bg-white border border-gray-200 p-6 rounded-xl shadow-sm">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Total Paid</p>
                  <p className="text-3xl font-bold text-gray-900">₹{stats.received.toLocaleString('en-IN')}</p>
               </div>
               <div className="bg-white border border-gray-200 p-6 rounded-xl shadow-sm">
                  <p className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-1">Total Billed</p>
                  <p className="text-3xl font-bold text-gray-900">₹{stats.revenue.toLocaleString('en-IN')}</p>
               </div>

               {/* 🔴 Sync Ledger Header on the Advance Card */}
               <div className={`border p-6 rounded-xl shadow-sm relative ${stats.balance < 0 ? 'bg-blue-50 border-blue-200' : stats.balance === 0 ? 'bg-emerald-50 border-emerald-200' : 'bg-rose-50 border-rose-200'}`}>

                  {/* Sync Button inside the card */}
                  <button onClick={handleSyncLedger} disabled={syncing} title="Fix mismatch in bills" className="absolute top-4 right-4 text-gray-400 hover:text-blue-600 bg-white p-1.5 rounded-md border shadow-sm transition">
                     {syncing ? <Loader2 size={14} className="animate-spin" /> : <RefreshCw size={14} />}
                  </button>

                  <p className={`text-xs font-bold uppercase tracking-widest mb-1 ${stats.balance < 0 ? 'text-blue-600' : stats.balance === 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                     {stats.balance < 0 ? 'Advance (Jama) +' : 'Outstanding Due'}
                  </p>
                  <p className={`text-3xl font-bold ${stats.balance < 0 ? 'text-blue-700' : stats.balance === 0 ? 'text-emerald-700' : 'text-rose-700'}`}>
                     ₹{Math.abs(stats.balance).toLocaleString('en-IN')}
                  </p>
               </div>
            </div>

            {/* TABS & TABLES */}
            <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
               <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-gray-200 bg-gray-50/50">
                  <div className="flex overflow-x-auto w-full sm:w-auto scrollbar-hide">
                     {['invoices', 'quotations', 'ledger'].map((tab) => (
                        <button
                           key={tab}
                           onClick={() => setActiveTab(tab)}
                           className={`whitespace-nowrap px-5 py-4 text-xs sm:text-sm font-bold uppercase tracking-wider transition-all border-b-2 ${activeTab === tab ? 'text-blue-600 border-blue-600 bg-white' : 'text-gray-400 border-transparent hover:text-gray-600'}`}
                        >
                           {tab === 'invoices' ? 'Invoices' : tab === 'quotations' ? 'Quotations' : 'Statement (Ledger)'}
                        </button>
                     ))}
                  </div>
                  {/* Sort Filter */}
                  <div className="px-4 py-3 sm:py-0 border-t sm:border-t-0 flex items-center gap-2 shrink-0 bg-white sm:bg-transparent justify-end">
                     <ArrowUpDown size={14} className="text-gray-400 shrink-0" />
                     <select
                        value={sortOrder}
                        onChange={e => setSortOrder(e.target.value)}
                        className="text-xs font-bold text-gray-600 border border-gray-200 rounded-lg px-2 py-1.5 bg-white outline-none focus:ring-2 focus:ring-blue-500 cursor-pointer w-auto"
                     >
                        <option value="desc">Newest First</option>
                        <option value="asc">Oldest First</option>
                     </select>
                  </div>
               </div>

               <div className="p-0">
                  {/* INVOICES TABLE */}
                  {activeTab === 'invoices' && (
                     <div className="overflow-x-auto">
                        <table className="w-full text-left">
                           <thead className="bg-white border-b border-gray-100">
                              <tr>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Date</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Invoice #</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Total</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Pending</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-center whitespace-nowrap">Status</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-center whitespace-nowrap">Action</th>
                              </tr>
                           </thead>
                           <tbody className="divide-y divide-gray-100">
                              {[...invoices].sort((a, b) => {
                                 const dateDiff = sortOrder === 'desc' ? new Date(b.date).setHours(0,0,0,0) - new Date(a.date).setHours(0,0,0,0) : new Date(a.date).setHours(0,0,0,0) - new Date(b.date).setHours(0,0,0,0);
                                 if (dateDiff !== 0) return dateDiff;
                                 return sortOrder === 'desc' ? new Date(b.createdAt || 0) - new Date(a.createdAt || 0) : new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
                              }).map(inv => {
                                 const due = (inv.remainingAmount === undefined || inv.remainingAmount === null) ? inv.totalAmount : inv.remainingAmount;
                                 const statusText = inv.status.toUpperCase();

                                 let badgeClass = "bg-gray-100 text-gray-700";
                                 if (statusText === 'PENDING' || statusText === 'UNPAID') badgeClass = "bg-yellow-100 text-yellow-800";
                                 if (statusText === 'PARTIALLY PAID') badgeClass = "bg-orange-100 text-orange-800";
                                 if (statusText === 'PAID') badgeClass = "bg-green-100 text-green-800";

                                 return (
                                    <tr key={inv._id} className="hover:bg-gray-50 transition">
                                       <td className="p-4 text-sm text-gray-600">{new Date(inv.date).toLocaleDateString()}</td>
                                       <td className="p-4 text-sm font-bold text-blue-600">#{inv.invoiceNumber}</td>
                                       <td className="p-4 text-sm font-bold text-gray-800 text-right">₹{inv.totalAmount.toLocaleString('en-IN')}</td>
                                       <td className={`p-4 text-sm font-bold text-right ${due > 0 ? 'text-red-500' : 'text-green-500'}`}>
                                          ₹{due.toLocaleString('en-IN')}
                                       </td>
                                       <td className="p-4 text-center">
                                          <span className={`px-2 py-1 text-[10px] font-bold rounded uppercase ${badgeClass}`}>{statusText}</span>
                                       </td>
                                       <td className="p-4 text-center">
                                          <Link to={`/invoices/${inv._id}`} className="text-blue-600 font-bold text-sm hover:underline">View</Link>
                                       </td>
                                    </tr>
                                 );
                              })}
                              {invoices.length === 0 && <tr><td colSpan="6" className="p-10 text-center text-gray-400">No invoices found.</td></tr>}
                           </tbody>
                        </table>
                     </div>
                  )}

                  {/* QUOTATIONS TABLE */}
                  {activeTab === 'quotations' && (
                     <div className="overflow-x-auto">
                        <table className="w-full text-left">
                           <thead className="bg-white border-b border-gray-100">
                              <tr>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Date</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Quote #</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Total Amount</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-center whitespace-nowrap">Action</th>
                              </tr>
                           </thead>
                           <tbody className="divide-y divide-gray-100">
                              {quotations.length > 0 ? [...quotations].sort((a, b) => {
                                 const dateDiff = sortOrder === 'desc' ? new Date(b.date).setHours(0,0,0,0) - new Date(a.date).setHours(0,0,0,0) : new Date(a.date).setHours(0,0,0,0) - new Date(b.date).setHours(0,0,0,0);
                                 if (dateDiff !== 0) return dateDiff;
                                 return sortOrder === 'desc' ? new Date(b.createdAt || 0) - new Date(a.createdAt || 0) : new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
                              }).map(quote => (
                                 <tr key={quote._id} className="hover:bg-gray-50 transition">
                                    <td className="p-4 text-sm text-gray-600">{new Date(quote.date).toLocaleDateString()}</td>
                                    <td className="p-4 text-sm font-bold text-purple-600">#{quote.quotationNumber}</td>
                                    <td className="p-4 text-sm font-bold text-gray-800 text-right">
                                       ₹{(quote.grandTotal || quote.totalAmount || 0).toLocaleString('en-IN')}
                                    </td>
                                    <td className="p-4 text-center">
                                       <Link to={`/quotations/${quote._id}`} className="text-blue-600 font-bold text-sm hover:underline">View</Link>
                                    </td>
                                 </tr>
                              )) : (
                                 <tr><td colSpan="4" className="p-10 text-center text-gray-400">No quotations found.</td></tr>
                              )}
                           </tbody>
                        </table>
                     </div>
                  )}

                  {/* KHATABOOK LEDGER TABLE */}
                  {activeTab === 'ledger' && (
                     <div className="overflow-x-auto">
                        {/* Date Filter UI */}
                        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 bg-gray-50 border-b border-gray-100 gap-3">
                           <h3 className="font-bold text-gray-700 text-sm uppercase tracking-wide">Account Statement</h3>
                           <div className="flex flex-wrap items-center gap-3">
                              <div className="flex items-center gap-2">
                                 <label className="text-xs font-bold text-gray-500 uppercase">From:</label>
                                 <input type="date" value={ledgerStartDate} onChange={e => setLedgerStartDate(e.target.value)} className="text-xs font-bold text-gray-600 border border-gray-200 rounded-lg px-2 py-1.5 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" />
                              </div>
                              <div className="flex items-center gap-2">
                                 <label className="text-xs font-bold text-gray-500 uppercase">To:</label>
                                 <input type="date" value={ledgerEndDate} onChange={e => setLedgerEndDate(e.target.value)} className="text-xs font-bold text-gray-600 border border-gray-200 rounded-lg px-2 py-1.5 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500" />
                              </div>
                              {(ledgerStartDate || ledgerEndDate) && (
                                 <button onClick={() => { setLedgerStartDate(''); setLedgerEndDate(''); }} className="text-xs font-bold text-blue-600 hover:underline hover:text-blue-800">Clear Filter</button>
                              )}
                           </div>
                        </div>

                        <table className="w-full text-left">
                           <thead className="bg-white border-b border-gray-100">
                              <tr>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Date & Time</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase whitespace-nowrap">Description</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Debit (Billed)</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Credit (Received)</th>
                                 <th className="p-4 text-xs font-bold text-gray-400 uppercase text-right whitespace-nowrap">Balance</th>
                              </tr>
                           </thead>
                           <tbody className="divide-y divide-gray-100">
                               {(() => {
                                  // Step 1: Build all entries (unsorted)
                                  const rawEntries = [
                                     ...invoices.map(inv => ({
                                         key: inv._id + '_inv',
                                         date: inv.date,
                                         createdAt: inv.createdAt,
                                         type: 'invoice',
                                         desc: `Invoice #${inv.invoiceNumber}`,
                                         debit: Number(inv.totalAmount) || 0,
                                         credit: 0,
                                         note: null,
                                         createdBy: inv.createdBy
                                     })),
                                     ...payments.map(p => ({
                                         key: p._id + '_pay',
                                         date: p.date || p.paymentDate,
                                         createdAt: p.createdAt,
                                         type: 'payment',
                                         desc: `Payment (${p.paymentMode})`,
                                         debit: 0,
                                         credit: Number(p.amount) || 0,
                                         note: p.referenceNote,
                                         createdBy: p.createdBy
                                     }))
                                  ];

                                  if (rawEntries.length === 0) {
                                     return <tr><td colSpan="5" className="p-10 text-center text-gray-400">No transactions recorded.</td></tr>;
                                  }

                                  // Step 2: Sort oldest → newest (First by Date, then by Exact Time)
                                  const chronological = [...rawEntries].sort((a, b) => {
                                     const dateA = new Date(a.date).setHours(0,0,0,0);
                                     const dateB = new Date(b.date).setHours(0,0,0,0);
                                     if (dateA !== dateB) return dateA - dateB;
                                     return new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
                                  });

                                  let running = 0;
                                  const withBalance = chronological.map(entry => {
                                     running += (entry.debit - entry.credit);
                                     return { ...entry, balance: running };
                                  });

                                  // Step 3: Date Filtering & Opening Balance
                                  let openingBalance = 0;
                                  let displayEntries = withBalance;

                                  if (ledgerStartDate) {
                                     const startMs = new Date(ledgerStartDate).setHours(0,0,0,0);
                                     const beforeStart = withBalance.filter(entry => new Date(entry.date).setHours(0,0,0,0) < startMs);
                                     if (beforeStart.length > 0) openingBalance = beforeStart[beforeStart.length - 1].balance;
                                     displayEntries = displayEntries.filter(entry => new Date(entry.date).setHours(0,0,0,0) >= startMs);
                                  }

                                  if (ledgerEndDate) {
                                     const endMs = new Date(ledgerEndDate).setHours(23,59,59,999);
                                     displayEntries = displayEntries.filter(entry => new Date(entry.date).setHours(0,0,0,0) <= endMs);
                                  }

                                  // Apply User's Sort Order (Reverse array if Newest First)
                                  if (sortOrder === 'desc') {
                                     displayEntries = [...displayEntries].reverse();
                                  }

                                  return (
                                     <>
                                        {ledgerStartDate && sortOrder === 'asc' && (
                                           <tr className="bg-blue-50/40 border-b border-blue-100/50">
                                              <td colSpan="4" className="p-4 text-sm font-bold text-gray-700 text-right uppercase tracking-wider text-[11px]">
                                                 Opening Balance as of {new Date(ledgerStartDate).toLocaleDateString('en-IN')}
                                              </td>
                                              <td className="p-4 text-sm font-extrabold text-right">
                                                 <span className={openingBalance < 0 ? 'text-blue-600' : openingBalance > 0 ? 'text-rose-600' : 'text-gray-500'}>
                                                    ₹{Math.abs(openingBalance).toLocaleString('en-IN')} {openingBalance < 0 ? '(Adv)' : openingBalance > 0 ? '(Due)' : ''}
                                                 </span>
                                              </td>
                                           </tr>
                                        )}
                                        
                                        {displayEntries.length === 0 ? (
                                           <tr><td colSpan="5" className="p-10 text-center text-gray-400">No transactions in this date range.</td></tr>
                                        ) : displayEntries.map(entry => {
                                           const isAdvance = entry.balance < 0;
                                           const timeStr = entry.createdAt ? new Date(entry.createdAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : '';
                                           return (
                                              <tr key={entry.key} className="hover:bg-gray-50 transition">
                                                 <td className="p-4 text-sm text-gray-600 whitespace-nowrap align-top">
                                                    <span className="block font-bold text-gray-800">{new Date(entry.date).toLocaleDateString('en-IN')}</span>
                                                    {timeStr && <span className="block text-xs text-gray-400 mt-0.5 font-medium tracking-wide">{timeStr}</span>}
                                                 </td>
                                                 <td className="p-4 text-sm font-bold text-gray-800 align-top">
                                                    {entry.desc}
                                                    {entry.note ? <span className="block text-xs text-gray-400 font-normal italic mt-1">{entry.note}</span> : null}
                                                    {entry.createdBy && (
                                                       <span className="block text-xs text-blue-500 font-medium mt-1">
                                                          By: {entry.createdBy.name || 'System'}
                                                       </span>
                                                    )}
                                                 </td>
                                                 <td className="p-4 text-sm font-bold text-gray-800 text-right align-top">
                                                    {entry.debit > 0 ? `₹${entry.debit.toLocaleString('en-IN')}` : '-'}
                                                 </td>
                                                 <td className="p-4 text-sm font-bold text-green-600 text-right align-top">
                                                    {entry.credit > 0 ? `+ ₹${entry.credit.toLocaleString('en-IN')}` : '-'}
                                                 </td>
                                                 <td className="p-4 text-sm font-extrabold text-right align-top">
                                                    <span className={isAdvance ? 'text-blue-600' : entry.balance > 0 ? 'text-rose-600' : 'text-gray-500'}>
                                                       ₹{Math.abs(entry.balance).toLocaleString('en-IN')} {isAdvance ? '(Adv)' : entry.balance > 0 ? '(Due)' : '✓'}
                                                    </span>
                                                 </td>
                                              </tr>
                                           );
                                        })}

                                        {ledgerStartDate && sortOrder === 'desc' && (
                                           <tr className="bg-blue-50/40 border-t border-blue-100/50">
                                              <td colSpan="4" className="p-4 text-sm font-bold text-gray-700 text-right uppercase tracking-wider text-[11px]">
                                                 Opening Balance as of {new Date(ledgerStartDate).toLocaleDateString('en-IN')}
                                              </td>
                                              <td className="p-4 text-sm font-extrabold text-right">
                                                 <span className={openingBalance < 0 ? 'text-blue-600' : openingBalance > 0 ? 'text-rose-600' : 'text-gray-500'}>
                                                    ₹{Math.abs(openingBalance).toLocaleString('en-IN')} {openingBalance < 0 ? '(Adv)' : openingBalance > 0 ? '(Due)' : ''}
                                                 </span>
                                              </td>
                                           </tr>
                                        )}
                                     </>
                                  );
                               })()}
                           </tbody>
                        </table>
                     </div>
                  )}
               </div>
            </div>

            {/* MODALS REMAIN THE SAME... (Edit & Collect) */}
            {/* ... (Keep your existing modal code here for Edit and Collect Payment) ... */}

            {/* EDIT CLIENT MODAL */}
            {isEditModalOpen && (
               <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                  <div className="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden">
                     <div className="border-b p-5 flex justify-between items-center bg-gray-50">
                        <h3 className="font-bold text-lg text-gray-800">Edit Client Details</h3>
                        <button onClick={() => setIsEditModalOpen(false)} className="text-gray-400 hover:text-red-500 text-xl font-bold">✕</button>
                     </div>
                     <form onSubmit={handleSubmit(onEditSubmit)} className="p-6 space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                           <div className="col-span-2">
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Business Name *</label>
                              <input {...register("name")} className="w-full border border-gray-300 p-2.5 rounded-lg focus:border-blue-500 outline-none" required />
                           </div>
                           <div>
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Email</label>
                              <input type="email" {...register("email")} className="w-full border border-gray-300 p-2.5 rounded-lg focus:border-blue-500 outline-none" />
                           </div>
                           <div>
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Phone</label>
                              <input {...register("phone")} className="w-full border border-gray-300 p-2.5 rounded-lg focus:border-blue-500 outline-none" />
                           </div>
                           <div className="col-span-2">
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">GST Number</label>
                              <input {...register("gstNumber")} className="w-full border border-gray-300 p-2.5 rounded-lg focus:border-blue-500 outline-none uppercase" placeholder="22AAAAA0000A1Z5" />
                           </div>
                           <div className="col-span-2">
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Billing Address</label>
                              <textarea {...register("address")} className="w-full border border-gray-300 p-2.5 rounded-lg focus:border-blue-500 outline-none" rows="2"></textarea>
                           </div>
                        </div>
                        <div className="flex gap-4 pt-4 border-t mt-6">
                           <button type="button" onClick={() => setIsEditModalOpen(false)} className="flex-1 py-3 bg-gray-100 text-gray-700 font-bold rounded-lg hover:bg-gray-200 transition">Cancel</button>
                           <button type="submit" className="flex-1 bg-blue-600 text-white font-bold py-3 rounded-lg hover:bg-blue-700 shadow-md transition">Save Changes</button>
                        </div>
                     </form>
                  </div>
               </div>
            )}

            {/* COLLECT PAYMENT MODAL */}
            {isPaymentModalOpen && (
               <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                  <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
                     <div className="border-b p-5 flex justify-between items-center bg-gray-50">
                        <h3 className="font-bold text-lg text-gray-800 flex items-center gap-2">
                           <IndianRupee size={18} /> Collect Payment
                        </h3>
                        <button onClick={() => setIsPaymentModalOpen(false)} className="text-gray-400 hover:text-red-500 text-xl font-bold">✕</button>
                     </div>
                     <form onSubmit={handleCollectPayment} className="p-6 space-y-4">
                        <div>
                           <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Amount Received (₹) *</label>
                           <input type="number" required value={payAmount} onChange={e => setPayAmount(e.target.value)} className="w-full border border-gray-300 p-3 rounded-lg text-2xl font-bold focus:border-blue-500 outline-none" placeholder="0.00" autoFocus />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                           <div>
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Mode</label>
                              <select value={payMode} onChange={e => setPayMode(e.target.value)} className="w-full border border-gray-300 p-2.5 rounded-lg text-sm font-bold bg-white focus:border-blue-500 outline-none">
                                 <option>UPI</option><option>Bank Transfer</option><option>Cash</option><option>Cheque</option>
                              </select>
                           </div>
                           <div>
                              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Date</label>
                              <input type="date" value={payDate} onChange={e => setPayDate(e.target.value)} className="w-full border border-gray-300 p-2.5 rounded-lg text-sm font-bold focus:border-blue-500 outline-none" />
                           </div>
                        </div>
                        <div>
                           <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Remarks / Notes</label>
                           <input type="text" value={payNote} onChange={e => setPayNote(e.target.value)} className="w-full border border-gray-300 p-2.5 rounded-lg text-sm focus:border-blue-500 outline-none" placeholder="Txn ID, etc." />
                        </div>
                        <button type="submit" disabled={isSubmittingPayment} className={`w-full text-white font-bold py-3.5 rounded-lg shadow-md transition mt-2 ${isSubmittingPayment ? 'bg-gray-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700'}`}>
                           {isSubmittingPayment ? 'Processing...' : 'Save Record'}
                        </button>
                     </form>
                  </div>
               </div>
            )}

            {/* DELETE CONFIRMATION MODAL */}
            {clientToDelete && (
              <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
                 <div className="bg-white rounded-xl shadow-2xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                    <div className="p-6 text-center">
                        <div className="mx-auto flex items-center justify-center h-14 w-14 rounded-full bg-red-50 mb-4 border border-red-100">
                          <Trash2 className="h-6 w-6 text-red-500" />
                        </div>
                        <h3 className="font-extrabold text-xl text-gray-900 mb-2 mt-4">Delete Client?</h3>
                        <p className="text-sm text-gray-500">This action is permanent and will remove all their associated data. Do you want to proceed?</p>
                    </div>
                    <div className="bg-gray-50 p-4 border-t flex gap-3 justify-center">
                       <button onClick={() => setClientToDelete(false)} className="flex-1 py-2.5 bg-white border border-gray-200 rounded-lg font-bold text-gray-600 hover:bg-gray-50 transition shadow-sm">Cancel</button>
                       <button onClick={handleDeleteClient} className="flex-1 py-2.5 bg-red-600 text-white rounded-lg font-bold shadow-md shadow-red-200 hover:bg-red-700 transition">Delete</button>
                    </div>
                 </div>
              </div>
            )}

         </div>
      </Layout>
   );
};

export default ClientProfile;