import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'
import { BrowserRouter } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import axios from 'axios'

// 1. Set Base URL (Optional but good practice)
// axios.defaults.baseURL = 'http://localhost:5001/api/v1'; 

// 2. REQUEST INTERCEPTOR (Attaches Token)
axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    
    // CRITICAL FIX: Only attach if token is a valid string
    if (token && typeof token === 'string' && token !== '[object Object]') {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 3. RESPONSE INTERCEPTOR (Handles 401 Logout)
axios.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear bad data and redirect
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      if (window.location.pathname !== '/login') {
          window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
      </AuthProvider>
    </BrowserRouter>
  </React.StrictMode>,
)