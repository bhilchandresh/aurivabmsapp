import React from 'react';
import { AlertCircle, X } from 'lucide-react';

const ConfirmModal = ({ 
  isOpen, 
  onClose, 
  onConfirm, 
  title = "Confirm Action", 
  message = "Are you sure you want to proceed?", 
  confirmText = "Confirm",
  cancelText = "Cancel",
  type = "info" // 'info', 'danger', 'success'
}) => {
  if (!isOpen) return null;

  const typeConfig = {
    info: {
      bg: "bg-blue-50",
      iconColor: "text-blue-500",
      buttonBg: "bg-blue-600 hover:bg-blue-700",
    },
    danger: {
      bg: "bg-red-50",
      iconColor: "text-red-500",
      buttonBg: "bg-red-600 hover:bg-red-700",
    },
    success: {
      bg: "bg-green-50",
      iconColor: "text-green-500",
      buttonBg: "bg-green-600 hover:bg-green-700",
    }
  };

  const currentType = typeConfig[type] || typeConfig.info;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-gray-900/40 backdrop-blur-sm px-4">
      <div 
        className="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-gray-100 overflow-hidden transform transition-all animate-in fade-in zoom-in duration-200"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-6">
          <div className="flex justify-between items-start mb-4">
            <div className={`p-3 rounded-full ${currentType.bg} flex-shrink-0`}>
              <AlertCircle className={`w-6 h-6 ${currentType.iconColor}`} />
            </div>
            <button 
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors bg-gray-50 hover:bg-gray-100 rounded-full p-1"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
          
          <h3 className="text-xl font-bold text-gray-900 mb-2">
            {title}
          </h3>
          <p className="text-sm text-gray-500 leading-relaxed">
            {message}
          </p>
        </div>
        
        <div className="bg-gray-50 px-6 py-4 flex flex-col-reverse sm:flex-row justify-end gap-3 rounded-b-2xl">
          <button
            onClick={onClose}
            className="w-full sm:w-auto px-5 py-2.5 text-sm font-semibold text-gray-700 bg-white border border-gray-300 rounded-xl hover:bg-gray-50 transition-all focus:outline-none focus:ring-2 focus:ring-gray-200"
          >
            {cancelText}
          </button>
          <button
            onClick={() => {
              onConfirm();
              onClose();
            }}
            className={`w-full sm:w-auto px-5 py-2.5 text-sm font-semibold text-white rounded-xl transition-all shadow-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-${currentType.iconColor.split('-')[1]}-500 ${currentType.buttonBg}`}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmModal;
