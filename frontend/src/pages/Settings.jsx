import { useState, useEffect, useContext } from "react";
import api from "../utils/api";
import toast from "react-hot-toast";
import { Save, Building, CreditCard, FileText, Upload, Trash2, Image as ImageIcon, AlertTriangle } from "lucide-react";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import { INDIAN_STATES } from "../utils/constants";
import { useLocation, useNavigate } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";

const Settings = () => {
  const { token } = useContext(AuthContext);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);

  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteOtp, setDeleteOtp] = useState("");
  const [deleting, setDeleting] = useState(false);
  const [otpSent, setOtpSent] = useState(false);
  
  const location = useLocation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const queryParams = new URLSearchParams(location.search);
  const isOnboarding = queryParams.get("onboarding") === "true";
  
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    address: "",
    gstNumber: "",
    state: "",
    website: "",
    gstEnabled: false,
    defaultTerms: "",
    logoImage: "",      
    bankDetails: {
      accountName: "", 
      bankName: "",
      accountNumber: "",
      ifscCode: ""
    }
  });


  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const res = await api.get("/auth/settings");
        const data = res.data.data;
        setFormData({
            name: data.name || "",
            email: data.email || "",
            phone: data.phone || "",
            address: data.address || "",
            gstNumber: data.gstNumber || "",
            state: data.state || "",
            gstEnabled: data.gstEnabled || false,
            website: data.website || "",
            defaultTerms: data.defaultTerms || "",
            logoImage: data.logoImage || "",
            bankDetails: {
              accountName: data.bankDetails?.accountName || "",
              bankName: data.bankDetails?.bankName || "",
              accountNumber: data.bankDetails?.accountNumber || "",
              ifscCode: data.bankDetails?.ifscCode || ""
            }
        });
      } catch (err) { console.error(err); toast.error("Failed to load settings"); }
    };
    if (token) fetchSettings();
  }, [token]);

  const handleFileUpload = (e, fieldName) => {
    const file = e.target.files[0];
    if (!file) return;

    if (file.size > 500000) {
      toast.error("File is too large! (Max 500KB)");
      return;
    }

    setUploading(true);
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onloadend = () => {
      setFormData(prev => ({ ...prev, [fieldName]: reader.result }));
      setUploading(false);
    };
  };

  const handleRemoveImage = (fieldName) => {
    setFormData(prev => ({ ...prev, [fieldName]: "" }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // If onboarding, enforce phone and address
    if (isOnboarding) {
       if (!formData.phone || !formData.address) {
          return toast.error("Phone number and Business Address are required to continue!");
       }
    }

    setLoading(true);
    try {
      await api.put("/auth/settings", formData);
      toast.success("Settings Updated Successfully!");
      
      // Clear cache completely so dashboard gets fresh data and doesn't use stale data to redirect back
      queryClient.removeQueries({ queryKey: ['dashboard'] });
      
      if (isOnboarding) {
         navigate('/dashboard');
      }
    } catch (err) {
      toast.error("Failed to update settings");
    } finally {
      setLoading(false);
    }
  };

  const handleRequestDelete = async () => {
    try {
      setDeleting(true);
      await api.post("/auth/account/delete-request");
      setOtpSent(true);
      toast.success("OTP sent to your email!");
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to send OTP");
    } finally {
      setDeleting(false);
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteOtp) return toast.error("Please enter OTP");
    try {
      setDeleting(true);
      await api.post("/auth/account/delete-confirm", { otp: deleteOtp });
      toast.success("Account deleted successfully");
      // Log out
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      window.location.href = "/login";
    } catch (err) {
      toast.error(err.response?.data?.message || "Invalid OTP");
    } finally {
      setDeleting(false);
    }
  };

  return (
    <Layout>
       <div className="max-w-5xl mx-auto pb-20 px-4">
          {isOnboarding && (
             <div className="bg-gradient-to-r from-blue-600 to-blue-800 text-white p-6 mb-8 rounded-2xl shadow-2xl shadow-blue-500/30 flex items-start gap-4 animate-[bounce_1s_ease-in-out_1]">
                <div className="bg-white/20 p-3 rounded-xl shrink-0 animate-pulse">
                   <AlertTriangle className="text-white" size={24} />
                </div>
                <div>
                   <h3 className="text-xl font-black tracking-tight text-white mb-1">Welcome to Auriva BMS! Let's get started.</h3>
                   <p className="text-blue-100 text-sm leading-relaxed">Before exploring the system, we need some basic details. Please fill out your <strong>Phone Number</strong> and <strong>Business Address</strong> below to continue.</p>
                </div>
             </div>
          )}

          <h1 className="text-3xl font-bold text-gray-800 mb-6 flex items-center gap-2">
             <Building className="text-blue-600"/> Company Settings
          </h1>

          <form onSubmit={handleSubmit} className="space-y-6">
             
             {/* --- 1. BRANDING (LOGO ONLY) --- */}
             <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-lg mb-4 border-b pb-2 flex items-center gap-2">
                  <ImageIcon size={18} /> Company Branding
                </h3>
                <div className="grid grid-cols-1 gap-8">
                   {/* Logo Upload */}
                   <div>
                      <label className="block text-xs font-bold text-gray-500 mb-2 uppercase tracking-wider">Company Logo</label>
                      <div className="flex items-center gap-6">
                        {formData.logoImage ? (
                          <div className="relative group">
                            <img src={formData.logoImage} alt="Logo" className="h-24 w-24 object-contain border rounded-lg p-2 bg-gray-50 shadow-inner" />
                            <button 
                              type="button"
                              onClick={() => handleRemoveImage('logoImage')}
                              className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1.5 opacity-0 group-hover:opacity-100 transition shadow-md hover:bg-red-600"
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        ) : (
                          <div className="h-24 w-24 border-2 border-dashed border-gray-300 rounded-lg flex flex-col items-center justify-center text-gray-400 bg-gray-50">
                             <ImageIcon size={24} />
                             <span className="text-[10px] mt-1">No Logo</span>
                          </div>
                        )}
                        <div>
                           <label className="cursor-pointer bg-blue-600 text-white px-4 py-2 rounded-lg font-bold text-xs hover:bg-blue-700 transition flex items-center gap-2 shadow-sm">
                              <Upload size={14} /> Upload New Logo
                              <input type="file" accept="image/*" className="hidden" onChange={(e) => handleFileUpload(e, 'logoImage')} />
                           </label>
                           <p className="text-[10px] text-gray-400 mt-2 italic">Recommended: Square image, PNG or JPG (Max 500KB).</p>
                        </div>
                      </div>
                   </div>
                </div>
             </div>

             {/* --- 2. BUSINESS DETAILS --- */}
             <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-lg mb-4 border-b pb-2 flex items-center gap-2">
                  <Building size={18} /> Business Information
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">Company Name</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">Official Email</label>
                      <input type="email" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">Phone Number</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">Website (Optional)</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.website} onChange={e => setFormData({...formData, website: e.target.value})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">State / UT</label>
                      <select 
                        className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" 
                        value={formData.state} 
                        onChange={e => setFormData({...formData, state: e.target.value})}
                      >
                         <option value="">Select State</option>
                         {INDIAN_STATES.map(state => (
                           <option key={state} value={state}>{state}</option>
                         ))}
                      </select>
                   </div>
                   <div className="md:col-span-2">
                      <label className="text-xs font-bold text-gray-500 uppercase">Business Address</label>
                      <textarea className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 h-24 bg-gray-50 focus:bg-white transition-all" value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})}></textarea>
                   </div>
                </div>
             </div>

             {/* --- 3. TAX & TERMS --- */}
             <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-lg mb-4 border-b pb-2 flex items-center gap-2">
                  <FileText size={18} /> Taxation & Invoice Terms
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                   <div>
                      <div className="flex items-center gap-2 mb-3">
                        <input 
                          type="checkbox" 
                          id="gst-toggle"
                          checked={formData.gstEnabled} 
                          onChange={e => setFormData({...formData, gstEnabled: e.target.checked})}
                          className="w-4 h-4 cursor-pointer accent-blue-600"
                        />
                        <label htmlFor="gst-toggle" className="text-sm font-bold text-gray-700 cursor-pointer">Register for GST</label>
                      </div>
                      <input 
                        type="text" 
                        placeholder="Enter 15-digit GSTIN"
                        className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-200 disabled:text-gray-400 font-mono transition-all" 
                        value={formData.gstNumber} 
                        onChange={e => setFormData({...formData, gstNumber: e.target.value})} 
                        disabled={!formData.gstEnabled}
                      />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase">Default Invoice Terms</label>
                      <textarea 
                        className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 h-28 bg-gray-50 focus:bg-white transition-all" 
                        value={formData.defaultTerms} 
                        onChange={e => setFormData({...formData, defaultTerms: e.target.value})}
                        placeholder="1. Payment due in 7 days&#10;2. Goods once sold..."
                      ></textarea>
                   </div>
                </div>
             </div>

             {/* --- 4. BANKING --- */}
             <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200">
                <h3 className="font-bold text-lg mb-4 border-b pb-2 flex items-center gap-2">
                  <CreditCard size={18} /> Banking Details
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                   <div className="md:col-span-2">
                      <label className="text-xs font-bold text-gray-500 uppercase tracking-tighter">Account Holder Name</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.bankDetails.accountName} onChange={e => setFormData({...formData, bankDetails: {...formData.bankDetails, accountName: e.target.value}})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase tracking-tighter">Bank Name</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.bankDetails.bankName} onChange={e => setFormData({...formData, bankDetails: {...formData.bankDetails, bankName: e.target.value}})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase tracking-tighter">Account Number</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all" value={formData.bankDetails.accountNumber} onChange={e => setFormData({...formData, bankDetails: {...formData.bankDetails, accountNumber: e.target.value}})} />
                   </div>
                   <div>
                      <label className="text-xs font-bold text-gray-500 uppercase tracking-tighter">IFSC Code</label>
                      <input type="text" className="w-full border p-2.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 bg-gray-50 focus:bg-white transition-all font-mono" value={formData.bankDetails.ifscCode} onChange={e => setFormData({...formData, bankDetails: {...formData.bankDetails, ifscCode: e.target.value}})} />
                   </div>
                </div>
             </div>

             <div className="flex justify-end pt-4">
                <button type="submit" disabled={loading || uploading} className="bg-blue-600 text-white px-10 py-3.5 rounded-xl font-bold hover:bg-blue-700 flex items-center gap-2 shadow-lg shadow-blue-200 transition-all disabled:opacity-50 active:scale-95">
                    {loading ? "Saving Changes..." : <><Save size={20}/> Update Business Settings</>}
                </button>
             </div>

             {/* --- DANGER ZONE --- */}
             <div className="bg-red-50 p-6 rounded-xl shadow-sm border border-red-200 mt-10">
                <h3 className="font-bold text-lg mb-2 text-red-700 flex items-center gap-2">
                  <AlertTriangle size={18} /> Danger Zone
                </h3>
                <p className="text-sm text-red-600 mb-4">
                  Permanently deleting your account will revoke access to all your business data, invoices, and settings. This action cannot be undone.
                </p>
                <button 
                  type="button" 
                  onClick={() => setShowDeleteModal(true)}
                  className="bg-red-600 text-white px-6 py-2.5 rounded-lg font-bold hover:bg-red-700 transition flex items-center gap-2"
                >
                  <Trash2 size={16} /> Request Account Deletion
                </button>
             </div>
          </form>

          {/* Delete Account Modal */}
          {showDeleteModal && (
            <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
              <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl">
                <div className="flex items-center gap-3 text-red-600 mb-4">
                  <div className="bg-red-100 p-3 rounded-full">
                    <AlertTriangle size={24} />
                  </div>
                  <h2 className="text-xl font-bold">Delete Account</h2>
                </div>
                
                {!otpSent ? (
                  <>
                    <p className="text-gray-600 mb-4 text-sm">
                      Are you absolutely sure you want to delete your account? A 6-digit OTP will be sent to your email to verify your identity.
                    </p>
                    <div className="bg-orange-50 border border-orange-200 p-3 rounded-lg mb-6">
                      <p className="text-orange-800 text-xs font-medium">
                        <strong>Note:</strong> Since business data is crucial, we retain your data securely for <strong>30 days</strong> after deletion. If you wish to recover your account during this period, please contact the AurivaBMS team.
                      </p>
                    </div>
                    <div className="flex justify-end gap-3">
                      <button onClick={() => setShowDeleteModal(false)} className="px-4 py-2 font-bold text-gray-500 hover:bg-gray-100 rounded-lg">Cancel</button>
                      <button onClick={handleRequestDelete} disabled={deleting} className="px-4 py-2 font-bold bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50">
                        {deleting ? "Sending OTP..." : "Yes, Send OTP"}
                      </button>
                    </div>
                  </>
                ) : (
                  <>
                    <p className="text-gray-600 mb-4 text-sm">
                      Enter the 6-digit verification code sent to your email to confirm deletion.
                    </p>
                    <input 
                      type="text" 
                      maxLength="6"
                      placeholder="------"
                      className="w-full border p-3 rounded-xl mb-6 text-center text-2xl font-black tracking-[0.5em] outline-none focus:ring-2 focus:ring-red-500 bg-gray-50"
                      value={deleteOtp}
                      onChange={e => setDeleteOtp(e.target.value.replace(/\D/g, ''))}
                    />
                    <div className="flex justify-end gap-3">
                      <button onClick={() => {setShowDeleteModal(false); setOtpSent(false); setDeleteOtp("");}} className="px-4 py-2 font-bold text-gray-500 hover:bg-gray-100 rounded-lg">Cancel</button>
                      <button onClick={handleConfirmDelete} disabled={deleting || deleteOtp.length !== 6} className="px-4 py-2 font-bold bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50">
                        {deleting ? "Deleting..." : "Permanently Delete"}
                      </button>
                    </div>
                  </>
                )}
              </div>
            </div>
          )}
       </div>
    </Layout>
  );
};

export default Settings;