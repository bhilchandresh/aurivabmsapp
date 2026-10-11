import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { AuthContext } from '../../context/AuthContext';
import Layout from '../../components/Layout';

const SubscriptionsList = () => {
  const [subscriptions, setSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const { token } = useContext(AuthContext);

  useEffect(() => {
    fetchSubscriptions();
  }, []);

  const fetchSubscriptions = async () => {
    try {
      const res = await axios.get(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/subscriptions`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setSubscriptions(res.data.data);
    } catch (error) {
      toast.error('Failed to fetch subscriptions');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout>
      <div className="p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-800">Subscriptions</h1>
        </div>

        {loading ? (
          <div>Loading...</div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm">
                    <th className="p-4 font-medium">Email</th>
                    <th className="p-4 font-medium">Plan Name</th>
                    <th className="p-4 font-medium">Type</th>
                    <th className="p-4 font-medium">Start Date</th>
                    <th className="p-4 font-medium">Expiry Date</th>
                    <th className="p-4 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {subscriptions.map(sub => (
                    <tr key={sub._id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="p-4 text-sm text-gray-700">{sub.email}</td>
                      <td className="p-4 text-sm text-gray-700">{sub.planName}</td>
                      <td className="p-4 text-sm text-gray-700">{sub.planType}</td>
                      <td className="p-4 text-sm text-gray-700">{new Date(sub.startDate).toLocaleDateString()}</td>
                      <td className="p-4 text-sm text-gray-700">{new Date(sub.expiryDate).toLocaleDateString()}</td>
                      <td className="p-4 text-sm">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${sub.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                          {sub.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
};

export default SubscriptionsList;
