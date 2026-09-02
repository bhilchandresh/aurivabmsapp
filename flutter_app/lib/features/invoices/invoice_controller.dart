import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';

class Invoice {
  final String dbId;
  final String id; // invoiceNumber
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String clientGst;
  final double amount;
  final double subtotal;
  final double discountPercentage;
  final double taxAmount;
  final String date;
  final String dueDate;
  final String status;
  final bool gstEnabled;
  final String taxType;
  final String placeOfSupply;
  final List<dynamic> items;
  final double advancePayment;

  Invoice({
    required this.dbId,
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
    required this.clientGst,
    required this.amount,
    required this.subtotal,
    required this.discountPercentage,
    required this.taxAmount,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.gstEnabled,
    required this.taxType,
    required this.placeOfSupply,
    required this.items,
    this.advancePayment = 0.0,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final clientObj = json['client'] ?? {};
    final String name = clientObj['name'] ?? 'Unknown';
    final String email = clientObj['email'] ?? '';
    final String phone = clientObj['phone'] ?? clientObj['phoneNumber'] ?? '';
    final String address = clientObj['address'] ?? '';
    final String gst = clientObj['gstin'] ?? clientObj['gstNumber'] ?? '';
    final String state = clientObj['state'] ?? '';

    return Invoice(
      dbId: json['_id'] ?? json['id'] ?? '',
      id: json['invoiceNumber'] ?? '',
      clientName: name,
      clientEmail: email,
      clientPhone: phone,
      clientAddress: address,
      clientGst: gst,
      amount: (json['totalAmount'] ?? 0.0).toDouble(),
      subtotal: (json['subTotal'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      taxAmount: (json['gstAmount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'Pending',
      gstEnabled: json['gstEnabled'] ?? false,
      taxType: json['taxType'] ?? 'exclusive',
      placeOfSupply: json['placeOfSupply'] ?? state,
      items: json['items'] ?? [],
      advancePayment: (json['advancePayment'] ?? 0.0).toDouble(),
    );
  }

  Invoice copyWith({String? status}) {
    return Invoice(
      dbId: dbId,
      id: id,
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      clientGst: clientGst,
      amount: amount,
      subtotal: subtotal,
      discountPercentage: discountPercentage,
      taxAmount: taxAmount,
      date: date,
      dueDate: dueDate,
      status: status ?? this.status,
      gstEnabled: gstEnabled,
      taxType: taxType,
      placeOfSupply: placeOfSupply,
      items: items,
      advancePayment: advancePayment,
    );
  }
}

class InvoiceController extends GetxController {
  var invoices = <Invoice>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(ApiConstants.invoices);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          invoices.assignAll(data.map((i) => Invoice.fromJson(i)).toList());
        }
      }
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateInvoiceStatus(String id, String newStatus) async {
    try {
      final response = await ApiService.put('${ApiConstants.invoices}/$id', {
        'status': newStatus,
      });
      if (response.statusCode == 200) {
        // Optimistic UI update
        final index = invoices.indexWhere((inv) => inv.dbId == id);
        if (index != -1) {
          invoices[index] = invoices[index].copyWith(status: newStatus);
          invoices.refresh();
        }
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
        // Optimistic UI update
        invoices.removeWhere((inv) => inv.dbId == id);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
    }
    return false;
  }
}
