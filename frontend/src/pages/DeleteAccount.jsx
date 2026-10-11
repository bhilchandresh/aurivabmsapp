import { ArrowLeft, UserX } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const DeleteAccount = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-slate-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto">
        <button 
            onClick={() => navigate(-1)} 
            className="mb-8 flex items-center text-sm font-medium text-slate-500 hover:text-blue-600 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-1" /> Back
        </button>

        <div className="bg-white shadow-xl shadow-slate-200/50 rounded-2xl overflow-hidden border border-slate-100">
           <div className="bg-red-600 px-8 py-10 text-white flex items-center space-x-4">
              <div className="p-3 bg-white/20 rounded-xl backdrop-blur-sm">
                 <UserX className="h-8 w-8 text-white" />
              </div>
              <div>
                 <h1 className="text-3xl font-bold">Account Deletion Request</h1>
                 <p className="mt-1 text-red-100">AURIVA Invoice App</p>
              </div>
           </div>
           
           <div className="p-8 sm:p-12 prose prose-slate max-w-none prose-headings:text-slate-800 prose-p:text-slate-600">
              <h3 className="text-xl font-bold mb-4">How to Request Account Deletion</h3>
              <p className="mb-4">
                If you wish to delete your AURIVA account and all associated data, you can do so by following these steps:
              </p>
              <ol className="list-decimal pl-6 mb-6 space-y-2">
                <li>Log in to your AURIVA account via the mobile app or web dashboard.</li>
                <li>Navigate to <strong>Settings</strong> from the main menu.</li>
                <li>Scroll down to the <strong>Danger Zone</strong> section.</li>
                <li>Click on <strong>Request Account Deletion</strong> and confirm your request.</li>
              </ol>
              <p className="mb-8">
                Alternatively, you can send an email to our support team at <strong>support@auriva.in</strong> from your registered email address with the subject line "Account Deletion Request".
              </p>

              <h3 className="text-xl font-bold mb-4">Data Deletion and Retention</h3>
              <p className="mb-4">Upon requesting account deletion, the following actions are taken:</p>
              <ul className="list-disc pl-6 mb-6 space-y-2">
                <li><strong>Deleted Data:</strong> Your personal profile information, invoices, client details, inventory, and transaction records will be permanently deleted from our active databases within 30 days.</li>
                <li><strong>Retained Data:</strong> We may retain certain financial and billing records for a longer period (up to 7 years) as required by law for tax and accounting purposes. This retained data is strictly isolated and not used for any other purposes.</li>
              </ul>
              
              <p>If you have any questions about our data retention policies, please <a href="/contact" className="text-blue-600 hover:underline">contact us</a>.</p>
           </div>
        </div>
      </div>
    </div>
  );
};

export default DeleteAccount;
