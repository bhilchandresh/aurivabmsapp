import { useState, useEffect, useCallback } from "react";
import { Link } from "react-router-dom";
import api from "../utils/api";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import {
  Truck, Plus, Search, Lock, ArrowRight, Trash2,
  AlertTriangle, X, User, Phone, Mail, MapPin, Hash, CheckCircle
} from "lucide-react";
import { useQuery, useQueryClient } from '@tanstack/react-query';

const StarterLock = () => (
  <div className="flex flex-col items-center justify-center py-24 text-center">
    <div className="bg-amber-100 rounded-full p-6 mb-6">
      <Lock className="h-12 w-12 text-amber-500" />
    </div>
    <h2 className="text-2xl font-bold text-gray-800 mb-3">Suppliers — Pro Feature</h2>
    <p className="text-gray-500 max-w-md mb-8">
      Track raw material purchases, manage vendors, and maintain a complete
      payable ledger. Upgrade to <strong>Pro</strong> or <strong>Business</strong> to unlock this module.
    </p>
    <div className="grid grid-cols-2 gap-4 max-w-md w-full text-sm mb-8">
      {[
        ["Pro Plan", "Up to 50 Suppliers"],
        ["Business Plan", "Unlimited Suppliers"],
      ].map(([plan, desc]) => (
        <div key={plan} className="bg-white border border-gray-200 rounded-xl p-4 text-left">
          <p className="font-bold text-gray-800">{plan}</p>
          <p className="text-gray-500 mt-1">{desc}</p>
        </div>
      ))}
    </div>
    <Link to="/settings" className="bg-amber-500 hover:bg-amber-600 text-white font-bold px-8 py-3 rounded-xl transition flex items-center gap-2">
      Upgrade Now <ArrowRight className="h-4 w-4" />
    </Link>
  </div>
);

