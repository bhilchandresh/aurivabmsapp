import { useEffect, useState, useContext } from "react";
import api from "../utils/api";
import { Link } from "react-router-dom";
import { 
  Wallet, FileText, Clock, TrendingUp, 
  Plus, Users, ArrowRight, ArrowUpRight, CheckCircle, Loader2
} from "lucide-react"; // Icons
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer 
} from 'recharts'; // Charts
import { AuthContext } from "../context/AuthContext";
import Layout from "../components/Layout";
import toast from "react-hot-toast";

const Dashboard = () => {
  const { user, token } = useContext(AuthContext);
  const [loading, setLoading] = useState(true);
  
  const [stats, setStats] = useState({
    totalRevenue: 0,
    totalExpenses: 0,
    netProfit: 0,
    totalPendingAmount: 0,
    totalInvoices: 0,
    paidInvoices: 0,
    pendingCount: 0
  });

  const [tenantInfo, setTenantInfo] = useState(null);

  const getDaysLeft = (endDate) => {
    if (!endDate) return 0;
    const diff = new Date(endDate) - new Date();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  const [recentInvoices, setRecentInvoices] = useState([]);
  
  const [chartDataMonthly, setChartDataMonthly] = useState([]);
  const [chartDataYearly, setChartDataYearly] = useState([]);
  const [chartView, setChartView] = useState("monthly");

  const [clients, setClients] = useState([]);
  const [selectedClientId, setSelectedClientId] = useState("");
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentMode, setPaymentMode] = useState("Bank Transfer");
  const [paymentDate, setPaymentDate] = useState(new Date().toISOString().split('T')[0]);
  const [isSubmittingPayment, setIsSubmittingPayment] = useState(false);

  // --- Helper: Format Currency (Indian Style) ---
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0
    }).format(amount);
  };

  const fetchData = async () => {
    try {
      const [resInv, resExp, resClients, resTenant] = await Promise.all([
         api.get("/invoices"),
         api.get("/business/expenses"),
         api.get("/clients"),
         api.get("/auth/settings")
      ]);
      
      const invoices = resInv.data.data || [];
      const expenses = resExp.data.data || [];
      setClients(resClients.data.data || []);
      setTenantInfo(resTenant.data.data || null);

        // 1. Calculate Stats
        const totalRev = invoices.reduce((sum, inv) => sum + (inv.totalAmount || 0), 0);
        const totalExp = expenses.reduce((sum, exp) => sum + (Number(exp.amount) || 0), 0);
        const netProfit = totalRev - totalExp;
        
        // Calculate amount stuck in 'Pending' or 'Overdue'
        const pendingAmt = invoices
          .filter(inv => inv.status === 'Pending' || inv.status === 'Overdue')
          .reduce((sum, inv) => sum + (inv.totalAmount || 0), 0);

        const paidCount = invoices.filter(inv => inv.status === 'Paid').length;
        const pendingCount = invoices.filter(inv => inv.status === 'Pending').length;

        setStats({
          totalRevenue: totalRev,
          totalExpenses: totalExp,
          netProfit: netProfit,
          totalPendingAmount: pendingAmt,
          totalInvoices: invoices.length,
          paidInvoices: paidCount,
          pendingCount: pendingCount
        });

        // 2. Recent Invoices (Last 5)
        const sorted = [...invoices].sort((a, b) => new Date(b.date) - new Date(a.date));
        setRecentInvoices(sorted.slice(0, 5));

        // 3. Prepare Dual-Bar Chart Data (Group by Month)
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const months = {};
        
        // Initialize last 6 months in chronological order
        for (let i = 5; i >= 0; i--) {
            const d = new Date();
            d.setMonth(d.getMonth() - i);
            const m = monthNames[d.getMonth()];
            months[m] = { name: m, income: 0, expense: 0 };
        }

        invoices.forEach(inv => {
          if (!inv.date) return;
          const m = monthNames[new Date(inv.date).getMonth()];
          if (months[m]) months[m].income += (inv.totalAmount || 0);
        });

        expenses.forEach(exp => {
          if (!exp.date) return;
          const m = monthNames[new Date(exp.date).getMonth()];
          if (months[m]) months[m].expense += (Number(exp.amount) || 0);
        });

        const chartArrayMonthly = Object.values(months);
        setChartDataMonthly(chartArrayMonthly);

        // 4. Prepare Dual-Bar Chart Data (Group by Year)
        const yearNames = [];
        for (let i = 4; i >= 0; i--) {
            yearNames.push((new Date().getFullYear() - i).toString());
        }
        const years = {};
        yearNames.forEach(y => years[y] = { name: y, income: 0, expense: 0 });

        invoices.forEach(inv => {
          if (!inv.date) return;
          const y = new Date(inv.date).getFullYear().toString();
          if (years[y]) years[y].income += (inv.totalAmount || 0);
        });

        expenses.forEach(exp => {
          if (!exp.date) return;
          const y = new Date(exp.date).getFullYear().toString();
          if (years[y]) years[y].expense += (Number(exp.amount) || 0);
        });

        const chartArrayYearly = Object.values(years);
        setChartDataYearly(chartArrayYearly);

      } catch (error) {
        console.error("Error loading dashboard data", error);
      } finally {
        setLoading(false);
      }
  };

  useEffect(() => {
    if(token) fetchData();
  }, [token]);

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
      fetchData(); // Silently refresh dashboard stats & backend data
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to log payment");
    } finally {
      setIsSubmittingPayment(false);
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
        <div className="flex gap-3">
           <Link to="/invoices/create" className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg shadow-md font-medium flex items-center gap-2 transition-all">
             <Plus className="w-5 h-5" /> New Invoice
           </Link>
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
              <div className="mt-1 text-[10px] text-blue-500 font-bold">Bottom Line</div>
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

            {/* 6. Success Rate */}
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 relative overflow-hidden group">
              <div className="flex items-center gap-3 mb-2">
                 <div className="p-2 bg-purple-100 rounded-lg text-purple-600"><Plus className="w-4 h-4" /></div>
                 <h3 className="text-slate-500 text-xs font-bold uppercase tracking-wider">Success</h3>
              </div>
              <p className="text-xl font-extrabold text-slate-800 mt-2">
                 {stats.totalInvoices > 0 ? Math.round((stats.paidInvoices / stats.totalInvoices) * 100) : 0}%
              </p>
              <div className="mt-1 text-[10px] text-purple-600 font-bold">Invoices paid</div>
            </div>

          </div>

          {/* --- MAIN CONTENT GRID --- */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            
            {/* LEFT: REVENUE CHART */}
            <div className="lg:col-span-2 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                 <h3 className="text-lg font-bold text-slate-800">Revenue Overview</h3>
                 <select value={chartView} onChange={(e) => setChartView(e.target.value)} className="text-xs border rounded px-2 py-1 bg-slate-50 outline-none font-medium text-slate-600">
                    <option value="monthly">Last 6 Months</option>
                    <option value="yearly">Last 5 Years</option>
                 </select>
              </div>
              
              <div className="h-64 w-full">
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

            {/* RIGHT: RECENT INVOICES LIST */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
               <div className="flex justify-between items-center mb-4">
                 <h3 className="text-lg font-bold text-slate-800">Recent Invoices</h3>
                 <Link to="/invoices" className="text-xs text-blue-600 font-bold hover:underline">View All</Link>
               </div>

               <div className="space-y-4">
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
                                 <p className="text-sm font-bold text-slate-800">{inv.client?.name}</p>
                                 <p className="text-xs text-slate-500">#{inv.invoiceNumber}</p>
                              </div>
                           </div>
                           <div className="text-right">
                              <p className="text-sm font-bold text-slate-800">{formatCurrency(inv.totalAmount)}</p>
                              <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
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

               {/* QUICK COLLECT PAYMENT WIDGET */}
               <div className="mt-6 pt-6 border-t border-slate-100">
                  <h4 className="flex items-center gap-2 text-sm font-bold text-slate-800 mb-3">
                     <Wallet className="w-4 h-4 text-emerald-600" /> Collect Payment
                  </h4>
                  <form onSubmit={handlePaymentSubmit} className="space-y-3">
                     <select 
                        required
                        value={selectedClientId} 
                        onChange={(e) => setSelectedClientId(e.target.value)}
                        className="w-full text-sm border border-slate-200 rounded-lg p-2 bg-slate-50 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-medium text-slate-700"
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

                     <div className="flex gap-2">
                         <div className="relative flex-1">
                            <span className="absolute left-3 top-2 text-slate-400 font-bold">₹</span>
                            <input 
                               type="number" 
                               required
                               placeholder="0.00"
                               value={paymentAmount}
                               onChange={(e) => setPaymentAmount(e.target.value)}
                               className="w-full text-sm border border-slate-200 rounded-lg py-2 pl-7 pr-3 bg-white outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-all font-bold text-slate-800"
                            />
                         </div>
                         <button 
                            type="submit" 
                            disabled={!selectedClientId || isSubmittingPayment}
                            className={`px-4 py-2 rounded-lg text-sm font-bold text-white transition-all flex items-center justify-center min-w-[90px] ${
                               !selectedClientId ? 'bg-slate-300 cursor-not-allowed' : 'bg-emerald-600 hover:bg-emerald-700 shadow-md shadow-emerald-200'
                            }`}
                         >
                            {isSubmittingPayment ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Log Pay'}
                         </button>
                     </div>
                  </form>
               </div>

               {/* Quick Action Box */}
               <div className="mt-6 pt-6 border-t border-slate-100">
                  <h4 className="text-xs font-bold text-slate-400 uppercase mb-3">Quick Actions</h4>
                  <div className="grid grid-cols-2 gap-3">
                     <Link to="/clients" className="flex items-center justify-center gap-2 p-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 hover:text-blue-600 transition-colors">
                        <Users className="w-4 h-4" /> Add Client
                     </Link>
                     <Link to="/invoices" className="flex items-center justify-center gap-2 p-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 hover:text-blue-600 transition-colors">
                        <ArrowRight className="w-4 h-4" /> All Invoices
                     </Link>
                  </div>
               </div>
            </div>

          </div>
        </>
      )}
    </Layout>
  );
};

export default Dashboard;