import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';

class Supplier {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String gstNumber;
  final String address;
  final double totalPurchased;
  final double totalPaid;
  final String createdBy;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.gstNumber,
    required this.address,
    required this.totalPurchased,
    required this.totalPaid,
    required this.createdBy,
  });

  double get pendingBalance => totalPurchased - totalPaid;

  Supplier copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? gstNumber,
    String? address,
    double? totalPurchased,
    double? totalPaid,
    String? createdBy,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gstNumber: gstNumber ?? this.gstNumber,
      address: address ?? this.address,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      totalPaid: totalPaid ?? this.totalPaid,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      address: json['address'] ?? '',
      totalPurchased: (json['totalPurchased'] ?? 0.0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0.0).toDouble(),
      createdBy: _parseCreatedBy(json),
    );
  }

  static String _parseCreatedBy(Map<String, dynamic> json) {
    try {
      if (json['user'] != null && json['user'] is Map) {
        final name = json['user']['name'];
        if (name != null) return name.toString();
      }
      if (json['createdBy'] != null && json['createdBy'] is Map) {
        final name = json['createdBy']['name'];
        if (name != null) return name.toString();
      }
      if (json['createdBy'] != null && json['createdBy'] is String) {
        return json['createdBy'].toString();
      }
      return 'Admin';
    } catch (e) {
      return 'Admin';
    }
  }
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class PurchaseBillItem {
  final String description;
  final int quantity;
  final double rate;
  final double amount;
  final String? inventoryId;

  PurchaseBillItem({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.inventoryId,
  });

  factory PurchaseBillItem.fromJson(Map<String, dynamic> json) {
    return PurchaseBillItem(
      description: json['description'] ?? '',
      quantity: Supplier._parseInt(json['quantity']),
      rate: Supplier._parseDouble(json['rate']),
      amount: Supplier._parseDouble(json['amount']),
      inventoryId: json['inventoryId'] is Map
          ? json['inventoryId']['_id']
          : json['inventoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      if (inventoryId != null) 'inventoryId': inventoryId,
    };
  }
}

class SupplierPurchaseBill {
  final String id;
  final String billNumber;
  final String date;
  final String dueDate;
  final double totalAmount;
  final double amountPaid;
  final String status; // 'Paid', 'Partial', 'Unpaid'
  final String notes;
  final List<PurchaseBillItem> items;
  final String createdBy;

  SupplierPurchaseBill({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.dueDate,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    required this.notes,
    required this.items,
    required this.createdBy,
  });

  factory SupplierPurchaseBill.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    final List<PurchaseBillItem> itemsList = list
        .map((i) => PurchaseBillItem.fromJson(i))
        .toList();

    return SupplierPurchaseBill(
      id: json['_id'] ?? json['id'] ?? '',
      billNumber: json['billNumber'] ?? '',
      date: json['date'] != null ? json['date'].toString() : '',
      dueDate: json['dueDate'] != null ? json['dueDate'].toString() : '',
      totalAmount: Supplier._parseDouble(json['totalAmount']),
      amountPaid: Supplier._parseDouble(json['amountPaid']),
      status: json['status'] ?? 'Unpaid',
      notes: json['notes'] ?? '',
      items: itemsList,
      createdBy: Supplier._parseCreatedBy(json),
    );
  }
}

class SupplierPayment {
  final String id;
  final double amount;
  final String paymentDate;
  final String paymentMode; // 'Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Other'
  final String referenceNumber;
  final String notes;

