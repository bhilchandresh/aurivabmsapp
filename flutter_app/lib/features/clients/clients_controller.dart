import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gstin;
  final String state;
  final String address;
  final double totalBilled;
  final double
  balance; // positive = pending due, negative = advance jama, 0 = settled
  final DateTime? createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.state,
    required this.address,
    required this.totalBilled,
    required this.balance,
    this.createdAt,
  });

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gstin,
    String? state,
    String? address,
    double? totalBilled,
    double? balance,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      state: state ?? this.state,
      address: address ?? this.address,
      totalBilled: totalBilled ?? this.totalBilled,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gstin: json['gstin'] ?? '',
      state: json['state'] ?? '',
      address: json['address'] ?? '',
      totalBilled: (json['totalBilled'] ?? 0.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class ClientInvoice {
  final String id;
  final String invoiceNumber;
  final double totalAmount;
  final double remainingAmount;
  final String date;
  final String status; // 'Paid', 'Pending', 'Partially Paid', 'Unpaid'

  ClientInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.remainingAmount,
    required this.date,
    required this.status,
  });

  factory ClientInvoice.fromJson(Map<String, dynamic> json) {
    return ClientInvoice(
      id: json['_id'] ?? json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }
}

class ClientQuotation {
  final String id;
  final String quotationNumber;
  final double grandTotal;
  final String date;

  ClientQuotation({
    required this.id,
    required this.quotationNumber,
    required this.grandTotal,
    required this.date,
  });

  factory ClientQuotation.fromJson(Map<String, dynamic> json) {
    return ClientQuotation(
      id: json['_id'] ?? json['id'] ?? '',
      quotationNumber: json['quoteNumber'] ?? json['quotationNumber'] ?? '',
      grandTotal: (json['totalAmount'] ?? json['grandTotal'] ?? 0.0).toDouble(),
      date: json['date'] ?? json['createdAt'] ?? '',
    );
  }
}

class ClientPayment {
  final String id;
  final double amount;
  final String date;
  final String paymentMode; // 'UPI', 'Bank Transfer', 'Cash', 'Cheque'
  final String referenceNote;

  ClientPayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.paymentMode,
    required this.referenceNote,
  });

  factory ClientPayment.fromJson(Map<String, dynamic> json) {
    return ClientPayment(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      paymentMode: json['paymentMode'] ?? '',
      referenceNote: json['referenceNote'] ?? '',
    );
  }
}

