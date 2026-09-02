import { useState, useEffect, useContext } from "react";
import { Link } from "react-router-dom";
import api from "../utils/api";
import toast from "react-hot-toast";
import { useForm } from "react-hook-form";
import Layout from "../components/Layout";
import { AuthContext } from "../context/AuthContext";
import { AlertCircle, CheckCircle, Plus, Trash2, Upload, RefreshCw, Lock, ArrowRight, Users, Edit2 } from "lucide-react";

// Plan limits mirror the backend PLANS config
const PLAN_LIMITS = {
  basic:      { maxUsers: 1 },
  premium:    { maxUsers: 5 },
  enterprise: { maxUsers: Infinity },
};

const Team = () => {
  const [team, setTeam] = useState([]);
  const [plan, setPlan] = useState("basic");
  const [pageLoading, setPageLoading] = useState(true);
  const { token, user } = useContext(AuthContext);

  const { register, handleSubmit, reset, formState: { errors } } = useForm();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editData, setEditData] = useState({ id: null, name: "" });
  const [editModalError, setEditModalError] = useState(null);
  
  const [uploadingId, setUploadingId] = useState(null);
  const [apiError, setApiError] = useState(null);
  const [apiSuccess, setApiSuccess] = useState(null);
  const [modalError, setModalError] = useState(null);

  const showSuccess = (msg) => {
    setApiSuccess(msg);
    setApiError(null);
    setTimeout(() => setApiSuccess(null), 4000);
  };

  const convertToBase64 = (file) => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result);
      reader.onerror = error => reject(error);
    });
  };

  const fetchTeam = async () => {
    try {
      const [resUsers, resSettings] = await Promise.all([
        api.get("/users"),
        api.get("/auth/settings"),
      ]);
      setTeam(resUsers.data.data || []);
      setPlan(resSettings.data.data.subscriptionPlan || "basic");
    } catch (error) {
      setApiError("Error fetching team details.");
    } finally {
      setPageLoading(false);
    }
  };

  useEffect(() => { if (token) fetchTeam(); }, [token]);

  const handleSignatureUpload = async (e, userId) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) { setApiError("Image is too large. Please select an image under 2MB."); return; }
    setUploadingId(userId); setApiError(null); setApiSuccess(null);
    try {
      const base64 = await convertToBase64(file);
      await api.put(`/users/${userId}`, { signatureImage: base64 });
      showSuccess("Signature updated successfully!");
      fetchTeam();
    } catch (error) {
      setApiError(error.response?.data?.message || "Failed to upload signature.");
    } finally { setUploadingId(null); }
  };

  const onSubmit = async (data) => {
    setModalError(null);
    try {
      await api.post("/users", data);
      setIsModalOpen(false);
      reset();
      showSuccess("New sales person added successfully!");
      fetchTeam();
    } catch (e) {
      setModalError(e.response?.data?.message || "Error adding user. Email might already exist.");
    }
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    if (!editData.name.trim()) {
      setEditModalError("Name is required");
      return;
    }
    setEditModalError(null);
    try {
      await api.put(`/users/${editData.id}`, { name: editData.name });
      setIsEditModalOpen(false);
      showSuccess("User name updated successfully!");
      fetchTeam();
    } catch (error) {
      setEditModalError(error.response?.data?.message || "Failed to update user.");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to remove this user?")) return;
    setApiError(null); setApiSuccess(null);
    try {
      await api.delete(`/users/${id}`);
      showSuccess("User removed successfully.");
      fetchTeam();
    } catch (error) {
      setApiError(error.response?.data?.message || "Failed to remove user.");
    }
  };

  const handleCloseModal = () => { setIsModalOpen(false); setModalError(null); reset(); };

  if (pageLoading) return <Layout><div className="flex justify-center items-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" /></div></Layout>;

  // Plan-based gating
  const maxUsers = PLAN_LIMITS[plan]?.maxUsers ?? 1;
  const usagePct = maxUsers === Infinity ? 0 : Math.min(100, (team.length / maxUsers) * 100);
  const isAtLimit = maxUsers !== Infinity && team.length >= maxUsers;

  return (
    <Layout>
      <div className="max-w-6xl mx-auto pb-10">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
              <Users className="h-6 w-6 text-blue-600" /> Team & Signatures
            </h2>
            <p className="text-sm text-gray-500 mt-1">Manage your staff and digital signatures</p>
          </div>
          {user?.role === 'admin' && (
            <button
              onClick={() => setIsModalOpen(true)}
              disabled={isAtLimit}
              className={`px-5 py-2.5 rounded-lg font-bold flex items-center gap-2 transition shadow-sm text-sm ${
                isAtLimit
                  ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                  : 'bg-blue-600 hover:bg-blue-700 text-white'
              }`}
            >
              <Plus className="w-5 h-5" /> Add Sales Person
            </button>
          )}
        </div>

        {plan !== "enterprise" && (
          <div className="bg-white border border-gray-200 rounded-xl p-4 mb-6">
            <div className="flex justify-between text-sm mb-2">
              <span className="font-semibold text-gray-700">Team Slots Used</span>
              <span className={`font-bold ${usagePct >= 100 ? 'text-red-600' : 'text-gray-600'}`}>
                {team.length} / {maxUsers}
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className={`h-2 rounded-full transition-all ${usagePct >= 100 ? 'bg-red-500' : usagePct >= 80 ? 'bg-amber-500' : 'bg-blue-500'}`}
                style={{ width: `${usagePct}%` }}
              />
            </div>
            {isAtLimit && (
              <p className="text-xs text-red-600 mt-2 flex items-center gap-1">
                <AlertCircle className="h-3 w-3" /> Team limit reached. <Link to="/settings" className="underline font-bold">Upgrade to {plan === 'basic' ? 'Pro' : 'Business'}</Link> for more members.
              </p>
            )}
          </div>
        )}

        {/* Success Banner */}
        {apiSuccess && (
          <div className="mb-6 bg-emerald-50 border-l-4 border-emerald-500 p-4 rounded-md flex items-start gap-3 shadow-sm">
            <CheckCircle className="h-5 w-5 text-emerald-500 mt-0.5" />
            <div>
              <h3 className="text-sm font-bold text-emerald-800">Success</h3>
              <p className="text-sm text-emerald-700 mt-1">{apiSuccess}</p>
            </div>
          </div>
        )}

        {/* Error Banner */}
        {apiError && (
          <div className="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-md flex items-start gap-3 shadow-sm">
            <AlertCircle className="h-5 w-5 text-red-500 mt-0.5" />
            <div>
              <h3 className="text-sm font-bold text-red-800">Error</h3>
              <p className="text-sm text-red-700 mt-1">{apiError}</p>
            </div>
          </div>
        )}

        {/* Team Table */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <table className="w-full text-left">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="p-4 px-6 text-xs font-bold uppercase tracking-wider text-gray-500">Name</th>
                <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500">Role</th>
                <th className="p-4 text-xs font-bold uppercase tracking-wider text-gray-500">Signature Status</th>
                <th className="p-4 px-6 text-xs font-bold uppercase tracking-wider text-gray-500 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {team.map((member) => (
                <tr key={member._id} className="hover:bg-gray-50 transition">
                  <td className="p-4 px-6 font-bold text-gray-900">
                    {member.name}<br />
                    <span className="text-xs text-gray-500 font-medium">{member.email}</span>
                  </td>
                  <td className="p-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase ${member.role === 'admin' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'}`}>
                      {member.role}
                    </span>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-4">
                      {member.signatureImage ? (
                        <div className="flex flex-col items-start gap-1">
                          <span className="text-emerald-600 text-xs font-bold flex items-center gap-1"><CheckCircle className="w-3.5 h-3.5" /> Uploaded</span>
                          <img src={member.signatureImage} className="h-10 border border-gray-200 rounded bg-white object-contain p-1 shadow-sm" alt="sig" />
                        </div>
                      ) : (
                        <span className="text-rose-500 text-xs font-bold flex items-center gap-1"><AlertCircle className="w-3.5 h-3.5" /> No Signature</span>
                      )}
                      <label className={`cursor-pointer flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded border transition ${uploadingId === member._id ? 'bg-gray-100 text-gray-400 cursor-not-allowed' : 'bg-white hover:bg-gray-50 text-gray-700 border-gray-300 shadow-sm'}`}>
                        {uploadingId === member._id ? (
                          <><RefreshCw className="w-3.5 h-3.5 animate-spin" /> Uploading</>
                        ) : (
                          <>{member.signatureImage ? <RefreshCw className="w-3.5 h-3.5" /> : <Upload className="w-3.5 h-3.5" />} {member.signatureImage ? "Change" : "Upload"}</>
                        )}
                        <input type="file" className="hidden" accept="image/*" onChange={(e) => handleSignatureUpload(e, member._id)} disabled={uploadingId === member._id} />
                      </label>
                    </div>
                  </td>
                  <td className="p-4 px-6 text-right">
                    <div className="flex justify-end items-center gap-1">
                      {user?.role === 'admin' && (
                        <button 
                          onClick={() => {
                            setEditData({ id: member._id, name: member.name });
                            setIsEditModalOpen(true);
                          }} 
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" 
                          title="Edit User Name"
                        >
                          <Edit2 className="w-5 h-5" />
                        </button>
                      )}
                      {member._id !== user._id ? (
                        <button onClick={() => handleDelete(member._id)} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Remove User">
                          <Trash2 className="w-5 h-5" />
                        </button>
                      ) : (
                        <span className="text-xs text-gray-400 font-medium italic pr-2">It's You</span>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Add User Modal */}
        {isModalOpen && (
          <div className="fixed inset-0 bg-gray-900 bg-opacity-60 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white p-8 rounded-2xl shadow-2xl w-full max-w-md">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-xl font-bold text-gray-800">Add New User</h3>
                <button onClick={handleCloseModal} className="text-gray-400 hover:text-gray-600 text-2xl leading-none">&times;</button>
              </div>
              {modalError && (
                <div className="mb-4 bg-red-50 text-red-600 text-sm p-3 rounded border border-red-200 flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" /> {modalError}
                </div>
              )}
              <form noValidate onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-1">Full Name</label>
                  <input {...register("name", { required: "Name is required" })} placeholder="e.g. Rahul Sharma"
                    className={`w-full border p-2.5 rounded-lg outline-none transition ${errors.name ? 'border-red-400 focus:ring-2 focus:ring-red-400' : 'bg-gray-50 focus:ring-2 focus:ring-blue-500'}`} />
                  {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name.message}</p>}
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-1">Email Address</label>
                  <input {...register("email", { required: "Email is required", pattern: { value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i, message: "Invalid email address" } })}
                    placeholder="rahul@company.com"
                    className={`w-full border p-2.5 rounded-lg outline-none transition ${errors.email ? 'border-red-400 focus:ring-2 focus:ring-red-400' : 'bg-gray-50 focus:ring-2 focus:ring-blue-500'}`} />
                  {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-1">Password</label>
                  <input {...register("password", { required: "Password is required", minLength: { value: 6, message: "Password must be at least 6 characters" } })}
                    type="password" placeholder="••••••••"
                    className={`w-full border p-2.5 rounded-lg outline-none transition ${errors.password ? 'border-red-400 focus:ring-2 focus:ring-red-400' : 'bg-gray-50 focus:ring-2 focus:ring-blue-500'}`} />
                  {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
                </div>
                <div className="pt-4 flex gap-3">
                  <button type="button" onClick={handleCloseModal} className="w-1/2 py-2.5 text-gray-600 font-bold bg-gray-100 hover:bg-gray-200 rounded-lg transition">Cancel</button>
                  <button type="submit" className="w-1/2 bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 rounded-lg transition shadow-md">Create User</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Edit User Modal */}
        {isEditModalOpen && (
          <div className="fixed inset-0 bg-gray-900 bg-opacity-60 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white p-8 rounded-2xl shadow-2xl w-full max-w-md">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-xl font-bold text-gray-800">Edit User Name</h3>
                <button onClick={() => setIsEditModalOpen(false)} className="text-gray-400 hover:text-gray-600 text-2xl leading-none">&times;</button>
              </div>
              {editModalError && (
                <div className="mb-4 bg-red-50 text-red-600 text-sm p-3 rounded border border-red-200 flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" /> {editModalError}
                </div>
              )}
              <form onSubmit={handleEditSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-gray-600 mb-1">Full Name</label>
                  <input 
                    value={editData.name}
                    onChange={(e) => setEditData({...editData, name: e.target.value})}
                    placeholder="e.g. Rahul Sharma"
                    autoFocus
                    className="w-full border bg-gray-50 p-2.5 rounded-lg outline-none transition focus:ring-2 focus:ring-blue-500" 
                  />
                </div>
                <div className="pt-4 flex gap-3">
                  <button type="button" onClick={() => setIsEditModalOpen(false)} className="w-1/2 py-2.5 text-gray-600 font-bold bg-gray-100 hover:bg-gray-200 rounded-lg transition">Cancel</button>
                  <button type="submit" className="w-1/2 bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 rounded-lg transition shadow-md">Save Changes</button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default Team;