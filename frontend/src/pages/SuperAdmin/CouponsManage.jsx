import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { AuthContext } from '../../context/AuthContext';
import Layout from '../../components/Layout';
import { Plus, Edit2, Trash2, X, Check } from 'lucide-react';

const CouponsManage = () => {
  const [coupons, setCoupons] = useState([]);
  const [loading, setLoading] = useState(true);
  const { token } = useContext(AuthContext);
  
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    code: '',
    discountType: 'percentage',
    discountValue: 0,
    maxUses: 0,
    expiryDate: '',
    active: true,
    isTrial: false
  });
  const [editId, setEditId] = useState(null);

  useEffect(() => {
    fetchCoupons();
  }, []);

  const fetchCoupons = async () => {
    try {
      const res = await axios.get(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/coupons`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setCoupons(res.data.data);
    } catch (error) {
      toast.error('Failed to fetch coupons');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editId) {
        await axios.put(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/coupons/${editId}`, formData, {
          headers: { Authorization: `Bearer ${token}` }
        });
        toast.success('Coupon updated successfully');
      } else {
        await axios.post(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/coupons`, formData, {
          headers: { Authorization: `Bearer ${token}` }
        });
        toast.success('Coupon created successfully');
      }
      setShowModal(false);
      fetchCoupons();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save coupon');
    }
  };

  const handleEdit = (coupon) => {
    setFormData({
      code: coupon.code,
      discountType: coupon.discountType,
      discountValue: coupon.discountValue,
      maxUses: coupon.maxUses,
      expiryDate: coupon.expiryDate ? new Date(coupon.expiryDate).toISOString().split('T')[0] : '',
      active: coupon.active,
      isTrial: coupon.isTrial
    });
    setEditId(coupon._id);
    setShowModal(true);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this coupon?')) {
      try {
        await axios.delete(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/coupons/${id}`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        toast.success('Coupon deleted successfully');
        fetchCoupons();
      } catch (error) {
        toast.error('Failed to delete coupon');
      }
    }
  };

  return (
    <Layout>
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-800">Coupons Management</h1>
          <button 
            onClick={() => {
              setEditId(null);
              setFormData({ code: '', discountType: 'percentage', discountValue: 0, maxUses: 0, expiryDate: '', active: true, isTrial: false });
              setShowModal(true);
            }}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus size={18} /> New Coupon
          </button>
        </div>

        {loading ? (
          <div>Loading...</div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm">
                    <th className="p-4 font-medium">Code</th>
                    <th className="p-4 font-medium">Discount</th>
                    <th className="p-4 font-medium">Usage</th>
                    <th className="p-4 font-medium">Expiry Date</th>
                    <th className="p-4 font-medium">Status</th>
                    <th className="p-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {coupons.map(coupon => (
                    <tr key={coupon._id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="p-4 text-sm font-semibold text-gray-800">{coupon.code} {coupon.isTrial && <span className="ml-2 text-xs bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full">Trial</span>}</td>
                      <td className="p-4 text-sm text-gray-700">
                        {coupon.discountType === 'percentage' ? `${coupon.discountValue}%` : `₹${coupon.discountValue}`}
                      </td>
                      <td className="p-4 text-sm text-gray-700">
                        {coupon.currentUses} / {coupon.maxUses === 0 ? 'Unlimited' : coupon.maxUses}
                      </td>
                      <td className="p-4 text-sm text-gray-700">
                        {coupon.expiryDate ? new Date(coupon.expiryDate).toLocaleDateString() : 'No Expiry'}
                      </td>
                      <td className="p-4 text-sm">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${coupon.active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                          {coupon.active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="p-4 text-sm text-right flex justify-end gap-3">
                        <button onClick={() => handleEdit(coupon)} className="text-blue-500 hover:text-blue-700 transition-colors">
                          <Edit2 size={16} />
                        </button>
                        <button onClick={() => handleDelete(coupon._id)} className="text-red-500 hover:text-red-700 transition-colors">
                          <Trash2 size={16} />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-gray-800">{editId ? 'Edit Coupon' : 'Create Coupon'}</h2>
                <button onClick={() => setShowModal(false)} className="text-gray-500 hover:bg-gray-100 p-2 rounded-full transition-colors">
                  <X size={20} />
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Coupon Code</label>
                  <input type="text" name="code" value={formData.code} onChange={handleInputChange} className="w-full p-2 border border-gray-300 rounded-lg uppercase" required placeholder="e.g. SUMMER20" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Discount Type</label>
                    <select name="discountType" value={formData.discountType} onChange={handleInputChange} className="w-full p-2 border border-gray-300 rounded-lg">
                      <option value="percentage">Percentage (%)</option>
                      <option value="fixed">Fixed Amount (₹)</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Discount Value</label>
                    <input type="number" name="discountValue" value={formData.discountValue} onChange={handleInputChange} className="w-full p-2 border border-gray-300 rounded-lg" required min="0" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Max Uses (0 = unlimited)</label>
                    <input type="number" name="maxUses" value={formData.maxUses} onChange={handleInputChange} className="w-full p-2 border border-gray-300 rounded-lg" min="0" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Expiry Date (Optional)</label>
                    <input type="date" name="expiryDate" value={formData.expiryDate} onChange={handleInputChange} className="w-full p-2 border border-gray-300 rounded-lg" />
                  </div>
                </div>
                
                <div className="flex items-center gap-6 pt-2">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" name="active" checked={formData.active} onChange={handleInputChange} className="w-4 h-4 text-blue-600 rounded border-gray-300" />
                    <span className="text-sm font-medium text-gray-700">Active</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" name="isTrial" checked={formData.isTrial} onChange={handleInputChange} className="w-4 h-4 text-blue-600 rounded border-gray-300" />
                    <span className="text-sm font-medium text-gray-700">Is Trial Code</span>
                  </label>
                </div>

                <div className="flex justify-end gap-3 mt-8">
                  <button type="button" onClick={() => setShowModal(false)} className="px-4 py-2 text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
                    Cancel
                  </button>
                  <button type="submit" className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors flex items-center gap-2">
                    <Check size={18} /> Save Coupon
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default CouponsManage;
