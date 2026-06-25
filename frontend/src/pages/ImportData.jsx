import React, { useState } from 'react';
import Papa from 'papaparse';
import { Upload, Download, CheckCircle, AlertCircle, FileText, Package, Users, ChevronRight } from 'lucide-react';
import api from '../utils/api';
import { toast } from 'react-hot-toast';

import Layout from '../components/Layout';

const ImportData = () => {
  const [activeTab, setActiveTab] = useState('clients');
  const [file, setFile] = useState(null);
  const [parsedData, setParsedData] = useState([]);
  const [isParsing, setIsParsing] = useState(false);
  const [isImporting, setIsImporting] = useState(false);

  const templates = {
    clients: {
      headers: ['name', 'email', 'phone', 'address', 'gstin', 'state'],
      sample: [['Acme Corp', 'contact@acme.com', '9876543210', '123 Business Rd', '22ABCDE1234F1Z5', 'Maharashtra']]
    },
    inventory: {
      headers: ['itemName', 'sku', 'description', 'unitPrice', 'currentStock', 'status'],
      sample: [['Premium Widget', 'WID-001', 'High quality widget', '499.00', '50', 'In Stock']]
    },
    invoices: {
      headers: ['invoiceNumber', 'date', 'clientName', 'clientEmail', 'clientPhone', 'status', 'advancePayment', 'discountPercentage', 'itemName', 'quantity', 'rate'],
      sample: [['INV-0001', '2023-10-15', 'Acme Corp', 'contact@acme.com', '9876543210', 'Paid', '0', '10', 'Premium Widget', '2', '499.00']]
    }
  };

  const handleDownloadTemplate = () => {
    const template = templates[activeTab];
    const csvContent = Papa.unparse({
      fields: template.headers,
      data: template.sample
    });

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `${activeTab}_template.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleFileUpload = (e) => {
    const uploadedFile = e.target.files[0];
    if (!uploadedFile) return;

    setFile(uploadedFile);
    setIsParsing(true);

    Papa.parse(uploadedFile, {
      header: true,
      skipEmptyLines: true,
      complete: function(results) {
        setParsedData(results.data);
        setIsParsing(false);
      },
      error: function(error) {
        toast.error("Error parsing CSV: " + error.message);
        setIsParsing(false);
      }
    });
  };

  const handleImport = async () => {
    if (parsedData.length === 0) return toast.error("No data found to import");

    setIsImporting(true);
    let payload = parsedData;

    try {
      // Special transformation for invoices (grouping rows by invoiceNumber)
      if (activeTab === 'invoices') {
        const invoiceMap = {};
        parsedData.forEach(row => {
          const invNum = row.invoiceNumber || 'NEW';
          if (!invoiceMap[invNum]) {
            invoiceMap[invNum] = {
              invoiceNumber: row.invoiceNumber,
              date: row.date,
              clientName: row.clientName,
              clientEmail: row.clientEmail,
              clientPhone: row.clientPhone,
              status: row.status,
              advancePayment: row.advancePayment,
              discountPercentage: row.discountPercentage,
              items: []
            };
          }
          if (row.itemName) {
            invoiceMap[invNum].items.push({
              description: row.itemName,
              quantity: row.quantity || 1,
              rate: row.rate || 0
            });
          }
        });
        payload = Object.values(invoiceMap);
      }

      const response = await api.post(`/${activeTab}/bulk`, payload);
      if (response.data.success) {
        toast.success(response.data.message);
        setFile(null);
        setParsedData([]);
      } else {
        toast.error(response.data.message);
      }
    } catch (error) {
      toast.error(error.response?.data?.message || "Import failed");
    } finally {
      setIsImporting(false);
    }
  };

  return (
    <Layout>
      <div className="max-w-5xl mx-auto space-y-6 pb-10 p-4">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-black text-gray-900 tracking-tight">Import Legacy Data</h1>
            <p className="text-gray-500 font-medium text-sm mt-1">Migrate your existing clients, inventory, and old invoices.</p>
          </div>
        </div>

        <div className="bg-white rounded-3xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="flex border-b border-gray-100 bg-gray-50">
            <button 
              onClick={() => {setActiveTab('clients'); setFile(null); setParsedData([]);}}
              className={`flex-1 flex items-center justify-center gap-2 py-4 font-black text-sm transition-colors ${activeTab === 'clients' ? 'bg-white text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-100 hover:text-gray-900'}`}
            >
              <Users size={18} /> Clients
            </button>
            <button 
              onClick={() => {setActiveTab('inventory'); setFile(null); setParsedData([]);}}
              className={`flex-1 flex items-center justify-center gap-2 py-4 font-black text-sm transition-colors ${activeTab === 'inventory' ? 'bg-white text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-100 hover:text-gray-900'}`}
            >
              <Package size={18} /> Inventory
            </button>
            <button 
              onClick={() => {setActiveTab('invoices'); setFile(null); setParsedData([]);}}
              className={`flex-1 flex items-center justify-center gap-2 py-4 font-black text-sm transition-colors ${activeTab === 'invoices' ? 'bg-white text-blue-600 border-b-2 border-blue-600' : 'text-gray-500 hover:bg-gray-100 hover:text-gray-900'}`}
            >
              <FileText size={18} /> Invoices
            </button>
          </div>

          <div className="p-8 flex flex-col md:flex-row gap-8">
            {/* Step 1: Download */}
            <div className="flex-1 bg-blue-50/50 p-6 rounded-2xl border border-blue-100 flex flex-col items-center justify-center text-center space-y-4">
              <div className="bg-white p-3 rounded-2xl shadow-sm text-blue-600">
                <Download size={24} />
              </div>
              <div>
                <h3 className="font-black text-gray-900">1. Download Template</h3>
                <p className="text-xs font-medium text-gray-500 mt-1">Download the required CSV format.</p>
              </div>
              <button 
                onClick={handleDownloadTemplate}
                className="px-5 py-2.5 bg-white border border-gray-200 shadow-sm rounded-xl text-sm font-bold hover:bg-gray-50 hover:-translate-y-0.5 transition-all"
              >
                Download CSV Template
              </button>
            </div>

            <div className="hidden md:flex items-center text-gray-200">
              <ChevronRight size={32} />
            </div>

            {/* Step 2: Upload */}
            <div className="flex-1 bg-emerald-50/50 p-6 rounded-2xl border border-emerald-100 flex flex-col items-center justify-center text-center space-y-4">
              <div className="bg-white p-3 rounded-2xl shadow-sm text-emerald-600">
                <Upload size={24} />
              </div>
              <div>
                <h3 className="font-black text-gray-900">2. Upload Filled CSV</h3>
                <p className="text-xs font-medium text-gray-500 mt-1">Upload the populated template.</p>
              </div>
              <label className="cursor-pointer px-5 py-2.5 bg-white border border-gray-200 shadow-sm rounded-xl text-sm font-bold hover:bg-gray-50 hover:-translate-y-0.5 transition-all">
                <span>{file ? file.name : "Select CSV File"}</span>
                <input type="file" accept=".csv" className="hidden" onChange={handleFileUpload} />
              </label>
            </div>
          </div>

          {/* Preview Section */}
          {parsedData.length > 0 && (
            <div className="border-t border-gray-100">
              <div className="p-5 bg-gray-50 flex flex-col sm:flex-row justify-between items-center gap-4">
                <div className="flex items-center gap-2">
                  <CheckCircle size={18} className="text-emerald-600" />
                  <span className="font-bold text-sm text-gray-900">Parsed {parsedData.length} rows ready for import</span>
                </div>
                <button 
                  onClick={handleImport}
                  disabled={isImporting}
                  className="px-8 py-2.5 bg-blue-600 text-white rounded-xl text-sm font-black shadow-lg shadow-blue-200 hover:bg-blue-700 transition disabled:opacity-50"
                >
                  {isImporting ? "Importing..." : "Start Import"}
                </button>
              </div>
              <div className="overflow-x-auto max-h-[400px]">
                <table className="w-full text-left border-collapse">
                  <thead className="bg-white sticky top-0 text-[10px] uppercase font-black tracking-widest text-gray-400 border-b border-gray-100">
                    <tr>
                      {Object.keys(parsedData[0]).map((key, i) => (
                        <th key={i} className="py-3 px-6 whitespace-nowrap">{key}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="text-sm divide-y divide-gray-50">
                    {parsedData.slice(0, 50).map((row, i) => (
                      <tr key={i} className="hover:bg-gray-50/50">
                        {Object.values(row).map((val, j) => (
                          <td key={j} className="py-3 px-6 whitespace-nowrap text-gray-600 font-medium">{val || '-'}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
                {parsedData.length > 50 && (
                  <div className="p-4 text-center text-sm font-bold text-gray-400 bg-gray-50">
                    Showing first 50 rows...
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
};

export default ImportData;
