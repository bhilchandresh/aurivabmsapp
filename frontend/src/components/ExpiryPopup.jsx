import { useState, useEffect, useContext } from 'react';
import { AlertCircle, Calendar, ShieldCheck, X, ArrowRight } from 'lucide-react';
import api from '../utils/api';
import { AuthContext } from '../context/AuthContext';
import toast from 'react-hot-toast';

const ExpiryPopup = () => {
  const { user, logout } = useContext(AuthContext);
  const [show, setShow] = useState(false);
  const [subscription, setSubscription] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Check localStorage for subscription data stored during login
    const subData = localStorage.getItem('subscription');
    if (subData) {
      const parsed = JSON.parse(subData);
      setSubscription(parsed);
      if (parsed.expiryWarning) {
        setShow(true);
      }
    }
  }, []);

  const handleRenew = async () => {
    setLoading(true);
    try {
      // 1. Create order on backend
      const res = await api.post('/payments/create-order', { 
        plan: subscription.plan || 'basic' 
      });

      if (!res.data.success) throw new Error(res.data.message);

      const order = res.data.data;

      // 2. Open Razorpay Checkout
      const options = {
        key: import.meta.env.VITE_RAZORPAY_KEY_ID || 'rzp_test_YOUR_KEY_HERE', // User should update this
        amount: order.amount,
        currency: order.currency,
        name: "Auriva BMS",
        description: `Renewal for ${subscription.plan} plan`,
        order_id: order.id,
        handler: async (response) => {
          // 3. Verify payment on backend
          try {
            const verifyRes = await api.post('/payments/verify', {
              ...response,
              plan: subscription.plan
            });

            if (verifyRes.data.success) {
              toast.success("Subscription Renewed Successfully!");
              setShow(false);
              // Update local state if needed or just suggest logout/login
              localStorage.removeItem('subscription'); // Force re-fetch on next login
              setTimeout(() => window.location.reload(), 2000);
            }
          } catch (err) {
            toast.error("Verification failed. Contact support.");
          }
        },
        prefill: {
          name: user.name,
          email: user.email,
        },
        theme: {
          color: "#2563eb",
        },
      };

      const rzp1 = new window.Razorpay(options);
      rzp1.open();

    } catch (error) {
      console.error("Renewal Error:", error);
      toast.error(error.response?.data?.message || "Failed to initiate payment");
    } finally {
      setLoading(false);
    }
  };

  if (!show || !subscription) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in duration-300">
      <div className="bg-white rounded-[2rem] shadow-2xl w-full max-w-lg overflow-hidden animate-in zoom-in slide-in-from-bottom-4 duration-500">
        <div className="bg-gradient-to-br from-amber-500 to-orange-600 p-8 text-white relative">
          <button 
            onClick={() => setShow(false)}
            className="absolute top-4 right-4 p-2 hover:bg-white/20 rounded-full transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
          
          <div className="flex items-center gap-4 mb-4">
            <div className="bg-white/20 p-3 rounded-2xl backdrop-blur-md">
              <AlertCircle className="w-8 h-8 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-black tracking-tight">Plan Expiring Soon!</h2>
              <p className="text-amber-100 font-medium">Action Required Immediately</p>
            </div>
          </div>
        </div>

        <div className="p-8 space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-gray-50 p-4 rounded-2xl border border-gray-100">
              <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Days Remaining</p>
              <p className="text-2xl font-black text-orange-600">{subscription.daysLeft} Days</p>
            </div>
            <div className="bg-gray-50 p-4 rounded-2xl border border-gray-100">
              <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Current Plan</p>
              <p className="text-2xl font-black text-gray-800 capitalize">{subscription.plan}</p>
            </div>
          </div>

          <div className="bg-blue-50 p-6 rounded-2xl border border-blue-100 flex gap-4">
            <div className="bg-blue-100 p-2 rounded-lg h-fit">
              <ShieldCheck className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <p className="text-sm font-bold text-blue-900 mb-1">Stay Uninterrupted</p>
              <p className="text-xs text-blue-700 leading-relaxed">Renew your annual subscription now to continue managing your invoices, inventory, and clients without any service break.</p>
            </div>
          </div>

          <div className="flex flex-col gap-3">
            <button 
              onClick={handleRenew}
              disabled={loading}
              className="w-full py-4 bg-gray-900 text-white rounded-2xl font-extrabold flex items-center justify-center gap-2 hover:bg-black transition-all shadow-xl shadow-gray-200 disabled:opacity-50"
            >
              {loading ? "Processing..." : "Renew Subscription Now"}
              {!loading && <ArrowRight className="w-5 h-5" />}
            </button>
            <button 
              onClick={() => setShow(false)}
              className="w-full py-3 text-sm font-bold text-gray-400 hover:text-gray-600 transition-colors"
            >
              Remind Me Later
            </button>
          </div>
          
          <p className="text-[10px] text-center text-gray-400 font-medium uppercase tracking-widest">
            Secure Payment Powered by Razorpay
          </p>
        </div>
      </div>
    </div>
  );
};

export default ExpiryPopup;
