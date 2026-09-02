import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Layout from "../components/Layout";
import api from "../utils/api";
import { Search, Plus, Trash2, Mail, Phone, ArrowRight, UserPlus, Briefcase, CheckCircle, Wallet, Edit } from "lucide-react";
import toast from "react-hot-toast";
import { AuthContext } from "../context/AuthContext";
import { useContext } from "react";

function StaffModal({ onClose, onSaved, initialData }) {
  const [formData, setFormData] = useState(
    initialData ? { ...initialData, joinDate: new Date(initialData.joinDate).toISOString().split('T')[0] } : {
      name: "", role: "", email: "", phone: "", monthlySalary: "", joinDate: new Date().toISOString().split('T')[0]
    }
  );
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      if (initialData) {
        const res = await api.put(`/employees/${initialData._id}`, formData);
        toast.success("Staff member updated");
        onSaved(res.data.data);
      } else {
        const res = await api.post("/employees", formData);
        toast.success("Staff member added");
        onSaved({ ...res.data.data, currentBalance: 0 });
      }
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to add staff");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden border border-slate-100">
        <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
          <div>
            <h3 className="text-xl font-black text-slate-800">{initialData ? 'Edit Staff Member' : 'Add Staff Member'}</h3>
            <p className="text-xs text-slate-500 font-bold mt-1">Enter employee details and compensation</p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-700 transition-colors p-2 rounded-full hover:bg-slate-200">
            &times;
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          <div>
            <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Full Name <span className="text-rose-500">*</span></label>
            <input required type="text" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-bold text-sm transition-all" placeholder="E.g. John Doe" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Role / Designation <span className="text-rose-500">*</span></label>
            <input required type="text" value={formData.role} onChange={e => setFormData({...formData, role: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-bold text-sm transition-all" placeholder="E.g. Sales Executive" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Phone</label>
              <input type="text" value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-medium text-sm transition-all" placeholder="Phone Number" />
            </div>
            <div>
              <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Email</label>
              <input type="email" value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-medium text-sm transition-all" placeholder="Email Address" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Monthly Salary <span className="text-rose-500">*</span></label>
              <input required type="number" min="0" value={formData.monthlySalary} onChange={e => setFormData({...formData, monthlySalary: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-bold text-sm transition-all" placeholder="₹ Amount" />
            </div>
            <div>
              <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Join Date <span className="text-rose-500">*</span></label>
              <input required type="date" value={formData.joinDate} onChange={e => setFormData({...formData, joinDate: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-medium text-sm transition-all" />
            </div>
          </div>

          <div className="pt-4 flex gap-3">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-3 bg-slate-100 text-slate-700 font-bold rounded-xl hover:bg-slate-200 transition-colors">Cancel</button>
            <button type="submit" disabled={loading} className="flex-1 px-4 py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all disabled:opacity-50">
              {loading ? "Saving..." : (initialData ? "Update Staff" : "Add Staff")}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function Staff() {
  const { user } = useContext(AuthContext);
  const [staff, setStaff] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingStaff, setEditingStaff] = useState(null);

  useEffect(() => {
    const fetchStaff = async () => {
      try {
        const res = await api.get("/employees");
        setStaff(res.data.data);
      } catch (err) {
        toast.error("Failed to load staff list");
      } finally {
        setLoading(false);
      }
    };
    fetchStaff();
  }, []);

  const handleDelete = async (id, name) => {
    if (!window.confirm(`Are you sure you want to completely delete ${name}? This will remove all their ledger history as well.`)) return;
    try {
      await api.delete(`/employees/${id}`);
      setStaff(prev => prev.filter(s => s._id !== id));
      toast.success("Staff deleted");
    } catch (err) {
      toast.error("Failed to delete");
    }
  };

  const filtered = staff.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    (s.phone || "").includes(search) ||
    (s.email || "").toLowerCase().includes(search.toLowerCase()) ||
    (s.role || "").toLowerCase().includes(search.toLowerCase())
  );

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10 p-4">
        {/* HEADER */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tight">Staff & Payroll</h1>
            <p className="text-slate-500 text-sm font-bold mt-1">{filtered.length} Active Team Members</p>
          </div>

          <div className="flex flex-col sm:flex-row w-full md:w-auto gap-3">
            {/* SEARCH */}
            <div className="relative w-full sm:w-64">
              <Search className="absolute left-4 top-3 text-slate-400 w-4 h-4" />
              <input
                type="text"
                placeholder="Search staff..."
                className="w-full pl-10 pr-4 py-2.5 border-2 border-slate-100 bg-white rounded-xl focus:outline-none focus:border-indigo-500 text-sm font-medium transition-all"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>

            <button onClick={() => { setEditingStaff(null); setShowModal(true); }} className="bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-black hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all whitespace-nowrap flex items-center justify-center gap-2">
              <UserPlus size={18} /> Add Staff
            </button>
          </div>
        </div>

        {/* LOADING STATE */}
        {loading ? (
          <div className="text-center p-20 text-slate-400 font-bold animate-pulse">Loading Staff Directory...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filtered.map(s => {
              const balance = s.currentBalance || 0;
              const isOwed = balance > 0; // We owe them money (Salary Pending)
              const isAdvance = balance < 0; // They owe us money (Overpaid / Advance)
              const isClear = balance === 0;

              return (
                <div key={s._id} className="bg-white rounded-[2rem] shadow-sm border border-slate-100 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 flex flex-col group overflow-hidden">
                  <div className="p-6 pb-4 relative">
                    <div className="absolute top-6 right-6 flex items-center justify-center w-8 h-8 rounded-full bg-slate-50 text-slate-400 group-hover:bg-indigo-50 group-hover:text-indigo-600 transition-colors">
                      <Briefcase size={16} />
                    </div>
                    
                    <div className="mb-4">
                      <div className="h-16 w-16 bg-indigo-600 text-white rounded-2xl flex items-center justify-center font-black text-3xl shadow-lg shadow-indigo-200">
                        {s.name.charAt(0).toUpperCase()}
                      </div>
                    </div>
                    
                    <div>
                       <h3 className="font-black text-xl text-slate-900 tracking-tight truncate mb-1" title={s.name}>{s.name}</h3>
                       <p className="text-sm font-bold text-indigo-600 mb-2 truncate">{s.role}</p>
                       {s.createdBy && s.createdBy.name && (
                          <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-slate-200 mb-2">
                             Added by {s.createdBy.name.split(' ')[0]}
                          </span>
                       )}
                    </div>
                    
                    <div className="space-y-2 mt-3 pt-4 border-t border-slate-50">
                      <p className="text-xs text-slate-500 font-medium flex items-center gap-2 truncate"><Wallet size={14} className="text-slate-400" /> ₹{(s.monthlySalary || 0).toLocaleString('en-IN')} / month</p>
                      <p className="text-xs text-slate-500 font-medium flex items-center gap-2 truncate"><Mail size={14} className="text-slate-400" /> {s.email || "No email"}</p>
                      <p className="text-xs text-slate-500 font-medium flex items-center gap-2"><Phone size={14} className="text-slate-400" /> {s.phone || "No phone"}</p>
                      
                      <div className="mt-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button 
                          onClick={() => {
                            setEditingStaff(s);
                            setShowModal(true);
                          }}
                          className="text-[10px] font-black uppercase text-indigo-500 hover:text-indigo-700 flex items-center gap-1 px-2 py-1.5 -ml-2 rounded-lg transition-colors hover:bg-indigo-50"
                        >
                          <Edit size={12} /> Edit
                        </button>
                        <button 
                          onClick={() => handleDelete(s._id, s.name)}
                          className="text-[10px] font-black uppercase text-rose-500 hover:text-rose-700 flex items-center gap-1 px-2 py-1.5 rounded-lg transition-colors hover:bg-rose-50"
                        >
                          <Trash2 size={12} /> Delete
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Financial Quick View */}
                  <div className="px-6 py-5 bg-slate-50/80 border-t border-b border-slate-50 flex items-center justify-between">
                    <div>
                      <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                        {isClear ? 'Status' : isOwed ? 'Salary Pending' : 'Advance Paid'}
                      </p>
                      {isClear ? (
                        <p className="font-black text-emerald-600 flex items-center gap-1 text-base">
                          <CheckCircle size={16} /> Cleared
                        </p>
                      ) : (
                        <p className={`font-black text-xl tracking-tight ${isOwed ? 'text-amber-500' : 'text-blue-600'}`}>
                          ₹{Math.abs(balance).toLocaleString('en-IN')}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Card Footer Action */}
                  <div className="mt-auto p-2">
                    <Link to={`/staff/${s._id}`} className="flex items-center justify-center gap-2 w-full py-3.5 bg-white text-slate-800 font-black text-sm rounded-xl hover:bg-slate-900 hover:text-white transition-all shadow-[0_0_0_1px_rgba(0,0,0,0.05)] hover:shadow-xl">
                      Open Ledger <ArrowRight size={16} />
                    </Link>
                  </div>
                </div>
              );
            })}

            {/* Empty State */}
            {filtered.length === 0 && (
              <div className="col-span-full flex flex-col items-center justify-center py-20 text-slate-400 bg-slate-50 rounded-[2rem] border-2 border-dashed border-slate-200">
                <Briefcase size={48} className="mb-4 opacity-20" />
                <p className="font-bold text-lg text-slate-500">No staff found</p>
                <p className="text-sm">Add your team members to manage their payroll.</p>
              </div>
            )}
          </div>
        )}
      </div>

      {showModal && (
        <StaffModal
          initialData={editingStaff}
          onClose={() => { setShowModal(false); setEditingStaff(null); }}
          onSaved={sup => {
            if (editingStaff) {
              setStaff(prev => prev.map(s => s._id === sup._id ? { ...sup, currentBalance: s.currentBalance } : s));
            } else {
              setStaff(prev => [sup, ...prev]);
            }
          }}
        />
      )}
    </Layout>
  );
}
