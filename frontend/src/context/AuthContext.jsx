import { createContext, useState, useEffect } from "react";
import api from "../utils/api";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem("token") || "");
  const [loading, setLoading] = useState(true);

  // --- 1. INITIAL LOAD & DEFENSIVE CHECKS ---
  useEffect(() => {
    const storedUser = localStorage.getItem("user");
    const storedToken = localStorage.getItem("token");

    if (storedToken && storedUser) {
      if (storedToken === "[object Object]" || !storedToken.startsWith("eyJ")) {
        console.error("CRITICAL: Bad token found in storage. Clearing.");
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        setToken("");
        setUser(null);
      } else {
        try {
          setToken(storedToken);
          setUser(JSON.parse(storedUser));
          
          // Fetch fresh subscription info if possible
          fetchSubscriptionInfo();
        } catch (err) {
          console.error("Failed to parse stored user, clearing storage");
          localStorage.removeItem("token");
          localStorage.removeItem("user");
          setToken("");
          setUser(null);
        }
      }
    } else {
      if (storedToken || storedUser) {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        setToken("");
        setUser(null);
      }
    }
    setLoading(false);
  }, []);

  const fetchSubscriptionInfo = async () => {
    try {
      const res = await api.get('/auth/settings');
      if (res.data.success) {
        const tenant = res.data.data;
        const currentDate = new Date();
        const expiryDate = new Date(tenant.subscriptionEnd);
        const diffTime = expiryDate - currentDate;
        const daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        
        const subInfo = {
          plan: tenant.subscriptionPlan,
          daysLeft,
          expiryWarning: daysLeft <= 5,
          expiryDate: tenant.subscriptionEnd
        };
        localStorage.setItem("subscription", JSON.stringify(subInfo));
      }
    } catch (err) {
      console.error("Failed to fetch subscription info on mount");
    }
  };

  // --- 2. GLOBAL API INTERCEPTOR FOR PLAN EXPIRY ---
  useEffect(() => {
    const interceptor = api.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response && error.response.data && error.response.data.isPlanExpired) {
          console.warn("PLAN EXPIRED: Auto-logging out...");
          localStorage.removeItem("token");
          localStorage.removeItem("user");
          setToken("");
          setUser(null);
          window.location.href = '/login?expired=true';
        }
        return Promise.reject(error);
      }
    );
    return () => api.interceptors.response.eject(interceptor);
  }, []);

  // --- 3. LOGIN HANDLER ---
  const login = (newToken, newUser, subscription = null) => {
    if (typeof newToken !== 'string') {
      console.error("LOGIN ERROR: Attempted to save non-string token:", newToken);
      alert("System Error: Invalid Token Format. Check Console.");
      return;
    }
    localStorage.setItem("token", newToken);
    localStorage.setItem("user", JSON.stringify(newUser));
    if (subscription) {
      localStorage.setItem("subscription", JSON.stringify(subscription));
    }
    setToken(newToken);
    setUser(newUser);
  };

  // --- 4. LOGOUT HANDLER ---
  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("user");
    localStorage.removeItem("subscription");
    setToken("");
    setUser(null);
    window.location.href = '/login';
  };

  // --- 5. COMPLETE TOUR HANDLER ---
  const completeUserTour = () => {
    if (user) {
      const updatedUser = { ...user, hasCompletedTour: true };
      setUser(updatedUser);
      localStorage.setItem("user", JSON.stringify(updatedUser));
    }
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, loading, completeUserTour }}>
      {children}
    </AuthContext.Provider>
  );
};
