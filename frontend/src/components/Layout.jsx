import { useState, useContext } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { 
  LayoutDashboard, FileText, FileStack, Users, Wallet, 
  ShieldCheck, Settings, LogOut, BarChart3, Menu, X, 
  ChevronRight, Hexagon, Shield, Package, Truck, Database, LifeBuoy, TrendingUp
} from "lucide-react"; 
import { AuthContext } from "../context/AuthContext";
import NotificationBell from "./NotificationBell";
import ExpiryPopup from "./ExpiryPopup";

const Layout = ({ children }) => {
  const { user, logout } = useContext(AuthContext);
  const location = useLocation();
  const navigate = useNavigate();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const getMenuItems = (role) => {
    if (role === 'super_admin') {
      return [
        { name: "Master Control", path: "/super-admin", icon: BarChart3 },
        { name: "Analytics", path: "/super-admin/analytics", icon: TrendingUp },
        { name: "SMTP Settings", path: "/super-admin/settings", icon: Settings },
      ];
    }
    
    let items = [
      { name: "Dashboard", path: "/dashboard", icon: LayoutDashboard },
      { name: "Invoices", path: "/invoices", icon: FileText },
      { name: "Quotations", path: "/quotations", icon: FileStack },
      { name: "Clients", path: "/clients", icon: Users },
      { name: "Inventory", path: "/inventory", icon: Package },
      { name: "Suppliers", path: "/suppliers", icon: Truck },
      { name: "Expenses", path: "/expenses", icon: Wallet },
    ];

    if (role === 'admin') {
      items.push(
        { name: "Import Data", path: "/import-data", icon: Database },
        { name: "Team & Access", path: "/team", icon: ShieldCheck },
        { name: "Settings", path: "/settings", icon: Settings }
      );
    }
    return items;
  };

  const menuItems = getMenuItems(user?.role);
  const pageTitle = menuItems.find(i => i.path === location.pathname)?.name || "Dashboard";

  return (
    <div className="flex h-screen bg-[#0f172a] font-sans selection:bg-blue-500/30">
      <ExpiryPopup />
      
      {/* MOBILE OVERLAY */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 bg-slate-950/80 z-40 lg:hidden backdrop-blur-md"
          onClick={() => setIsMobileMenuOpen(false)}></div>
      )}

      {/* --- SIDEBAR --- */}
      <aside className={`
        flex flex-col fixed lg:static inset-y-0 left-0 z-50 w-72 bg-[#1e293b] text-white transform transition-transform duration-300 ease-out border-r border-slate-800
        ${isMobileMenuOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}
      `}>
        {/* NEW LOGO AREA (Matched to Screenshot) */}
        <div className="flex flex-col items-center justify-center pt-10 pb-8 px-6">
          <div className="bg-white p-2.5 rounded-2xl shadow-2xl shadow-blue-500/20 mb-4 border border-slate-200">
            <Hexagon size={32} className="text-[#2563eb]" fill="#2563eb" fillOpacity={0.1} />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Auriva<span className="text-[#2563eb]">BMS</span>
          </h1>
          <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1 opacity-80">
            Business Management System
          </p>
        </div>

        {/* NAVIGATION */}
        <nav className="flex-1 overflow-y-auto py-4 px-4 space-y-1">
          {menuItems.map((item) => {
            const isActive = item.path === '/super-admin' ? location.pathname === '/super-admin' : location.pathname.startsWith(item.path);
            const Icon = item.icon;
            
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => setIsMobileMenuOpen(false)}
                className={`
                  group flex items-center gap-3.5 px-4 py-3.5 rounded-xl transition-all duration-200
                  ${isActive 
                    ? "bg-[#2563eb] text-white shadow-lg shadow-blue-600/25" 
                    : "text-slate-400 hover:bg-slate-800 hover:text-white"
                  }
                `}
              >
                <Icon size={20} className={isActive ? "text-white" : "text-slate-500 group-hover:text-blue-400"} />
                <span className={`text-sm font-semibold ${isActive ? "text-white" : "text-slate-300"}`}>{item.name}</span>
                {isActive && <ChevronRight size={14} className="ml-auto opacity-60" />}
              </Link>
            );
          })}
        </nav>

        {/* FOOTER AREA */}
        <div className="p-6 border-t border-slate-800/50">
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 w-full px-4 py-3 text-slate-400 hover:bg-red-500/10 hover:text-red-400 rounded-xl transition-all group font-bold text-sm"
          >
            <LogOut size={18} className="group-hover:-translate-x-1 transition-transform" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* --- MAIN CONTENT --- */}
      <div className="flex-1 flex flex-col min-w-0 bg-[#f8fafc]">
        
        {/* NAVBAR */}
        <header className="bg-white/70 backdrop-blur-xl border-b border-slate-200 h-20 flex items-center justify-between px-6 lg:px-10 sticky top-0 z-30">
          <div className="flex items-center gap-4">
            <button onClick={() => setIsMobileMenuOpen(true)} className="lg:hidden p-2 text-slate-600 hover:bg-slate-100 rounded-xl transition-colors">
              <Menu size={22} />
            </button>
            <div className="flex flex-col">
                <h2 className="text-xl font-bold text-slate-900 leading-tight tracking-tight">
                    {pageTitle}
                </h2>
                <div className="flex items-center gap-1.5 mt-0.5">
                   <div className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></div>
                   <p className="text-[10px] text-slate-500 font-bold uppercase tracking-tighter">System Live</p>
                </div>
            </div>
          </div>

          <div className="flex items-center gap-6">
             {user?.role === 'super_admin' ? (
                 <div className="hidden sm:flex items-center gap-2 bg-amber-50 text-amber-700 px-3 py-1.5 rounded-full text-[10px] font-black border border-amber-100 ring-4 ring-amber-50">
                    <Shield size={12} />
                    SYSTEM ROOT ACCESS
                 </div>
             ) : (
                <div className="hidden sm:flex items-center gap-2 bg-blue-50 text-[#2563eb] px-3 py-1.5 rounded-full text-[10px] font-black border border-blue-100 ring-4 ring-blue-50">
                    <Hexagon size={12} />
                    {user?.role?.toUpperCase()}
                </div>
             )}
             
             <NotificationBell />
             
             <div className="flex items-center gap-3 pl-6 border-l border-slate-200">
                <div className="text-right hidden sm:block">
                  <p className="text-xs font-black text-slate-900 leading-none">{user?.name?.toUpperCase()}</p>
                  <p className="text-[9px] text-slate-400 font-bold mt-1 tracking-tighter">SECURE SESSION</p>
                </div>
                <div className="h-11 w-11 rounded-2xl bg-gradient-to-tr from-[#2563eb] to-[#3b82f6] flex items-center justify-center text-white font-black shadow-xl shadow-blue-500/20 border-2 border-white">
                   {user?.name?.charAt(0).toUpperCase()}
                </div>
             </div>
          </div>
        </header>

        {/* MAIN BODY */}
        <main className="flex-1 overflow-auto p-4 lg:p-10">
          <div className="max-w-[1600px] mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default Layout;