const AddSupplierModal = ({ onClose, onAdded }) => {
  const [form, setForm] = useState({ name: "", email: "", phone: "", address: "", gstNumber: "" });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.name.trim()) { toast.error("Supplier name is required"); return; }
    setLoading(true);
    try {
      const res = await api.post("/suppliers", form);
      toast.success("Supplier added!");
      onAdded(res.data.data);
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to add supplier");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-md animate-in zoom-in duration-200">
        <div className="flex justify-between items-center p-8 pb-4">
          <h2 className="font-black text-2xl text-gray-900 tracking-tight">New Supplier</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-400 hover:text-red-500 font-bold" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-8 pt-4 space-y-4">
          <div>
            <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Supplier / Company Name *</label>
            <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
              className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 font-bold text-gray-700"
              placeholder="e.g. Rajesh Traders" required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Phone</label>
              <input value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })}
                className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" placeholder="9876543210" />
            </div>
            <div>
              <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Email</label>
              <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })}
                className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" placeholder="supplier@email.com" />
            </div>
          </div>
          <div>
            <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">GSTIN (Optional)</label>
            <input value={form.gstNumber} onChange={e => setForm({ ...form, gstNumber: e.target.value.toUpperCase() })}
              className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-bold uppercase" placeholder="29ABCDE1234F1Z1" />
          </div>
          <div>
            <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1 block">Address</label>
            <input value={form.address} onChange={e => setForm({ ...form, address: e.target.value })}
              className="w-full border-2 border-gray-100 p-3 rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium" placeholder="City, State" />
          </div>
          <div className="flex justify-end gap-3 pt-4">
            <button type="button" onClick={onClose} className="px-6 py-3 text-sm font-bold text-gray-500 hover:text-gray-700 hover:bg-gray-50 rounded-xl transition">Cancel</button>
            <button type="submit" disabled={loading}
              className="px-6 py-3 text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl transition disabled:opacity-60 shadow-lg shadow-blue-200">
              {loading ? "Saving..." : "Add Supplier"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default function Suppliers() {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [plan, setPlan] = useState("basic");
  const [maxSuppliers, setMaxSuppliers] = useState(0);
  const [search, setSearch] = useState("");
  const [showModal, setShowModal] = useState(false);

  const queryClient = useQueryClient();

  const { data: fetchedSuppliers, isLoading: queryLoading } = useQuery({
    queryKey: ['suppliers'],
    queryFn: async () => {
      const [resSup, resSettings] = await Promise.all([
        api.get("/suppliers"),
        api.get("/auth/settings")
      ]);
      return {
        suppliers: resSup.data.data,
        plan: resSettings.data.data.subscriptionPlan || "basic"
      };
    }
  });

  useEffect(() => {
    if (fetchedSuppliers) {
      setSuppliers(fetchedSuppliers.suppliers);
      const p = fetchedSuppliers.plan;
      setPlan(p);
      setMaxSuppliers(p === "basic" ? 0 : p === "premium" ? 50 : Infinity);
      setLoading(false);
    }
  }, [fetchedSuppliers]);

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Delete "${name}" and all their purchase records?`)) return;
    try {
      await api.delete(`/suppliers/${id}`);
      setSuppliers(prev => prev.filter(s => s._id !== id));
      toast.success("Supplier deleted");
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    } catch (err) {
      toast.error("Failed to delete");
    }
  };

  const filtered = suppliers.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    (s.phone || "").includes(search) ||
    (s.email || "").toLowerCase().includes(search.toLowerCase())
  );

  const isLocked = plan === "basic";
  const usagePct = maxSuppliers === Infinity ? 0 : Math.min(100, (suppliers.length / maxSuppliers) * 100);

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10 p-4">
        {/* HEADER WITH SEARCH & FILTER */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <h1 className="text-3xl font-black text-gray-900 tracking-tight">Suppliers Directory</h1>
            <p className="text-gray-500 text-sm font-medium mt-1">{filtered.length} Active Suppliers</p>
          </div>

          <div className="flex flex-col sm:flex-row w-full md:w-auto gap-3">
            {/* SEARCH BAR */}
            <div className="relative w-full sm:w-64">
              <Search className="absolute left-4 top-3 text-gray-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search by name, email or phone..."
                className="w-full pl-10 pr-4 py-2.5 border-2 border-gray-100 bg-white rounded-xl focus:outline-none focus:border-blue-500 text-sm font-medium transition-all"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>

            {!isLocked && (
              <button onClick={() => setShowModal(true)} className="bg-blue-600 text-white px-6 py-2.5 rounded-xl font-black hover:bg-blue-700 shadow-lg shadow-blue-200 transition-all whitespace-nowrap flex items-center justify-center gap-2">
                <Plus size={18} /> New Supplier
              </button>
            )}
          </div>
        </div>

        {/* LOADING STATE */}
        {loading && <div className="text-center p-20 text-gray-400 font-bold animate-pulse">Loading Supplier Directory...</div>}

        {!loading && isLocked ? <StarterLock /> : !loading && (
          <>
            {/* PRO USAGE BAR */}
            {plan === "premium" && (
              <div className="bg-white border border-gray-200 rounded-[2rem] p-6 mb-6 shadow-sm">
                <div className="flex justify-between text-sm mb-2">
                  <span className="font-semibold text-gray-700">Supplier Slots Used</span>
                  <span className={`font-bold ${usagePct >= 90 ? 'text-red-600' : 'text-gray-600'}`}>
                    {suppliers.length} / {maxSuppliers}
                  </span>
                </div>
                <div className="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
                  <div className={`h-full rounded-full transition-all ${usagePct >= 90 ? 'bg-red-500' : 'bg-blue-500'}`}
                    style={{ width: `${usagePct}%` }} />
                </div>
                {usagePct >= 90 && (
                  <p className="text-xs text-red-600 mt-2 flex items-center gap-1 font-bold">
                    <AlertTriangle className="h-3 w-3" /> Approaching limit. Consider upgrading to Business.
                  </p>
                )}
              </div>
            )}

            {/* SUPPLIER CARDS GRID */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {filtered.map(s => {
                const balance = s.balance || 0;
                const isAdvance = balance < 0;
                const isClear = balance === 0;

                return (
                  <div key={s._id} className="bg-white rounded-[2rem] shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 flex flex-col group overflow-hidden">
                    {/* Card Header */}
                    <div className="p-6 pb-4">
                      <div className="flex justify-between items-start mb-4">
                        <div className="h-14 w-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center font-black text-2xl shadow-inner">
                          {s.name.charAt(0).toUpperCase()}
                        </div>
                        {(s.gstin || s.gstNumber) && <span className="bg-purple-50 text-purple-600 px-2 py-1 rounded text-[10px] font-black uppercase tracking-widest border border-purple-100">GST Reg</span>}
                      </div>
                      <div>
                         <h3 className="font-black text-xl text-gray-900 tracking-tight truncate mb-1" title={s.name}>{s.name}</h3>
                         {s.createdBy && (
                            <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-slate-200">
                               {s.createdBy.name.split(' ')[0]}
                            </span>
                         )}
                      </div>
                      <div className="space-y-1.5 mt-3">
                        <p className="text-xs text-gray-500 font-medium flex items-center gap-2 truncate"><Mail size={12} className="text-blue-400" /> {s.email || "No email added"}</p>
                        <p className="text-xs text-gray-500 font-medium flex items-center gap-2"><Phone size={12} className="text-green-500" /> {s.phone || "No phone added"}</p>
                        
                        {/* DELETE ACTION */}
                        <button 
                          onClick={() => handleDelete(s._id, s.name)}
                          className="mt-2 text-[10px] font-black uppercase text-red-600 hover:text-red-700 flex items-center gap-1 bg-red-50 px-2 py-1 rounded-lg transition-colors"
                        >
                          <Trash2 size={10} /> Delete
                        </button>
                      </div>
                    </div>

                    {/* Financial Quick View */}
                    <div className="px-6 py-4 bg-gray-50/50 border-t border-b border-gray-50 grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">Total Bought</p>
                        <p className="font-bold text-gray-700">₹{(s.totalPurchased || 0).toLocaleString('en-IN')}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-0.5">
                          {isAdvance ? 'Advance' : isClear ? 'Status' : 'Pending Due'}
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
                      <Link to={`/suppliers/${s._id}`} className="flex items-center justify-center gap-2 w-full py-3 bg-white text-blue-600 font-black text-sm rounded-xl group-hover:bg-blue-50 transition-colors">
                        View Full Ledger <ArrowRight size={16} />
                      </Link>
                    </div>
                  </div>
                );
              })}

              {/* Empty State */}
              {filtered.length === 0 && (
                <div className="col-span-full flex flex-col items-center justify-center py-20 text-gray-400 bg-gray-50 rounded-[2rem] border-2 border-dashed border-gray-200">
                  <Truck size={48} className="mb-4 opacity-20" />
                  <p className="font-bold text-lg text-gray-500">No suppliers found</p>
                  <p className="text-sm">Try adjusting your search or add a new supplier.</p>
                </div>
              )}
            </div>
          </>
        )}
      </div>

      {showModal && (
        <AddSupplierModal
          onClose={() => setShowModal(false)}
          onAdded={sup => setSuppliers(prev => [sup, ...prev])}
        />
      )}
    </Layout>
  );
}
