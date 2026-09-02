import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import { ArrowLeft, FileText } from 'lucide-react';

const TermsAndConditions = () => {
  const navigate = useNavigate();
  const [content, setContent] = useState('Loading...');

  useEffect(() => {
    const fetchTerms = async () => {
      try {
        const res = await api.get('/public/legal/terms_and_conditions');
        if (res.data.success) {
          setContent(res.data.data.value);
        }
      } catch (error) {
        setContent('Failed to load terms and conditions. Please try again later.');
      }
    };
    fetchTerms();
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <button 
            onClick={() => navigate(-1)} 
            className="mb-8 flex items-center text-sm font-medium text-slate-500 hover:text-blue-600 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-1" /> Back
        </button>

        <div className="bg-white shadow-xl shadow-slate-200/50 rounded-2xl overflow-hidden border border-slate-100">
           <div className="bg-blue-600 px-8 py-10 text-white flex items-center space-x-4">
              <div className="p-3 bg-white/20 rounded-xl backdrop-blur-sm">
                 <FileText className="h-8 w-8 text-white" />
              </div>
              <div>
                 <h1 className="text-3xl font-bold">Terms & Conditions</h1>
                 <p className="mt-1 text-blue-100">Last updated: {new Date().toLocaleDateString()}</p>
              </div>
           </div>
           
           <div className="p-8 sm:p-12 prose prose-slate max-w-none prose-headings:text-slate-800 prose-p:text-slate-600 whitespace-pre-wrap">
              {content}
           </div>
        </div>
      </div>
    </div>
  );
};

export default TermsAndConditions;
