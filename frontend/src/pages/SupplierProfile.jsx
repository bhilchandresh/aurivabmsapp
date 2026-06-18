import { useState, useEffect, useCallback } from "react";
import { Link, useParams } from "react-router-dom";
import api from "../utils/api";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import {
  ArrowLeft, Plus, Truck, IndianRupee, TrendingDown,
  BadgeCheck, Clock, X, Trash2, Package, CreditCard
} from "lucide-react";

const fmt = (n) => Number(n || 0).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const StatusBadge = ({ status }) => {
  const cls = {
    Paid: "bg-green-100 text-green-700",
    Partial: "bg-amber-100 text-amber-700",
    Unpaid: "bg-red-100 text-red-700"
  }[status] || "bg-gray-100 text-gray-600";
  return <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${cls}`}>{status}</span>;
};

const AddBillModal = ({ supplierId, onClose, onAdded }) => {
  const [form, setForm] = useState({
    billNumber: "", date: new Date().toISOString().split("T")[0], dueDate: "",
    notes: "", totalAmount: ""
  });
  const [items, setItems] = useState([{ description: "", quantity: 1, rate: 0, amount: 0, inventoryId: null }]);
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api.get("/inventory").then(res => setInventory(res.data.data)).catch(console.error);
  }, []);

  const updateItem = (i, field, val) => {
    const next = [...items];
    next[i] = { ...next[i], [field]: val };
    if (field === "quantity" || field === "rate") {
      next[i].amount = Number(next[i].quantity) * Number(next[i].rate);
    }
    setItems(next);
  };

  const subTotal = items.reduce((s, i) => s + (Number(i.amount) || 0), 0);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.billNumber.trim()) { toast.error("Bill number required"); return; }
    setLoading(true);
    try {
      const payload = {
        ...form,
        supplierId,
        items: items.map(i => ({ ...i, quantity: Number(i.quantity), rate: Number(i.rate), amount: Number(i.amount), inventoryId: i.inventoryId || null })),
        subTotal,
        totalAmount: Number(form.totalAmount) || subTotal
      };
      const res = await api.post("/suppliers/purchases/all", payload);
      toast.success("Purchase bill added!");
      onAdded(res.data.data);
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to add bill");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl my-6">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-lg font-bold text-gray-800 flex items-center gap-2"><Package className="h-5 w-5 text-blue-600" /> Add Purchase Bill</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-500 hover:text-gray-800" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Bill / Invoice No. *</label>
              <input value={form.billNumber} onChange={e => setForm({ ...form, billNumber: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" placeholder="e.g. BILL-001" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Bill Date *</label>
              <input type="date" value={form.date} onChange={e => setForm({ ...form, date: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Due Date</label>
              <input type="date" value={form.dueDate} onChange={e => setForm({ ...form, dueDate: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Total Amount (override optional)</label>
              <input type="number" min="0" step="0.01" value={form.totalAmount} onChange={e => setForm({ ...form, totalAmount: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder={subTotal > 0 ? `Auto: ₹${fmt(subTotal)}` : "₹ Amount"} />
            </div>
          </div>

          {/* Items */}
          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-2 block">Items / Materials Purchased</label>
            <div className="space-y-2">
              {items.map((item, i) => (
                <div key={i} className="grid grid-cols-12 gap-2 items-center">
                  <input value={item.description} list="inv-list" onChange={e => {
                    const val = e.target.value;
                    const found = inventory.find(x => x.itemName === val);
                    if (found) {
                      updateItem(i, "description", found.itemName);
                      updateItem(i, "rate", found.unitPrice);
                      updateItem(i, "inventoryId", found._id);
                    } else {
                      updateItem(i, "description", val);
                      updateItem(i, "inventoryId", null);
                    }
                  }}
                    className="col-span-12 md:col-span-5 border rounded-lg p-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none" placeholder="Item name" />
                  <input type="number" value={item.quantity} onChange={e => updateItem(i, "quantity", e.target.value)}
                    className="col-span-2 border rounded-lg p-2 text-sm text-center focus:ring-1 focus:ring-blue-400 outline-none" placeholder="Qty" />
                  <input type="number" step="0.01" value={item.rate} onChange={e => updateItem(i, "rate", e.target.value)}
                    className="col-span-2 border rounded-lg p-2 text-sm text-right focus:ring-1 focus:ring-blue-400 outline-none" placeholder="Rate" />
                  <div className="col-span-2 text-right text-sm font-semibold text-gray-700">₹{fmt(item.amount)}</div>
                  <button type="button" onClick={() => setItems(items.filter((_, j) => j !== i))}
                    className="col-span-1 text-red-400 hover:text-red-600"><X className="h-4 w-4" /></button>
                </div>
              ))}
            </div>
            <datalist id="inv-list">
              {inventory.map(x => <option key={x._id} value={x.itemName}>{x.sku}</option>)}
            </datalist>
            <button type="button" onClick={() => setItems([...items, { description: "", quantity: 1, rate: 0, amount: 0, inventoryId: null }])}
              className="mt-2 text-blue-600 text-sm font-semibold hover:underline flex items-center gap-1">
              <Plus className="h-3.5 w-3.5" /> Add Item
            </button>
            <div className="text-right text-sm font-bold text-gray-700 mt-2">
              Subtotal: ₹{fmt(subTotal)}
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Notes</label>
            <textarea value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })}
              className="w-full border rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-blue-500 outline-none resize-none h-20"
              placeholder="Delivery details, conditions etc." />
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 rounded-lg transition">Cancel</button>
            <button type="submit" disabled={loading}
              className="px-6 py-2 text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition disabled:opacity-60">
              {loading ? "Saving..." : "Save Bill"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const AddPaymentModal = ({ supplierId, onClose, onAdded }) => {
  const [form, setForm] = useState({
    amount: "", paymentDate: new Date().toISOString().split("T")[0],
    paymentMode: "Bank Transfer", referenceNumber: "", notes: ""
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.amount || Number(form.amount) <= 0) { toast.error("Enter a valid amount"); return; }
    setLoading(true);
    try {
      const res = await api.post(`/suppliers/${supplierId}/payments`, { ...form, amount: Number(form.amount) });
      toast.success("Payment recorded!");
      onAdded(res.data.data);
      onClose();
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to record payment");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-lg font-bold text-gray-800 flex items-center gap-2"><CreditCard className="h-5 w-5 text-green-600" /> Record Payment to Supplier</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-500 hover:text-gray-800" /></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Amount Paid *</label>
            <div className="relative">
              <span className="absolute left-3 top-2.5 text-gray-500 font-bold">₹</span>
              <input type="number" min="1" step="0.01" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })}
                className="w-full border rounded-lg pl-7 pr-4 py-2.5 focus:ring-2 focus:ring-green-500 outline-none text-lg font-bold" placeholder="0.00" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Payment Date</label>
              <input type="date" value={form.paymentDate} onChange={e => setForm({ ...form, paymentDate: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-green-500 outline-none" />
            </div>
            <div>
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Mode</label>
              <select value={form.paymentMode} onChange={e => setForm({ ...form, paymentMode: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-green-500 outline-none bg-white">
                {["Cash", "Bank Transfer", "UPI", "Cheque", "Other"].map(m => <option key={m}>{m}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Reference / UTR No.</label>
            <input value={form.referenceNumber} onChange={e => setForm({ ...form, referenceNumber: e.target.value })}
              className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-green-500 outline-none" placeholder="Optional" />
          </div>
          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Notes</label>
            <textarea value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })}
              className="w-full border rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-green-500 outline-none resize-none h-16" />
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <button type="button" onClick={onClose} className="px-4 py-2 text-sm font-semibold text-gray-600 hover:bg-gray-100 rounded-lg transition">Cancel</button>
            <button type="submit" disabled={loading}
              className="px-6 py-2 text-sm font-bold text-white bg-green-600 hover:bg-green-700 rounded-lg transition disabled:opacity-60">
              {loading ? "Saving..." : "Record Payment"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default function SupplierProfile() {
  const { id } = useParams();
  const [supplier, setSupplier] = useState(null);
  const [purchases, setPurchases] = useState([]);
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("bills");
  const [showBillModal, setShowBillModal] = useState(false);
  const [showPayModal, setShowPayModal] = useState(false);

  const loadAll = useCallback(async () => {
    try {
      const [resSup, resBills, resPays] = await Promise.all([
        api.get(`/suppliers/${id}`),
        api.get(`/suppliers/purchases/all?supplierId=${id}`),
        api.get(`/suppliers/${id}/payments`)
      ]);
      setSupplier(resSup.data.data);
      setPurchases(resBills.data.data);
      setPayments(resPays.data.data);
    } catch (err) {
      toast.error("Failed to load supplier data");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { loadAll(); }, [loadAll]);

  const totalPurchased = purchases.reduce((s, b) => s + (b.totalAmount || 0), 0);
  const totalPaid = payments.reduce((s, p) => s + (p.amount || 0), 0);
  const pending = totalPurchased - totalPaid;

  const handleDeleteBill = async (billId) => {
    if (!window.confirm("Delete this bill?")) return;
    try {
      await api.delete(`/suppliers/purchases/${billId}`);
      toast.success("Bill deleted");
      loadAll();
    } catch { toast.error("Failed to delete"); }
  };

  const handleDeletePayment = async (payId) => {
    if (!window.confirm("Delete this payment?")) return;
    try {
      await api.delete(`/suppliers/payments/${payId}`);
      toast.success("Payment deleted");
      loadAll();
    } catch { toast.error("Failed to delete"); }
  };

  if (loading) return <Layout><div className="flex justify-center items-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div></Layout>;
  if (!supplier) return <Layout><p className="text-center py-20 text-gray-500">Supplier not found.</p></Layout>;

  return (
    <Layout>
      <div className="max-w-5xl mx-auto pb-20">
        {/* BREADCRUMB */}
        <Link to="/suppliers" className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-800 mb-6 transition">
          <ArrowLeft className="h-4 w-4" /> Back to Suppliers
        </Link>

        {/* SUPPLIER HEADER */}
        <div className="bg-white border border-gray-200 rounded-2xl p-6 mb-6 shadow-sm">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <div className="bg-blue-600 text-white rounded-2xl h-16 w-16 flex items-center justify-center text-2xl font-bold flex-shrink-0">
                {supplier.name.charAt(0).toUpperCase()}
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-800">{supplier.name}</h1>
                <div className="flex flex-wrap gap-3 mt-1">
                  {supplier.phone && <span className="text-sm text-gray-500">📞 {supplier.phone}</span>}
                  {supplier.email && <span className="text-sm text-gray-500">✉️ {supplier.email}</span>}
                  {supplier.gstNumber && <span className="text-sm text-gray-500 font-mono">GST: {supplier.gstNumber}</span>}
                  {supplier.address && <span className="text-sm text-gray-500">📍 {supplier.address}</span>}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* STATS */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
          <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
            <p className="text-xs font-bold text-gray-500 uppercase mb-1 flex items-center gap-1"><TrendingDown className="h-3.5 w-3.5 text-blue-500" /> Total Purchased</p>
            <p className="text-2xl font-extrabold text-gray-800">₹{fmt(totalPurchased)}</p>
            <p className="text-xs text-gray-400 mt-1">{purchases.length} bills</p>
          </div>
          <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
            <p className="text-xs font-bold text-gray-500 uppercase mb-1 flex items-center gap-1"><BadgeCheck className="h-3.5 w-3.5 text-green-500" /> Total Paid</p>
            <p className="text-2xl font-extrabold text-green-600">₹{fmt(totalPaid)}</p>
            <p className="text-xs text-gray-400 mt-1">{payments.length} payments</p>
          </div>
          <div className={`border rounded-xl p-5 shadow-sm ${pending > 0 ? "bg-red-50 border-red-200" : "bg-green-50 border-green-200"}`}>
            <p className={`text-xs font-bold uppercase mb-1 flex items-center gap-1 ${pending > 0 ? "text-red-600" : "text-green-600"}`}>
              <Clock className="h-3.5 w-3.5" /> Pending Balance
            </p>
            <p className={`text-2xl font-extrabold ${pending > 0 ? "text-red-600" : "text-green-600"}`}>
              {pending > 0 ? `₹${fmt(pending)}` : "✅ Settled"}
            </p>
            <p className="text-xs text-gray-400 mt-1">{pending > 0 ? "Amount payable to supplier" : "No dues outstanding"}</p>
          </div>
        </div>

        {/* ACTION BUTTONS */}
        <div className="flex gap-3 mb-6">
          <button onClick={() => setShowBillModal(true)}
            className="bg-blue-600 hover:bg-blue-700 text-white font-bold px-5 py-2.5 rounded-xl flex items-center gap-2 transition shadow">
            <Plus className="h-4 w-4" /> Add Purchase Bill
          </button>
          <button onClick={() => setShowPayModal(true)}
            className="bg-green-600 hover:bg-green-700 text-white font-bold px-5 py-2.5 rounded-xl flex items-center gap-2 transition shadow">
            <CreditCard className="h-4 w-4" /> Record Payment
          </button>
        </div>

        {/* TABS */}
        <div className="flex gap-2 mb-4 border-b border-gray-200">
          {["bills", "payments"].map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)}
              className={`pb-3 px-4 text-sm font-semibold capitalize transition border-b-2 ${activeTab === tab ? "border-blue-600 text-blue-600" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
              {tab === "bills" ? `Purchase Bills (${purchases.length})` : `Payments (${payments.length})`}
            </button>
          ))}
        </div>

        {/* PURCHASES TABLE */}
        {activeTab === "bills" && (
          purchases.length === 0 ? (
            <div className="text-center py-16 bg-white rounded-2xl border border-dashed">
              <Package className="h-10 w-10 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 font-semibold">No purchase bills yet</p>
            </div>
          ) : (
            <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b text-xs font-bold text-gray-500 uppercase">
                  <tr>
                    <th className="px-5 py-3 text-left">Bill No.</th>
                    <th className="px-5 py-3 text-left">Date</th>
                    <th className="px-5 py-3 text-right">Amount</th>
                    <th className="px-5 py-3 text-right">Paid</th>
                    <th className="px-5 py-3 text-center">Status</th>
                    <th className="px-5 py-3"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {purchases.map(bill => (
                    <tr key={bill._id} className="hover:bg-gray-50 transition">
                      <td className="px-5 py-4 font-mono font-bold text-gray-700">{bill.billNumber}</td>
                      <td className="px-5 py-4 text-gray-500">{new Date(bill.date).toLocaleDateString("en-IN")}</td>
                      <td className="px-5 py-4 text-right font-semibold text-gray-800">₹{fmt(bill.totalAmount)}</td>
                      <td className="px-5 py-4 text-right text-green-600 font-semibold">₹{fmt(bill.amountPaid)}</td>
                      <td className="px-5 py-4 text-center"><StatusBadge status={bill.status} /></td>
                      <td className="px-5 py-4 text-right">
                        <button onClick={() => handleDeleteBill(bill._id)} className="text-red-400 hover:text-red-600 transition">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        )}

        {/* PAYMENTS TABLE */}
        {activeTab === "payments" && (
          payments.length === 0 ? (
            <div className="text-center py-16 bg-white rounded-2xl border border-dashed">
              <IndianRupee className="h-10 w-10 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 font-semibold">No payments recorded yet</p>
            </div>
          ) : (
            <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden shadow-sm">
              <table className="w-full text-sm">
                <thead className="bg-gray-50 border-b text-xs font-bold text-gray-500 uppercase">
                  <tr>
                    <th className="px-5 py-3 text-left">Date</th>
                    <th className="px-5 py-3 text-right">Amount</th>
                    <th className="px-5 py-3 text-center">Mode</th>
                    <th className="px-5 py-3 text-left">Ref / UTR</th>
                    <th className="px-5 py-3"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {payments.map(pay => (
                    <tr key={pay._id} className="hover:bg-gray-50 transition">
                      <td className="px-5 py-4 text-gray-500">{new Date(pay.paymentDate).toLocaleDateString("en-IN")}</td>
                      <td className="px-5 py-4 text-right font-bold text-green-600">₹{fmt(pay.amount)}</td>
                      <td className="px-5 py-4 text-center">
                        <span className="bg-blue-50 text-blue-700 text-xs font-bold px-2.5 py-1 rounded-full">{pay.paymentMode}</span>
                      </td>
                      <td className="px-5 py-4 text-gray-500 font-mono text-xs">{pay.referenceNumber || "—"}</td>
                      <td className="px-5 py-4 text-right">
                        <button onClick={() => handleDeletePayment(pay._id)} className="text-red-400 hover:text-red-600 transition">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )
        )}
      </div>

      {showBillModal && (
        <AddBillModal supplierId={id} onClose={() => setShowBillModal(false)} onAdded={() => { setShowBillModal(false); loadAll(); }} />
      )}
      {showPayModal && (
        <AddPaymentModal supplierId={id} onClose={() => setShowPayModal(false)} onAdded={() => { setShowPayModal(false); loadAll(); }} />
      )}
    </Layout>
  );
}
