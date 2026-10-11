import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { AuthContext } from '../../context/AuthContext';
import Layout from '../../components/Layout';

const TransactionsList = () => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);
  const { token } = useContext(AuthContext);

  useEffect(() => {
    fetchTransactions();
  }, []);

  const fetchTransactions = async () => {
    try {
      const res = await axios.get(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/transactions`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setTransactions(res.data.data);
    } catch (error) {
      toast.error('Failed to fetch transactions');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Layout>
      <div className="p-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">Transactions (Landing Page)</h1>

        {loading ? (
          <div>Loading...</div>
        ) : (
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm">
                    <th className="p-4 font-medium">Order ID</th>
                    <th className="p-4 font-medium">Email</th>
                    <th className="p-4 font-medium">Amount</th>
                    <th className="p-4 font-medium">Plan</th>
                    <th className="p-4 font-medium">Coupon</th>
                    <th className="p-4 font-medium">Status</th>
                    <th className="p-4 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {transactions.map(txn => (
                    <tr key={txn._id} className="hover:bg-gray-50/50 transition-colors">
                      <td className="p-4 text-sm text-gray-700">{txn.razorpay_order_id}</td>
                      <td className="p-4 text-sm text-gray-700">{txn.email}</td>
                      <td className="p-4 text-sm text-gray-700 font-semibold text-green-600">₹{txn.amount}</td>
                      <td className="p-4 text-sm text-gray-700">{txn.planName} ({txn.planType})</td>
                      <td className="p-4 text-sm text-gray-700">{txn.couponCode || '-'}</td>
                      <td className="p-4 text-sm">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          txn.status === 'completed' ? 'bg-green-100 text-green-700' :
                          txn.status === 'pending' ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                        }`}>
                          {txn.status}
                        </span>
                      </td>
                      <td className="p-4 text-sm text-gray-700">{new Date(txn.createdAt).toLocaleDateString()}</td>
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

export default TransactionsList;
