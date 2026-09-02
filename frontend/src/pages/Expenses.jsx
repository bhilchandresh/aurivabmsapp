import { useState, useEffect, useContext, useMemo } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useForm } from "react-hook-form";
import { getLocalDateString } from "../utils/dateUtils";
import { 
  Wallet, Plus, Trash2, Calendar, Tag, FileText, 
  TrendingDown, Loader2, Filter, ChevronDown, ChevronUp, BarChart3, Download 
} from "lucide-react"; 
import { 
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell, CartesianGrid 
} from "recharts";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import Pagination from "../components/Pagination";

const Expenses = () => {
  const { token } = useContext(AuthContext);
  const { register, handleSubmit, reset, formState: { errors } } = useForm();
  
  // --- STATE ---
  const [expenses, setExpenses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  // UI States
  const [showAll, setShowAll] = useState(false);
  const [expenseToDelete, setExpenseToDelete] = useState(null);
  const [filterMonth, setFilterMonth] = useState(getLocalDateString().slice(0, 7)); 
  const [filterCategory, setFilterCategory] = useState("All");
  const [sortBy, setSortBy] = useState("date-desc");

  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ total: 0, page: 1, pages: 1 });

  // Reset page when filters change
  useEffect(() => {
    setPage(1);
  }, [filterMonth, filterCategory, sortBy]);

  // --- 1. FETCH EXPENSES ---
  const fetchExpenses = async () => {
    try {
      const params = new URLSearchParams();
      params.append('page', page);
      params.append('limit', 20);
      if (filterMonth) params.append('month', filterMonth);
      if (filterCategory !== "All") params.append('category', filterCategory);
      if (sortBy) params.append('sortBy', sortBy);

      const res = await api.get(`/business/expenses?${params.toString()}`);
      setExpenses(res.data.data);
      if (res.data.pagination) setPagination(res.data.pagination);
    } catch (error) {
      console.error("Error fetching expenses", error);
      toast.error("Failed to load expenses");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { if(token) fetchExpenses(); }, [token, page, filterMonth, filterCategory, sortBy]);

  // --- 2. ADD EXPENSE ---
  const onSubmit = async (data) => {
    setSubmitting(true);
    try {
      const payload = {
        ...data,
        amount: Number(data.amount),
        date: data.date || getLocalDateString()
      };
      await api.post("/business/expenses", payload);
      reset(); 
      toast.success("Expense added successfully");
      fetchExpenses(); 
    } catch (error) {
      toast.error("Failed to add expense");
    } finally {
      setSubmitting(false);
    }
  };

  // --- 3. DELETE EXPENSE ---
  const handleDelete = async () => {
    if(!expenseToDelete) return;
    try {
      await api.delete(`/business/expenses/${expenseToDelete}`);
      setExpenses(expenses.filter(exp => exp._id !== expenseToDelete));
      toast.success("Expense deleted");
    } catch (error) {
      toast.error("Failed to delete expense");
    } finally {
      setExpenseToDelete(null);
    }
  };

  // --- 4. DATA PROCESSING ---
  const uniqueCategories = useMemo(() => {
    const categories = expenses.map(exp => exp.category).filter(Boolean);
    return [...new Set(categories)].sort();
  }, [expenses]);

  // --- 5. EXPORT TO EXCEL (CSV) FUNCTION ---
  const handleExport = () => {
    if (expenses.length === 0) return toast.error("No data to export");

    // 1. Headers
    const headers = ["Date,Category,Amount,Description"];

    // 2. Map Data to CSV Format
    const rows = expenses.map(item => {
      const date = new Date(item.date).toLocaleDateString('en-IN');
      const category = `"${item.category}"`; // Wrap in quotes to handle commas in text
      const amount = item.amount;
      const description = `"${item.description || ''}"`; // Wrap in quotes
      
      return `${date},${category},${amount},${description}`;
    });

    // 3. Combine
    const csvContent = [headers, ...rows].join("\n");

    // 4. Create Blob and Download
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute("download", `Expenses_${filterMonth || 'All'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // --- 5. CHART DATA ---
  const chartData = useMemo(() => {
    const categories = {};
    expenses.forEach(exp => {
      const cat = exp.category.charAt(0).toUpperCase() + exp.category.slice(1);
      categories[cat] = (categories[cat] || 0) + Number(exp.amount);
    });

    return Object.keys(categories).map((key, index) => ({
      name: key,
      value: categories[key],
      color: ["#3B82F6", "#EF4444", "#10B981", "#F59E0B", "#8B5CF6", "#EC4899"][index % 6]
    }));
  }, [expenses]);

  const totalFilteredSpent = expenses.reduce((sum, item) => sum + (Number(item.amount) || 0), 0);
  const totalAllTimeSpent = expenses.reduce((sum, item) => sum + (Number(item.amount) || 0), 0);

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amount);
  };

  return (
    <Layout>
      <div className="max-w-7xl mx-auto pb-20">
        
        {/* --- HEADER --- */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-8 gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-800 flex items-center gap-2">
              <Wallet className="h-8 w-8 text-blue-600 shrink-0" /> Expense Dashboard
            </h1>
            <p className="text-sm text-gray-500 mt-1">Track and manage your business outflows</p>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-4 w-full md:w-auto">
              <div className="bg-white px-6 py-3 rounded-xl shadow-sm border border-blue-100 flex flex-col items-start sm:items-end min-w-[180px] w-full sm:w-auto">
                 <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">
                    {filterMonth ? 'Monthly Total' : 'Total Filtered'}
                 </p>
                 <p className="text-2xl font-extrabold text-blue-600">{formatCurrency(totalFilteredSpent)}</p>
              </div>
              
              {filterMonth && (
                 <div className="bg-gray-50 px-6 py-3 rounded-xl border border-gray-200 flex flex-col items-start sm:items-end min-w-[150px] w-full sm:w-auto md:flex">
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">All Time</p>
                    <p className="text-xl font-bold text-gray-600">{formatCurrency(totalAllTimeSpent)}</p>
                 </div>
              )}
          </div>
        </div>

        {/* --- MAIN GRID --- */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          
          {/* LEFT: ADD FORM */}
          <div className="lg:col-span-4 space-y-6">
             <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-gray-800 mb-6 flex items-center gap-2 border-b pb-2">
                   <Plus className="w-5 h-5 text-blue-600" /> Add New Expense
                </h3>
                
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                  <div>
                    <label className="text-xs font-bold text-gray-500 mb-1 block">Category</label>
                    <div className="relative">
                      <Tag className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
                      <input 
                        list="expense-categories"
                        {...register("category", { required: true })} 
                        placeholder="Select or type new..." 
                        className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-sm" 
                        autoComplete="off"
                      />
                      <datalist id="expense-categories">
                        {uniqueCategories.map(cat => (
                           <option key={cat} value={cat} />
                        ))}
                      </datalist>
                    </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-gray-500 mb-1 block">Amount</label>
                    <div className="relative">
                       <span className="absolute left-3 top-2 text-gray-500 font-bold">₹</span>
                       <input {...register("amount", { required: true, min: 1 })} placeholder="0.00" type="number" step="0.01" className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-sm font-bold" />
                    </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-gray-500 mb-1 block">Date</label>
                    <div className="relative">
                       <Calendar className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
                       <input type="date" defaultValue={new Date().toISOString().split('T')[0]} {...register("date")} className="w-full pl-10 pr-4 py-2 border rounded-lg outline-none text-sm" />
                    </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-gray-500 mb-1 block">Description</label>
                    <div className="relative">
                       <FileText className="absolute left-3 top-3 w-4 h-4 text-gray-400" />
                       <textarea {...register("description")} placeholder="Notes..." className="w-full pl-10 pr-4 py-2 border rounded-lg outline-none text-sm h-20 resize-none" />
                    </div>
                  </div>

                  <button type="submit" disabled={submitting} className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2.5 rounded-lg font-bold shadow-md flex justify-center items-center gap-2">
                    {submitting ? <Loader2 className="animate-spin w-4 h-4" /> : <Plus className="w-4 h-4" />} Add Expense
                  </button>
                </form>
             </div>
          </div>

          {/* RIGHT: CHART & LIST */}
          <div className="lg:col-span-8 space-y-6">
             
             {/* CHART */}
             {expenses.length > 0 && (
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                    <div className="flex justify-between items-center mb-4">
                        <h3 className="font-bold text-gray-700 flex items-center gap-2">
                            <BarChart3 className="w-5 h-5 text-purple-500" /> 
                            Spending Analysis <span className="text-xs font-normal text-gray-400 ml-1">(By Category)</span>
                        </h3>
                    </div>
                    <div className="h-64 w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} />
                                <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#6B7280'}} tickFormatter={(val) => `₹${val}`} />
                                <Tooltip 
                                    cursor={{fill: '#f9fafb'}}
                                    contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}} 
                                    formatter={(value) => [`₹${value}`, 'Amount']}
                                />
                                <Bar dataKey="value" radius={[4, 4, 0, 0]} barSize={40}>
                                    {chartData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.color} />
                                    ))}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
             )}

             {/* LIST & FILTERS */}
             <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden min-h-[400px]">
                
                {/* --- FILTERS & EXPORT BAR --- */}
                <div className="bg-gray-50 px-6 py-3 border-b border-gray-200 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                   
                   {/* Left: Filters Label */}
                   <div className="flex items-center gap-2 hidden md:flex">
                       <Filter className="w-4 h-4 text-gray-500 shrink-0" />
                       <span className="text-xs font-bold text-gray-500 uppercase whitespace-nowrap">Filters:</span>
                   </div>
                   
                   {/* Right: Controls */}
                   <div className="grid grid-cols-2 sm:flex sm:flex-nowrap gap-3 w-full md:w-auto items-center">
                       {/* Month */}
                       <input 
                          type="month" 
                          value={filterMonth}
                          onChange={(e) => setFilterMonth(e.target.value)}
                          className="col-span-1 bg-white border border-gray-300 text-gray-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2 w-full"
                       />
                       
                       {/* Category Filter */}
                       <select 
                          value={filterCategory} 
                          onChange={(e) => setFilterCategory(e.target.value)}
                          className="col-span-1 bg-white border border-gray-300 text-gray-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2 w-full truncate"
                       >
                          <option value="All">All Categories</option>
                          {uniqueCategories.map(cat => (
                             <option key={cat} value={cat}>{cat}</option>
                          ))}
                       </select>
                       
                       {/* Sort */}
                       <select 
                          value={sortBy} 
                          onChange={(e) => setSortBy(e.target.value)}
                          className="col-span-1 sm:col-span-auto bg-white border border-gray-300 text-gray-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2 w-full"
                       >
                          <option value="date-desc">Newest First</option>
                          <option value="date-asc">Oldest First</option>
                          <option value="amount-desc">High Amount</option>
                          <option value="amount-asc">Low Amount</option>
                       </select>

                       {/* EXPORT BUTTON */}
                       <button 
                         onClick={handleExport}
                         className="col-span-1 sm:col-span-auto bg-green-600 hover:bg-green-700 text-white text-xs font-bold py-2.5 px-3 rounded-lg flex justify-center items-center gap-1 transition-colors shadow-sm sm:ml-2 w-full sm:w-auto whitespace-nowrap"
                         title="Export Filtered Data"
                       >
                          <Download className="w-4 h-4 shrink-0" /> Export
                       </button>
                   </div>
                </div>

                {/* TABLE */}
                {loading ? (
                   <div className="flex flex-col items-center justify-center h-64 text-gray-400">
                      <Loader2 className="w-8 h-8 animate-spin mb-2 text-blue-600" />
                      <p className="text-sm">Loading expenses...</p>
                   </div>
                ) : expenses.length === 0 ? (
                   <div className="flex flex-col items-center justify-center h-64 text-gray-400">
                      <div className="bg-gray-50 p-4 rounded-full mb-3">
                         <Wallet className="w-8 h-8 text-gray-300" />
                      </div>
                      <p className="text-sm">No expenses found for this period.</p>
                      {filterMonth && <button onClick={() => setFilterMonth("")} className="text-blue-600 text-xs font-bold mt-2 hover:underline">Clear Filters</button>}
                   </div>
                ) : (
                    <div className="overflow-x-auto">
                       <table className="w-full text-left border-collapse">
                          <thead className="bg-white border-b border-gray-100">
                            <tr>
                              <th className="px-6 py-3 text-xs font-bold text-gray-500 uppercase whitespace-nowrap">Date</th>
                              <th className="px-6 py-3 text-xs font-bold text-gray-500 uppercase whitespace-nowrap">Category / Desc</th>
                              <th className="px-6 py-3 text-xs font-bold text-gray-500 uppercase text-right whitespace-nowrap">Amount</th>
                              <th className="px-6 py-3 w-10 whitespace-nowrap"></th>
                            </tr>
                          </thead>
                         <tbody className="divide-y divide-gray-50">
                           {expenses.map(exp => (
                             <tr key={exp._id} className="hover:bg-gray-50 transition-colors group">
                                <td className="px-6 py-3 text-sm text-gray-500 whitespace-nowrap">
                                  {new Date(exp.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                                </td>
                                <td className="px-6 py-3">
                                  <div className="flex items-center gap-2 mb-1">
                                    <span className="inline-block bg-blue-50 text-blue-700 text-[10px] font-bold px-2 py-0.5 rounded-full border border-blue-100">
                                       {exp.category}
                                    </span>
                                    {exp.createdBy && (
                                       <span className="inline-flex items-center gap-1 bg-gray-100 text-gray-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-gray-200">
                                          <div className="w-3 h-3 rounded-full bg-gray-200 flex items-center justify-center text-[7px] text-gray-600">
                                             {exp.createdBy.name.charAt(0).toUpperCase()}
                                          </div>
                                          {exp.createdBy.name.split(' ')[0]}
                                       </span>
                                    )}
                                 </div>
                                 {exp.description && (
                                    <p className="text-xs text-gray-500 truncate max-w-[200px]">{exp.description}</p>
                                 )}
                               </td>
                               <td className="px-6 py-3 text-right">
                                 <span className="font-bold text-gray-800 text-sm">
                                   ₹{exp.amount.toLocaleString('en-IN')}
                                 </span>
                               </td>
                               <td className="px-6 py-3 text-right">
                                  <button onClick={() => setExpenseToDelete(exp._id)} className="text-gray-300 hover:text-red-500 transition-colors">
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                               </td>
                             </tr>
                           ))}
                         </tbody>
                       </table>
                       <Pagination pagination={pagination} setPage={setPage} />
                    </div>
                )}
             </div>

          </div>
        </div>
      </div>

      {/* DELETE CONFIRMATION MODAL */}
      {expenseToDelete && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
           <div className="bg-white rounded-xl shadow-2xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in-95 duration-200">
              <div className="p-6 text-center">
                  <div className="mx-auto flex items-center justify-center h-14 w-14 rounded-full bg-red-50 mb-4 border border-red-100">
                    <Trash2 className="h-6 w-6 text-red-500" />
                  </div>
                  <h3 className="font-extrabold text-xl text-gray-900 mb-2 mt-4">Delete Expense?</h3>
                  <p className="text-sm text-gray-500">This action is permanent and cannot be undone. Do you want to proceed?</p>
              </div>
              <div className="bg-gray-50 p-4 border-t flex gap-3 justify-center">
                 <button onClick={() => setExpenseToDelete(null)} className="flex-1 py-2.5 bg-white border border-gray-200 rounded-lg font-bold text-gray-600 hover:bg-gray-50 transition shadow-sm">Cancel</button>
                 <button onClick={handleDelete} className="flex-1 py-2.5 bg-red-600 text-white rounded-lg font-bold shadow-md shadow-red-200 hover:bg-red-700 transition">Delete</button>
              </div>
           </div>
        </div>
      )}
    </Layout>
  );
};

export default Expenses;