  SupplierPayment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    required this.referenceNumber,
    required this.notes,
  });

  factory SupplierPayment.fromJson(Map<String, dynamic> json) {
    return SupplierPayment(
      id: json['_id'] ?? json['id'] ?? '',
      amount: Supplier._parseDouble(json['amount']),
      paymentDate: json['paymentDate'] != null
          ? json['paymentDate'].toString()
          : '',
      paymentMode: json['paymentMode'] ?? 'Bank Transfer',
      referenceNumber: json['referenceNumber'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}

class SuppliersController extends GetxController {
  var suppliers = <Supplier>[].obs;
  var supplierBills = <String, List<SupplierPurchaseBill>>{}.obs;
  var supplierPayments = <String, List<SupplierPayment>>{}.obs;
  var isLoading = false.obs;

  // Subscription Plan simulation
  var subscriptionPlan = 'premium'.obs;
  var maxLimit = RxnInt();

  @override
  void onInit() {
    super.onInit();

    // Ensure AuthController is permanent and fetch settings
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    authController.fetchTenantSettings();
    
    if (authController.tenantInfo.value != null) {
      subscriptionPlan.value = authController.tenantInfo.value?['subscriptionPlan'] ?? 'premium';
    }
    ever(authController.tenantInfo, (tenant) {
      if (tenant != null) {
        subscriptionPlan.value = tenant['subscriptionPlan'] ?? 'premium';
      }
    });

    fetchSuppliers();
  }

  // Plan metrics
  int get maxSuppliers {
    if (maxLimit.value != null) {
      return maxLimit.value!;
    }
    switch (subscriptionPlan.value) {
      case 'basic':
        return 0; // locked completely
      case 'premium':
        return 50;
      default:
        return 99999; // unlimited
    }
  }

  bool get isLocked => subscriptionPlan.value == 'basic';

  bool get isAtLimit {
    if (maxSuppliers == 99999) return false;
    return suppliers.length >= maxSuppliers;
  }

  Future<void> fetchSuppliers() async {
    try {
      isLoading.value = true;

      // Fetch both suppliers and all purchase bills in parallel
      final responses = await Future.wait([
        ApiService.get(ApiConstants.suppliers),
        ApiService.get('${ApiConstants.suppliers}/purchases/all'),
      ]);

      final suppliersRes = responses[0];
      final purchasesRes = responses[1];

      if (suppliersRes.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(suppliersRes.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          final tempSuppliers = data.map((s) => Supplier.fromJson(s)).toList();

          final Map<String, double> purchasedMap = {};
          final Map<String, double> paidMap = {};
          final Map<String, List<SupplierPurchaseBill>> tempBillsMap = {};

          if (purchasesRes.statusCode == 200) {
            final Map<String, dynamic> purchasesBody = jsonDecode(
              purchasesRes.body,
            );
            if (purchasesBody['success'] == true) {
              final List<dynamic> purchasesData = purchasesBody['data'] ?? [];

              for (var p in purchasesData) {
                final bill = SupplierPurchaseBill.fromJson(p);
                final sId = p['supplierId'] is Map
                    ? p['supplierId']['_id']
                    : p['supplierId'];
                if (sId != null) {
                  final String supplierId = sId.toString();
                  purchasedMap[supplierId] =
                      (purchasedMap[supplierId] ?? 0.0) + bill.totalAmount;
                  paidMap[supplierId] =
                      (paidMap[supplierId] ?? 0.0) + bill.amountPaid;

                  if (!tempBillsMap.containsKey(supplierId)) {
                    tempBillsMap[supplierId] = [];
                  }
                  tempBillsMap[supplierId]!.add(bill);
                }
              }
            }
          }

          // Recompute final suppliers with correct aggregated stats
          final finalSuppliers = tempSuppliers.map((s) {
            return s.copyWith(
              totalPurchased: purchasedMap[s.id] ?? 0.0,
              totalPaid: paidMap[s.id] ?? 0.0,
            );
          }).toList();

          suppliers.assignAll(finalSuppliers);
          supplierBills.assignAll(tempBillsMap);
          
          if (body['maxLimit'] != null) {
            maxLimit.value = (body['maxLimit'] as num).toInt();
          } else {
            maxLimit.value = null; // Unbounded or Basic
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSupplierDetails(String supplierId) async {
    try {
      isLoading.value = true;

      final responses = await Future.wait([
        ApiService.get(
          '${ApiConstants.suppliers}/purchases/all?supplierId=$supplierId',
        ),
        ApiService.get('${ApiConstants.suppliers}/$supplierId/payments'),
      ]);

      final billsRes = responses[0];
      final paymentsRes = responses[1];

      if (billsRes.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(billsRes.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          supplierBills[supplierId] = data
              .map((b) => SupplierPurchaseBill.fromJson(b))
              .toList();
        }
      }

      if (paymentsRes.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(paymentsRes.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          supplierPayments[supplierId] = data
              .map((p) => SupplierPayment.fromJson(p))
              .toList();
        }
      }

      _recomputeSupplierStats(supplierId);
    } catch (e) {
      debugPrint('Error fetching supplier details for $supplierId: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addSupplier(
    String name,
    String email,
    String phone,
    String gstNumber,
    String address,
  ) async {
    if (isAtLimit) return false;
    try {
      isLoading.value = true;
      final response = await ApiService.post(ApiConstants.suppliers, {
        'name': name,
        'email': email,
        'phone': phone,
        'gstNumber': gstNumber,
        'address': address,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSuppliers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete('${ApiConstants.suppliers}/$id');

      if (response.statusCode == 200) {
        suppliers.removeWhere((s) => s.id == id);
        supplierBills.remove(id);
        supplierPayments.remove(id);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addPurchaseBill(
    String supplierId,
    String billNo,
    String date,
    String dueDate,
    String notes,
    double totalOverride,
    List<PurchaseBillItem> items,
  ) async {
    try {
      isLoading.value = true;

      final double computedSubtotal = items.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );
      final double finalAmount = totalOverride > 0 ? totalOverride : computedSubtotal;

      final response =
          await ApiService.post('${ApiConstants.suppliers}/purchases/all', {
            'supplierId': supplierId,
            'billNumber': billNo,
            'date': date,
            'dueDate': dueDate,
            'totalAmount': finalAmount,
            'notes': notes,
            'items': items.map((i) => i.toJson()).toList(),
          });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSupplierDetails(supplierId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding purchase bill: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePurchaseBill(String supplierId, String billId) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete(
        '${ApiConstants.suppliers}/purchases/$billId',
      );

      if (response.statusCode == 200) {
        await fetchSupplierDetails(supplierId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting purchase bill: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> recordPayment(
    String supplierId,
    double amount,
    String paymentDate,
    String paymentMode,
    String referenceNumber,
    String notes,
  ) async {
    try {
      isLoading.value = true;
      final response = await ApiService.post(
        '${ApiConstants.suppliers}/$supplierId/payments',
        {
          'amount': amount,
          'paymentDate': paymentDate,
          'paymentMode': paymentMode,
          'referenceNumber': referenceNumber,
          'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSupplierDetails(supplierId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletePayment(String supplierId, String paymentId) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete(
        '${ApiConstants.suppliers}/payments/$paymentId',
      );

      if (response.statusCode == 200) {
        await fetchSupplierDetails(supplierId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting payment: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _recomputeSupplierStats(String supplierId) {
    final index = suppliers.indexWhere((s) => s.id == supplierId);
    if (index != -1) {
      final supplier = suppliers[index];
      final billsList = supplierBills[supplierId] ?? [];
      final paymentsList = supplierPayments[supplierId] ?? [];

      final totalPurchased = billsList.fold<double>(
        0.0,
        (sum, b) => sum + b.totalAmount,
      );
      final totalPaid = paymentsList.fold<double>(
        0.0,
        (sum, p) => sum + p.amount,
      );

      suppliers[index] = supplier.copyWith(
        totalPurchased: totalPurchased,
        totalPaid: totalPaid,
      );
    }
  }
}
