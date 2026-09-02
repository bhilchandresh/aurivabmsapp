import { useState, useContext } from 'react';
import { Bell, Info, AlertTriangle, CheckCircle2, X } from 'lucide-react';
import { AuthContext } from '../context/AuthContext';
import { NotificationContext } from '../context/NotificationContext';

const NotificationBell = () => {
  const [isOpen, setIsOpen] = useState(false);
  const { user } = useContext(AuthContext);
  const { notifications, unreadCount, markAsRead } = useContext(NotificationContext);

  const getIcon = (type) => {
    switch (type) {
      case 'warning': return <AlertTriangle className="w-4 h-4 text-amber-500" />;
      case 'success': return <CheckCircle2 className="w-4 h-4 text-emerald-500" />;
      case 'error': return <X className="w-4 h-4 text-rose-500" />;
      default: return <Info className="w-4 h-4 text-blue-500" />;
    }
  };

  return (
    <div className="relative">
      <button 
        onClick={() => setIsOpen(!isOpen)}
        className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors relative"
      >
        <Bell className="w-6 h-6" />
        {unreadCount > 0 && (
          <span className="absolute top-1.5 right-1.5 bg-rose-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full border-2 border-white">
            {unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <>
          <div className="fixed inset-0 z-40 bg-gray-900/10 sm:bg-transparent" onClick={() => setIsOpen(false)}></div>
          <div className="fixed sm:absolute left-4 right-4 top-16 sm:left-auto sm:right-0 sm:top-auto sm:mt-2 sm:w-[22rem] bg-white rounded-xl shadow-2xl border border-gray-100 z-50 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200 flex flex-col max-h-[80vh] sm:max-h-[500px]">
            <div className="p-4 border-b bg-gray-50 flex justify-between items-center shrink-0">
              <h3 className="font-bold text-gray-900 text-sm uppercase tracking-wide">Notifications</h3>
              <span className="text-xs font-bold text-blue-600 bg-blue-50 px-2 py-1 rounded-md">{unreadCount} Unread</span>
            </div>
            
            <div className="overflow-y-auto overflow-x-hidden flex-1 scrollbar-hide">
              {notifications.length === 0 ? (
                <div className="p-10 text-center text-gray-400">
                  <Bell className="w-10 h-10 mx-auto mb-3 opacity-20" />
                  <p className="text-sm font-medium">No notifications yet</p>
                </div>
              ) : (
                notifications.map((notif) => (
                  <div 
                    key={notif._id}
                    className={`p-4 border-b last:border-0 transition-colors cursor-pointer ${!notif.isRead ? 'bg-blue-50/50' : 'hover:bg-gray-50'}`}
                    onClick={() => {
                      if (!notif.isRead) markAsRead(notif._id);
                    }}
                  >
                    <div className="flex gap-3">
                      <div className="mt-0.5 shrink-0">{getIcon(notif.type)}</div>
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm leading-snug break-words ${!notif.isRead ? 'font-bold text-gray-900' : 'font-medium text-gray-600'}`}>
                          {notif.message}
                        </p>
                        <p className="text-[10px] font-bold text-gray-400 mt-1.5 uppercase tracking-wider">
                          {new Date(notif.createdAt).toLocaleString()}
                        </p>
                        {notif.actionLink && (
                          <a 
                            href={notif.actionLink}
                            className="inline-block mt-2 text-xs font-bold text-blue-600 hover:text-blue-800 hover:underline"
                            onClick={(e) => e.stopPropagation()}
                          >
                            View Details
                          </a>
                        )}
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default NotificationBell;
