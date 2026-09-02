import { useState, useEffect, useContext } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useForm, Controller } from "react-hook-form";
import { useLocation, useNavigate } from "react-router-dom";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import TemplatePicker from "../components/TemplatePicker"; 
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, Legend } from 'recharts';
import { ShieldAlert, Users, TrendingUp, Building2, CheckCircle, XCircle, Search, Trash2, Edit, Calendar, AlertCircle, Clock, IndianRupee, ArrowRight, RotateCcw, History, ShieldCheck, Mail, Lock, Globe, Bell, Settings, LifeBuoy, MessageSquare, FileText, Package, Truck, X, Save, Plus } from "lucide-react";
import { getLocalDateString } from "../utils/dateUtils";

const SuperAdminDashboard = () => {
  // --- STATE ---
  const [tenants, setTenants] = useState([]);
  const [logs, setLogs] = useState([]); 
  const [stats, setStats] = useState({ totalTenants: 0, activeTenants: 0, totalUsers: 0, estRevenue: 0, growthData: [], planDistribution: [], featureAdoption: [] });
  const [viewMode, setViewMode] = useState('list'); 
  const [searchQuery, setSearchQuery] = useState("");

  const [editingTenant, setEditingTenant] = useState(null);
  const [showLogsModal, setShowLogsModal] = useState(false);
  const [viewingTenant, setViewingTenant] = useState(null); 
  const [usageStats, setUsageStats] = useState(null); 
  const [activeTemplateModal, setActiveTemplateModal] = useState(null);
  const [showNotificationModal, setShowNotificationModal] = useState(false);
  const [notificationForm, setNotificationForm] = useState({ message: '', type: 'info', target: 'all_admins', sendEmail: false, subject: '', tenantId: '' });
  const [systemSettings, setSystemSettings] = useState({ SMTP_HOST: '', SMTP_PORT: '', SMTP_USER: '', SMTP_PASS: '', terms_and_conditions: '', privacy_policy: '' });
  const [settingsTab, setSettingsTab] = useState('smtp');
  const [contactMessages, setContactMessages] = useState([]);
  const [blockedIPs, setBlockedIPs] = useState([]);
  const [activeTraffic, setActiveTraffic] = useState([]);
  const [socForm, setSocForm] = useState({ ipAddress: '', reason: '' });

  const { token } = useContext(AuthContext);
  const location = useLocation();
  const navigate = useNavigate();
  
  const getDefaultDate = () => {
    const d = new Date();
    d.setFullYear(d.getFullYear() + 1);
    return d.toISOString().split('T')[0];
  };

  const { control: controlEdit, register: registerEdit, handleSubmit: handleSubmitEdit, setValue: setValueEdit, reset: resetEdit, watch: watchEdit } = useForm();
  
  const { 
    control: controlCreate, 
    register: registerCreate, 
    handleSubmit: handleSubmitCreate, 
    reset: resetCreate, 
    setValue: setValueCreate,
    watch: watchCreate
  } = useForm({
      defaultValues: {
          subscriptionEnd: getDefaultDate(),
          plan: 'basic',
          templatePreference: 'standard',
          quotationTemplate: 'standard'
      }
  });

  const formatINR = (amount) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount || 0);
  
  const getDaysLeft = (endDate) => {
    if (!endDate) return 0;
    const diff = new Date(endDate) - new Date();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  const addDaysToDate = (currentDate, daysToAdd) => {
    const result = currentDate ? new Date(currentDate) : new Date();
    result.setDate(result.getDate() + daysToAdd);
    return result.toISOString().split('T')[0];
  };

  const fetchData = async () => {
    try {
      const [resTenants, resStats, resLogs] = await Promise.all([
        api.get('/auth/tenants'), 
        api.get('/auth/stats'),
        api.get('/auth/logs')
      ]);
      setTenants(resTenants.data.data || []);
      setStats(resStats.data.data || { totalTenants: 0, activeTenants: 0, totalUsers: 0, estRevenue: 0, growthData: [], planDistribution: [], featureAdoption: [] });
      setLogs(resLogs.data.data || []);
    } catch (error) { 
        console.error("Fetch Error:", error);
        toast.error("Failed to load admin data");
    }
  };

  useEffect(() => { if (token) fetchData(); }, [token]);

  const loadSettings = async () => {
    try {
      const [resSettings, resContacts] = await Promise.all([
        api.get('/settings'),
        api.get('/settings/contact-messages')
      ]);
      setSystemSettings(resSettings.data.data || { SMTP_HOST: '', SMTP_PORT: '', SMTP_USER: '', SMTP_PASS: '', terms_and_conditions: '', privacy_policy: '' });
      setContactMessages(resContacts.data.data || []);
      setViewMode('settings');
      setSettingsTab('smtp');
    } catch (e) { toast.error("Failed to load settings"); }
  };

  const loadSecurityData = async () => {
    try {
      const [resBlocked, resTraffic] = await Promise.all([
        api.get('/security/blocked-ips'),
        api.get('/security/active-traffic')
      ]);
      setBlockedIPs(resBlocked.data.data || []);
      setActiveTraffic(resTraffic.data.data || []);
      setViewMode('security');
    } catch (e) { toast.error("Failed to load SOC data"); }
  };

  const handleBlockIP = async (e) => {
    e.preventDefault();
    if (!socForm.ipAddress) return toast.error("IP Address is required");
    try {
      await api.post('/security/block-ip', socForm);
      toast.success("IP successfully blocked");
      setSocForm({ ipAddress: '', reason: '' });
      loadSecurityData();
    } catch (e) { toast.error(e.response?.data?.message || "Failed to block IP"); }
  };

  const handleUnblockIP = async (ip) => {
    if (!window.confirm(`Are you sure you want to unblock ${ip}?`)) return;
    try {
      await api.delete(`/security/unblock-ip/${encodeURIComponent(ip)}`);
      toast.success("IP successfully unblocked");
      loadSecurityData();
    } catch (e) { toast.error("Failed to unblock IP"); }
  };
  
  useEffect(() => {
    if (location.pathname === '/super-admin/analytics') {
      setViewMode('analytics');
    } else if (location.pathname === '/super-admin/settings') {
      loadSettings();
    } else if (location.pathname === '/super-admin/security') {
      loadSecurityData();
    } else {
      setViewMode('list');
    }
  }, [location.pathname]);

  useEffect(() => {
    if (editingTenant) {
        resetEdit({
            name: editingTenant.name,
            email: editingTenant.email,
            phone: editingTenant.phone || '',
            address: editingTenant.address || '',
            website: editingTenant.website || '',
            gstEnabled: editingTenant.gstEnabled || false,
            gstNumber: editingTenant.gstNumber || '',
            status: editingTenant.status,
            subscriptionPlan: editingTenant.subscriptionPlan,
            subscriptionEnd: editingTenant.subscriptionEnd 
                ? new Date(editingTenant.subscriptionEnd).toISOString().split('T')[0] 
                : getLocalDateString(),
            templatePreference: editingTenant.templatePreference || 'standard',
            quotationTemplate: editingTenant.quotationTemplate || 'standard'
        });
    }
  }, [editingTenant, resetEdit]);

  const handleOpenCreate = () => {
    resetCreate({
        subscriptionEnd: getDefaultDate(),
        plan: 'basic',
        templatePreference: 'standard',
        quotationTemplate: 'standard',
        companyName: '',
        slug: '',
        name: '',
        email: '',
        password: ''
    });
    window.history.pushState({ mode: 'create' }, '', '#new-company');
    setViewMode('create');
  };

  const handleBackToDashboard = () => {
    setViewMode('list');
    if (window.location.hash === '#new-company') window.history.back();
  };

  const handleViewUsage = async (tenant) => {
    setViewingTenant(tenant);
    setUsageStats(null);
    try {
      const res = await api.get(`/auth/tenants/${tenant._id}/usage`);
      setUsageStats(res.data.data);
    } catch { setViewingTenant(null); }
  };

  const openEdit = (tenant) => { 
    setEditingTenant(tenant); 
    setViewMode('manage');
    window.scrollTo(0, 0);
  };

  const closeEdit = () => {
    setEditingTenant(null);
    setViewMode('list');
  };

  const handleResetSubscription = () => {
      if(!window.confirm("Reset to 1 Year from today?")) return;
      setValueEdit("subscriptionEnd", getDefaultDate());
  };
  const extendSubscriptionEdit = (days) => {
      const currentEnd = watchEdit("subscriptionEnd");
      setValueEdit("subscriptionEnd", addDaysToDate(currentEnd, days));
  };
  const setAllocationCreate = (days) => {
      const today = new Date();
      const newDate = addDaysToDate(today, days);
      setValueCreate("subscriptionEnd", newDate);
  };

  const handleResetPassword = async () => {
    const newPassword = prompt("Enter new password for this admin (Min 6 chars):");
    if (!newPassword) return;
    if (newPassword.length < 6) {
        toast.error("Password too short!");
        return;
    }

    try {
      await api.put(`/auth/tenants/${editingTenant._id}/password`, { password: newPassword });
      toast.success("Password updated successfully!");
    } catch (e) {
      toast.error(e.response?.data?.message || "Failed to reset password");
    }
  };

  const handleSendResetPasswordEmail = async () => {
    if (!window.confirm(`Send a password reset email to ${editingTenant?.email}?`)) return;
    try {
      await api.post('/auth/forgot-password', { email: editingTenant.email });
      toast.success("Password reset email sent to " + editingTenant.email);
    } catch (e) {
      toast.error(e.response?.data?.message || "Failed to send reset email");
    }
  };

  const onCreateSubmit = async (data) => {
    try {
      if (!data.password || data.password.length < 6) {
          toast.error("Password must be at least 6 characters.");
          return;
      }
      const payload = {
        ...data,
        templatePreference: data.templatePreference || 'standard',
        quotationTemplate: data.quotationTemplate || 'standard'
      };

      await api.post(`/auth/tenants`, payload);
      toast.success("Company Created Successfully!");
      resetCreate();
      handleBackToDashboard();
      fetchData();
    } catch (e) { 
        toast.error(e.response?.data?.message || "Failed to create company."); 
    }
  };

  const onEditSubmit = async (data) => {
    try {
      await api.put(`/auth/tenants/${editingTenant._id}`, data);
      toast.success("Settings Updated");
      setEditingTenant(null);
      setViewMode('list');
      fetchData();
    } catch (e) { toast.error("Update Failed"); }
  };

  const handleDelete = async (id) => {
    if(!window.confirm("Are you sure? This cannot be undone.")) return;
    try { 
        await api.delete(`/auth/tenants/${id}`); 
        toast.success("Company deleted");
        fetchData(); 
    } catch (e) { toast.error("Delete Failed"); }
  };

  const filteredTenants = tenants.filter(t => 
    t.email !== 'riva@auriva.in' && t.name !== 'Platform HQ' &&
    (t.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
    t.email.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4">
           <div>
             <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Super Admin</h1>
             <p className="text-gray-500 text-sm mt-1">Platform Overview & Management</p>
           </div>
           {viewMode === 'list' && (
             <div className="flex gap-3">
                 <button onClick={() => setViewMode('notifications')} className="bg-white text-gray-700 border border-gray-300 px-4 py-2 rounded-lg font-bold hover:bg-gray-50 transition shadow-sm flex items-center gap-2">
                   <Bell className="w-4 h-4"/> Broadcast
                 </button>
                 <button onClick={() => setShowLogsModal(true)} className="bg-white text-gray-700 border border-gray-300 px-4 py-2 rounded-lg font-bold hover:bg-gray-50 transition shadow-sm flex items-center gap-2">
                   <History className="w-4 h-4"/> System Logs
                 </button>
                 <button onClick={handleOpenCreate} className="bg-blue-600 text-white px-5 py-2 rounded-lg shadow-md hover:bg-blue-700 font-bold transition flex items-center gap-2">
                   <Plus className="w-4 h-4"/> New Company
                 </button>
             </div>
           )}
        </div>

        {viewMode === 'list' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-10">
            <StatCard icon={<Building2 className="text-blue-600"/>} label="Total Companies" value={stats.totalTenants} />
            <StatCard icon={<CheckCircle className="text-green-600"/>} label="Active Subs" value={stats.activeTenants} />
            <StatCard icon={<Users className="text-purple-600"/>} label="Total Users" value={stats.totalUsers} />
            <StatCard icon={<IndianRupee className="text-yellow-600"/>} label="Est. Monthly Rev" value={formatINR(stats.estRevenue)} />
          </div>
        )}

        {viewMode === 'list' && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-4 border-b flex items-center justify-between gap-4 bg-gray-50">
                <div className="relative w-full max-w-md">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4"/>
                    <input type="text" placeholder="Search companies..." className="w-full pl-10 pr-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-blue-500 outline-none text-sm"
                        value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
                </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="th-cell pl-6">Company</th>
                    <th className="th-cell">Plan & Rate</th>
                    <th className="th-cell">Expiry Timeline</th>
                    <th className="th-cell">Status</th>
                    <th className="th-cell text-right pr-6">Manage</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {filteredTenants.map((t) => {
                      const daysLeft = getDaysLeft(t.subscriptionEnd);
                      const isExpiring = daysLeft < 15 && daysLeft > 0;
                      const isExpired = daysLeft <= 0;
                      return (
                        <tr key={t._id} className="hover:bg-gray-50 transition-colors">
                          <td className="p-4 pl-6">
                            <div className="font-bold text-gray-900 text-lg">{t.name}</div>
                            <div className="text-xs text-gray-500">{t.email}</div>
                          </td>
                          <td className="p-4">
                             <span className="px-2 py-1 rounded bg-blue-50 text-blue-700 text-xs font-bold uppercase border border-blue-100">
                                {t.subscriptionPlan === 'basic' ? 'Freelancer' : t.subscriptionPlan === 'premium' ? 'Pro' : 'Business'}
                             </span>
                             <div className="text-xs text-gray-500 mt-1">
                                {t.subscriptionPlan === 'enterprise' ? '₹599' : t.subscriptionPlan === 'premium' ? '₹299' : '₹199'}
                             </div>
                          </td>
                          <td className="p-4 min-w-[200px]">
                             <div className="flex justify-between items-center text-xs mb-1">
                                <span className="text-gray-500">{formatDate(t.subscriptionEnd).split(',')[0]}</span>
                                <span className={`font-bold ${isExpired ? 'text-red-600' : isExpiring ? 'text-orange-500' : 'text-green-600'}`}>
                                    {isExpired ? 'Expired' : `${daysLeft} days left`}
                                </span>
                             </div>
                             <div className="w-full bg-gray-200 rounded-full h-2">
                                <div className={`h-full rounded-full ${isExpired ? 'bg-red-500' : 'bg-green-500'}`} style={{ width: '100%' }}></div>
                             </div>
                          </td>
                          <td className="p-4">
                             {t.status === 'active' 
                                ? <span className="text-green-600 font-bold text-xs flex items-center gap-1"><CheckCircle className="w-4 h-4"/> Active</span>
                                : t.status === 'deleted'
                                ? <span className="text-red-600 font-bold text-xs flex items-center gap-1"><Trash2 className="w-4 h-4"/> Deleted</span>
                                : <span className="text-orange-600 font-bold text-xs flex items-center gap-1"><AlertCircle className="w-4 h-4"/> Suspended</span>
                             }
                          </td>
                          <td className="p-4 text-right pr-6">
                            <div className="flex justify-end gap-2">
                                <button onClick={() => handleViewUsage(t)} className="p-2 text-purple-600 bg-purple-50 rounded hover:bg-purple-100 border border-purple-200" title="Insights"><TrendingUp className="w-4 h-4"/></button>
                                <button onClick={() => openEdit(t)} className="px-3 py-2 text-blue-600 bg-blue-50 rounded font-bold hover:bg-blue-100 border border-blue-200 flex items-center gap-2" title="Edit">
                                    <Edit className="w-4 h-4"/> Manage
                                </button>
                                {t.slug !== 'platform-admin' && ( 
                                    <button onClick={() => handleDelete(t._id)} className="p-2 text-red-600 bg-red-50 rounded hover:bg-red-100 border border-red-200" title="Delete"><Trash2 className="w-4 h-4"/></button>
                                )}
                            </div>
                          </td>
                        </tr>
                      );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {viewMode === 'create' && (
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 max-w-5xl mx-auto overflow-hidden">
             <div className="px-8 py-6 border-b flex justify-between items-center bg-gray-50">
                <div>
                    <h2 className="text-2xl font-extrabold text-gray-900">Onboard New Client</h2>
                    <p className="text-sm text-gray-500 mt-1">Setup company details, admin access & subscription validity.</p>
                </div>
                <button onClick={handleBackToDashboard} className="text-gray-500 hover:text-black font-bold text-sm bg-white border px-4 py-2 rounded-lg">Cancel</button>
             </div>
             
             <form onSubmit={handleSubmitCreate(onCreateSubmit)} className="p-8">
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
                   <div className="lg:col-span-7 space-y-6">
                      <h3 className="text-sm font-bold text-blue-600 uppercase tracking-wider border-b pb-2 mb-4">1. Company & Admin Details</h3>
                      <div className="grid grid-cols-2 gap-6">
                          <InputGroup label="Company Name" icon={<Building2 className="w-4 h-4"/>} register={registerCreate("companyName", { required: true })} placeholder="Acme Inc" />
                          <InputGroup label="Slug (Unique URL)" icon={<Globe className="w-4 h-4"/>} register={registerCreate("slug", { required: true })} placeholder="acme" />
                      </div>
                      <div className="grid grid-cols-2 gap-6">
                          <InputGroup label="Admin Name" icon={<ShieldCheck className="w-4 h-4"/>} register={registerCreate("name", { required: true })} placeholder="John Doe" />
                          <InputGroup label="Admin Email" icon={<Mail className="w-4 h-4"/>} register={registerCreate("email", { required: true })} type="email" />
                      </div>
                      <InputGroup label="Password" icon={<Lock className="w-4 h-4"/>} register={registerCreate("password", { required: true, minLength: 6 })} type="password" placeholder="Min 6 chars" />
                   </div>

                   <div className="lg:col-span-5 space-y-6 bg-gray-50 p-6 rounded-xl border border-gray-200">
                        <h3 className="text-sm font-bold text-blue-600 uppercase tracking-wider border-b pb-2 mb-4">2. Subscription Plan</h3>
                        <div>
                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Select Plan</label>
                            <select {...registerCreate("plan", { required: true })} className="w-full border p-3 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white font-medium">
                                <option value="basic">Freelancer (₹199)</option>
                                <option value="premium">Pro (₹299)</option>
                                <option value="enterprise">Business (₹599)</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Valid Until</label>
                            <div className="relative">
                                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5"/>
                                <input type="date" {...registerCreate("subscriptionEnd", { required: true })} className="w-full pl-10 border p-3 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none bg-white font-bold text-gray-800" />
                            </div>
                            <div className="grid grid-cols-3 gap-2 mt-3">
                                <button type="button" onClick={() => setAllocationCreate(30)} className="text-xs font-bold bg-white border px-2 py-1.5 rounded hover:bg-blue-50 hover:text-blue-600 transition">+1 Month</button>
                                <button type="button" onClick={() => setAllocationCreate(180)} className="text-xs font-bold bg-white border px-2 py-1.5 rounded hover:bg-blue-50 hover:text-blue-600 transition">+6 Months</button>
                                <button type="button" onClick={() => setAllocationCreate(365)} className="text-xs font-bold bg-blue-100 border border-blue-200 text-blue-700 px-2 py-1.5 rounded hover:bg-blue-200 transition">+1 Year</button>
                            </div>
                        </div>
                   </div>
                </div>

                <div className="mt-8 pt-8 border-t">
                    <h3 className="text-sm font-bold text-blue-600 uppercase tracking-wider mb-6">3. Default Visual Settings</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                         <div className="bg-gray-50 p-5 rounded-2xl border border-gray-200 shadow-sm flex justify-between items-center">
                            <div>
                               <span className="text-xs font-bold text-gray-500 block mb-1 uppercase tracking-widest">Invoice Design</span>
                               <span className="font-extrabold text-blue-700 uppercase">{watchCreate('templatePreference') || 'standard'}</span>
                            </div>
                            <button type="button" onClick={() => setActiveTemplateModal('create-invoice')} className="px-4 py-2 bg-white border border-gray-300 text-gray-700 font-bold rounded-lg hover:bg-gray-100 transition text-sm shadow-sm flex items-center gap-2">
                               <Edit className="w-4 h-4"/> Change
                            </button>
                         </div>
                         <div className="bg-gray-50 p-5 rounded-2xl border border-gray-200 shadow-sm flex justify-between items-center">
                            <div>
                               <span className="text-xs font-bold text-gray-500 block mb-1 uppercase tracking-widest">Quotation Design</span>
                               <span className="font-extrabold text-purple-700 uppercase">{watchCreate('quotationTemplate') || 'standard'}</span>
                            </div>
                            <button type="button" onClick={() => setActiveTemplateModal('create-quotation')} className="px-4 py-2 bg-white border border-gray-300 text-gray-700 font-bold rounded-lg hover:bg-gray-100 transition text-sm shadow-sm flex items-center gap-2">
                               <Edit className="w-4 h-4"/> Change
                            </button>
                         </div>
                    </div>
                </div>
                
                <div className="pt-8 flex justify-end">
                    <button className="bg-blue-600 text-white font-bold py-3 px-10 rounded-lg hover:bg-blue-700 shadow-lg shadow-blue-200 transition transform hover:-translate-y-1">Create Company & Allocate System</button>
                </div>
             </form>
          </div>
        )}

        {viewMode === 'manage' && editingTenant && (
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 max-w-6xl mx-auto overflow-hidden flex flex-col mb-10">
            <div className="bg-gray-50 border-b border-gray-200 p-6 sm:p-10 flex justify-between items-start flex-col sm:flex-row gap-4 relative overflow-hidden">
               <div className="absolute top-0 right-0 -mt-10 -mr-10 text-gray-200 opacity-50 rotate-12 scale-150 pointer-events-none">
                 <Building2 strokeWidth={0.5} size={300} />
               </div>
               <div className="z-10 relative">
                 <h2 className="text-3xl font-black text-gray-900 tracking-tight flex items-center gap-3">
                   {editingTenant.name} <span className="text-xs bg-blue-100 text-blue-700 px-3 py-1 rounded-full uppercase tracking-widest font-bold">Admin Panel</span>
                 </h2>
                 <p className="text-sm text-gray-500 mt-2 flex items-center gap-2 font-medium"><Mail className="w-4 h-4 text-gray-400"/> {editingTenant.email}</p>
               </div>
               <button 
                 onClick={closeEdit} 
                 className="z-10 px-6 py-2.5 bg-white border border-gray-300 text-gray-700 font-bold rounded-lg hover:bg-gray-50 hover:text-gray-900 transition-all flex items-center gap-2 shadow-sm"
               >
                 <ArrowRight className="w-4 h-4 rotate-180"/> Cancel & Return
               </button>
            </div>
            <form onSubmit={handleSubmitEdit(onEditSubmit)} className="flex-1 p-6 sm:p-10 bg-white">
                 <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                    
                    <div className="lg:col-span-5 space-y-6">
                        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-4">
                            <h4 className="text-sm font-bold text-gray-900 uppercase flex items-center gap-2 border-b pb-2"><Building2 className="w-4 h-4 text-blue-500"/> Company Details</h4>
                            <div className="grid grid-cols-1 gap-4">
                                <InputGroup label="Company Name" register={registerEdit("name", { required: true })} />
                                <InputGroup label="Admin Email" register={registerEdit("email", { required: true })} type="email" />
                                <InputGroup label="Phone" register={registerEdit("phone")} />
                                <InputGroup label="Website" register={registerEdit("website")} />
                                <div>
                                    <label className="text-xs font-bold text-gray-500 uppercase block mb-1">Address</label>
                                    <textarea {...registerEdit("address")} className="w-full border rounded-lg p-2 text-sm bg-gray-50 min-h-[80px]" />
                                </div>
                                <div className="flex items-center gap-4 border-t pt-4">
                                    <div className="flex items-center gap-2">
                                        <input type="checkbox" {...registerEdit("gstEnabled")} id="editGst" />
                                        <label htmlFor="editGst" className="text-xs font-bold text-gray-600 uppercase">GST Enabled</label>
                                    </div>
                                    <input {...registerEdit("gstNumber")} placeholder="GSTIN" className="flex-1 text-sm border p-2 rounded bg-gray-50" />
                                </div>
                            </div>
                        </div>

                        <div className="bg-orange-50 p-6 rounded-xl border border-orange-200 shadow-sm">
                            <h4 className="text-sm font-bold text-orange-800 uppercase mb-4 flex items-center gap-2"><Lock className="w-4 h-4"/> Security</h4>
                            <div className="flex flex-col gap-3">
                              <button type="button" onClick={handleResetPassword} className="w-full py-3 bg-white text-orange-700 font-bold rounded-lg border-2 border-orange-200 hover:bg-orange-100 transition shadow-sm flex items-center justify-center gap-2">
                                 <RotateCcw className="w-4 h-4"/> Manual Reset Password
                              </button>
                              <button type="button" onClick={handleSendResetPasswordEmail} className="w-full py-3 bg-orange-600 text-white font-bold rounded-lg hover:bg-orange-700 transition shadow-sm flex items-center justify-center gap-2">
                                 <Mail className="w-4 h-4"/> Send Reset Password Email
                              </button>
                            </div>
                            <p className="text-[10px] text-orange-600 mt-3 font-medium">Reset password manually or send a reset link to the admin.</p>
                        </div>

                        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                            <h4 className="text-sm font-bold text-gray-900 uppercase mb-4 flex items-center gap-2"><CheckCircle className="w-4 h-4 text-blue-500"/> Account Status</h4>
                            <div className="grid grid-cols-2 gap-4">
                                <div><label className="text-xs font-bold text-gray-500 uppercase block mb-1">Status</label><select {...registerEdit("status")} className="w-full border p-2.5 rounded-lg bg-gray-50 font-medium outline-none"><option value="active">Active</option><option value="suspended">Suspended</option><option value="deleted">Deleted</option></select></div>
                                <div><label className="text-xs font-bold text-gray-500 uppercase block mb-1">Plan</label><select {...registerEdit("subscriptionPlan")} className="w-full border p-2.5 rounded-lg bg-gray-50 font-medium outline-none"><option value="basic">Freelancer</option><option value="premium">Pro (Popular)</option><option value="enterprise">Business</option></select></div>
                            </div>
                        </div>

                        <div className="bg-white p-6 rounded-xl border border-blue-200 shadow-sm ring-1 ring-blue-50">
                            <div className="flex justify-between items-center mb-4"><h4 className="text-sm font-bold text-blue-700 uppercase flex items-center gap-2"><Calendar className="w-4 h-4"/> Subscription Validity</h4><button type="button" onClick={handleResetSubscription} className="text-xs font-bold text-gray-400 hover:text-red-500 flex items-center gap-1 transition"><RotateCcw className="w-3 h-3"/> Reset Default</button></div>
                            <div className="mb-6"><label className="text-xs font-bold text-gray-500 uppercase block mb-1">Valid Until</label><input type="date" {...registerEdit("subscriptionEnd")} className="w-full border p-3 rounded-lg text-lg font-bold text-gray-800 outline-none focus:ring-2 focus:ring-blue-500" /><p className="text-right text-xs font-bold text-blue-600 mt-2">{getDaysLeft(watchEdit("subscriptionEnd"))} Days Remaining</p></div>
                            <div className="grid grid-cols-2 gap-3">
                                <button type="button" onClick={() => extendSubscriptionEdit(30)} className="py-2 px-3 bg-blue-50 text-blue-700 font-bold text-sm rounded-lg hover:bg-blue-100 border border-blue-100 transition flex items-center justify-center gap-1"><Plus className="w-3 h-3"/> Add 1 Month</button>
                                <button type="button" onClick={() => extendSubscriptionEdit(365)} className="py-2 px-3 bg-blue-50 text-blue-700 font-bold text-sm rounded-lg hover:bg-blue-100 border border-blue-100 transition flex items-center justify-center gap-1"><Plus className="w-3 h-3"/> Add 1 Year</button>
                            </div>
                        </div>
                    </div>

                    <div className="lg:col-span-7 space-y-10">
                        <div className="bg-white p-8 rounded-2xl border border-gray-200 shadow-xl flex flex-col space-y-12">
                            <h4 className="text-xl font-black text-gray-900 uppercase tracking-tighter flex items-center gap-3 border-b pb-6">
                                <div className="p-2 bg-purple-100 rounded-lg"><Edit className="w-5 h-5 text-purple-600"/></div>
                                Theme Designer
                            </h4>
                            
                            <div className="space-y-4">
                               <div className="bg-gray-50 p-5 rounded-2xl border border-gray-200 shadow-sm flex justify-between items-center">
                                  <div>
                                     <h5 className="text-lg font-extrabold text-gray-800 flex items-center gap-2">
                                        <div className="w-3 h-3 rounded-full bg-blue-500 shadow-sm shrink-0"></div> Invoice Layout
                                     </h5>
                                     <p className="text-xs text-gray-400 mt-1 uppercase tracking-widest font-bold">Currently Selected: <span className="text-blue-600 font-black">{watchEdit('templatePreference')}</span></p>
                                  </div>
                                  <button type="button" onClick={() => setActiveTemplateModal('manage-invoice')} className="px-5 py-2.5 bg-white border-2 border-gray-200 text-gray-700 font-bold rounded-xl hover:bg-gray-100 hover:border-blue-400 transition shadow-sm flex items-center gap-2">
                                     <Edit className="w-4 h-4"/> Change Layout
                                  </button>
                               </div>
                               
                               <div className="bg-gray-50 p-5 rounded-2xl border border-gray-200 shadow-sm flex justify-between items-center">
                                  <div>
                                     <h5 className="text-lg font-extrabold text-gray-800 flex items-center gap-2">
                                        <div className="w-3 h-3 rounded-full bg-purple-500 shadow-sm shrink-0"></div> Quotation Layout
                                     </h5>
                                     <p className="text-xs text-gray-400 mt-1 uppercase tracking-widest font-bold">Currently Selected: <span className="text-purple-600 font-black">{watchEdit('quotationTemplate')}</span></p>
                                  </div>
                                  <button type="button" onClick={() => setActiveTemplateModal('manage-quotation')} className="px-5 py-2.5 bg-white border-2 border-gray-200 text-gray-700 font-bold rounded-xl hover:bg-gray-100 hover:border-purple-400 transition shadow-sm flex items-center gap-2">
                                     <Edit className="w-4 h-4"/> Change Layout
                                  </button>
                               </div>
                            </div>

                            <div className="mt-6 p-5 bg-gradient-to-r from-blue-600 to-indigo-700 rounded-2xl shadow-lg shadow-blue-200 flex items-center gap-5 text-white">
                                <div className="bg-white/20 p-3 rounded-xl backdrop-blur-md shadow-inner"><Globe className="w-6 h-6 text-white"/></div>
                                <div>
                                    <p className="text-sm font-black uppercase tracking-tighter">Instant Cloud Sync</p>
                                    <p className="text-[11px] text-blue-100 font-bold leading-relaxed">Your design selections are synchronized across all device nodes and client-facing portals in real-time.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                 </div>
              </form>
              <div className="p-10 border-t bg-gray-50 flex justify-end gap-4 rounded-b-xl">
                 <button type="button" onClick={closeEdit} className="px-8 py-4 rounded-xl font-bold text-gray-600 bg-white border border-gray-300 hover:bg-gray-100 transition shadow-sm">Cancel</button>
                 <button onClick={handleSubmitEdit(onEditSubmit)} className="px-10 py-4 rounded-xl font-extrabold text-white bg-blue-600 hover:bg-blue-700 shadow-xl shadow-blue-200 flex items-center gap-3 transition transform hover:-translate-y-1"><Save className="w-5 h-5"/> Apply System Changes</button>
              </div>
          </div>
        )}

        {showLogsModal && (
          <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
             <div className="bg-white rounded-xl shadow-2xl w-full max-w-4xl max-h-[85vh] flex flex-col">
                <div className="p-6 border-b flex justify-between items-center"><h3 className="font-bold">System Logs</h3><button onClick={() => setShowLogsModal(false)}>✕</button></div>
                <div className="overflow-auto flex-1 p-0">
                  <table className="w-full text-left"><thead className="bg-gray-100 sticky top-0"><tr><th className="p-4 text-xs font-bold">Time</th><th className="p-4 text-xs font-bold">Action</th><th className="p-4 text-xs font-bold">Details</th><th className="p-4 text-xs font-bold text-right">User</th></tr></thead>
                  <tbody>{logs.map(l => <tr key={l._id} className="border-b"><td className="p-4 text-xs font-mono">{formatDate(l.createdAt)}</td><td className="p-4"><span className="bg-gray-100 px-2 py-1 rounded text-xs font-bold">{l.action}</span></td><td className="p-4 text-sm">{l.details}</td><td className="p-4 text-right text-xs font-bold">{l.tenantId?.name}</td></tr>)}</tbody></table>
                </div>
                <div className="p-4 border-t flex justify-end"><button onClick={() => setShowLogsModal(false)} className="bg-gray-800 text-white px-4 py-2 rounded">Close</button></div>
             </div>
          </div>
        )}

        {viewingTenant && (
            <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
                <div className="bg-white p-6 rounded-xl w-full max-w-lg shadow-2xl">
                    <div className="flex justify-between items-center mb-6"><h3 className="font-bold text-xl">Usage</h3><button onClick={() => setViewingTenant(null)}>✕</button></div>
                    {!usageStats ? <div className="text-center py-10">Loading...</div> : (
                        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
                             <UsageItem label="Invoices" value={usageStats.invoiceCount} color="text-blue-600" bg="bg-blue-50"/>
                             <UsageItem label="Quotations" value={usageStats.quotationCount} color="text-purple-600" bg="bg-purple-50"/>
                             <UsageItem label="Clients" value={usageStats.clientCount} color="text-green-600" bg="bg-green-50"/>
                             <UsageItem label="Users" value={usageStats.userCount} color="text-yellow-600" bg="bg-yellow-50"/>
                             <UsageItem label="Items (Inv)" value={usageStats.inventoryCount} color="text-orange-600" bg="bg-orange-50"/>
                             <UsageItem label="Suppliers" value={usageStats.supplierCount} color="text-teal-600" bg="bg-teal-50"/>
                        </div>
                    )}
                    <button onClick={() => setViewingTenant(null)} className="w-full mt-6 py-2 bg-gray-800 text-white rounded font-bold">Close</button>
                </div>
            </div>
        )}

        {viewMode === 'notifications' && (
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 max-w-2xl mx-auto overflow-hidden">
            <div className="px-8 py-6 border-b flex justify-between items-center bg-gray-50">
                <div>
                    <h2 className="text-2xl font-extrabold text-gray-900">Broadcast Notification</h2>
                    <p className="text-sm text-gray-500 mt-1">Send a popup message to all admins.</p>
                </div>
                <button onClick={() => setViewMode('list')} className="text-gray-500 hover:text-black font-bold text-sm bg-white border px-4 py-2 rounded-lg">Back</button>
            </div>
            <div className="p-8 space-y-6">
                <div className="flex items-center gap-2 mb-2 border-b pb-4">
                    <input 
                        type="checkbox" 
                        id="sendEmail" 
                        className="w-4 h-4 text-blue-600 rounded"
                        checked={notificationForm.sendEmail}
                        onChange={(e) => setNotificationForm({...notificationForm, sendEmail: e.target.checked})}
                    />
                    <label htmlFor="sendEmail" className="text-sm font-bold text-gray-700">Also send as Email Broadcast to all Tenants</label>
                </div>
                {notificationForm.sendEmail && (
                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase mb-2 tracking-widest">Email Subject</label>
                        <input 
                            type="text"
                            className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold"
                            placeholder="e.g., Bug Fix Update: Application is now faster!"
                            value={notificationForm.subject}
                            onChange={(e) => setNotificationForm({...notificationForm, subject: e.target.value})}
                        />
                    </div>
                )}
                <div>
                    <label className="block text-xs font-bold text-gray-500 uppercase mb-2 tracking-widest">Message Content</label>
                    <textarea 
                        className="w-full border rounded-2xl p-4 text-gray-800 focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 min-h-[120px] font-medium"
                        placeholder="Type your message here..."
                        value={notificationForm.message}
                        onChange={(e) => setNotificationForm({...notificationForm, message: e.target.value})}
                    />
                </div>
                <div className="grid grid-cols-2 gap-6">
                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase mb-2 tracking-widest">Notification Type</label>
                        <select 
                            className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold"
                            value={notificationForm.type}
                            onChange={(e) => setNotificationForm({...notificationForm, type: e.target.value})}
                        >
                            <option value="info">Information (Blue)</option>
                            <option value="success">Success (Green)</option>
                            <option value="warning">Warning (Amber)</option>
                            <option value="error">Urgent (Red)</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-xs font-bold text-gray-500 uppercase mb-2 tracking-widest">Target Audience</label>
                        <select 
                            className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold mb-3"
                            value={notificationForm.target}
                            onChange={(e) => setNotificationForm({...notificationForm, target: e.target.value, tenantId: ''})}
                        >
                            <option value="all_admins">All Tenants (Broadcast)</option>
                            <option value="specific_tenant">Specific Tenant</option>
                        </select>
                        {notificationForm.target === 'specific_tenant' && (
                            <select 
                                className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-white font-bold"
                                value={notificationForm.tenantId}
                                onChange={(e) => setNotificationForm({...notificationForm, tenantId: e.target.value})}
                            >
                                <option value="">-- Select a Tenant --</option>
                                {tenants.filter(t => t.slug !== 'platform-admin').map(t => (
                                    <option key={t._id} value={t._id}>{t.name} ({t.email})</option>
                                ))}
                            </select>
                        )}
                    </div>
                </div>
                <div className="pt-4">
                    <button 
                        onClick={async () => {
                            if(!notificationForm.message) return toast.error("Message is required");
                            if(notificationForm.target === 'specific_tenant' && !notificationForm.tenantId) return toast.error("Please select a specific tenant");
                            try {
                                await api.post('/notifications', notificationForm);
                                toast.success("Notification sent successfully!");
                                setNotificationForm({ message: '', type: 'info', target: 'all_admins', sendEmail: false, subject: '', tenantId: '' });
                                setViewMode('list');
                            } catch (e) {
                                toast.error("Failed to send notification");
                            }
                        }}
                        className="w-full py-4 bg-blue-600 text-white rounded-2xl font-black text-lg shadow-xl shadow-blue-200 hover:bg-blue-700 transition transform hover:-translate-y-1 flex items-center justify-center gap-3"
                    >
                        <ShieldCheck className="w-6 h-6"/> Push Notification
                    </button>
                </div>
            </div>
          </div>
        )}

        {viewMode === 'analytics' && stats.growthData && (
          <div className="space-y-8 max-w-7xl mx-auto mb-10">
            {/* Header */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 px-8 py-6 flex justify-between items-center">
              <div>
                <h2 className="text-2xl font-extrabold text-gray-900">Platform Analytics</h2>
                <p className="text-sm text-gray-500 mt-1">High-level metrics across all companies.</p>
              </div>
              <button onClick={() => navigate('/super-admin')} className="text-gray-500 hover:text-black font-bold text-sm bg-white border px-4 py-2 rounded-lg shadow-sm">Back</button>
            </div>

            {/* KPI Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
               <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                    <IndianRupee className="w-6 h-6"/>
                  </div>
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1">Platform GMV</p>
                    <h3 className="text-2xl font-black text-gray-900">{formatINR(stats.platformGMV)}</h3>
                  </div>
               </div>
               <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                    <FileText className="w-6 h-6"/>
                  </div>
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1">Invoices Processed</p>
                    <h3 className="text-2xl font-black text-gray-900">{stats.platformInvoicesCount}</h3>
                  </div>
               </div>
               <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
                    <Users className="w-6 h-6"/>
                  </div>
                  <div>
                    <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1">End Clients Managed</p>
                    <h3 className="text-2xl font-black text-gray-900">{stats.platformClientsCount}</h3>
                  </div>
               </div>
            </div>

            {/* Charts Row 1 */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <h3 className="text-sm font-bold text-gray-500 uppercase mb-6 tracking-widest text-center">New Companies Growth</h3>
                <div className="h-80 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={stats.growthData}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                      <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} />
                      <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} />
                      <RechartsTooltip cursor={{fill: '#f8fafc'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}} />
                      <Bar dataKey="newTenants" fill="#3b82f6" radius={[4, 4, 0, 0]} name="New Companies" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <h3 className="text-sm font-bold text-gray-500 uppercase mb-6 tracking-widest text-center">Estimated MRR (₹)</h3>
                <div className="h-80 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={stats.growthData}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                      <XAxis dataKey="month" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} />
                      <YAxis axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} />
                      <RechartsTooltip contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}} />
                      <Line type="monotone" dataKey="mrr" stroke="#10b981" strokeWidth={3} dot={{r: 4, fill: '#10b981', strokeWidth: 2, stroke: '#fff'}} activeDot={{r: 6}} name="Est. MRR" />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>

            {/* Charts Row 2 */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <h3 className="text-sm font-bold text-gray-500 uppercase mb-6 tracking-widest text-center">Plan Distribution</h3>
                <div className="h-80 w-full flex items-center justify-center">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={stats.planDistribution} innerRadius={80} outerRadius={120} paddingAngle={5} dataKey="value">
                        {stats.planDistribution?.map((entry, index) => {
                          const colors = ['#cbd5e1', '#3b82f6', '#8b5cf6'];
                          return <Cell key={`cell-${index}`} fill={colors[index % colors.length]} />;
                        })}
                      </Pie>
                      <RechartsTooltip contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}} />
                      <Legend verticalAlign="bottom" height={36} iconType="circle" />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>
              <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                <h3 className="text-sm font-bold text-gray-500 uppercase mb-6 tracking-widest text-center">Feature Adoption</h3>
                <div className="h-80 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={stats.featureAdoption} layout="vertical" margin={{top: 20, right: 30, left: 20, bottom: 5}}>
                      <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#eee" />
                      <XAxis type="number" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} />
                      <YAxis dataKey="name" type="category" axisLine={false} tickLine={false} tick={{fontSize: 12, fill: '#888'}} width={80}/>
                      <RechartsTooltip cursor={{fill: '#f8fafc'}} contentStyle={{borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'}} />
                      <Bar dataKey="users" fill="#f59e0b" radius={[0, 4, 4, 0]} name="Companies Using" barSize={40} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>

          </div>
        )}

        {viewMode === 'settings' && (
          <div className="max-w-5xl mx-auto mb-10">
            <div className="flex justify-between items-center mb-6">
              <div>
                  <h2 className="text-2xl font-extrabold text-gray-900">System Settings</h2>
                  <p className="text-sm text-gray-500 mt-1">Manage global configurations and legal documents.</p>
              </div>
              <button onClick={() => navigate('/super-admin')} className="text-gray-500 hover:text-black font-bold text-sm bg-white border px-4 py-2 rounded-lg">Back</button>
            </div>
            
            <div className="flex border-b border-gray-200 mb-6 gap-6">
               <button onClick={() => setSettingsTab('smtp')} className={`pb-3 text-sm font-bold border-b-2 transition-colors ${settingsTab === 'smtp' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>Email Config (SMTP)</button>
               <button onClick={() => setSettingsTab('legal')} className={`pb-3 text-sm font-bold border-b-2 transition-colors ${settingsTab === 'legal' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>Legal Documents</button>
               <button onClick={() => setSettingsTab('contact')} className={`pb-3 text-sm font-bold border-b-2 transition-colors ${settingsTab === 'contact' ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>Contact Messages</button>
            </div>

            <div className="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden">
               {settingsTab === 'smtp' && (
                 <div className="p-8 space-y-6">
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">SMTP Host</label>
                      <input value={systemSettings.SMTP_HOST} onChange={e => setSystemSettings({...systemSettings, SMTP_HOST: e.target.value})} className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold" placeholder="smtp.gmail.com" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">SMTP Port</label>
                      <input value={systemSettings.SMTP_PORT} onChange={e => setSystemSettings({...systemSettings, SMTP_PORT: e.target.value})} className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold" placeholder="465" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">SMTP Username</label>
                      <input value={systemSettings.SMTP_USER} onChange={e => setSystemSettings({...systemSettings, SMTP_USER: e.target.value})} className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold" placeholder="billing@domain.com" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">SMTP Password</label>
                      <input type="password" value={systemSettings.SMTP_PASS} onChange={e => setSystemSettings({...systemSettings, SMTP_PASS: e.target.value})} className="w-full border p-3 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-bold" placeholder="App Password" />
                    </div>
                    <button onClick={async () => {
                      try {
                        await api.put('/settings', systemSettings);
                        toast.success("SMTP settings saved!");
                      } catch(e) { toast.error("Failed to save settings"); }
                    }} className="w-full py-4 bg-blue-600 text-white rounded-2xl font-black text-lg shadow-xl shadow-blue-200 hover:bg-blue-700 transition flex justify-center gap-2">
                      <Save className="w-5 h-5"/> Save Configuration
                    </button>
                 </div>
               )}

               {settingsTab === 'legal' && (
                 <div className="p-8 space-y-6">
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Terms & Conditions</label>
                      <textarea value={systemSettings.terms_and_conditions || ''} onChange={e => setSystemSettings({...systemSettings, terms_and_conditions: e.target.value})} className="w-full border p-4 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-medium min-h-[250px]" placeholder="Enter terms and conditions text..." />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-gray-500 uppercase mb-2">Privacy Policy</label>
                      <textarea value={systemSettings.privacy_policy || ''} onChange={e => setSystemSettings({...systemSettings, privacy_policy: e.target.value})} className="w-full border p-4 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none bg-gray-50 font-medium min-h-[250px]" placeholder="Enter privacy policy text..." />
                    </div>
                    <button onClick={async () => {
                      try {
                        await api.put('/settings', systemSettings);
                        toast.success("Legal documents saved!");
                      } catch(e) { toast.error("Failed to save documents"); }
                    }} className="w-full py-4 bg-blue-600 text-white rounded-2xl font-black text-lg shadow-xl shadow-blue-200 hover:bg-blue-700 transition flex justify-center gap-2">
                      <Save className="w-5 h-5"/> Save Documents
                    </button>
                 </div>
               )}

               {settingsTab === 'contact' && (
                 <div className="p-0">
                    {contactMessages.length === 0 ? (
                       <div className="p-10 text-center text-gray-500 font-bold">No contact messages received yet.</div>
                    ) : (
                       <div className="overflow-x-auto">
                         <table className="w-full text-left">
                           <thead className="bg-gray-50 border-b border-gray-200">
                             <tr>
                               <th className="p-4 text-xs font-bold uppercase text-gray-500">Date</th>
                               <th className="p-4 text-xs font-bold uppercase text-gray-500">From</th>
                               <th className="p-4 text-xs font-bold uppercase text-gray-500">Subject</th>
                               <th className="p-4 text-xs font-bold uppercase text-gray-500">Message</th>
                             </tr>
                           </thead>
                           <tbody className="divide-y divide-gray-100">
                             {contactMessages.map(msg => (
                               <tr key={msg._id} className="hover:bg-gray-50">
                                 <td className="p-4 text-sm text-gray-500 whitespace-nowrap">{new Date(msg.createdAt).toLocaleDateString()}</td>
                                 <td className="p-4 text-sm font-bold">
                                   <div>{msg.name}</div>
                                   <div className="text-xs text-gray-500 font-normal">{msg.email}</div>
                                 </td>
                                 <td className="p-4 text-sm text-gray-800 font-medium">{msg.subject}</td>
                                 <td className="p-4 text-sm text-gray-600 max-w-xs truncate" title={msg.message}>{msg.message}</td>
                               </tr>
                             ))}
                           </tbody>
                         </table>
                       </div>
                    )}
                 </div>
               )}
            </div>
          </div>
        )}

         {viewMode === 'security' && (
          <div className="bg-white rounded-xl shadow-lg border border-gray-200 max-w-6xl mx-auto overflow-hidden animate-in fade-in">
             <div className="px-8 py-6 border-b flex justify-between items-center bg-gray-50">
                <div>
                    <h2 className="text-2xl font-extrabold text-gray-900 flex items-center gap-2"><ShieldCheck className="w-6 h-6 text-red-500"/> Security Operations Center (SOC)</h2>
                    <p className="text-sm text-gray-500 mt-1">Monitor live traffic, manage blocked IP addresses, and secure your application.</p>
                </div>
                <button onClick={() => navigate('/super-admin')} className="text-gray-500 hover:text-black font-bold text-sm bg-white border px-4 py-2 rounded-lg">Back to Dashboard</button>
             </div>
             
             <div className="p-8 grid lg:grid-cols-3 gap-8">
                {/* LEFT COL: Live Traffic & Manual Block */}
                <div className="lg:col-span-1 space-y-6">
                   
                   {/* Live Traffic */}
                   <div className="bg-blue-50 border border-blue-100 p-6 rounded-xl">
                      <h3 className="font-bold text-blue-800 mb-4 flex items-center gap-2"><TrendingUp className="w-4 h-4"/> Active Connections (Last 15m)</h3>
                      {activeTraffic.length === 0 ? (
                         <div className="text-sm text-gray-500 text-center bg-white p-4 rounded-lg border border-blue-50">No active traffic.</div>
                      ) : (
                         <div className="max-h-60 overflow-y-auto pr-2 space-y-2">
                            {activeTraffic.map((t, idx) => (
                               <div key={idx} className="flex justify-between items-center bg-white p-3 rounded-lg border border-blue-50 text-sm">
                                  <div>
                                     <div className="font-bold font-mono text-gray-700">{t.ipAddress}</div>
                                     <div className="text-xs text-gray-400">Last: {new Date(t.lastRequest).toLocaleTimeString()}</div>
                                  </div>
                                  <div className={`font-bold px-2 py-1 rounded-md ${t.count > 100 ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                                     {t.count} reqs
                                  </div>
                               </div>
                            ))}
                         </div>
                      )}
                   </div>

                   {/* Manual Block Form */}
                   <div className="bg-red-50 border border-red-100 p-6 rounded-xl">
                      <h3 className="font-bold text-red-800 mb-4 flex items-center gap-2"><Lock className="w-4 h-4"/> Block IP Address</h3>
                      <form onSubmit={handleBlockIP} className="space-y-4">
                         <div>
                            <label className="block text-xs font-bold text-red-700 uppercase mb-1">IP Address</label>
                            <input 
                               type="text" 
                               required
                               placeholder="e.g. 192.168.1.1" 
                               value={socForm.ipAddress} 
                               onChange={e => setSocForm({...socForm, ipAddress: e.target.value})} 
                               className="w-full border-red-200 rounded-lg p-3 focus:ring-2 focus:ring-red-500 outline-none border bg-white font-medium" 
                            />
                         </div>
                         <div>
                            <label className="block text-xs font-bold text-red-700 uppercase mb-1">Reason</label>
                            <input 
                               type="text" 
                               required
                               placeholder="e.g. Spamming API" 
                               value={socForm.reason} 
                               onChange={e => setSocForm({...socForm, reason: e.target.value})} 
                               className="w-full border-red-200 rounded-lg p-3 focus:ring-2 focus:ring-red-500 outline-none border bg-white font-medium" 
                            />
                         </div>
                         <button type="submit" className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-3 rounded-lg shadow-sm transition">
                            Block IP
                         </button>
                      </form>
                   </div>
                </div>

                {/* RIGHT COL: Blocked IPs */}
                <div className="lg:col-span-2">
                   <h3 className="font-bold text-gray-800 mb-4">Currently Blocked IPs ({blockedIPs.length})</h3>
                   {blockedIPs.length === 0 ? (
                      <div className="p-10 text-center text-gray-500 font-bold bg-gray-50 rounded-xl border border-gray-100">No IPs are currently blocked.</div>
                   ) : (
                      <div className="overflow-x-auto border border-gray-200 rounded-xl">
                        <table className="w-full text-left">
                          <thead className="bg-gray-50 border-b border-gray-200">
                            <tr>
                              <th className="p-4 text-xs font-bold uppercase text-gray-500">IP Address</th>
                              <th className="p-4 text-xs font-bold uppercase text-gray-500">Reason</th>
                              <th className="p-4 text-xs font-bold uppercase text-gray-500 text-right">Action</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-gray-100">
                            {blockedIPs.map(b => (
                              <tr key={b._id} className={`transition ${b.autoBlocked ? 'hover:bg-orange-50' : 'hover:bg-red-50'}`}>
                                <td className="p-4">
                                   <div className={`font-bold font-mono ${b.autoBlocked ? 'text-orange-600' : 'text-red-600'}`}>{b.ipAddress}</div>
                                   {b.autoBlocked && <div className="text-[10px] uppercase font-bold text-orange-500 mt-1 bg-orange-100 inline-block px-2 py-0.5 rounded">Auto Blocked</div>}
                                </td>
                                <td className="p-4">
                                   <div className="text-sm font-medium text-gray-700">{b.reason}</div>
                                   <div className="text-xs text-gray-500 mt-1">Blocked: {new Date(b.createdAt).toLocaleTimeString()}</div>
                                   {b.expiresAt && <div className="text-xs font-bold text-gray-400 mt-1">Expires: {new Date(b.expiresAt).toLocaleTimeString()}</div>}
                                </td>
                                <td className="p-4 text-right">
                                   <button 
                                      onClick={() => handleUnblockIP(b.ipAddress)} 
                                      className="text-xs font-bold bg-white text-gray-600 hover:text-green-600 border border-gray-300 hover:border-green-300 px-3 py-1.5 rounded-lg shadow-sm transition"
                                   >
                                      Unblock
                                   </button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                   )}
                </div>
             </div>
          </div>
        )}

        {/* TEMPLATE PICKER MODAL */}
        {activeTemplateModal && (
           <div className="fixed inset-0 bg-slate-900/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
              <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-6xl flex flex-col my-8 animate-in zoom-in duration-200">
                 <div className="px-8 py-6 border-b flex justify-between items-center bg-gray-50 rounded-t-[2rem]">
                    <div>
                        <h3 className="text-2xl font-black text-gray-900 tracking-tight">Select Theme Layout</h3>
                        <p className="text-sm text-gray-500 font-medium">Choose a professional design for your documents.</p>
                    </div>
                    <button onClick={() => setActiveTemplateModal(null)} className="text-gray-400 hover:text-red-500 bg-white shadow-sm border p-2 rounded-lg transition">✕</button>
                 </div>
                 <div className="p-8 bg-gray-100 overflow-x-auto overflow-y-hidden rounded-b-[2rem]">
                     <TemplatePicker 
                        selectedId={
                          activeTemplateModal === 'create-invoice' ? watchCreate('templatePreference') :
                          activeTemplateModal === 'create-quotation' ? watchCreate('quotationTemplate') :
                          activeTemplateModal === 'manage-invoice' ? watchEdit('templatePreference') :
                          activeTemplateModal === 'manage-quotation' ? watchEdit('quotationTemplate') : 'standard'
                        } 
                        onSelect={(id) => {
                          if (activeTemplateModal === 'create-invoice') setValueCreate('templatePreference', id);
                          if (activeTemplateModal === 'create-quotation') setValueCreate('quotationTemplate', id);
                          if (activeTemplateModal === 'manage-invoice') setValueEdit('templatePreference', id);
                          if (activeTemplateModal === 'manage-quotation') setValueEdit('quotationTemplate', id);
                          setActiveTemplateModal(null);
                        }} 
                     />
                 </div>
              </div>
           </div>
        )}

      </div>
    </Layout>
  );
};

const StatCard = ({ icon, label, value }) => (<div className="p-5 rounded-xl border border-gray-100 bg-white shadow-sm flex items-center gap-4"><div className="p-3 bg-gray-50 rounded-lg">{icon}</div><div><p className="text-xs font-bold text-gray-400 uppercase tracking-wide">{label}</p><p className="text-xl font-extrabold text-gray-800">{value}</p></div></div>);
const InputGroup = ({ label, icon, register, type="text", placeholder }) => (<div><label className="text-xs font-bold text-gray-500 uppercase mb-1 flex items-center gap-1">{icon && icon} {label}</label><input {...register} type={type} placeholder={placeholder} className="w-full border-gray-300 rounded-lg p-3 focus:ring-2 focus:ring-blue-500 outline-none border bg-white font-medium" /></div>);
const UsageItem = ({ label, value, color, bg }) => (<div className={`${bg} p-4 rounded-xl text-center border border-opacity-50`}><div className={`text-2xl font-extrabold ${color}`}>{value}</div><div className="text-xs font-bold text-gray-500 uppercase mt-1">{label}</div></div>);

export default SuperAdminDashboard;