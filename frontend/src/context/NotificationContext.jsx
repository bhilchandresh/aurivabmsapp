import React, { createContext, useState, useEffect, useContext } from 'react';
import { io } from 'socket.io-client';
import api from '../utils/api';
import { AuthContext } from './AuthContext';

export const NotificationContext = createContext();

export const NotificationProvider = ({ children }) => {
  const { user } = useContext(AuthContext);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [socket, setSocket] = useState(null);

  const fetchInitialNotifications = async () => {
    try {
      const res = await api.get('/notifications');
      if (res.data.success) {
        setNotifications(res.data.data);
        setUnreadCount(res.data.data.filter(n => !n.isRead).length);
      }
    } catch (error) {
      console.error("Failed to fetch initial notifications:", error);
    }
  };

  useEffect(() => {
    if (user && user.tenantId) {
      // 1. Fetch initial list ONCE
      fetchInitialNotifications();

      // 2. Setup Socket.io connection
      const socketUrl = import.meta.env.VITE_API_URL 
        ? import.meta.env.VITE_API_URL
        : 'http://localhost:5001';

      const newSocket = io(socketUrl, {
        withCredentials: true,
      });

      setSocket(newSocket);

      newSocket.on('connect', () => {
        console.log('Connected to notification socket');
        // Join the tenant-specific room
        newSocket.emit('join_tenant', user.tenantId);
      });

      // Listen for new notifications
      newSocket.on('new_notification', (notification) => {
        setNotifications((prev) => [notification, ...prev]);
        setUnreadCount((prev) => prev + 1);
      });

      // Cleanup
      return () => {
        newSocket.disconnect();
      };
    } else {
      if (socket) {
        socket.disconnect();
      }
      setNotifications([]);
      setUnreadCount(0);
    }
  }, [user]); // Only runs when user logs in/out

  const markAsRead = async (id) => {
    try {
      await api.put(`/notifications/${id}/read`);
      setNotifications(prev => 
        prev.map(n => n._id === id ? { ...n, isRead: true } : n)
      );
      setUnreadCount(prev => Math.max(0, prev - 1));
    } catch (error) {
      console.error("Failed to mark notification as read:", error);
    }
  };

  return (
    <NotificationContext.Provider value={{ notifications, unreadCount, markAsRead }}>
      {children}
    </NotificationContext.Provider>
  );
};
