import React, { useState, useEffect, useContext } from 'react';
import axios from 'axios';
import toast from 'react-hot-toast';
import { AuthContext } from '../../context/AuthContext';
import Layout from '../../components/Layout';
import { CheckCircle, Clock } from 'lucide-react';

const MessagesList = () => {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const { token } = useContext(AuthContext);

  useEffect(() => {
    fetchMessages();
  }, []);

  const fetchMessages = async () => {
    try {
      const res = await axios.get(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/messages`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setMessages(res.data.data);
    } catch (error) {
      toast.error('Failed to fetch messages');
    } finally {
      setLoading(false);
    }
  };

  const updateStatus = async (id, status) => {
    try {
      await axios.put(`${import.meta.env.VITE_API_URL}/api/v1/superadmin/messages/${id}`, { status }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      toast.success(`Message marked as ${status}`);
      setMessages(messages.map(m => m._id === id ? { ...m, status } : m));
    } catch (error) {
      toast.error('Failed to update message status');
    }
  };

  return (
    <Layout>
      <div className="p-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">Contact Messages (Leads)</h1>

        {loading ? (
          <div>Loading...</div>
        ) : (
          <div className="grid gap-4">
            {messages.map(msg => (
              <div key={msg._id} className={`bg-white p-5 rounded-xl shadow-sm border ${msg.status === 'unread' ? 'border-blue-200' : 'border-gray-100'} transition-all`}>
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <h3 className="font-bold text-gray-800 text-lg">{msg.subject}</h3>
                    <div className="text-sm text-gray-500 flex items-center gap-2 mt-1">
                      <span className="font-medium text-gray-700">{msg.name}</span>
                      <span>•</span>
                      <a href={`mailto:${msg.email}`} className="text-blue-600 hover:underline">{msg.email}</a>
                      <span>•</span>
                      <span>{new Date(msg.createdAt).toLocaleString()}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {msg.status === 'unread' && (
                      <span className="bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-xs font-medium">New</span>
                    )}
                    {msg.status === 'read' && (
                      <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-xs font-medium">Read</span>
                    )}
                    {msg.status === 'resolved' && (
                      <span className="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs font-medium flex items-center gap-1">
                        <CheckCircle size={14} /> Resolved
                      </span>
                    )}
                  </div>
                </div>
                
                <p className="text-gray-700 whitespace-pre-wrap bg-gray-50 p-4 rounded-lg border border-gray-100 mt-3">{msg.message}</p>

                <div className="flex gap-3 mt-4">
                  {msg.status !== 'resolved' && (
                    <button 
                      onClick={() => updateStatus(msg._id, 'resolved')}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-green-50 text-green-700 hover:bg-green-100 rounded-md transition-colors"
                    >
                      <CheckCircle size={16} /> Mark Resolved
                    </button>
                  )}
                  {msg.status === 'unread' && (
                    <button 
                      onClick={() => updateStatus(msg._id, 'read')}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-gray-50 text-gray-700 hover:bg-gray-200 rounded-md transition-colors border border-gray-200"
                    >
                      <Clock size={16} /> Mark Read
                    </button>
                  )}
                </div>
              </div>
            ))}
            
            {messages.length === 0 && (
              <div className="text-center text-gray-500 py-10 bg-white rounded-xl border border-gray-100">
                No contact messages found.
              </div>
            )}
          </div>
        )}
      </div>
    </Layout>
  );
};

export default MessagesList;
