import { useState, useEffect, useContext } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { Link } from "react-router-dom";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import { useForm } from "react-hook-form";
import {
  Search, Plus, Mail, Phone, MapPin, ArrowRight,
  Wallet, TrendingDown, CheckCircle
} from "lucide-react";
import { INDIAN_STATES } from "../utils/constants";

const Clients = () => {
  const { token } = useContext(AuthContext);
  const [clients, setClients] = useState([]);
  const [filteredClients, setFilteredClients] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [loading, setLoading] = useState(true);

  // Search & Filter State
  const [searchTerm, setSearchTerm] = useState("");
  const [sortBy, setSortBy] = useState("newest");

  const { register, handleSubmit, reset } = useForm();



  const fetchClients = async () => {
    setLoading(true);
    try {
      const res = await api.get('/clients');
      setClients(res.data.data);
      setFilteredClients(res.data.data);
    } catch (err) { console.error(err); toast.error("Failed to load clients"); }
    finally { setLoading(false); }
  };

  useEffect(() => { if (token) fetchClients(); }, [token]);

  // --- FILTER & SORT LOGIC ---
  useEffect(() => {
    let result = [...clients];

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(c =>
        c.name?.toLowerCase().includes(term) ||
        c.email?.toLowerCase().includes(term) ||
        c.phone?.includes(term)
      );
    }

    if (sortBy === "newest") result.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    else if (sortBy === "oldest") result.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    else if (sortBy === "alpha_asc") result.sort((a, b) => a.name.localeCompare(b.name));
    else if (sortBy === "dues_high") result.sort((a, b) => (b.balance || 0) - (a.balance || 0));

    setFilteredClients(result);
  }, [searchTerm, sortBy, clients]);

  const onSubmit = async (data) => {
    try {
      await api.post('/clients', data);
      setShowModal(false);
      reset();
      toast.success("Client added successfully");
      fetchClients();
    } catch (error) { toast.error(error.response?.data?.message || "Error adding client"); }
  };

  const handleSendEmail = async (clientId, clientEmail, clientName) => {
    if (!clientEmail) return toast.error("Client email not found!");
    if (!window.confirm(`Send professional update email to ${clientName}?`)) return;

    try {
      await api.post(`/clients/${clientId}/mail`, {
        subject: "Professional Update from Auriva",
        message: `Hi ${clientName},\n\nHope you're doing well.\n\nThis is a quick update regarding your account.`
      });
      toast.success("Professional email sent!");
    } catch (error) {
      toast.error(error.response?.data?.message || "Failed to send email.");
    }
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10 p-4">

        {/* HEADER WITH SEARCH & FILTER */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <h1 className="text-3xl font-black text-gray-900 tracking-tight">Clients Directory</h1>
            <p className="text-gray-500 text-sm font-medium mt-1">{filteredClients.length} Active Clients</p>
          </div>

          <div className="flex flex-col sm:flex-row w-full md:w-auto gap-3">
            {/* SEARCH BAR */}
            <div className="relative w-full sm:w-64">
              <Search className="absolute left-4 top-3 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search by name, email or phone..."
                className="w-full pl-10 pr-4 py-2.5 border-2 border-gray-100 bg-white rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium transition-all"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            {/* SORT DROPDOWN */}
            <select
              className="border-2 border-gray-100 px-4 py-2.5 rounded-xl bg-white focus:outline-none focus:border-blue-500 text-sm font-bold text-gray-600 cursor-pointer appearance-none transition-all"
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
            >
              <option value="newest">Newest First</option>
              <option value="dues_high">Highest Dues ⚠️</option>
              <option value="alpha_asc">A-Z Name</option>
              <option value="oldest">Oldest First</option>
            </select>

            <button onClick={() => setShowModal(true)} className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-black hover:bg-blue-700 shadow-lg shadow-blue-200 transition-all whitespace-nowrap flex items-center justify-center gap-2">
              <Plus size={18} /> New Client
            </button>
          </div>
        </div>

        {/* LOADING STATE */}
        {loading && <div className="text-center p-20 text-gray-400 font-bold animate-pulse">Loading Client Directory...</div>}

        {/* CLIENT CARDS GRID */}
        {!loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredClients.map((client) => {
              // Extract calculated financials (Defaults to 0 if not present)
              const balance = client.balance || 0;
              const isAdvance = balance < 0;
              const isClear = balance === 0;

              return (
                <div key={client._id} className="bg-white rounded-[2rem] shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 flex flex-col group overflow-hidden">

                  {/* Card Header */}
                  <div className="p-6 pb-4">
                    <div className="flex justify-between items-start mb-4">
                      <div className="h-14 w-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center font-black text-2xl shadow-inner">
                        {client.name.charAt(0).toUpperCase()}
                      </div>
                      {(client.gstin || client.gstNumber) && <span className="bg-purple-50 text-purple-600 px-2 py-1 rounded text-[10px] font-black uppercase tracking-widest border border-purple-100">GST Reg</span>}
                    </div>
                    <h3 className="font-black text-xl text-gray-900 tracking-tight truncate mb-1" title={client.name}>{client.name}</h3>
                    <div className="space-y-1.5 mt-3">
                      <p className="text-xs text-gray-500 font-medium flex items-center gap-2 truncate"><Mail size={12} className="text-blue-400" /> {client.email || "No email added"}</p>
                      <p className="text-xs text-gray-500 font-medium flex items-center gap-2"><Phone size={12} className="text-green-500" /> {client.phone || "No phone added"}</p>
                      
                      {/* EMAIL QUICK ACTION */}
                      <button 
                        onClick={(e) => { e.preventDefault(); e.stopPropagation(); handleSendEmail(client._id, client.email, client.name); }}
                        className="mt-2 text-[10px] font-black uppercase text-blue-600 hover:text-blue-700 flex items-center gap-1 bg-blue-50 px-2 py-1 rounded-lg"
                      >
                        <Mail size={10} /> Send Update Mail
                      </button>
                    </div>
                  </div>

                  {/* Financial Quick View (The Smart Part) */}
                  <div className="px-6 py-4 bg-gray-50/50 border-t border-b border-gray-50 grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">Total Billed</p>
                      <p className="font-bold text-gray-700">₹{(client.totalBilled || 0).toLocaleString('en-IN')}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">
                        {isAdvance ? 'Advance Jama' : isClear ? 'Status' : 'Pending Due'}
                      </p>
                      {isClear ? (
                        <p className="font-black text-emerald-600 flex items-center justify-end gap-1 text-sm mt-1">
                          <CheckCircle size={14} /> Settled
                        </p>
                      ) : (
                        <p className={`font-black ${isAdvance ? 'text-blue-600' : 'text-rose-600'}`}>
                          ₹{Math.abs(balance).toLocaleString('en-IN')}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Card Footer Action */}
                  <div className="mt-auto p-2">
                    <Link to={`/clients/${client._id}`} className="flex items-center justify-center gap-2 w-full py-3 bg-white text-blue-600 font-black text-sm rounded-xl group-hover:bg-blue-50 transition-colors">
                      View Full Ledger <ArrowRight size={16} />
                    </Link>
                  </div>
                </div>
              );
            })}

            {/* Empty State */}
            {filteredClients.length === 0 && (
              <div className="col-span-full flex flex-col items-center justify-center py-20 text-gray-400 bg-gray-50 rounded-[2rem] border-2 border-dashed border-gray-200">
                <Wallet size={48} className="mb-4 opacity-20" />
                <p className="font-bold text-lg text-gray-500">No clients found</p>
                <p className="text-sm">Try adjusting your search or add a new client.</p>
              </div>
            )}
          </div>
        )}

        {/* MODAL: ADD CLIENT */}
        {showModal && (
          <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white p-8 rounded-[2.5rem] shadow-2xl w-full max-w-md animate-in zoom-in duration-200">
              <div className="flex justify-between items-center mb-6">
                <h2 className="font-black text-2xl text-gray-900 tracking-tight">New Client</h2>
                <button onClick={() => setShowModal(false)} className="text-gray-400 hover:text-red-500 font-bold">✕</button>
              </div>

              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Business Name *</label>
                  <input {...register("name")} placeholder="e.g. Acme Corp" className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 font-bold text-gray-700" required />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Email</label>
                    <input type="email" {...register("email")} placeholder="name@company.com" className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" />
                  </div>
                  <div>
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Phone</label>
                    <input {...register("phone")} placeholder="+91..." className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">GSTIN</label>
                    <input {...register("gstin")} placeholder="22AAAAA0000A1Z5" className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-bold uppercase" />
                  </div>
                  <div>
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">State / UT</label>
                    <select {...register("state")} className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-bold appearance-none bg-white">
                      <option value="">Select State</option>
                      {INDIAN_STATES.map(state => (
                        <option key={state} value={state}>{state}</option>
                      ))}
                    </select>
                  </div>
                </div>
                <div>
                  <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Address</label>
                  <textarea {...register("address")} placeholder="Full billing address..." className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" rows="2"></textarea>
                </div>

                <div className="flex gap-3 pt-4 border-t border-gray-50">
                  <button type="button" onClick={() => setShowModal(false)} className="flex-1 py-3 text-sm font-bold text-gray-500 hover:bg-gray-50 rounded-xl transition-all">Cancel</button>
                  <button type="submit" className="flex-1 bg-blue-600 text-white font-black py-3 rounded-xl shadow-lg shadow-blue-200 hover:bg-blue-700 transition-all">Save Client</button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default Clients;