import { useState, useEffect, useCallback } from "react";
import { Link, useParams } from "react-router-dom";
import api from "../utils/api";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import {
  ArrowLeft, Plus, Truck, IndianRupee, TrendingDown,
  BadgeCheck, Clock, X, Trash2, Package, CreditCard, Eye, Pencil
} from "lucide-react";
import { getLocalDateString } from "../utils/dateUtils";

const fmt = (n) => Number(n || 0).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const StatusBadge = ({ status }) => {
  const cls = {
    Paid: "bg-green-100 text-green-700",
    Partial: "bg-amber-100 text-amber-700",
    Unpaid: "bg-red-100 text-red-700"
  }[status] || "bg-gray-100 text-gray-600";
  return <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${cls}`}>{status}</span>;
};

const ViewBillModal = ({ bill, onClose }) => {
  if (!bill) return null;
  return (
    <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl my-6">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-lg font-bold text-gray-800 flex items-center gap-2"><Package className="h-5 w-5 text-blue-600" /> View Purchase Bill</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-500 hover:text-gray-800" /></button>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div>
              <p className="text-xs font-bold text-gray-500 uppercase mb-1">Bill / Invoice No.</p>
              <p className="font-bold text-gray-800">{bill.billNumber}</p>
            </div>
            <div>
              <p className="text-xs font-bold text-gray-500 uppercase mb-1">Date</p>
              <p className="font-bold text-gray-800">{new Date(bill.date).toLocaleDateString("en-IN")}</p>
            </div>
            {bill.dueDate && (
              <div>
                <p className="text-xs font-bold text-gray-500 uppercase mb-1">Due Date</p>
                <p className="font-bold text-gray-800">{new Date(bill.dueDate).toLocaleDateString("en-IN")}</p>
              </div>
            )}
            <div>
              <p className="text-xs font-bold text-gray-500 uppercase mb-1">Status</p>
              <StatusBadge status={bill.status} />
            </div>
          </div>
          <div className="mb-6">
            <h3 className="text-xs font-bold text-gray-500 uppercase mb-2">Items</h3>
            <div className="bg-gray-50 border border-gray-200 rounded-xl overflow-hidden">
              <table className="w-full text-sm">
                <thead className="bg-gray-100 text-gray-500 font-bold border-b">
                  <tr>
                    <th className="px-4 py-2 text-left">Item</th>
                    <th className="px-4 py-2 text-right">Qty</th>
                    <th className="px-4 py-2 text-right">Rate</th>
                    <th className="px-4 py-2 text-right">Disc.</th>
                    <th className="px-4 py-2 text-right">GST</th>
                    <th className="px-4 py-2 text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {bill.items?.map((item, idx) => (
                    <tr key={idx}>
                      <td className="px-4 py-2">{item.description}</td>
                      <td className="px-4 py-2 text-right">{item.quantity}</td>
                      <td className="px-4 py-2 text-right">₹{fmt(item.rate)}</td>
                      <td className="px-4 py-2 text-right text-red-500">{item.discount > 0 ? `${item.discount}%` : "0%"}</td>
                      <td className="px-4 py-2 text-right text-blue-500">{item.gstRate > 0 ? `${item.gstRate}%` : "0%"}</td>
                      <td className="px-4 py-2 text-right font-semibold">₹{fmt(item.amount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
            <div className="flex flex-col items-end gap-1.5 text-sm bg-gray-50 p-4 rounded-xl">
              <div className="flex justify-between w-48"><span className="text-gray-500 font-medium">Subtotal:</span><span className="font-semibold text-gray-800">₹{fmt(bill.subTotal)}</span></div>
              {bill.taxAmount > 0 && <div className="flex justify-between w-48"><span className="text-gray-500 font-medium">GST Tax:</span><span className="font-semibold text-blue-600">+₹{fmt(bill.taxAmount)}</span></div>}
              <div className="flex justify-between w-48 text-lg mt-2 pt-2 border-t border-gray-200"><span className="font-bold text-gray-800">Total:</span><span className="font-black text-gray-900">₹{fmt(bill.totalAmount)}</span></div>
              
              <div className="flex justify-between w-48 mt-2"><span className="text-gray-500 font-medium">Amount Paid:</span><span className="font-bold text-green-600">₹{fmt(bill.amountPaid)}</span></div>
              <div className="flex justify-between w-48 pt-1"><span className="text-gray-500 font-medium">Balance Due:</span><span className="font-bold text-red-500">₹{fmt(bill.totalAmount - bill.amountPaid)}</span></div>
            </div>
          {bill.notes && (
            <div className="mt-4 p-4 bg-gray-50 rounded-lg text-sm text-gray-700">
              <span className="font-bold">Notes: </span>{bill.notes}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const BillModal = ({ supplierId, onClose, onAdded, initialData }) => {
  const [form, setForm] = useState(() => {
    return {
      billNumber: initialData?.billNumber || "", 
      date: initialData?.date ? new Date(initialData.date).toISOString().split('T')[0] : getLocalDateString(), 
      dueDate: initialData?.dueDate ? new Date(initialData.dueDate).toISOString().split('T')[0] : "",
      notes: initialData?.notes || "", 
      totalAmount: ""
    };
  });
  const [items, setItems] = useState(initialData?.items && initialData.items.length > 0 
    ? initialData.items.map(i => {
        const base = Number(i.quantity || 0) * Number(i.rate || 0);
        const discounted = base - (base * (Number(i.discount || 0) / 100));
        return { ...i, amount: discounted };
      }) 
    : [{ description: "", quantity: 1, rate: 0, discount: 0, gstRate: 0, amount: 0, inventoryId: null, addToInventory: false, sellingPrice: 0 }]);
  const [inventory, setInventory] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api.get("/inventory").then(res => setInventory(res.data.data)).catch(console.error);
  }, []);

  const updateItem = (i, fieldOrUpdates, val) => {
    const next = [...items];
    if (typeof fieldOrUpdates === 'object' && fieldOrUpdates !== null) {
      next[i] = { ...next[i], ...fieldOrUpdates };
    } else {
      next[i] = { ...next[i], [fieldOrUpdates]: val };
    }
    const baseAmt = Number(next[i].quantity || 0) * Number(next[i].rate || 0);
    const discountedAmt = baseAmt - (baseAmt * (Number(next[i].discount || 0) / 100));
    next[i].amount = discountedAmt;
    setItems(next);
  };

  let subTotal = 0;
  let taxAmount = 0;
  items.forEach(i => {
    const base = Number(i.quantity || 0) * Number(i.rate || 0);
    const discounted = base - (base * (Number(i.discount || 0) / 100));
    const tax = discounted * (Number(i.gstRate || 0) / 100);
    subTotal += discounted;
    taxAmount += tax;
  });
  const calculatedTotal = subTotal + taxAmount;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.billNumber.trim()) { toast.error("Bill number required"); return; }
    setLoading(true);
    try {
      const payload = {
        ...form,
        supplierId,
        items: items.map(i => ({ ...i, quantity: Number(i.quantity), rate: Number(i.rate), discount: Number(i.discount), gstRate: Number(i.gstRate), amount: Number(i.amount), inventoryId: i.inventoryId || null, addToInventory: !!i.addToInventory, sellingPrice: Number(i.sellingPrice || 0) })),
        subTotal,
        taxAmount,
        totalAmount: form.totalAmount ? Number(form.totalAmount) : calculatedTotal
      };
      
      if (initialData) {
        const res = await api.put(`/suppliers/purchases/${initialData._id}`, payload);
        toast.success("Purchase bill updated!");
        onAdded(res.data.data);
      } else {
        const res = await api.post("/suppliers/purchases/all", payload);
        toast.success("Purchase bill added!");
        onAdded(res.data.data);
      }
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
          <h2 className="text-lg font-bold text-gray-800 flex items-center gap-2"><Package className="h-5 w-5 text-blue-600" /> {initialData ? "Edit Purchase Bill" : "Add Purchase Bill"}</h2>
          <button type="button" onClick={onClose}><X className="h-5 w-5 text-gray-500 hover:text-gray-800" /></button>
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
            <div className="col-span-2">
              <label className="text-xs font-bold text-gray-500 uppercase mb-1 block">Total Amount (override optional)</label>
              <input type="number" min="0" step="0.01" value={form.totalAmount} onChange={e => setForm({ ...form, totalAmount: e.target.value })}
                className="w-full border rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 outline-none"
                placeholder={calculatedTotal > 0 ? `Auto: ₹${fmt(calculatedTotal)}` : "₹ Amount"} />
            </div>
          </div>

          {/* Items */}
          <div>
            <label className="text-xs font-bold text-gray-500 uppercase mb-2 block">Items / Materials Purchased</label>
            <div className="space-y-2">
              <div className="hidden md:grid grid-cols-12 gap-2 px-2 md:pr-10 text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">
                <div className="col-span-4">Item Details</div>
                <div className="col-span-1 text-center">Qty</div>
                <div className="col-span-2 text-right">Rate</div>
                <div className="col-span-1 text-right">Disc</div>
                <div className="col-span-1 text-right">GST</div>
                <div className="col-span-3 text-right pr-6">Amount</div>
              </div>
              {items.map((item, i) => (
                <div key={i} className="group relative bg-white border border-gray-200 rounded-xl shadow-sm hover:shadow-md transition-all p-3 md:p-2 md:pr-10">
                  <button type="button" onClick={() => setItems(items.filter((_, j) => j !== i))}
                    className="absolute top-2 right-2 md:top-1/2 md:-translate-y-1/2 text-gray-300 hover:text-red-500 transition">
                    <X className="h-4 w-4" />
                  </button>
                  <div className="flex flex-col md:grid md:grid-cols-12 gap-3 md:gap-2 items-start md:items-center">
                    
                    <div className="md:col-span-4 w-full flex flex-col gap-1.5">
                      <input value={item.description} list="inv-list" onChange={e => {
                        const val = e.target.value;
                        const found = inventory.find(x => x.itemName === val);
                        if (found) {
                          updateItem(i, { description: found.itemName, rate: found.purchasePrice || 0, sellingPrice: found.unitPrice || 0, inventoryId: found._id, addToInventory: true });
                        } else {
                          updateItem(i, { description: val, inventoryId: null, addToInventory: false });
                        }
                      }}
                        className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-blue-500 outline-none font-medium text-gray-800" placeholder="Enter item description..." />
                      <div className="flex flex-wrap items-center gap-2 pl-1">
                        <label className="flex items-center gap-1 cursor-pointer text-[10px] font-semibold text-gray-500 uppercase tracking-wide">
                          <input type="checkbox" checked={item.addToInventory} onChange={e => updateItem(i, "addToInventory", e.target.checked)}
                            className="w-3 h-3 text-blue-600 rounded border-gray-300 focus:ring-blue-500" />
                          Track in Inventory
                        </label>
                        {item.addToInventory && (
                          <div className="flex items-center gap-1 animate-in fade-in slide-in-from-left-2">
                            <span className="text-[10px] font-bold text-gray-400">Sell At:</span>
                            <input type="number" step="0.01" value={item.sellingPrice} onChange={e => updateItem(i, "sellingPrice", e.target.value)}
                              className="border-b border-gray-300 bg-transparent w-16 text-xs font-semibold text-gray-700 outline-none focus:border-blue-500 px-1" placeholder="0.00" />
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="w-full md:contents grid grid-cols-8 gap-2 items-center">
                      <div className="col-span-2 md:col-span-1">
                        <input type="number" step="any" value={item.quantity} onChange={e => updateItem(i, "quantity", e.target.value)}
                          className="w-full border rounded-lg p-2 text-sm text-center focus:ring-1 focus:ring-blue-400 outline-none" placeholder="Qty" />
                      </div>
                      <div className="col-span-3 md:col-span-2">
                        <input type="number" step="0.01" value={item.rate} onChange={e => updateItem(i, "rate", e.target.value)}
                          className="w-full border rounded-lg p-2 text-sm text-right focus:ring-1 focus:ring-blue-400 outline-none" placeholder="Rate" />
                      </div>
                      <div className="col-span-3 md:col-span-1 relative">
                        <input type="number" step="0.01" value={item.discount} onChange={e => updateItem(i, "discount", e.target.value)}
                          className="w-full border rounded-lg p-2 text-sm text-right text-red-500 focus:ring-1 focus:ring-red-400 outline-none pr-5" placeholder="0" />
                        <span className="absolute right-1.5 top-2.5 text-[10px] text-red-400 font-bold">%</span>
                      </div>
                      <div className="col-span-4 md:col-span-1 relative">
                        <input type="number" step="0.01" value={item.gstRate} onChange={e => updateItem(i, "gstRate", e.target.value)}
                          className="w-full border rounded-lg p-2 text-sm text-right text-blue-500 focus:ring-1 focus:ring-blue-400 outline-none pr-5" placeholder="GST" />
                        <span className="absolute right-1.5 top-2.5 text-[10px] text-blue-400 font-bold">%</span>
                      </div>
                      <div className="col-span-4 md:col-span-3 text-right text-sm font-bold text-gray-800 pr-1">₹{fmt(item.amount)}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <datalist id="inv-list">
              {inventory.map(x => <option key={x._id} value={x.itemName}>{x.sku}</option>)}
            </datalist>
            <button type="button" onClick={() => setItems([...items, { description: "", quantity: 1, rate: 0, amount: 0, inventoryId: null, addToInventory: false, sellingPrice: 0 }])}
              className="mt-2 text-blue-600 text-sm font-semibold hover:underline flex items-center gap-1">
              <Plus className="h-3.5 w-3.5" /> Add Item
            </button>
            <div className="flex flex-col items-end gap-1.5 text-sm mt-4 bg-gray-50 p-4 rounded-xl border border-gray-100">
              <div className="flex justify-between w-56"><span className="text-gray-500 font-medium">Subtotal:</span><span className="font-semibold text-gray-800">₹{fmt(subTotal)}</span></div>
              {taxAmount > 0 && <div className="flex justify-between w-56"><span className="text-gray-500 font-medium">GST Tax:</span><span className="font-semibold text-blue-600">+₹{fmt(taxAmount)}</span></div>}
              <div className="flex justify-between w-56 text-lg mt-2 pt-2 border-t border-gray-200"><span className="font-bold text-gray-800">Grand Total:</span><span className="font-black text-gray-900">₹{fmt(calculatedTotal)}</span></div>
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
    amount: "", paymentDate: getLocalDateString(),
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
  const [viewingBill, setViewingBill] = useState(null);
  const [editingBill, setEditingBill] = useState(null);

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
        <div className="flex flex-col sm:flex-row gap-3 mb-6">
          <button onClick={() => setShowBillModal(true)}
            className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white font-bold px-5 py-2.5 rounded-xl flex items-center justify-center gap-2 transition shadow">
            <Plus className="h-4 w-4" /> Add Purchase Bill
          </button>
          <button onClick={() => setShowPayModal(true)}
            className="w-full sm:w-auto bg-green-600 hover:bg-green-700 text-white font-bold px-5 py-2.5 rounded-xl flex items-center justify-center gap-2 transition shadow">
            <CreditCard className="h-4 w-4" /> Record Payment
          </button>
        </div>

        {/* TABS */}
        <div className="flex overflow-x-auto scrollbar-hide gap-2 mb-4 border-b border-gray-200">
          {["bills", "payments"].map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)}
              className={`whitespace-nowrap pb-3 px-4 text-sm font-semibold capitalize transition border-b-2 ${activeTab === tab ? "border-blue-600 text-blue-600" : "border-transparent text-gray-500 hover:text-gray-700"}`}>
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
            <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 border-b text-xs font-bold text-gray-500 uppercase">
                    <tr>
                      <th className="px-5 py-3 text-left whitespace-nowrap">Bill No.</th>
                      <th className="px-5 py-3 text-left whitespace-nowrap">Date</th>
                      <th className="px-5 py-3 text-right whitespace-nowrap">Amount</th>
                      <th className="px-5 py-3 text-right whitespace-nowrap">Paid</th>
                      <th className="px-5 py-3 text-center whitespace-nowrap">Status</th>
                      <th className="px-5 py-3 whitespace-nowrap"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                  {purchases.map(bill => (
                    <tr key={bill._id} className="hover:bg-gray-50 transition">
                      <td className="px-5 py-4 font-mono font-bold text-gray-700">{bill.billNumber}</td>
                      <td className="px-5 py-4 text-gray-500">
                        <div className="mb-1">{new Date(bill.date).toLocaleDateString("en-IN")}</div>
                        {bill.createdBy && (
                            <span className="inline-flex items-center gap-1 bg-gray-100 text-gray-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-gray-200">
                               <div className="w-3 h-3 rounded-full bg-gray-200 flex items-center justify-center text-[7px] text-gray-600">
                                  {bill.createdBy.name.charAt(0).toUpperCase()}
                               </div>
                               {bill.createdBy.name.split(' ')[0]}
                            </span>
                        )}
                      </td>
                      <td className="px-5 py-4 text-right font-semibold text-gray-800">₹{fmt(bill.totalAmount)}</td>
                      <td className="px-5 py-4 text-right text-green-600 font-semibold">₹{fmt(bill.amountPaid)}</td>
                      <td className="px-5 py-4 text-center"><StatusBadge status={bill.status} /></td>
                      <td className="px-5 py-4 text-right flex gap-3 justify-end items-center">
                        <button onClick={() => setViewingBill(bill)} className="text-blue-500 hover:text-blue-700 transition" title="View">
                          <Eye className="h-4 w-4" />
                        </button>
                        <button onClick={() => setEditingBill(bill)} className="text-amber-500 hover:text-amber-700 transition" title="Edit">
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button onClick={() => handleDeleteBill(bill._id)} className="text-red-400 hover:text-red-600 transition" title="Delete">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
             </div>
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
            <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 border-b text-xs font-bold text-gray-500 uppercase">
                    <tr>
                      <th className="px-5 py-3 text-left whitespace-nowrap">Date</th>
                      <th className="px-5 py-3 text-right whitespace-nowrap">Amount</th>
                      <th className="px-5 py-3 text-center whitespace-nowrap">Mode</th>
                      <th className="px-5 py-3 text-left whitespace-nowrap">Ref / UTR</th>
                      <th className="px-5 py-3 whitespace-nowrap"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                  {payments.map(pay => (
                    <tr key={pay._id} className="hover:bg-gray-50 transition">
                      <td className="px-5 py-4 text-gray-500">
                        <div className="mb-1">{new Date(pay.paymentDate).toLocaleDateString("en-IN")}</div>
                        {pay.createdBy && (
                            <span className="inline-flex items-center gap-1 bg-gray-100 text-gray-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-gray-200">
                               <div className="w-3 h-3 rounded-full bg-gray-200 flex items-center justify-center text-[7px] text-gray-600">
                                  {pay.createdBy.name.charAt(0).toUpperCase()}
                               </div>
                               {pay.createdBy.name.split(' ')[0]}
                            </span>
                        )}
                      </td>
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
            </div>
          )
        )}
      </div>

      {(showBillModal || editingBill) && (
        <BillModal 
          supplierId={id} 
          initialData={editingBill}
          onClose={() => { setShowBillModal(false); setEditingBill(null); }} 
          onAdded={() => { setShowBillModal(false); setEditingBill(null); loadAll(); }} 
        />
      )}
      {showPayModal && (
        <AddPaymentModal supplierId={id} onClose={() => setShowPayModal(false)} onAdded={() => { setShowPayModal(false); loadAll(); }} />
      )}
      {viewingBill && (
        <ViewBillModal bill={viewingBill} onClose={() => setViewingBill(null)} />
      )}
    </Layout>
  );
}
