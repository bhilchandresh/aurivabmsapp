class AnalyticsEvents {
  // Auth Events
  static const String login = 'auth_login';
  static const String logout = 'auth_logout';
  static const String offlineLogin = 'auth_offline_login';

  // Business Events
  static const String clientCreated = 'client_created';
  static const String supplierCreated = 'supplier_created';
  static const String invoiceCreated = 'invoice_created';
  static const String quotationCreated = 'quotation_created';
  static const String expenseCreated = 'expense_created';
  static const String inventoryUpdated = 'inventory_updated';

  // Sync Engine Events
  static const String syncStarted = 'sync_started';
  static const String syncCompleted = 'sync_completed';
  static const String syncFailed = 'sync_failed';
  static const String offlineOperationCreated = 'offline_operation_created';
  static const String queueRetry = 'queue_retry';
  static const String deadLetterCreated = 'dead_letter_created';
  static const String conflictDetected = 'sync_conflict_detected';
  
  // Specific Module Conflicts
  static const String inventoryConflict = 'conflict_inventory';
  static const String invoiceConflict = 'conflict_invoice';
  static const String quotationConflict = 'conflict_quotation';

  // UI Navigation Events
  static const String dashboardOpened = 'nav_dashboard_opened';
  static const String reportsOpened = 'nav_reports_opened';
}
