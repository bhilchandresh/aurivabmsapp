import { useState, useEffect, useContext } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { Link, useNavigate } from "react-router-dom"; 
import { 
  Search, Plus, Filter, Eye, Pencil, Trash2, 
  FileText, ArrowRightCircle, CheckCircle, XCircle, Clock, Loader2, Share2 
} from "lucide-react"; 
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";

const StatusDropdown = ({ q, statusStyle, isUpdating, handleStatusChange }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="relative inline-block" onMouseLeave={() => setIsOpen(false)}>
      {isUpdating ? (
        <div className="flex items-center gap-2 text-sm text-gray-500"><Loader2 className="w-4 h-4 animate-spin text-blue-600" /> Updating...</div>
      ) : (
        <div className="relative">
          <div 
            onClick={(e) => { e.stopPropagation(); setIsOpen(!isOpen); }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border cursor-pointer transition-colors w-fit ${statusStyle.css}`}
          >
            {statusStyle.icon}
            <span className="text-xs font-bold uppercase pr-4">{q.status}</span>
            <svg className={`w-3 h-3 absolute right-2.5 top-1/2 -translate-y-1/2 opacity-60 transition-transform ${isOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
          </div>
          
          {isOpen && (
            <div className="absolute left-0 top-full mt-1 w-32 rounded-xl shadow-xl bg-white border border-gray-100 z-50 overflow-hidden origin-top">
              {['Pending', 'Accepted', 'Rejected'].map(opt => (
                <div 
                  key={opt}
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsOpen(false);
                    handleStatusChange(q._id, opt);
                  }}
                  className={`px-4 py-2.5 text-xs font-bold uppercase cursor-pointer hover:bg-slate-50 transition-colors ${opt === q.status ? 'text-blue-600 bg-blue-50/50' : 'text-slate-600'}`}
                >
                  {opt}
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

const Quotations = () => {
  const { token } = useContext(AuthContext);
  const navigate = useNavigate(); 
  
  const [quotations, setQuotations] = useState([]);
  const [filteredQuotations, setFilteredQuotations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const [convertingId, setConvertingId] = useState(null); 
  
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [sortBy, setSortBy] = useState("newest");


  // --- 1. FETCH ---
  useEffect(() => {
    const fetchQuotations = async () => {
      try {
        const res = await api.get("/quotations");
        setQuotations(res.data.data);
        setFilteredQuotations(res.data.data);
      } catch (err) { 
        console.error("Error fetching quotations:", err); 
      } finally {
        setLoading(false);
      }
    };
    if (token) fetchQuotations();
  }, [token]);

  // --- 2. FILTER ---
  useEffect(() => {
    let result = [...quotations];

    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      result = result.filter(q => 
        q.quotationNumber.toLowerCase().includes(lowerTerm) || 
        q.client?.name.toLowerCase().includes(lowerTerm)
      );
    }

    if (statusFilter !== "all") {
      result = result.filter(q => q.status.toLowerCase() === statusFilter.toLowerCase());
    }

    if (sortBy === "newest") {
      result.sort((a, b) => {
        const dateDiff = new Date(b.date).setHours(0,0,0,0) - new Date(a.date).setHours(0,0,0,0);
        if (dateDiff !== 0) return dateDiff;
        return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
      });
    } else if (sortBy === "oldest") {
      result.sort((a, b) => {
        const dateDiff = new Date(a.date).setHours(0,0,0,0) - new Date(b.date).setHours(0,0,0,0);
        if (dateDiff !== 0) return dateDiff;
        return new Date(a.createdAt || 0) - new Date(b.createdAt || 0);
      });
    } else if (sortBy === "amount_high") {
      result.sort((a, b) => (b.totalAmount || b.grandTotal || 0) - (a.totalAmount || a.grandTotal || 0));
    }

    setFilteredQuotations(result);
  }, [searchTerm, statusFilter, sortBy, quotations]);

  // --- 3. CONVERT TO INVOICE ---
  const handleConvertToInvoice = async (id) => {
    if(!window.confirm("Convert this Quotation to an Invoice?")) return;
    
    try {
      setConvertingId(id); 
      
      const res = await api.post(`/quotations/${id}/convert`);
      
      toast.success("Converted successfully! Redirecting...");
      navigate(`/invoices/${res.data.invoiceId}`); 
      
    } catch (error) {
      console.error(error);
      toast.error("Conversion Failed: " + (error.response?.data?.message || error.message));
    } finally {
      setConvertingId(null);
    }
  };

  // --- 4. STATUS UPDATE ---
  const handleStatusChange = async (id, newStatus) => {
    try {
      setUpdatingId(id);
      await api.put(`/quotations/${id}`, { status: newStatus });
      
      const updatedList = quotations.map(q => 
        q._id === id ? { ...q, status: newStatus } : q
      );
      setQuotations(updatedList);
      toast.success("Status updated");
    } catch (error) {
      toast.error("Failed to update status.");
    } finally {
      setUpdatingId(null);
    }
  };

  // --- 5. DELETE ---
  const handleDelete = async (id) => {
    if(!window.confirm("Delete this quotation?")) return;
    try {
      await api.delete(`/quotations/${id}`);
      setQuotations(prev => prev.filter(q => q._id !== id));
      toast.success("Deleted successfully.");
    } catch(e) { toast.error("Delete failed"); }
  };

  // --- HELPER: Currency ---
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 2
    }).format(amount || 0);
  };

  const getStatusStyle = (status) => {
    switch(status?.toLowerCase()) {
      case 'accepted': return { css: 'bg-emerald-100 text-emerald-700 border-emerald-200', icon: <CheckCircle className="w-3 h-3"/> };
      case 'rejected': return { css: 'bg-rose-100 text-rose-700 border-rose-200', icon: <XCircle className="w-3 h-3"/> };
      default: return { css: 'bg-amber-100 text-amber-700 border-amber-200', icon: <Clock className="w-3 h-3"/> };
    }
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10">
        <div className="flex justify-between items-center mb-8">
           <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2"><FileText className="text-blue-600"/> Quotations</h1>
           <Link to="/quotations/create" className="bg-blue-600 text-white px-5 py-2.5 rounded-lg font-medium flex items-center gap-2 hover:bg-blue-700"><Plus size={20}/> Create Quote</Link>
        </div>

        {/* FILTERS */}
        <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6 flex flex-col md:flex-row gap-4">
           <div className="relative w-full md:w-96">
              <Search className="absolute left-3 top-2.5 w-5 h-5 text-gray-400" />
              <input type="text" placeholder="Search..." className="pl-10 pr-4 py-2 border rounded-lg w-full outline-none focus:ring-2 focus:ring-blue-500" value={searchTerm} onChange={e => setSearchTerm(e.target.value)} />
           </div>
           <select className="px-4 py-2 border rounded-lg" value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
               <option value="all">All Status</option>
               <option value="Accepted">Accepted</option>
               <option value="Pending">Pending</option>
               <option value="Rejected">Rejected</option>
           </select>
        </div>

        {/* TABLE */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {loading ? <div className="p-10 text-center text-gray-500">Loading...</div> : (
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-gray-50 border-b">
                  <tr>
                    <th className="px-6 py-4 font-bold text-gray-500 text-xs uppercase">Quote #</th>
                    <th className="px-6 py-4 font-bold text-gray-500 text-xs uppercase">Client</th>
                    <th className="px-6 py-4 font-bold text-gray-500 text-xs uppercase">Date</th>
                    <th className="px-6 py-4 font-bold text-gray-500 text-xs uppercase">Amount</th>
                    <th className="px-6 py-4 font-bold text-gray-500 text-xs uppercase">Status</th>
                    <th className="px-6 py-4 text-right font-bold text-gray-500 text-xs uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {filteredQuotations.map(q => (
                    <tr key={q._id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 font-bold text-blue-600">#{q.quotationNumber}</td>
                      <td className="px-6 py-4">{q.client?.name}</td>
                      <td className="px-6 py-4 text-sm text-gray-500">{new Date(q.date).toLocaleDateString()}</td>
                      <td className="px-6 py-4 font-bold">
                        {(() => {
                          const subTotal = q.subTotal || (q.items?.reduce((sum, item) => sum + ((Number(item.quantity) || 0) * (Number(item.rate || item.price) || 0)), 0) || 0);
                          const taxableAmount = subTotal - (subTotal * ((q.discountPercentage || 0) / 100));
                          const isGstEnabled = q.gstEnabled !== undefined ? q.gstEnabled : (Number(q.taxRate) > 0);
                          const taxRate = isGstEnabled ? (Number(q.taxRate) || 0) : 0;
                          const calculatedTotal = taxableAmount + (taxableAmount * (taxRate / 100));
                          
                          // If DB totalAmount erroneously includes GST when gstEnabled is false, override it
                          let displayAmount = q.totalAmount || q.grandTotal || calculatedTotal;
                          if (!isGstEnabled && displayAmount > taxableAmount + 0.1) {
                            displayAmount = calculatedTotal;
                          }
                          
                          return formatCurrency(displayAmount);
                        })()}
                      </td>
                      
                      <td className="px-6 py-4">
                        <StatusDropdown 
                          q={q} 
                          statusStyle={getStatusStyle(q.status)} 
                          isUpdating={updatingId === q._id} 
                          handleStatusChange={handleStatusChange} 
                        />
                      </td>
                      
                      <td className="px-6 py-4 text-right flex justify-end items-center gap-2">
                         <button 
                            onClick={() => {
                              const url = `${window.location.origin}/public/quotation/${q._id}`;
                              navigator.clipboard.writeText(url);
                              toast.success("Link copied!");
                            }}
                            className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                            title="Copy Public Link"
                          >
                            <Share2 className="w-4 h-4" />
                          </button>
                         
                         {/* --- UPDATED CONVERT BUTTON LOGIC --- */}
                         {q.convertedInvoiceId ? (
                            // STATE 1: ALREADY CONVERTED
                            <span className="flex items-center gap-1 bg-gray-100 text-gray-500 px-3 py-1.5 rounded text-xs font-bold border border-gray-200 cursor-not-allowed select-none">
                               <CheckCircle className="w-3 h-3" /> Converted
                            </span>
                         ) : (
                            // STATE 2: READY TO CONVERT
                            <button 
                                onClick={() => handleConvertToInvoice(q._id)} 
                                className="flex items-center gap-1 bg-purple-100 text-purple-700 hover:bg-purple-200 px-3 py-1.5 rounded text-xs font-bold transition-colors"
                                title="Convert to Invoice"
                                disabled={convertingId === q._id}
                            >
                                {convertingId === q._id ? <Loader2 className="w-3 h-3 animate-spin"/> : <ArrowRightCircle size={14} />}
                                {convertingId === q._id ? "..." : "Convert"}
                            </button>
                         )}

                         <Link to={`/quotations/${q._id}`} className="p-2 hover:bg-blue-50 text-blue-600 rounded"><Eye size={16}/></Link>
                         
                         {/* Optional: Disable Edit if already converted */}
                         {q.convertedInvoiceId ? (
                            <button disabled className="p-2 text-gray-300 cursor-not-allowed"><Pencil size={16}/></button>
                         ) : (
                            <Link to={`/quotations/edit/${q._id}`} className="p-2 hover:bg-amber-50 text-amber-600 rounded"><Pencil size={16}/></Link>
                         )}
                         
                         <button onClick={() => handleDelete(q._id)} className="p-2 hover:bg-red-50 text-red-600 rounded"><Trash2 size={16}/></button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};

export default Quotations;