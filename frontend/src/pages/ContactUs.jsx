import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import toast from 'react-hot-toast';
import api from '../api';
import { ArrowLeft, Send, Mail, User, BookOpen } from 'lucide-react';

const ContactUs = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({ name: '', email: '', subject: '', message: '' });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await api.post('/public/contact', formData);
      if (res.data.success) {
        toast.success(res.data.message);
        setFormData({ name: '', email: '', subject: '', message: '' });
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to send message');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
           <div className="bg-blue-600 p-3 rounded-xl shadow-lg">
              <Mail className="h-8 w-8 text-white" />
           </div>
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-slate-900 tracking-tight">
          Get in Touch
        </h2>
        <p className="mt-2 text-center text-sm text-slate-600">
          Have questions? We'd love to hear from you.
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-xl">
        <div className="bg-white py-8 px-4 shadow-2xl shadow-blue-900/5 sm:rounded-2xl sm:px-10 border border-slate-100 relative overflow-hidden">
          <div className="absolute top-0 right-0 -mr-8 -mt-8 w-32 h-32 rounded-full bg-blue-50 opacity-50 blur-2xl"></div>
          
          <button 
            onClick={() => navigate(-1)} 
            className="mb-6 flex items-center text-sm font-medium text-slate-500 hover:text-blue-600 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-1" /> Back
          </button>

          <form className="space-y-6 relative z-10" onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
              <div>
                <label htmlFor="name" className="block text-sm font-semibold text-slate-700">Name</label>
                <div className="mt-2 relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <User className="h-5 w-5 text-slate-400" />
                  </div>
                  <input
                    id="name"
                    name="name"
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="block w-full pl-10 pr-3 py-2.5 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-600 focus:border-transparent text-sm transition-all bg-slate-50 focus:bg-white"
                    placeholder="John Doe"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-semibold text-slate-700">Email Address</label>
                <div className="mt-2 relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-slate-400" />
                  </div>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="block w-full pl-10 pr-3 py-2.5 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-600 focus:border-transparent text-sm transition-all bg-slate-50 focus:bg-white"
                    placeholder="john@example.com"
                  />
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="subject" className="block text-sm font-semibold text-slate-700">Subject</label>
              <div className="mt-2 relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <BookOpen className="h-5 w-5 text-slate-400" />
                  </div>
                <input
                  id="subject"
                  name="subject"
                  type="text"
                  required
                  value={formData.subject}
                  onChange={(e) => setFormData({...formData, subject: e.target.value})}
                  className="block w-full pl-10 pr-3 py-2.5 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-600 focus:border-transparent text-sm transition-all bg-slate-50 focus:bg-white"
                  placeholder="How can we help?"
                />
              </div>
            </div>

            <div>
              <label htmlFor="message" className="block text-sm font-semibold text-slate-700">Message</label>
              <div className="mt-2">
                <textarea
                  id="message"
                  name="message"
                  rows={4}
                  required
                  value={formData.message}
                  onChange={(e) => setFormData({...formData, message: e.target.value})}
                  className="block w-full p-3 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-600 focus:border-transparent text-sm transition-all bg-slate-50 focus:bg-white resize-none"
                  placeholder="Write your message here..."
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center items-center py-3 px-4 border border-transparent rounded-xl shadow-md text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-70 disabled:cursor-not-allowed transition-all hover:shadow-lg hover:-translate-y-0.5"
              >
                {loading ? (
                  <span className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                ) : (
                  <>
                    Send Message <Send className="ml-2 w-4 h-4" />
                  </>
                )}
              </button>
            </div>
          </form>
          
          <div className="mt-8 pt-6 border-t border-slate-100 flex flex-col sm:flex-row justify-between items-center text-xs text-slate-500">
             <div className="flex space-x-4 mb-4 sm:mb-0">
               <Link to="/terms" className="hover:text-blue-600 transition-colors">Terms of Service</Link>
               <Link to="/privacy" className="hover:text-blue-600 transition-colors">Privacy Policy</Link>
             </div>
             <p>&copy; {new Date().getFullYear()} Auriva. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ContactUs;
