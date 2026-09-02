import { useEffect, useState, useContext } from "react";
import api from "../utils/api";
import { Link, useNavigate } from "react-router-dom";
import { 
  Wallet, FileText, Clock, TrendingUp, 
  Plus, Users, ArrowRight, ArrowUpRight, CheckCircle, Loader2, Receipt, X, Tag, Calendar
} from "lucide-react"; // Icons
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer 
} from 'recharts'; // Charts
import { AuthContext } from "../context/AuthContext";
import Layout from "../components/Layout";
import toast from "react-hot-toast";
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getLocalDateString } from "../utils/dateUtils";


const Dashboard = () => {
  const { user, token } = useContext(AuthContext);
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  
  const [stats, setStats] = useState({
    totalRevenue: 0,
    totalExpenses: 0,
    totalPurchases: 0,
    netProfit: 0,
    totalPendingAmount: 0,
    totalInvoices: 0,
    paidInvoices: 0,
    pendingCount: 0
  });

  const [globalTimeFilter, setGlobalTimeFilter] = useState("lifetime");

  const [tenantInfo, setTenantInfo] = useState(null);

  const getDaysLeft = (endDate) => {
    if (!endDate) return 0;
    const diff = new Date(endDate) - new Date();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  const [recentInvoices, setRecentInvoices] = useState([]);
  const [recentExpenses, setRecentExpenses] = useState([]);
  const [expenseCategories, setExpenseCategories] = useState([]);
  
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [expenseForm, setExpenseForm] = useState({
    category: "",
    amount: "",
    date: getLocalDateString(),
    description: ""
  });
  const [isSubmittingExpense, setIsSubmittingExpense] = useState(false);

  const [chartDataMonthly, setChartDataMonthly] = useState([]);
  const [chartDataYearly, setChartDataYearly] = useState([]);
  const [chartView, setChartView] = useState("monthly");

  const [clients, setClients] = useState([]);
  const [selectedClientId, setSelectedClientId] = useState("");
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentMode, setPaymentMode] = useState("Bank Transfer");
  const [paymentDate, setPaymentDate] = useState(getLocalDateString());
  const [isSubmittingPayment, setIsSubmittingPayment] = useState(false);

  // --- Helper: Format Currency (Indian Style) ---
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0
    }).format(amount);
  };

  const queryClient = useQueryClient();

  const { data, isLoading: queryLoading, error } = useQuery({
    queryKey: ['dashboard', globalTimeFilter],
    queryFn: async () => {
      const [resStats, resClients, resTenant] = await Promise.all([
         api.get(`/business/dashboard-stats?filter=${globalTimeFilter}`),
         api.get("/clients"),
         api.get("/auth/settings")
      ]);
      return {
        statsData: resStats.data.data,
        clients: resClients.data.data || [],
        tenant: resTenant.data.data || null,
      };
    },
    enabled: !!token
  });

  useEffect(() => {
    if (data) {
      const { statsData, clients, tenant } = data;
      setClients(clients);
      setTenantInfo(tenant);

      // Business Info Guard Check (Only on first login session)
      if (tenant && (!tenant.phone || !tenant.address) && !sessionStorage.getItem('onboardingPrompted')) {
         sessionStorage.setItem('onboardingPrompted', 'true');
         navigate('/settings?onboarding=true');
      }

      setStats(statsData.stats);
      setRecentInvoices(statsData.recentInvoices || []);
      setRecentExpenses(statsData.recentExpenses || []);
      setExpenseCategories(statsData.expenseCategories || []);
      setChartDataMonthly(statsData.chartDataMonthly || []);
      setChartDataYearly(statsData.chartDataYearly || []);

      setLoading(false);
    }
  }, [data, navigate]);

  const handlePaymentSubmit = async (e) => {
    e.preventDefault();
    if (!selectedClientId || !paymentAmount || isNaN(paymentAmount) || Number(paymentAmount) <= 0) {
      return toast.error("Please enter a valid amount");
    }
    setIsSubmittingPayment(true);
    try {
      await api.post(`/clients/${selectedClientId}/payments`, {
        amount: Number(paymentAmount),
        date: paymentDate,
        paymentMode: paymentMode,
        referenceNote: "Dashboard Quick Collect"
      });
      toast.success("Payment Logged Successfully!");
      setPaymentAmount("");
      setSelectedClientId("");
      queryClient.invalidateQueries(['dashboard']);
      queryClient.invalidateQueries(['clients']);
      queryClient.invalidateQueries(['invoices']);
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to log payment");
    } finally {
      setIsSubmittingPayment(false);
    }
  };

  const handleExpenseSubmit = async (e) => {
    e.preventDefault();
    if (!expenseForm.category || !expenseForm.amount) {
      return toast.error("Category and amount are required");
    }
    setIsSubmittingExpense(true);
    try {
      await api.post("/business/expenses", {
        ...expenseForm,
        amount: Number(expenseForm.amount)
      });
      toast.success("Expense Added Successfully!");
      setShowExpenseModal(false);
      setExpenseForm({ category: "", amount: "", date: getLocalDateString(), description: "" });
      queryClient.invalidateQueries(['dashboard']);
      queryClient.invalidateQueries(['expenses']);
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to log expense");
    } finally {
      setIsSubmittingExpense(false);
    }
  };

  const activeClient = clients.find(c => c._id === selectedClientId);

  return (
    <Layout>
      {/* --- HEADER --- */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">Dashboard</h1>
          <div className="mt-1 flex flex-wrap items-center gap-2">
             <p className="text-slate-500">Welcome back, <span className="font-semibold text-blue-600">{user?.name}</span> 👋</p>
             {tenantInfo && tenantInfo.subscriptionEnd && (
                <>
                   <span className="hidden sm:inline-block text-slate-300">•</span>
                   <div className="inline-flex items-center gap-1.5 bg-indigo-50 border border-indigo-100 px-2.5 py-1 rounded-full">
                      <span className="text-[10px] font-black uppercase text-indigo-700">
                         {tenantInfo.subscriptionPlan === 'enterprise' ? 'Business' : tenantInfo.subscriptionPlan === 'premium' ? 'Pro' : 'Freelancer'}
                      </span>
                      <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full ${getDaysLeft(tenantInfo.subscriptionEnd) <= 15 ? 'bg-red-100 text-red-600 animate-pulse' : 'bg-emerald-100 text-emerald-600'}`}>
                         {getDaysLeft(tenantInfo.subscriptionEnd) > 0 ? `${getDaysLeft(tenantInfo.subscriptionEnd)} Days Left` : 'Expired'}
                      </span>
                   </div>
                </>
             )}
          </div>
        </div>
        <div className="flex flex-col sm:flex-row gap-3">
           <select 
              value={globalTimeFilter} 
              onChange={(e) => setGlobalTimeFilter(e.target.value)}
              className="bg-white border border-slate-200 text-slate-700 font-medium px-4 py-2.5 rounded-lg shadow-sm outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all text-sm cursor-pointer"
           >
              <option value="lifetime">Lifetime</option>
              <option value="this_year">This Year</option>
              <option value="this_quarter">This Quarter</option>
              <option value="this_month">This Month</option>
           </select>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-20 text-slate-400">Loading dashboard insights...</div>
      ) : (
        <>
          {/* --- STATS CARDS --- */}
          {/* --- STATS CARDS --- */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-5 mb-8">
            
            {/* 1. Total Revenue */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-emerald-100 rounded-lg text-emerald-600"><Wallet className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Revenue</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2 truncate">{formatCurrency(stats.totalRevenue)}</p>
              <div className="mt-1 text-[10px] text-emerald-600 font-bold flex items-center gap-1"><ArrowUpRight className="w-3 h-3" /> Income</div>
            </div>

            {/* 2. Total Expenses */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-rose-100 rounded-lg text-rose-600"><TrendingUp className="w-4 h-4 rotate-180" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Expenses</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2 truncate">{formatCurrency(stats.totalExpenses)}</p>
              <div className="mt-1 text-[10px] text-rose-600 font-bold">Outflow</div>
            </div>

            {/* 3. Net Profit */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group border-b-4 border-b-blue-500">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-blue-100 rounded-lg text-blue-600"><TrendingUp className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Net Profit</h3>
              </div>
              <p className="text-2xl font-black text-blue-700 mt-2 truncate">{formatCurrency(stats.netProfit)}</p>
              <div className="mt-1 text-[10px] text-blue-500 font-bold">Rev - (Exp + Purchases)</div>
            </div>

            {/* 4. Pending Amount */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-amber-100 rounded-lg text-amber-600"><Clock className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Pending</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2 truncate">{formatCurrency(stats.totalPendingAmount)}</p>
              <div className="mt-1 text-[10px] text-amber-600 font-bold">{stats.pendingCount} unpaid</div>
            </div>

            {/* 5. Total Invoices */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-violet-100 rounded-lg text-violet-600"><FileText className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Invoices</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2">{stats.totalInvoices}</p>
              <div className="mt-1 text-[10px] text-violet-600 font-bold">Lifetime billed</div>
            </div>

            {/* 6. Received Amount */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-indigo-100 rounded-lg text-indigo-600"><CheckCircle className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Received</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2 truncate">
                 {formatCurrency(stats.totalRevenue - stats.totalPendingAmount)}
              </p>
              <div className="mt-1 text-[10px] text-indigo-600 font-bold">Payment collected</div>
            </div>

          </div>

          {/* QUICK ACTIONS ROW */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <button onClick={() => setShowExpenseModal(true)} className="bg-white hover:bg-rose-50 border border-slate-100 hover:border-rose-100 p-4 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 group">
              <div className="p-2 bg-rose-100 text-rose-600 rounded-lg group-hover:scale-110 transition-transform"><Receipt className="w-5 h-5" /></div>
              <span className="font-bold text-slate-700">Add Expense</span>
            </button>
            <Link to="/invoices/create" className="bg-white hover:bg-blue-50 border border-slate-100 hover:border-blue-100 p-4 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 group">
              <div className="p-2 bg-blue-100 text-blue-600 rounded-lg group-hover:scale-110 transition-transform"><FileText className="w-5 h-5" /></div>
              <span className="font-bold text-slate-700">New Invoice</span>
            </Link>
            <Link to="/quotations/create" className="bg-white hover:bg-amber-50 border border-slate-100 hover:border-amber-100 p-4 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 group">
              <div className="p-2 bg-amber-100 text-amber-600 rounded-lg group-hover:scale-110 transition-transform"><FileText className="w-5 h-5" /></div>
              <span className="font-bold text-slate-700">New Quotation</span>
            </Link>
            <Link to="/clients" className="bg-white hover:bg-emerald-50 border border-slate-100 hover:border-emerald-100 p-4 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 group">
              <div className="p-2 bg-emerald-100 text-emerald-600 rounded-lg group-hover:scale-110 transition-transform"><Users className="w-5 h-5" /></div>
              <span className="font-bold text-slate-700">Add Client</span>
            </Link>
          </div>

          {/* --- MAIN CONTENT GRID --- */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* FULL WIDTH REVENUE CHART AT TOP OF GRID */}
            <div className="lg:col-span-3 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                 <h3 className="text-lg font-bold text-slate-800">Revenue Overview</h3>
                 <select value={chartView} onChange={(e) => setChartView(e.target.value)} className="text-xs border rounded px-2 py-1 bg-slate-50 outline-none font-medium text-slate-600">
                    <option value="monthly">Last 6 Months</option>
                    <option value="yearly">Last 5 Years</option>
                 </select>
              </div>
              
              <div className="h-52 w-full">
                 <ResponsiveContainer width="100%" height="100%">
                     <BarChart data={chartView === 'monthly' ? chartDataMonthly : chartDataYearly} margin={{ top: 10, right: 10, left: 10, bottom: 5}}>
                       <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                       <XAxis 
                          dataKey="name" 
                          axisLine={false} 
                          tickLine={false} 
                          tick={{fill: '#64748b', fontSize: 12}} 
                          dy={10}
                       />
                       <YAxis 
                          axisLine={false} 
                          tickLine={false} 
                          tick={{fill: '#64748b', fontSize: 12}}
                          tickFormatter={(value) => `₹${value >= 1000 ? value/1000 + 'k' : value}`} 
                       />
                       <Tooltip 
                          cursor={{fill: '#f8fafc'}}
                          contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                          formatter={(value, name) => [`₹${Number(value).toLocaleString('en-IN')}`, name === 'income' ? 'Income' : 'Expense']}
                       />
                       <Bar dataKey="income" name="Income" fill="#3b82f6" radius={[4, 4, 0, 0]} barSize={16} />
                       <Bar dataKey="expense" name="Expense" fill="#f43f5e" radius={[4, 4, 0, 0]} barSize={16} />
                     </BarChart>
                 </ResponsiveContainer>
              </div>
            </div>

            {/* BOTTOM 3 COLUMNS */}

            {/* 1. RECENT INVOICES */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col">
               <div className="flex justify-between items-center mb-4">
                 <h3 className="text-lg font-bold text-slate-800">Recent Invoices</h3>
                 <Link to="/invoices" className="text-xs text-blue-600 font-bold hover:underline">View All</Link>
               </div>

               <div className="space-y-4 flex-1">
                  {recentInvoices.length === 0 ? (
                     <p className="text-sm text-slate-400 italic">No invoices created yet.</p>
                  ) : (
                     recentInvoices.map((inv) => (
                        <div key={inv._id} className="flex justify-between items-center p-3 hover:bg-slate-50 rounded-lg transition-colors border border-transparent hover:border-slate-100">
                           <div className="flex items-center gap-3">
                              <div className="bg-blue-50 p-2 rounded text-blue-600">
                                 <FileText className="w-4 h-4" />
                              </div>
                              <div>
                                 <div className="flex items-center gap-2 mb-0.5">
                                    <p className="text-sm font-bold text-slate-800 truncate w-24 sm:w-32">{inv.client?.name}</p>
                                    {inv.createdBy && (
                                       <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-slate-200">
                                          {inv.createdBy.name.split(' ')[0]}
                                       </span>
                                    )}
                                 </div>
                                 <p className="text-xs text-slate-500">#{inv.invoiceNumber}</p>
                              </div>
                           </div>
                           <div className="text-right">
                              <p className="text-sm font-bold text-slate-800">{formatCurrency(inv.totalAmount)}</p>
                              <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold inline-block mt-0.5 ${
                                 inv.status === 'Paid' ? 'bg-emerald-100 text-emerald-700' : 
                                 inv.status === 'Pending' ? 'bg-amber-100 text-amber-700' : 'bg-rose-100 text-rose-700'
                              }`}>
                                 {inv.status}
                              </span>
                           </div>
                        </div>
                     ))
                  )}
               </div>
            </div>

            {/* 2. RECENT EXPENSES */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col">
               <div className="flex justify-between items-center mb-4">
                 <h3 className="text-lg font-bold text-slate-800">Recent Expenses</h3>
                 <Link to="/expenses" className="text-xs text-rose-600 font-bold hover:underline">View All</Link>
               </div>

               <div className="space-y-4 flex-1">
                  {recentExpenses.length === 0 ? (
                     <p className="text-sm text-slate-400 italic">No expenses added yet.</p>
                  ) : (
                     recentExpenses.map((exp) => (
                        <div key={exp._id} className="flex justify-between items-center p-3 hover:bg-slate-50 rounded-lg transition-colors border border-transparent hover:border-slate-100">
                           <div className="flex items-center gap-3">
                              <div className="bg-rose-50 p-2 rounded text-rose-600">
                                 <Receipt className="w-4 h-4" />
                              </div>
                              <div>
                                 <div className="flex items-center gap-2 mb-0.5">
                                    <p className="text-sm font-bold text-slate-800 truncate w-24 sm:w-32">{exp.category}</p>
                                    {exp.createdBy && (
                                       <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-500 text-[9px] font-bold px-1.5 py-0.5 rounded border border-slate-200">
                                          {exp.createdBy.name.split(' ')[0]}
                                       </span>
                                    )}
                                 </div>
                                 <p className="text-xs text-slate-500">{new Date(exp.date).toLocaleDateString('en-IN', { day: '2-digit', month: 'short' })}</p>
                              </div>
                           </div>
                           <div className="text-right">
                              <p className="text-sm font-bold text-rose-600">{formatCurrency(exp.amount)}</p>
                           </div>
                        </div>
                     ))
                  )}
               </div>
            </div>

            {/* 3. QUICK COLLECT WIDGET */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
               <h3 className="flex items-center gap-2 text-lg font-bold text-slate-800 mb-4">
                  <Wallet className="w-5 h-5 text-emerald-600" /> Collect Payment
               </h3>
               <form onSubmit={handlePaymentSubmit} className="space-y-4">
                  <select 
                     required
                     value={selectedClientId} 
                     onChange={(e) => setSelectedClientId(e.target.value)}
                     className="w-full text-sm border border-slate-200 rounded-lg p-2.5 bg-slate-50 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-medium text-slate-700"
                  >
                     <option value="">Select a Client...</option>
                     {clients.map(c => (
                        <option key={c._id} value={c._id}>{c.name}</option>
                     ))}
                  </select>

                  {/* KHATABOOK LEDGER CARD */}
                  {activeClient && (
                      <div className="bg-slate-50/80 p-3 rounded-lg border border-slate-200 text-xs shadow-inner">
                          <div className="flex justify-between mb-1.5 text-slate-500">
                             <span>Total Billed:</span>
                             <span className="font-bold text-slate-700">₹{(activeClient.totalBilled || 0).toLocaleString('en-IN')}</span>
                          </div>
                          <div className="flex justify-between mb-2.5 text-slate-500">
                             <span>Total Received:</span>
                             <span className="font-bold text-emerald-600">₹{(activeClient.totalPaid || 0).toLocaleString('en-IN')}</span>
                          </div>
                          <div className="flex justify-between pt-2.5 border-t border-slate-200 border-dashed">
                             <span className="font-bold text-slate-700">Ledger Balance:</span>
                             {activeClient.balance > 0 ? (
                                 <span className="font-extrabold text-rose-600 text-sm">₹{activeClient.balance.toLocaleString('en-IN')} Due</span>
                             ) : activeClient.balance < 0 ? (
                                 <span className="font-extrabold text-blue-600 text-sm">₹{Math.abs(activeClient.balance).toLocaleString('en-IN')} Adv</span>
                             ) : (
                                 <span className="font-bold text-emerald-600">Settled ✓</span>
                             )}
                          </div>
                      </div>
                  )}

                  <div className="flex flex-col gap-3">
                      <div className="relative">
                         <span className="absolute left-3 top-2.5 text-slate-400 font-bold">₹</span>
                         <input 
                            type="number" 
                            required
                            placeholder="Amount..."
                            value={paymentAmount}
                            onChange={(e) => setPaymentAmount(e.target.value)}
                            className="w-full text-sm border border-slate-200 rounded-lg py-2.5 pl-8 pr-3 bg-white outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-bold text-slate-800"
                         />
                      </div>
                      <button 
                         type="submit" 
                         disabled={!selectedClientId || isSubmittingPayment}
                         className={`w-full py-2.5 rounded-lg text-sm font-bold text-white transition-all flex items-center justify-center gap-2 ${
                            !selectedClientId ? 'bg-slate-300 cursor-not-allowed' : 'bg-emerald-600 hover:bg-emerald-700 shadow-md shadow-emerald-200'
                         }`}
                      >
                         {isSubmittingPayment ? <Loader2 className="w-4 h-4 animate-spin" /> : <><CheckCircle className="w-4 h-4" /> Log Payment</>}
                      </button>
                  </div>
               </form>
            </div>

          </div>

        </>
      )}

      {/* QUICK ADD EXPENSE MODAL */}
      {showExpenseModal && (
        <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200">
           <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
              <div className="flex justify-between items-center p-5 border-b border-slate-100">
                 <h3 className="font-bold text-lg text-slate-800 flex items-center gap-2">
                    <Receipt className="w-5 h-5 text-rose-600" /> Log Expense
                 </h3>
                 <button onClick={() => setShowExpenseModal(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                    <X className="w-5 h-5" />
                 </button>
              </div>
              <form onSubmit={handleExpenseSubmit} className="p-5 space-y-4">
                  <div>
                    <label className="text-xs font-bold text-slate-500 mb-1 block">Category</label>
                    <div className="relative">
                      <Tag className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
                      <input 
                        required
                        list="dashboard-expense-categories"
                        value={expenseForm.category}
                        onChange={(e) => setExpenseForm({...expenseForm, category: e.target.value})}
                        placeholder="e.g. Office Supplies" 
                        className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-sm" 
                        autoComplete="off"
                      />
                      <datalist id="dashboard-expense-categories">
                         {expenseCategories.map(cat => <option key={cat} value={cat} />)}
                      </datalist>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                     <div>
                       <label className="text-xs font-bold text-slate-500 mb-1 block">Amount</label>
                       <div className="relative">
                          <span className="absolute left-3 top-2 text-slate-500 font-bold">₹</span>
                          <input 
                             required
                             type="number" 
                             step="0.01" 
                             min="0.1"
                             value={expenseForm.amount}
                             onChange={(e) => setExpenseForm({...expenseForm, amount: e.target.value})}
                             placeholder="0.00" 
                             className="w-full pl-8 pr-4 py-2 border border-slate-200 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-sm font-bold" 
                          />
                       </div>
                     </div>
                     <div>
                       <label className="text-xs font-bold text-slate-500 mb-1 block">Date</label>
                       <div className="relative">
                          <Calendar className="absolute left-3 top-2.5 w-4 h-4 text-slate-400" />
                          <input 
                             required
                             type="date" 
                             value={expenseForm.date}
                             onChange={(e) => setExpenseForm({...expenseForm, date: e.target.value})}
                             className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg outline-none text-sm focus:ring-2 focus:ring-blue-500" 
                          />
                       </div>
                     </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-slate-500 mb-1 block">Description (Optional)</label>
                    <div className="relative">
                       <FileText className="absolute left-3 top-3 w-4 h-4 text-slate-400" />
                       <textarea 
                          value={expenseForm.description}
                          onChange={(e) => setExpenseForm({...expenseForm, description: e.target.value})}
                          placeholder="Notes..." 
                          className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-lg outline-none text-sm h-20 resize-none focus:ring-2 focus:ring-blue-500" 
                       />
                    </div>
                  </div>

                  <div className="pt-2 flex gap-3">
                     <button type="button" onClick={() => setShowExpenseModal(false)} className="flex-1 py-2.5 bg-slate-50 border border-slate-200 text-slate-600 rounded-lg font-bold hover:bg-slate-100 transition-colors">
                        Cancel
                     </button>
                     <button type="submit" disabled={isSubmittingExpense} className="flex-1 py-2.5 bg-rose-600 text-white rounded-lg font-bold hover:bg-rose-700 transition-colors shadow-md shadow-rose-200 flex justify-center items-center gap-2">
                        {isSubmittingExpense ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Save Expense'}
                     </button>
                  </div>
              </form>
           </div>
        </div>
      )}
    </Layout>
  );
};

export default Dashboard;