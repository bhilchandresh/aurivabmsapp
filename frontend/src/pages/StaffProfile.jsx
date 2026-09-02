import React, { useState, useEffect, useCallback } from "react";
import { useParams, Link } from "react-router-dom";
import Layout from "../components/Layout";
import api from "../utils/api";
import { ArrowLeft, User, Phone, Mail, TrendingUp, TrendingDown, Wallet, Calendar, Plus, Trash2, CheckCircle } from "lucide-react";
import toast from "react-hot-toast";
import { AuthContext } from "../context/AuthContext";
import { useContext } from "react";

function formatCurrency(amount) {
  return amount ? amount.toLocaleString('en-IN') : '0';
}

function AddTransactionModal({ employee, onClose, onAdded }) {
  const [type, setType] = useState('Payment');
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [description, setDescription] = useState('');
  
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      setLoading(true);
      const payload = {
        type,
        amount: Number(amount),
        date,
        description
      };
      const res = await api.post(`/employees/${employee._id}/transactions`, payload);
      toast.success("Transaction added successfully");
      onAdded(res.data.data);
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to add transaction");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden border border-slate-100">
        <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
          <div>
            <h3 className="text-xl font-black text-slate-800">Add Transaction</h3>
            <p className="text-xs text-slate-500 font-bold mt-1">Record a payment, advance, or salary credit</p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-700 transition-colors p-2 rounded-full hover:bg-slate-200">
            &times;
          </button>
        </div>
        
        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          <div>
            <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Transaction Type <span className="text-rose-500">*</span></label>
            <div className="grid grid-cols-3 gap-2">
              {['Payment', 'Advance', 'Deduction'].map(t => (
                <button
                  key={t}
                  type="button"
                  onClick={() => {
                    setType(t);
                    setAmount('');
                    setDescription('');
                  }}
                  className={`p-2 rounded-xl text-xs font-bold border-2 transition-all ${type === t ? 'border-indigo-600 bg-indigo-50 text-indigo-700' : 'border-slate-100 bg-white text-slate-500 hover:border-slate-200'}`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Date <span className="text-rose-500">*</span></label>
              <input required type="date" value={date} onChange={e => setDate(e.target.value)} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-medium text-sm transition-all" />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Amount <span className="text-rose-500">*</span></label>
            <input required type="number" min="1" step="any" value={amount} onChange={e => setAmount(e.target.value)} className="w-full border p-3 rounded-xl outline-none focus:ring-4 font-black text-lg transition-all border-slate-200 text-slate-800 focus:border-indigo-500 focus:ring-indigo-500/10" placeholder="₹ 0" />
          </div>

          <div>
            <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Description <span className="text-rose-500">*</span></label>
            <input required type="text" value={description} onChange={e => setDescription(e.target.value)} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-medium text-sm transition-all" placeholder="e.g. June Salary / Travel Advance" />
          </div>

          <div className="pt-4 flex gap-3">
            <button type="button" onClick={onClose} className="flex-1 px-4 py-3 bg-slate-100 text-slate-700 font-bold rounded-xl hover:bg-slate-200 transition-colors">Cancel</button>
            <button type="submit" disabled={loading} className="flex-1 px-4 py-3 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all disabled:opacity-50">
              {loading ? "Saving..." : "Save Transaction"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function StaffProfile() {
  const { user } = useContext(AuthContext);
  const { id } = useParams();
  const [employee, setEmployee] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const [empRes, txRes] = await Promise.all([
        api.get(`/employees/${id}`),
        api.get(`/employees/${id}/transactions`)
      ]);
      setEmployee(empRes.data.data);
      setTransactions(txRes.data.data);
    } catch (err) {
      toast.error("Failed to load employee details");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleDeleteTx = async (txId) => {
    if (!window.confirm("Delete this transaction? It will affect the ledger balance.")) return;
    try {
      await api.delete(`/employees/${id}/transactions/${txId}`);
      toast.success("Transaction deleted");
      loadData();
    } catch (err) {
      toast.error("Failed to delete transaction");
    }
  };

  if (loading) {
    return <Layout><div className="p-20 text-center text-slate-400 font-bold animate-pulse">Loading employee profile...</div></Layout>;
  }

  if (!employee) {
    return <Layout><div className="p-20 text-center font-bold text-slate-500">Employee not found.</div></Layout>;
  }

  let totalEarned = 0; // Salary Credits
  let totalPaid = 0; // Payments, Advances
  let totalDeductions = 0; // Deductions

  transactions.forEach(tx => {
    if (tx.type === 'Salary Credit') totalEarned += tx.amount;
    else if (tx.type === 'Payment' || tx.type === 'Advance') totalPaid += tx.amount;
    else if (tx.type === 'Deduction') totalDeductions += tx.amount;
  });

  const currentBalance = totalEarned - totalPaid - totalDeductions;
  const isOwed = currentBalance > 0;
  const isAdvance = currentBalance < 0;

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-10 p-4">
        {/* Header */}
        <div className="mb-6 flex items-center justify-between">
          <Link to="/staff" className="text-slate-500 hover:text-indigo-600 transition flex items-center gap-2 font-bold text-sm bg-white px-4 py-2 rounded-xl shadow-sm border border-slate-100 w-fit">
            <ArrowLeft size={16} /> Back to Directory
          </Link>
          <button onClick={() => setShowModal(true)} className="bg-indigo-600 text-white px-5 py-2 rounded-xl font-black hover:bg-indigo-700 shadow-lg shadow-indigo-200 transition-all flex items-center gap-2">
            <Plus size={16} /> Add Transaction
          </button>
        </div>

        {/* Profile Card */}
        <div className="bg-white rounded-3xl border border-slate-100 shadow-sm p-6 mb-6 flex flex-col md:flex-row md:items-center justify-between gap-6 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-50 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3 opacity-60"></div>
          
          <div className="flex items-center gap-6 relative z-10">
            <div className="h-24 w-24 bg-indigo-600 text-white rounded-3xl flex items-center justify-center font-black text-4xl shadow-xl shadow-indigo-200 shrink-0">
              {employee.name.charAt(0).toUpperCase()}
            </div>
            <div>
              <h1 className="text-3xl font-black text-slate-900 tracking-tight">{employee.name}</h1>
              <p className="text-indigo-600 font-bold mb-3">{employee.role}</p>
              <div className="flex flex-wrap gap-4 text-sm font-medium text-slate-500">
                <span className="flex items-center gap-1.5"><Wallet size={16} className="text-slate-400" /> ₹{formatCurrency(employee.monthlySalary)} / mo</span>
                {employee.phone && <span className="flex items-center gap-1.5"><Phone size={16} className="text-slate-400" /> {employee.phone}</span>}
                {employee.email && <span className="flex items-center gap-1.5"><Mail size={16} className="text-slate-400" /> {employee.email}</span>}
                <span className="flex items-center gap-1.5"><Calendar size={16} className="text-slate-400" /> Joined {new Date(employee.joinDate).toLocaleDateString()}</span>
              </div>
            </div>
          </div>

          {/* Current Status Box */}
          <div className={`shrink-0 p-5 rounded-2xl border-2 ${isOwed ? 'bg-amber-50 border-amber-100' : isAdvance ? 'bg-blue-50 border-blue-100' : 'bg-emerald-50 border-emerald-100'} min-w-[200px] text-center relative z-10`}>
            <p className="text-[11px] font-black uppercase tracking-widest mb-1 opacity-70">
              {isOwed ? 'Salary Pending' : isAdvance ? 'Advance Due' : 'Account Settled'}
            </p>
            {currentBalance === 0 ? (
              <p className="text-2xl font-black text-emerald-600 flex items-center justify-center gap-2"><CheckCircle size={24} /> Clear</p>
            ) : (
              <p className={`text-3xl font-black tracking-tight ${isOwed ? 'text-amber-600' : 'text-blue-600'}`}>
                ₹{formatCurrency(Math.abs(currentBalance))}
              </p>
            )}
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
            <p className="text-xs font-bold text-slate-500 uppercase flex items-center gap-1.5 mb-1"><TrendingUp size={14} className="text-emerald-500" /> Total Earned (Salary)</p>
            <p className="text-2xl font-black text-slate-800">₹{formatCurrency(totalEarned)}</p>
          </div>
          <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
            <p className="text-xs font-bold text-slate-500 uppercase flex items-center gap-1.5 mb-1"><TrendingDown size={14} className="text-rose-500" /> Total Paid & Advances</p>
            <p className="text-2xl font-black text-slate-800">₹{formatCurrency(totalPaid)}</p>
          </div>
          <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm">
            <p className="text-xs font-bold text-slate-500 uppercase flex items-center gap-1.5 mb-1"><TrendingDown size={14} className="text-orange-500" /> Total Deductions</p>
            <p className="text-2xl font-black text-slate-800">₹{formatCurrency(totalDeductions)}</p>
          </div>
        </div>

        {/* Ledger Table */}
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-5 border-b border-slate-100 bg-slate-50/50 flex justify-between items-center">
            <h2 className="text-lg font-black text-slate-800">Ledger History</h2>
          </div>
          
          <div className="overflow-x-auto">
            {transactions.length === 0 ? (
              <div className="p-16 text-center">
                <p className="text-slate-400 font-bold mb-2">No transactions recorded yet.</p>
                <p className="text-sm text-slate-500">Record an advance or credit their salary to start the ledger.</p>
              </div>
            ) : (
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-50 border-b border-slate-100 text-xs font-black text-slate-500 uppercase tracking-wider">
                  <tr>
                    <th className="px-6 py-4">Date</th>
                    <th className="px-6 py-4">Type</th>
                    <th className="px-6 py-4">Description</th>
                    <th className="px-6 py-4 text-right">Credit (Earned)</th>
                    <th className="px-6 py-4 text-right">Debit (Paid)</th>
                    <th className="px-6 py-4 text-center">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {transactions.map(tx => {
                    const isCredit = tx.type === 'Salary Credit';
                    const isDebit = tx.type === 'Payment' || tx.type === 'Advance' || tx.type === 'Deduction';

                    return (
                      <tr key={tx._id} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-4 font-bold text-slate-600">{new Date(tx.date).toLocaleDateString('en-IN')}</td>
                        <td className="px-6 py-4">
                          <span className={`px-2.5 py-1 rounded-md text-[10px] font-black uppercase tracking-wider ${
                            tx.type === 'Salary Credit' ? 'bg-emerald-100 text-emerald-700' :
                            tx.type === 'Payment' ? 'bg-blue-100 text-blue-700' :
                            tx.type === 'Advance' ? 'bg-amber-100 text-amber-700' :
                            'bg-rose-100 text-rose-700'
                          }`}>
                            {tx.type}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="font-medium text-slate-800 mb-1">{tx.description}</div>
                          {tx.createdBy && tx.createdBy.name && (
                              <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-slate-200">
                                {tx.createdBy.name.split(' ')[0]}
                              </span>
                          )}
                        </td>
                        <td className="px-6 py-4 text-right font-black text-emerald-600">
                          {isCredit ? `₹${formatCurrency(tx.amount)}` : '—'}
                        </td>
                        <td className="px-6 py-4 text-right font-black text-rose-500">
                          {isDebit ? `₹${formatCurrency(tx.amount)}` : '—'}
                        </td>
                        <td className="px-6 py-4 text-center">
                          <button onClick={() => handleDeleteTx(tx._id)} className="text-slate-300 hover:text-rose-500 transition-colors p-1.5 rounded-lg hover:bg-rose-50">
                            <Trash2 size={16} />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {showModal && (
        <AddTransactionModal
          employee={employee}
          onClose={() => setShowModal(false)}
          onAdded={() => { setShowModal(false); loadData(); }}
        />
      )}
    </Layout>
  );
}