class ClientsController extends GetxController {
  var clients = <Client>[].obs;
  var clientInvoices = <String, List<ClientInvoice>>{}.obs;
  var allInvoices = <dynamic>[].obs;
  var clientQuotations = <String, List<ClientQuotation>>{}.obs;
  var allQuotations = <dynamic>[].obs;
  var clientPayments = <String, List<ClientPayment>>{}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  Future<void> fetchClients() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(ApiConstants.clients);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          clients.assignAll(data.map((c) => Client.fromJson(c)).toList());
        }
      }
      // Wait for invoices and quotations while loading is active
      await fetchInvoices();
    } catch (e) {
      debugPrint('Error fetching clients: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await ApiService.get(ApiConstants.invoices);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          allInvoices.assignAll(data);

          final Map<String, List<ClientInvoice>> groupedInvoices = {};

          for (var item in data) {
            final inv = ClientInvoice.fromJson(item);
            final clientObj = item['client'];
            String cid = '';
            if (clientObj is Map) {
              cid = clientObj['clientId'] ?? clientObj['id'] ?? '';
            } else if (clientObj is String) {
              cid = clientObj;
            }
            if (cid.isNotEmpty) {
              groupedInvoices.putIfAbsent(cid, () => []).add(inv);
            }
          }
          clientInvoices.assignAll(groupedInvoices);
        }
      }
      // Fetch quotations sequentially
      await fetchQuotations();
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
    }
  }

  Future<bool> updateInvoiceStatus(String id, String newStatus) async {
    try {
      final response = await ApiService.put('${ApiConstants.invoices}/$id', {
        'status': newStatus,
      });
      if (response.statusCode == 200) {
        fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
    }
    return false;
  }

  Future<bool> deleteInvoice(String id) async {
    try {
      final response = await ApiService.delete('${ApiConstants.invoices}/$id');
      if (response.statusCode == 200) {
        fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
    }
    return false;
  }

  Future<bool> updateQuotationStatus(String id, String newStatus) async {
    try {
      final response = await ApiService.put('${ApiConstants.quotations}/$id', {
        'status': newStatus,
      });
      if (response.statusCode == 200) {
        fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating quotation status: $e');
    }
    return false;
  }

  Future<bool> deleteQuotation(String id) async {
    try {
      final response = await ApiService.delete(
        '${ApiConstants.quotations}/$id',
      );
      if (response.statusCode == 200) {
        fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting quotation: $e');
    }
    return false;
  }

  Future<String?> convertQuotationToInvoice(String id) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.quotations}/$id/convert',
        {},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          fetchClients();
          return body['invoiceId']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error converting quotation: $e');
    }
    return null;
  }

  Future<void> fetchQuotations() async {
    try {
      final response = await ApiService.get(ApiConstants.quotations);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          allQuotations.assignAll(data);
          final Map<String, List<ClientQuotation>> groupedQuotes = {};

          for (var item in data) {
            final quote = ClientQuotation.fromJson(item);
            final clientObj = item['client'];
            String cid = '';
            if (clientObj is Map) {
              cid = clientObj['_id'] ?? clientObj['id'] ?? '';
            } else if (clientObj is String) {
              cid = clientObj;
            }
            if (cid.isNotEmpty) {
              groupedQuotes.putIfAbsent(cid, () => []).add(quote);
            }
          }
          clientQuotations.assignAll(groupedQuotes);
        }
      }
    } catch (e) {
      debugPrint('Error fetching quotations: $e');
    }
  }

  Future<void> fetchPayments(String clientId) async {
    try {
      final response = await ApiService.get(
        '${ApiConstants.clients}/$clientId/payments',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          clientPayments[clientId] = data
              .map((p) => ClientPayment.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching payments for client $clientId: $e');
    }
  }

  Future<bool> addClient(
    String name,
    String email,
    String phone,
    String gstin,
    String state,
    String address,
  ) async {
    try {
      final response = await ApiService.post(ApiConstants.clients, {
        'name': name,
        'email': email,
        'phone': phone,
        'gstin': gstin,
        'state': state,
        'address': address,
      });
      if (response.statusCode == 201) {
        await fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding client: $e');
    }
    return false;
  }

  Future<bool> updateClient(
    String id,
    String name,
    String email,
    String phone,
    String gstin,
    String state,
    String address,
  ) async {
    try {
      final response = await ApiService.put('${ApiConstants.clients}/$id', {
        'name': name,
        'email': email,
        'phone': phone,
        'gstin': gstin,
        'state': state,
        'address': address,
      });
      if (response.statusCode == 200) {
        await fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
    }
    return false;
  }

  Future<bool> deleteClient(String id) async {
    try {
      final response = await ApiService.delete('${ApiConstants.clients}/$id');
      if (response.statusCode == 200) {
        await fetchClients();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting client: $e');
    }
    return false;
  }

  Future<bool> collectPayment(
    String clientId,
    double amount,
    String date,
    String mode,
    String note,
  ) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.clients}/$clientId/payments',
        {
          'amount': amount,
          'date': date,
          'paymentMode': mode,
          'referenceNote': note,
        },
      );
      if (response.statusCode == 201) {
        await fetchClients();
        await fetchPayments(clientId);
        return true;
      }
    } catch (e) {
      debugPrint('Error collecting payment: $e');
    }
    return false;
  }

  Future<bool> syncLedger(String clientId) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.clients}/$clientId/sync-ledger',
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchClients();
        await fetchPayments(clientId);
        return true;
      }
    } catch (e) {
      debugPrint('Error syncing ledger: $e');
    }
    return false;
  }

  Future<bool> sendAccountSummary(String clientId) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.clients}/$clientId/send-summary',
        {},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Error sending account summary: $e');
    }
    return false;
  }

  Future<String?> sendInvoiceEmail(String id) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.invoices}/$id/email',
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } catch (e) {
      debugPrint('Error sending invoice email: $e');
      return e.toString();
    }
  }

  Future<String?> sendQuotationEmail(String id) async {
    try {
      final response = await ApiService.post(
        '${ApiConstants.quotations}/$id/email',
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } catch (e) {
      debugPrint('Error sending quotation email: $e');
      return e.toString();
    }
  }
}
