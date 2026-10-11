const PLANS = {
  freelance: {
    name: 'Freelance',
    price: 499,
    limits: {
      invoices: 50,
      clients: 50,
      users: 1
    },
    features: [
      'create_invoice', 
      'download_pdf', 
      'basic_reports'
    ]
  },
  pro: {
    name: 'Pro',
    price: 999,
    limits: {
      invoices: Infinity,
      clients: Infinity,
      users: 5
    },
    features: [
      'create_invoice', 'download_pdf', 'basic_reports',
      'custom_branding', 'reminders', 'export_excel', 'analytics',
      'expense_tracking', 'recurring_invoices', 'multi_user'
    ]
  },
  business: {
    name: 'Business',
    price: 1999, // Custom
    limits: {
      invoices: Infinity,
      clients: Infinity,
      users: Infinity
    },
    features: ['all', 'white_label']
  }
};

module.exports = PLANS;