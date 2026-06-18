import { Routes, Route, Navigate } from "react-router-dom";
import { useContext } from "react";
import { AuthContext } from "./context/AuthContext";
import { Toaster } from "react-hot-toast";

import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Clients from "./pages/Clients";
import ClientProfile from "./pages/ClientProfile";
import Invoices from "./pages/Invoices";
import CreateInvoice from "./pages/CreateInvoice";
import EditInvoice from "./pages/EditInvoice"; 
import ViewInvoice from "./pages/ViewInvoice";
import PublicInvoice from "./pages/PublicInvoice";
import Quotations from "./pages/Quotations";
import CreateQuotation from "./pages/CreateQuotation";
import ViewQuotation from "./pages/ViewQuotation";
import PublicQuotation from "./pages/PublicQuotation";
import EditQuotation from "./pages/EditQuotation"; 
import Team from "./pages/Team"; 
import Settings from "./pages/Settings"; 
import Expenses from "./pages/Expenses"; 
import Inventory from "./pages/Inventory"; 
import Suppliers from "./pages/Suppliers";
import SupplierProfile from "./pages/SupplierProfile";
import PrivateRoute from "./components/PrivateRoute";
import SuperAdminDashboard from "./pages/SuperAdminDashboard";

function App() {
  const { token, user, loading } = useContext(AuthContext);

  const ADMIN_ACCESS = ['admin', 'user']; 
  const SUPER_ACCESS = ['super_admin'];   

  // 1. Loading State Handle Karein (Taaki Refresh par blank screen na aaye)
  if (loading) {
    return (
      <div className="h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <>
      <Toaster position="top-right" reverseOrder={false} />
      <Routes>
      {/* --- ROOT PATH CONTROL --- */}
      <Route path="/" element={
        (!token || !user) ? (
          <Navigate to="/login" replace />
        ) : user?.role === 'super_admin' ? (
          <Navigate to="/super-admin" replace />
        ) : (
          <Navigate to="/dashboard" replace />
        )
      } />

      {/* --- PUBLIC ROUTES --- */}
      <Route path="/login" element={
        (token && user) ? <Navigate to="/" replace /> : <Login />
      } />

      <Route path="/public/invoice/:id" element={<PublicInvoice />} />
      <Route path="/public/quotation/:id" element={<PublicQuotation />} />
      
      {/* --- TENANT ROUTES (Admin & User) --- */}
      <Route path="/dashboard" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Dashboard /></PrivateRoute>
      } />
      
      <Route path="/clients" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Clients /></PrivateRoute>
      } />
      <Route path="/clients/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><ClientProfile /></PrivateRoute>
      } />
      
      <Route path="/invoices" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Invoices /></PrivateRoute>
      } />
      <Route path="/invoices/create" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><CreateInvoice /></PrivateRoute>
      } />
      <Route path="/invoices/edit/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><EditInvoice /></PrivateRoute>
      } />
      <Route path="/invoices/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><ViewInvoice /></PrivateRoute>
      } />

      <Route path="/quotations" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Quotations /></PrivateRoute>
      } />
      <Route path="/quotations/create" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><CreateQuotation /></PrivateRoute>
      } />
      <Route path="/quotations/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><ViewQuotation /></PrivateRoute>
      } />
      <Route path="/quotations/edit/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><EditQuotation /></PrivateRoute>
      } />
      
      <Route path="/expenses" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Expenses /></PrivateRoute>
      } />

      <Route path="/inventory" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Inventory /></PrivateRoute>
      } />

      <Route path="/suppliers" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><Suppliers /></PrivateRoute>
      } />
      <Route path="/suppliers/:id" element={
        <PrivateRoute allowedRoles={ADMIN_ACCESS}><SupplierProfile /></PrivateRoute>
      } />

      <Route path="/settings" element={
        <PrivateRoute allowedRoles={['admin', 'super_admin']}><Settings /></PrivateRoute>
      } />

      <Route path="/team" element={
        <PrivateRoute allowedRoles={['admin']}><Team /></PrivateRoute>
      } />

      {/* --- SUPER ADMIN ROUTE --- */}
      <Route path="/super-admin" element={
        <PrivateRoute allowedRoles={SUPER_ACCESS}><SuperAdminDashboard /></PrivateRoute>
      } />

      {/* --- FALLBACK --- */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
    </>
  );
}

export default App;