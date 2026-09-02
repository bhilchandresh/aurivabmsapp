import { useState, useContext, useEffect } from "react";
import { AuthContext } from "../context/AuthContext";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import {
  Mail, Lock, Eye, EyeOff, Loader2, Hexagon, ArrowRight, AlertCircle
} from "lucide-react";
import toast from "react-hot-toast";
import api from "../utils/api";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [expiryMessage, setExpiryMessage] = useState("");
  const [loading, setLoading] = useState(false);

  const { login } = useContext(AuthContext);
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  useEffect(() => {
    if (searchParams.get("expired") === "true") {
      setExpiryMessage("Your subscription plan has expired. Please contact support to renew your plan.");
    }
  }, [searchParams]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setExpiryMessage("");
    setLoading(true);

    try {
      const res = await api.post("/auth/login", { email, password });
      login(res.data.token, res.data.user, res.data.subscription);
      toast.success(`Welcome back, ${res.data.user.name.split(' ')[0]}!`);

      if (res.data.user.role === 'super_admin') {
        navigate("/super-admin");
      } else {
        navigate("/");
      }
    } catch (err) {
      if (err.response?.data?.isPlanExpired) {
        setExpiryMessage("Subscription Expired");
        toast.error("Access denied: Plan Expired.");
      } else {
        const msg = err.response?.data?.message || "Login failed";
        setError(msg);
        toast.error(msg);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-blue-900 p-4 font-sans">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden relative">
        <div className="h-1.5 bg-gradient-to-r from-blue-500 to-purple-600 w-full"></div>
        <div className="p-8 md:p-10">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-blue-50 text-blue-600 mb-4 shadow-sm">
              <Hexagon className="w-8 h-8" strokeWidth={2.5} />
            </div>
            <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Auriva<span className="text-blue-600">BMS</span></h1>
            <p className="text-sm text-gray-500 mt-2 font-medium">Business Management System</p>
          </div>

          {expiryMessage && (
            <div className="mb-6 bg-red-50 border-l-4 border-red-500 p-4 rounded-md flex items-start gap-3 shadow-sm animate-fade-in">
              <AlertCircle className="h-5 w-5 text-red-500 mt-0.5 shrink-0" />
              <div>
                <h3 className="text-sm font-bold text-red-800">Plan Expired</h3>
                <p className="text-sm text-red-700 mt-1 leading-snug">{expiryMessage}</p>
              </div>
            </div>
          )}

          {error && !expiryMessage && (
            <div className="mb-6 bg-red-50 border-l-4 border-red-500 text-red-700 p-3 text-sm rounded flex items-center animate-pulse">
              <span className="font-bold mr-1">Error:</span> {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1 ml-1 select-none">Work Email</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="h-5 w-5 text-gray-400 group-focus-within:text-blue-500 transition-colors" />
                </div>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-xl leading-5 bg-gray-50 placeholder-gray-400 focus:outline-none focus:bg-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all sm:text-sm font-medium text-gray-900"
                  placeholder="name@company.com"
                />
              </div>
            </div>

            <div>
              <div className="flex justify-between items-center mb-1 ml-1">
                <label className="block text-xs font-bold text-gray-500 uppercase select-none">Password</label>
              </div>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-blue-500 transition-colors" />
                </div>
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="block w-full pl-10 pr-10 py-3 border border-gray-300 rounded-xl leading-5 bg-gray-50 placeholder-gray-400 focus:outline-none focus:bg-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all sm:text-sm font-medium text-gray-900"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center cursor-pointer text-gray-400 hover:text-blue-600 focus:outline-none transition-colors select-none"
                >
                  {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center items-center gap-2 py-3 px-4 border border-transparent rounded-xl shadow-lg text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all transform hover:-translate-y-0.5 disabled:opacity-70 disabled:cursor-not-allowed select-none"
            >
              {loading ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  <span>Signing In...</span>
                </>
              ) : (
                <>
                  <span>Sign In to Dashboard</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          <div className="mt-8 text-center border-t pt-6 select-none">
            <div className="flex justify-center space-x-4 mb-4 text-xs text-gray-500 font-medium">
              <Link to="/contact" className="hover:text-blue-600 transition-colors">Contact Us</Link>
              <Link to="/terms" className="hover:text-blue-600 transition-colors">Terms of Service</Link>
              <Link to="/privacy" className="hover:text-blue-600 transition-colors">Privacy Policy</Link>
            </div>
            <p className="text-xs text-gray-400">
              Protected by Enterprise Security. <br />
              © {new Date().getFullYear()} Auriva Solutions.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;