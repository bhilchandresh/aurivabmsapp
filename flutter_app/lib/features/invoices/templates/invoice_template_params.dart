import 'package:intl/intl.dart';

class InvoiceTemplateParams {
  final Map<String, String> tenant;
  final Map<String, dynamic> bankDetails;
  final String invoiceId;
  final String date;
  final String dueDate;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String clientGst;
  final String placeOfSupply;
  final double discountPercentage;
  final bool gstEnabled;
  final String taxType;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final double advancePayment;
  final NumberFormat formatCurrency;
  
  // Custom labels to support both Invoices and Quotations
  final String documentTitle; // e.g., 'INVOICE', 'QUOTATION'
  final String numberLabel;   // e.g., 'Invoice No', 'Quotation No'
  final String dateLabel;     // e.g., 'Invoice Date', 'Quotation Date'

  InvoiceTemplateParams({
    required this.tenant,
    required this.bankDetails,
    required this.invoiceId,
    required this.date,
    required this.dueDate,
    required this.clientName,
    required this.clientEmail,
    this.clientPhone = '',
    required this.clientAddress,
    required this.clientGst,
    required this.placeOfSupply,
    required this.discountPercentage,
    required this.gstEnabled,
    required this.taxType,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    this.advancePayment = 0.0,
    required this.formatCurrency,
    this.documentTitle = 'INVOICE',
    this.numberLabel = 'Invoice No',
    this.dateLabel = 'Invoice Date',
  });
}
