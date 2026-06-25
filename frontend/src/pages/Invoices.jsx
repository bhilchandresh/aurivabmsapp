import { useState, useEffect, useContext } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { Link } from "react-router-dom";
import {
  Search, Plus, Filter, Eye, Pencil, Trash2,
  FileText, ArrowUpDown, CheckCircle, AlertCircle, Clock, Loader2,
  Download, Share2
} from "lucide-react";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";

const StatusDropdown = ({ inv, statusStyle, isUpdating, handleStatusChange }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="relative inline-block" onMouseLeave={() => setIsOpen(false)}>
      {isUpdating ? (
        <div className="flex items-center gap-2 text-sm text-gray-500"><Loader2 className="w-4 h-4 animate-spin text-blue-600" /> Updating...</div>
      ) : (
        <div className="relative">
          <div 
            onClick={(e) => { e.stopPropagation(); setIsOpen(!isOpen); }}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border cursor-pointer transition-colors ${statusStyle.css}`}
          >
            {statusStyle.icon}
            <span className="text-xs font-bold uppercase pr-4">{inv.status}</span>
            <svg className={`w-3 h-3 absolute right-2.5 top-1/2 -translate-y-1/2 opacity-60 transition-transform ${isOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
          </div>
          
          {isOpen && (
            <div className="absolute left-0 top-full mt-1 w-36 rounded-xl shadow-xl bg-white border border-gray-100 z-50 overflow-hidden origin-top">
              {['Pending', 'Paid', 'Overdue'].map(opt => (
                <div 
                  key={opt}
                  onClick={(e) => {
                    e.stopPropagation();
                    setIsOpen(false);
                    handleStatusChange(inv._id, opt);
                  }}
                  className={`px-4 py-2.5 text-xs font-bold uppercase cursor-pointer hover:bg-slate-50 transition-colors ${opt === inv.status ? 'text-blue-600 bg-blue-50/50' : 'text-slate-600'}`}
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

const Invoices = () => {
  const { token } = useContext(AuthContext);

  const [invoices, setInvoices] = useState([]);
  const [filteredInvoices, setFilteredInvoices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);

  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [filterMonth, setFilterMonth] = useState("");
  const [sortBy, setSortBy] = useState("newest");



  useEffect(() => {
    const fetchInvoices = async () => {
      try {
        const res = await api.get("/invoices");
        setInvoices(res.data?.data || []);
        setFilteredInvoices(res.data?.data || []);
      } catch (err) {
        console.error("Error fetching invoices:", err);
        toast.error("Failed to load invoices");
      } finally {
        setLoading(false);
      }
    };
    if (token) fetchInvoices();
  }, [token]);

  useEffect(() => {
    let result = Array.isArray(invoices) ? [...invoices] : [];

    if (searchTerm) {
      const lowerTerm = searchTerm.toLowerCase();
      result = result.filter(inv =>
        inv.invoiceNumber.toLowerCase().includes(lowerTerm) ||
        inv.client?.name.toLowerCase().includes(lowerTerm)
      );
    }

    if (statusFilter !== "all") {
      result = result.filter(inv => inv.status.toLowerCase() === statusFilter.toLowerCase());
    }

    if (filterMonth) {
      result = result.filter(inv => inv.date.startsWith(filterMonth));
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
    }
    else if (sortBy === "amount_high") result.sort((a, b) => b.totalAmount - a.totalAmount);
    else if (sortBy === "amount_low") result.sort((a, b) => a.totalAmount - b.totalAmount);

    setFilteredInvoices(result);
  }, [searchTerm, statusFilter, filterMonth, sortBy, invoices]);

  const handleExport = () => {
    if (filteredInvoices.length === 0) return toast.error("No invoices to export");

    const headers = [
      "Invoice Number", "Invoice Date", "Client Name", "Client GSTIN", "Invoice Type",
      "Reverse Charge", "Tax Rate (%)", "Taxable Value", "CGST Amount", "SGST Amount",
      "Total Invoice Value", "Status"
    ];

    const rows = filteredInvoices.map(inv => {
      const d = new Date(inv.date);
      const formattedDate = `${d.getDate().toString().padStart(2, '0')}/${(d.getMonth() + 1).toString().padStart(2, '0')}/${d.getFullYear()}`;
      const clientName = `"${inv.client?.name || 'Unknown'}"`;
      const clientGstin = inv.client?.gstNumber || "";
      const invoiceType = clientGstin && clientGstin.length > 10 ? "B2B" : "B2C";
      const taxRate = inv.gstEnabled ? (inv.taxRate || 0) : 0;

      const subTotal = inv.items ? inv.items.reduce((sum, item) => sum + (Number(item.quantity) * Number(item.rate)), 0) : 0;
      const discountAmount = subTotal * ((inv.discountPercentage || 0) / 100);
      const taxableValue = subTotal - discountAmount;
      const gstAmount = inv.gstEnabled ? (taxableValue * (taxRate / 100)) : 0;
      const cgst = (gstAmount / 2).toFixed(2);
      const sgst = (gstAmount / 2).toFixed(2);
      const totalValue = inv.totalAmount || (taxableValue + gstAmount);

      return [
        inv.invoiceNumber, formattedDate, clientName, clientGstin, invoiceType, "N",
        taxRate, taxableValue.toFixed(2), cgst, sgst, totalValue.toFixed(2), inv.status
      ].join(",");
    });

    const csvContent = [headers.join(","), ...rows].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `GST_Sales_Register_${filterMonth || 'All'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleStatusChange = async (id, newStatus) => {
    try {
      setUpdatingId(id);
      await api.put(`/invoices/${id}`, { status: newStatus });

      const updatedList = invoices.map(inv =>
        inv._id === id ? { ...inv, status: newStatus } : inv
      );
      setInvoices(updatedList);
      toast.success("Status updated");
    } catch (error) {
      console.error("Status update failed:", error);
      toast.error("Failed to update status.");
    } finally {
      setUpdatingId(null);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this invoice?")) return;
    try {
      await api.delete(`/invoices/${id}`);
      const updatedList = invoices.filter(i => i._id !== id);
      setInvoices(updatedList);
      toast.success("Invoice deleted");
    } catch (e) { toast.error("Delete failed"); }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(amount);
  };

  // 🔴 FIX: Added Partially Paid styling and differentiated Pending vs Overdue
  const getStatusStyle = (status) => {
    switch (status.toLowerCase()) {
      case 'paid': return { css: 'bg-emerald-100 text-emerald-700 border-emerald-200', icon: <CheckCircle className="w-3 h-3" /> };
      case 'partially paid': return { css: 'bg-amber-100 text-amber-700 border-amber-200', icon: <Clock className="w-3 h-3" /> };
      case 'pending': case 'unpaid': return { css: 'bg-blue-100 text-blue-700 border-blue-200', icon: <Clock className="w-3 h-3" /> };
      case 'overdue': return { css: 'bg-rose-100 text-rose-700 border-rose-200', icon: <AlertCircle className="w-3 h-3" /> };
      default: return { css: 'bg-gray-100 text-gray-700 border-gray-200', icon: <FileText className="w-3 h-3" /> };
    }
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
              <FileText className="w-8 h-8 text-blue-600" /> Invoices
            </h1>
            <p className="text-sm text-gray-500 mt-1">Manage billing & track payouts</p>
          </div>
          <div className="flex gap-3">
            <button onClick={handleExport} className="bg-green-600 hover:bg-green-700 text-white px-4 py-2.5 rounded-lg font-bold shadow-sm flex items-center gap-2 transition-all text-sm">
              <Download className="w-4 h-4" /> Export for GST
            </button>
            <Link to="/invoices/create" className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg font-bold shadow-sm flex items-center gap-2 transition-all text-sm">
              <Plus className="w-5 h-5" /> Create Invoice
            </Link>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-200 mb-6 flex flex-col lg:flex-row gap-4 items-center justify-between">
          <div className="relative w-full lg:w-96">
            <Search className="absolute left-3 top-2.5 w-5 h-5 text-gray-400" />
            <input type="text" placeholder="Search Invoice # or Client..." className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg w-full focus:ring-2 focus:ring-blue-500 outline-none transition-all text-sm" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
          <div className="flex flex-wrap md:flex-nowrap gap-3 w-full lg:w-auto">
            <div className="relative w-full md:w-auto">
              <input type="month" className="w-full md:w-auto pl-3 pr-3 py-2 border border-gray-300 rounded-lg bg-white cursor-pointer hover:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm" value={filterMonth} onChange={(e) => setFilterMonth(e.target.value)} />
            </div>
            <div className="relative w-full md:w-auto">
              <Filter className="absolute left-3 top-2.5 w-4 h-4 text-gray-500" />
              <select className="w-full md:w-auto pl-9 pr-8 py-2 border border-gray-300 rounded-lg bg-white cursor-pointer hover:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm appearance-none" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option value="all">All Status</option>
                <option value="Paid">Paid</option>
                <option value="Pending">Pending</option>
                <option value="Partially Paid">Partially Paid</option>
                <option value="Overdue">Overdue</option>
              </select>
            </div>
            <div className="relative w-full md:w-auto">
              <ArrowUpDown className="absolute left-3 top-2.5 w-4 h-4 text-gray-500" />
              <select className="w-full md:w-auto pl-9 pr-8 py-2 border border-gray-300 rounded-lg bg-white cursor-pointer hover:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm appearance-none" value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="amount_high">Highest Amount</option>
                <option value="amount_low">Lowest Amount</option>
              </select>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden min-h-[400px]">
          {loading ? (
            <div className="flex flex-col items-center justify-center h-64 text-gray-500">
              <Loader2 className="w-8 h-8 animate-spin mb-2 text-blue-600" />
              <p>Loading invoices...</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Invoice #</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Client</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Date</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Amount</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-4 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {(filteredInvoices || []).length > 0 ? (
                    (filteredInvoices || []).map((inv) => {
                      const statusStyle = getStatusStyle(inv.status);
                      const isUpdating = updatingId === inv._id;

                      return (
                        <tr key={inv._id} className="hover:bg-gray-50 transition-colors duration-150 group">
                          <td className="px-6 py-4 font-bold text-blue-600">#{inv.invoiceNumber}</td>
                          <td className="px-6 py-4"><div className="font-medium text-gray-900">{inv.client?.name || "Unknown"}</div></td>
                          <td className="px-6 py-4 text-gray-500 text-sm">{new Date(inv.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</td>
                          <td className="px-6 py-4 font-bold text-gray-900">{formatCurrency(inv.totalAmount)}</td>
                          <td className="px-6 py-4">
                            <StatusDropdown 
                              inv={inv} 
                              statusStyle={statusStyle} 
                              isUpdating={isUpdating} 
                              handleStatusChange={handleStatusChange} 
                            />
                          </td>
                          <td className="px-6 py-4 text-right">
                            <div className="flex items-center justify-end gap-2">
                              <button 
                                onClick={() => {
                                  const url = `${window.location.origin}/public/invoice/${inv._id}`;
                                  navigator.clipboard.writeText(url);
                                  toast.success("Link copied!");
                                }}
                                className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                                title="Copy Public Link"
                              >
                                <Share2 className="w-4 h-4" />
                              </button>
                              <Link to={`/invoices/${inv._id}`} className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="View"><Eye className="w-4 h-4" /></Link>
                              <Link to={`/invoices/edit/${inv._id}`} className="p-2 text-gray-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors" title="Edit"><Pencil className="w-4 h-4" /></Link>
                              <button onClick={() => handleDelete(inv._id)} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Delete"><Trash2 className="w-4 h-4" /></button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  ) : (
                    <tr>
                      <td colSpan="6" className="px-6 py-12 text-center">
                        <div className="flex flex-col items-center justify-center text-gray-400">
                          <FileText className="w-12 h-12 mb-2 opacity-20" />
                          <p>No invoices found matching your filters.</p>
                        </div>
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};

export default Invoices;