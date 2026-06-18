import { useState, useEffect, useCallback } from "react";
import { Link } from "react-router-dom";
import api from "../utils/api";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import {
  Truck, Plus, Search, Lock, ArrowRight, Trash2,
  AlertTriangle, X, User, Phone, Mail, MapPin, Hash
} from "lucide-react";

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
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-lg font-bold text-gray-800 flex items-center gap-2"><Truck className="h-5 w-5 text-blue-600" /> Add New Supplier</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-500 hover:text-gray-800" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Supplier / Company Name *</label>
              <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder="e.g. Rajesh Traders" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Phone</label>
              <input value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" placeholder="9876543210" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Email</label>
              <input type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" placeholder="supplier@email.com" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">GSTIN (Optional)</label>
              <input value={form.gstNumber} onChange={e => setForm({ ...form, gstNumber: e.target.value.toUpperCase() })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none font-mono uppercase" placeholder="29ABCDE1234F1Z1" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Address</label>
              <input value={form.address} onChange={e => setForm({ ...form, address: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" placeholder="City, State" />
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 rounded-lg transition">Cancel</button>
            <button type="submit" disabled={loading}
              className="px-6 py-2 text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition disabled:opacity-60">
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

  const fetchData = useCallback(async () => {
    try {
      const [resSup, resSettings] = await Promise.all([
        api.get("/suppliers"),
        api.get("/auth/settings")
      ]);
      setSuppliers(resSup.data.data);
      const p = resSettings.data.data.subscriptionPlan || "basic";
      setPlan(p);
      setMaxSuppliers(p === "basic" ? 0 : p === "premium" ? 50 : Infinity);
    } catch (err) {
      toast.error("Failed to load suppliers");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Delete "${name}" and all their purchase records?`)) return;
    try {
      await api.delete(`/suppliers/${id}`);
      setSuppliers(prev => prev.filter(s => s._id !== id));
      toast.success("Supplier deleted");
    } catch (err) {
      toast.error("Failed to delete");
    }
  };

  if (loading) return <Layout><div className="flex justify-center items-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div></Layout>;

  const filtered = suppliers.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    (s.phone || "").includes(search) ||
    (s.email || "").toLowerCase().includes(search.toLowerCase())
  );

  const isLocked = plan === "basic";
  const usagePct = maxSuppliers === Infinity ? 0 : Math.min(100, (suppliers.length / maxSuppliers) * 100);

  return (
    <Layout>
      <div className="max-w-5xl mx-auto pb-20">
        {/* HEADER */}
        <div className="flex justify-between items-center mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
              <Truck className="h-6 w-6 text-blue-600" /> Suppliers
            </h1>
            <p className="text-sm text-gray-500 mt-1">Manage your vendors and purchase history</p>
          </div>
          {!isLocked && (
            <button onClick={() => setShowModal(true)}
              className="bg-blue-600 hover:bg-blue-700 text-white font-bold px-5 py-2.5 rounded-xl flex items-center gap-2 transition shadow-md">
              <Plus className="h-4 w-4" /> Add Supplier
            </button>
          )}
        </div>

        {isLocked ? <StarterLock /> : (
          <>
            {/* PRO USAGE BAR */}
            {plan === "premium" && (
              <div className="bg-white border border-gray-200 rounded-xl p-4 mb-6">
                <div className="flex justify-between text-sm mb-2">
                  <span className="font-semibold text-gray-700">Supplier Slots Used</span>
                  <span className={`font-bold ${usagePct >= 90 ? 'text-red-600' : 'text-gray-600'}`}>
                    {suppliers.length} / {maxSuppliers}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className={`h-2 rounded-full transition-all ${usagePct >= 90 ? 'bg-red-500' : 'bg-blue-500'}`}
                    style={{ width: `${usagePct}%` }} />
                </div>
                {usagePct >= 90 && (
                  <p className="text-xs text-red-600 mt-2 flex items-center gap-1">
                    <AlertTriangle className="h-3 w-3" /> Approaching limit. Consider upgrading to Business.
                  </p>
                )}
              </div>
            )}

            {/* SEARCH */}
            <div className="relative mb-6">
              <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="w-full border border-gray-200 rounded-xl pl-10 pr-4 py-2.5 focus:ring-2 focus:ring-blue-500 outline-none bg-white"
                placeholder="Search suppliers by name, phone or email..."
              />
            </div>

            {/* LIST */}
            {filtered.length === 0 ? (
              <div className="text-center py-20 bg-white rounded-2xl border border-dashed border-gray-300">
                <Truck className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="font-semibold text-gray-500">No suppliers yet</p>
                <p className="text-sm text-gray-400 mt-1">Click "Add Supplier" to get started</p>
              </div>
            ) : (
              <div className="space-y-3">
                {filtered.map(s => (
                  <div key={s._id} className="bg-white border border-gray-200 rounded-xl p-5 flex items-center justify-between hover:shadow-md transition group">
                    <div className="flex items-center gap-4">
                      <div className="bg-blue-100 text-blue-700 rounded-full h-11 w-11 flex items-center justify-center font-bold text-lg flex-shrink-0">
                        {s.name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="font-bold text-gray-800">{s.name}</p>
                        <div className="flex items-center gap-4 mt-1 flex-wrap">
                          {s.phone && <span className="text-xs text-gray-500 flex items-center gap-1"><Phone className="h-3 w-3" />{s.phone}</span>}
                          {s.email && <span className="text-xs text-gray-500 flex items-center gap-1"><Mail className="h-3 w-3" />{s.email}</span>}
                          {s.gstNumber && <span className="text-xs font-mono text-gray-500 flex items-center gap-1"><Hash className="h-3 w-3" />{s.gstNumber}</span>}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <Link to={`/suppliers/${s._id}`}
                        className="bg-blue-50 hover:bg-blue-100 text-blue-700 font-semibold text-sm px-4 py-2 rounded-lg transition flex items-center gap-1">
                        View Ledger <ArrowRight className="h-3 w-3" />
                      </Link>
                      <button onClick={() => handleDelete(s._id, s.name)}
                        className="text-red-400 hover:text-red-600 p-2 rounded-lg hover:bg-red-50 transition">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
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
