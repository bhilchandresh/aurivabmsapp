const PLANS = {
  starter: {
    name: 'Starter',
    price: 499,
    limits: {
      invoices: 50, // Max 50 per month
      clients: 50,
      users: 1
    },
    features: [
      'create_invoice', 
      'download_pdf', 
      'basic_reports'
    ]
  },
  growth: {
    name: 'Growth',
    price: 699,
    limits: {
      invoices: Infinity, // Unlimited
      clients: Infinity,
      users: 1
    },
    features: [
      'create_invoice', 'download_pdf', 'basic_reports',
      'custom_branding', 'reminders', 'export_excel', 'analytics'
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
  enterprise: {
    name: 'Enterprise',
    price: 0, // Custom
    limits: {
      invoices: Infinity,
      clients: Infinity,
      users: Infinity
    },
    features: ['all', 'white_label']
  }
};

module.exports = PLANS;