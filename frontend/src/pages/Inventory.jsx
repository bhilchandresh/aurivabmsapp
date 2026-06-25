import { useState, useEffect, useContext } from "react";
import { Link } from "react-router-dom";
import api from "../utils/api";
import { AuthContext } from "../context/AuthContext";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import { Package, Plus, Edit, Trash2, Search, Lock, AlertTriangle, ArrowRight, History, X, ArrowUpRight, ArrowDownLeft } from "lucide-react";

const Inventory = () => {
    const { token } = useContext(AuthContext);
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [planDetails, setPlanDetails] = useState(null); // { plan: 'basic', usage: 0 }

    // Modal States
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({ itemName: '', sku: '', description: '', unitPrice: '', currentStock: '' });
    const [historyItem, setHistoryItem] = useState(null);
    const [historyData, setHistoryData] = useState([]);
    const [loadingHistory, setLoadingHistory] = useState(false);
    
    // Restock Modal States
    const [isRestockModalOpen, setIsRestockModalOpen] = useState(false);
    const [restockItem, setRestockItem] = useState(null);
    const [restockQuantity, setRestockQuantity] = useState('');

    const fetchData = async () => {
        setLoading(true);
        try {
            const [resItems, resSettings] = await Promise.all([
                api.get("/inventory"),
                api.get("/auth/settings")
            ]);
            setItems(resItems.data.data);
            setPlanDetails({ 
                plan: resSettings.data.data.subscriptionPlan || 'basic', 
                usage: resItems.data.data.length 
            });
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if(token) fetchData();
    }, [token]);

    const handleOpenModal = (item = null) => {
        if (item) {
            setEditingItem(item);
            setFormData({
                itemName: item.itemName, sku: item.sku, description: item.description,
                unitPrice: item.unitPrice, currentStock: item.currentStock
            });
        } else {
            setEditingItem(null);
            setFormData({ itemName: '', sku: '', description: '', unitPrice: '', currentStock: '' });
        }
        setIsModalOpen(true);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingItem) {
                await api.put(`/inventory/${editingItem._id}`, formData);
                toast.success("Item updated successfully!");
            } else {
                await api.post("/inventory", formData);
                toast.success("Item added successfully!");
            }
            setIsModalOpen(false);
            fetchData();
        } catch (err) {
            toast.error(err.response?.data?.message || "Operation failed");
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm("Are you sure you want to delete this inventory item?")) return;
        try {
            await api.delete(`/inventory/${id}`);
            toast.success("Item deleted successfully!");
            fetchData();
        } catch (err) {
            toast.error("Delete failed");
        }
    };

    const fetchHistory = async (item) => {
        setHistoryItem(item);
        setLoadingHistory(true);
        try {
            const res = await api.get(`/inventory/${item._id}/transactions`);
            setHistoryData(res.data.data);
        } catch (err) {
            toast.error("Failed to load history");
        } finally {
            setLoadingHistory(false);
        }
    };

    const handleRestock = async (e) => {
        e.preventDefault();
        try {
            const newStock = Number(restockItem.currentStock) + Number(restockQuantity);
            await api.put(`/inventory/${restockItem._id}`, {
                ...restockItem,
                currentStock: newStock,
                transactionDescription: "Restocked Inventory"
            });
            toast.success(`Successfully restocked ${restockQuantity} units!`);
            setIsRestockModalOpen(false);
            fetchData();
        } catch (err) {
            toast.error(err.response?.data?.message || "Restock failed");
        }
    };

    if (loading) return <Layout><div className="flex items-center justify-center p-20 font-bold text-slate-400">Loading Inventory...</div></Layout>;

    // 🔴 GATEKEEPING: STARTER PLAN LOCK SCREEN
    if (planDetails?.plan === 'basic') {
        return (
            <Layout>
                <div className="flex flex-col items-center justify-center py-24 text-center">
                    <div className="bg-amber-100 rounded-full p-6 mb-6">
                        <Lock className="h-12 w-12 text-amber-500" />
                    </div>
                    <h2 className="text-2xl font-bold text-gray-800 mb-3">Inventory — Pro Feature</h2>
                    <p className="text-gray-500 max-w-md mb-8">
                        Track stock levels, manage SKUs effortlessly, and auto-sync with your invoices.
                        Upgrade to <strong>Pro</strong> or <strong>Business</strong> to unlock this module.
                    </p>
                    <div className="grid grid-cols-2 gap-4 max-w-md w-full text-sm mb-8">
                        {[
                            ["Pro Plan", "Up to 100 SKU Items"],
                            ["Business Plan", "Unlimited Inventory"],
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
            </Layout>
        );
    }

    // Pro Limit Tracking Variables
    const isPro = planDetails?.plan === 'premium';
    const limitHit = isPro && planDetails.usage >= 100;

    const filteredItems = items.filter(i => i.itemName.toLowerCase().includes(searchTerm.toLowerCase()) || i.sku.toLowerCase().includes(searchTerm.toLowerCase()));

    return (
        <Layout>
            <div className="max-w-7xl mx-auto space-y-6">
                
                {/* Header & Usage Tracker */}
                <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
                    <div>
                        <h1 className="text-2xl font-black text-slate-800 flex items-center gap-3">
                            <Link to="/" className="mr-2 hover:bg-slate-100 p-1.5 rounded-full transition-colors">
                                <ArrowDownLeft className="h-5 w-5 rotate-45" /> {/* Imitating the left arrow from screenshot */}
                            </Link>
                            Inventory Management
                        </h1>
                        <p className="text-sm text-slate-500 mt-1 font-medium ml-11">Manage all your products, SKUs, and stock levels</p>
                    </div>
                    
                    <div className="flex items-center gap-4 w-full md:w-auto">
                        {isPro && (
                            <div className="bg-blue-50/50 border border-blue-100 px-4 py-2.5 rounded-xl flex items-center gap-4 w-full md:w-auto transition-all">
                                <span className="text-xs font-bold text-blue-700 uppercase tracking-widest">Usage</span>
                                <div className="flex-1 w-24 h-2 bg-blue-200/50 rounded-full overflow-hidden">
                                    <div className={`h-full rounded-full transition-all ${limitHit ? 'bg-rose-500' : 'bg-blue-600'}`} style={{ width: `${(planDetails.usage / 100) * 100}%` }}></div>
                                </div>
                                <span className={`text-xs font-black ${limitHit ? 'text-rose-600' : 'text-blue-800'}`}>{planDetails.usage} / 100</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Filter, Search Bar, and Add Item */}
                <div className="flex flex-col md:flex-row gap-3">
                    <div className="flex-1 bg-white p-3 rounded-xl shadow-sm border border-slate-100 flex items-center gap-3 transition-shadow focus-within:ring-2 focus-within:ring-blue-100 focus-within:border-blue-300">
                        <Search className="text-slate-400 ml-1" size={20} />
                        <input 
                            type="text" 
                            placeholder="Search by Product Name or SKU..." 
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="flex-1 bg-transparent p-1 outline-none text-slate-700 font-medium placeholder-slate-400"
                        />
                    </div>
                    
                    <button 
                        onClick={() => handleOpenModal()} 
                        disabled={limitHit}
                        className={`flex items-center justify-center gap-2 px-6 py-3.5 md:py-2.5 rounded-xl text-sm font-bold text-white transition-all shadow-sm ${limitHit ? 'bg-slate-300 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 shadow-blue-500/30'}`}
                    >
                        <Plus size={18} /> Add Item
                    </button>
                </div>

                {/* Sub-heading */}
                <div className="flex items-center justify-between mt-6 mb-2 px-1">
                    <h2 className="text-base font-bold text-slate-800">Warehouse Registry</h2>
                    <Package className="h-5 w-5 text-slate-300" />
                </div>

                {/* Grid of Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                    {filteredItems.map(item => (
                        <div key={item._id} className="bg-white rounded-2xl border border-slate-200 p-5 flex flex-col gap-3 shadow-sm hover:shadow-md transition-shadow">
                            
                            {/* Top Row: SKU & Stock Badge */}
                            <div className="flex justify-between items-center mb-1">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{item.sku || 'N/A'}</span>
                                <span className={`px-2.5 py-1 text-[10px] font-black rounded-full ${item.currentStock <= 5 ? 'bg-rose-50 text-rose-600' : 'bg-emerald-50 text-emerald-600'}`}>
                                    {item.currentStock} UNITS
                                </span>
                            </div>

                            {/* Middle Row: Name & Price */}
                            <div className="flex justify-between items-start gap-4">
                                <h3 className="text-base font-bold text-slate-900 leading-tight">{item.itemName}</h3>
                                <span className="text-base font-black text-slate-900">₹{item.unitPrice.toLocaleString('en-IN')}</span>
                            </div>

                            {/* Description */}
                            <p className="text-xs text-slate-400 mt-[-4px]">
                                {item.description || 'No description available'}
                            </p>

                            {/* Action Buttons Row */}
                            <div className="flex justify-between gap-2 mt-2 pt-3">
                                <button onClick={() => { setRestockItem(item); setRestockQuantity(''); setIsRestockModalOpen(true); }} className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-indigo-50/70 text-indigo-600 hover:bg-indigo-100 transition-colors">
                                    <ArrowUpRight size={13} strokeWidth={2.5} />
                                    <span className="text-[10px] font-bold">Restock</span>
                                </button>
                                <button onClick={() => fetchHistory(item)} className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-emerald-50/70 text-emerald-600 hover:bg-emerald-100 transition-colors">
                                    <History size={13} strokeWidth={2.5} />
                                    <span className="text-[10px] font-bold">History</span>
                                </button>
                                <button onClick={() => handleOpenModal(item)} className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-blue-50/70 text-blue-600 hover:bg-blue-100 transition-colors">
                                    <Edit size={13} strokeWidth={2.5} />
                                    <span className="text-[10px] font-bold">Edit</span>
                                </button>
                                <button onClick={() => handleDelete(item._id)} className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-rose-50/70 text-rose-600 hover:bg-rose-100 transition-colors">
                                    <Trash2 size={13} strokeWidth={2.5} />
                                    <span className="text-[10px] font-bold">Delete</span>
                                </button>
                            </div>
                        </div>
                    ))}

                    {/* Empty State */}
                    {filteredItems.length === 0 && (
                        <div className="col-span-full flex flex-col items-center justify-center py-16 px-4 text-center bg-white rounded-2xl border border-slate-100 border-dashed">
                            <Package size={48} className="text-slate-300 mb-4" />
                            <h3 className="text-lg font-bold text-slate-800 mb-1">No items found</h3>
                            <p className="text-slate-500 font-medium text-sm">Your inventory registry is currently empty.</p>
                        </div>
                    )}
                </div>

                {/* Create/Edit Pop-up Modal */}
                {isModalOpen && (
                    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
                        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden transform transition-all border border-slate-100">
                            <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                                <h3 className="text-lg font-black text-slate-800 flex items-center gap-2">
                                    {editingItem ? <Edit size={18} className="text-blue-600"/> : <Plus size={18} className="text-blue-600"/>} 
                                    {editingItem ? 'Edit Item' : 'Add New Item'}
                                </h3>
                                <button type="button" onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-700 transition-colors">
                                    <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                                </button>
                            </div>
                            <form onSubmit={handleSubmit} className="p-6 space-y-5">
                                <div>
                                    <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5 flex gap-1">Item Name <span className="text-rose-500">*</span></label>
                                    <input required type="text" value={formData.itemName} onChange={e => setFormData({...formData, itemName: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 font-medium text-sm transition-all" placeholder="E.g. Wireless Mouse"/>
                                </div>
                                <div className="grid grid-cols-2 gap-5">
                                    <div>
                                        <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">SKU / Code</label>
                                        <input type="text" value={formData.sku} onChange={e => setFormData({...formData, sku: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 font-medium text-sm transition-all placeholder-slate-300" placeholder="E.g. MS-109X"/>
                                    </div>
                                    <div>
                                        <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5 flex gap-1">Available Stock <span className="text-rose-500">*</span></label>
                                        <input required type="number" min="0" value={formData.currentStock} onChange={e => setFormData({...formData, currentStock: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 font-black text-sm transition-all text-slate-800"/>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5 flex gap-1">Unit Price (₹) <span className="text-rose-500">*</span></label>
                                    <div className="relative">
                                        <span className="absolute left-3.5 top-3 text-slate-400 font-black">₹</span>
                                        <input required type="number" min="0" value={formData.unitPrice} onChange={e => setFormData({...formData, unitPrice: e.target.value})} className="w-full border border-slate-200 py-3 pl-8 pr-3 rounded-xl outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 font-black text-sm transition-all text-slate-800"/>
                                    </div>
                                </div>
                                <div>
                                    <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5">Item Description</label>
                                    <textarea rows="2" value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 font-medium text-sm transition-all resize-none placeholder-slate-300" placeholder="Optional notes..."></textarea>
                                </div>
                                <div className="pt-3 flex gap-4">
                                    <button type="button" onClick={() => setIsModalOpen(false)} className="flex-1 px-4 py-3.5 bg-white border border-slate-200 hover:bg-slate-50 text-slate-600 rounded-xl font-bold text-sm transition-colors">Cancel</button>
                                    <button type="submit" className="flex-1 px-4 py-3.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-sm transition-all shadow-lg shadow-blue-500/30">Save Item</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* Restock Pop-up Modal */}
                {isRestockModalOpen && restockItem && (
                    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
                        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden transform transition-all border border-slate-100">
                            <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-indigo-50/50">
                                <h3 className="text-lg font-black text-slate-800 flex items-center gap-2">
                                    <Package size={18} className="text-indigo-600"/> 
                                    Restock Item
                                </h3>
                                <button type="button" onClick={() => setIsRestockModalOpen(false)} className="text-slate-400 hover:text-slate-700 transition-colors">
                                    <X size={24} />
                                </button>
                            </div>
                            <form onSubmit={handleRestock} className="p-6 space-y-4">
                                <div>
                                    <p className="text-[13px] font-black text-slate-800 mb-1">{restockItem.itemName}</p>
                                    <p className="text-xs font-bold text-slate-500 mb-4 bg-slate-100 py-1.5 px-3 rounded-lg inline-block shadow-inner border border-slate-200/60">Current Stock: {restockItem.currentStock} Units</p>
                                    
                                    <label className="block text-[11px] font-black text-slate-500 uppercase tracking-widest mb-1.5 flex gap-1">Quantity to Add <span className="text-rose-500">*</span></label>
                                    <input required type="number" min="1" value={restockQuantity} onChange={e => setRestockQuantity(e.target.value)} className="w-full border border-slate-200 p-3 rounded-xl outline-none focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 font-bold text-lg text-slate-800 transition-all text-center" placeholder="+" />
                                </div>
                                
                                <div className="pt-2 flex gap-3">
                                    <button type="button" onClick={() => setIsRestockModalOpen(false)} className="flex-1 px-4 py-3 bg-white border border-slate-200 hover:bg-slate-50 text-slate-600 rounded-xl font-bold text-sm transition-colors">Cancel</button>
                                    <button type="submit" className="flex-1 px-4 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold text-sm transition-all shadow-lg shadow-indigo-500/30">Confirm Restock</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}

                {/* History Modal */}
                {historyItem && (
                    <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in duration-200">
                        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden border border-slate-100">
                            <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                                <div>
                                    <h3 className="text-lg font-black text-slate-800">Stock History</h3>
                                    <p className="text-xs text-slate-500 font-bold uppercase tracking-wider mt-0.5">{historyItem.itemName}</p>
                                </div>
                                <button type="button" onClick={() => setHistoryItem(null)} className="text-slate-400 hover:text-slate-700 transition-colors">
                                    <X size={24} />
                                </button>
                            </div>
                            <div className="p-0 max-h-[400px] overflow-y-auto">
                                {loadingHistory ? (
                                    <div className="p-10 text-center text-slate-400 font-bold">Loading history...</div>
                                ) : historyData.length === 0 ? (
                                    <div className="p-10 text-center text-slate-400 font-bold italic">No transactions found for this item.</div>
                                ) : (
                                    <table className="w-full text-left">
                                        <thead className="bg-slate-50 text-[10px] font-black text-slate-400 uppercase tracking-widest sticky top-0">
                                            <tr>
                                                <th className="p-4">Date</th>
                                                <th className="p-4 text-center">Type</th>
                                                <th className="p-4">Details</th>
                                                <th className="p-4 text-right">Qty</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-100">
                                            {historyData.map(tx => (
                                                <tr key={tx._id} className="text-sm font-medium hover:bg-slate-50/50 transition-colors">
                                                    <td className="p-4 whitespace-nowrap text-slate-400 font-bold">{new Date(tx.date).toLocaleDateString("en-IN")}</td>
                                                    <td className="p-4 text-center">
                                                        <span className={`px-2 py-0.5 rounded text-[10px] font-black uppercase tracking-wider ${tx.type === 'Sale' ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}>
                                                            {tx.type}
                                                        </span>
                                                    </td>
                                                    <td className="p-4 text-slate-600">{tx.description}</td>
                                                    <td className={`p-4 text-right font-black ${tx.quantity < 0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                                                        {tx.quantity > 0 ? '+' : ''}{tx.quantity}
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                )}
                            </div>
                            <div className="px-6 py-4 bg-slate-50 border-t border-slate-100 flex justify-end">
                                <button onClick={() => setHistoryItem(null)} className="px-6 py-2 bg-slate-200 hover:bg-slate-300 text-slate-700 font-bold rounded-xl transition-all">Close</button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </Layout>
    );
};
export default Inventory;
