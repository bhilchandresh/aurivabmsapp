import { useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../utils/api';
import toast from 'react-hot-toast';
import { Mail, KeyRound } from 'lucide-react';

const ForgotPassword = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email) return;

    setLoading(true);
    try {
      await api.post('/auth/forgot-password', { email });
      toast.success('Reset link sent to your email.');
      setSent(true);
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to send reset link.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100 text-blue-600 mb-4 shadow-sm">
          <KeyRound className="w-8 h-8" />
        </div>
        <h2 className="mt-2 text-center text-3xl font-extrabold text-gray-900 tracking-tight">Forgot Password?</h2>
        <p className="mt-2 text-center text-sm text-gray-600">No worries, we'll send you reset instructions.</p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow-xl shadow-gray-200/50 sm:rounded-2xl sm:px-10 border border-gray-100">
          
          {sent ? (
             <div className="text-center space-y-4">
                <div className="bg-green-50 text-green-700 p-4 rounded-xl border border-green-200 font-medium">
                  We have sent a password reset link to <strong>{email}</strong>. Please check your inbox (and spam folder).
                </div>
                <Link to="/login" className="inline-block mt-4 w-full flex justify-center py-3.5 px-4 border border-gray-300 rounded-xl shadow-sm text-sm font-extrabold text-gray-700 bg-white hover:bg-gray-50 transition">
                  Return to Login
                </Link>
             </div>
          ) : (
            <form className="space-y-6" onSubmit={handleSubmit}>
              <div>
                <label className="block text-sm font-bold text-gray-700 mb-1">Email Address</label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                    <Mail className="w-5 h-5" />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="appearance-none block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-xl placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent sm:text-sm transition bg-gray-50 hover:bg-white focus:bg-white"
                    placeholder="you@company.com"
                  />
                </div>
              </div>

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex justify-center py-3.5 px-4 border border-transparent rounded-xl shadow-lg shadow-blue-500/30 text-sm font-extrabold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition transform hover:-translate-y-0.5 disabled:opacity-70 disabled:hover:translate-y-0"
                >
                  {loading ? 'Sending...' : 'Send Reset Link'}
                </button>
              </div>
            </form>
          )}

          {!sent && (
             <div className="mt-6 text-center">
               <Link to="/login" className="font-bold text-blue-600 hover:text-blue-500 text-sm">Back to Login</Link>
             </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
