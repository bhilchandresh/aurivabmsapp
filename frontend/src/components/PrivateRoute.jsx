import { useContext } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { AuthContext } from "../context/AuthContext";
import { Loader2 } from "lucide-react"; // Icon import kar lein

const PrivateRoute = ({ children, allowedRoles }) => {
  const { user, token, loading } = useContext(AuthContext); // Context se 'loading' zaroor nikalein
  const location = useLocation();

  // 1. Loading Check: Jab tak user check ho raha hai, tab tak wait karo
  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  // 2. Auth Check: Token nahi hai to Login par bhejo
  if (!token || !user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // 3. Role Check: Agar allowedRoles pass kiya hai aur user ka role match nahi karta
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    // Agar user logged in hai par galat jagah ja raha hai -> Dashboard bhej do
    return <Navigate to="/dashboard" replace />;
  }

  // Sab sahi hai
  return children;
};

export default PrivateRoute;