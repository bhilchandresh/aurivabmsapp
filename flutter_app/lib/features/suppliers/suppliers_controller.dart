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

  static String _parseCreatedBy(Map<String, dynamic>? json) {
    if (json == null) return '';
    try {
      // 1. Direct tag field
      if (json['tag'] != null && json['tag'].toString().trim().isNotEmpty) {
        final t = json['tag'].toString().trim();
        if (t.toLowerCase() != 'null') return t;
      }
      if (json['tags'] is List && (json['tags'] as List).isNotEmpty) {
        final t = (json['tags'] as List).first.toString().trim();
        if (t.toLowerCase() != 'null') return t;
      }

      // 2. Check 'createdBy' object (populated in supplierController.js / backend)
      final createdByVal = json['createdBy'];
      if (createdByVal is Map) {
        final name = createdByVal['name'] ??
            createdByVal['fullName'] ??
            createdByVal['userName'] ??
            createdByVal['email'];
        if (name != null && name.toString().trim().isNotEmpty) {
          final str = name.toString().trim();
          if (str.toLowerCase() != 'null') return str;
        }
      } else if (createdByVal is String && createdByVal.trim().isNotEmpty) {
        final str = createdByVal.trim();
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(str) && str.toLowerCase() != 'null') {
          return str;
        }
      }

      // 3. Check 'user' object
      final userVal = json['user'];
      if (userVal is Map) {
        final name = userVal['name'] ??
            userVal['fullName'] ??
            userVal['userName'] ??
            userVal['email'];
        if (name != null && name.toString().trim().isNotEmpty) {
          final str = name.toString().trim();
          if (str.toLowerCase() != 'null') return str;
        }
      } else if (userVal is String && userVal.trim().isNotEmpty) {
        final str = userVal.trim();
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(str) && str.toLowerCase() != 'null') {
          return str;
        }
      }

      // 4. Check 'recordedBy' or 'addedBy'
      if (json['recordedBy'] is Map && json['recordedBy']['name'] != null) {
        final name = json['recordedBy']['name'].toString().trim();
        if (name.isNotEmpty && name.toLowerCase() != 'null') return name;
      }
      if (json['addedBy'] != null && json['addedBy'].toString().trim().isNotEmpty) {
        final ab = json['addedBy'].toString().trim();
        if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(ab) && ab.toLowerCase() != 'null') {
          return ab;
        }
      }

      return '';
    } catch (_) {
      return '';
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
  final String? _id;
  final String? _billNumber;
  final String? _date;
  final String? _dueDate;
  final double? _totalAmount;
  final double? _amountPaid;
  final String? _status; // 'Paid', 'Partial', 'Unpaid'
  final String? _notes;
  final List<PurchaseBillItem>? _items;
  final String? _createdBy;

  SupplierPurchaseBill({
    String? id,
    String? billNumber,
    String? date,
    String? dueDate,
    double? totalAmount,
    double? amountPaid,
    String? status,
    String? notes,
    List<PurchaseBillItem>? items,
    String? createdBy,
  })  : _id = id,
        _billNumber = billNumber,
        _date = date,
        _dueDate = dueDate,
        _totalAmount = totalAmount,
        _amountPaid = amountPaid,
        _status = status,
        _notes = notes,
        _items = items,
        _createdBy = createdBy;

  String get id => _id ?? '';
  String get billNumber => _billNumber ?? '';
  String get date => _date ?? '';
  String get dueDate => _dueDate ?? '';
  double get totalAmount => _totalAmount ?? 0.0;
  double get amountPaid => _amountPaid ?? 0.0;
  String get status => _status ?? 'Unpaid';
  String get notes => _notes ?? '';
  List<PurchaseBillItem> get items => _items ?? [];
  String get createdBy {
    final creator = _createdBy;
    if (creator == null) return 'Undefined';
    final trimmed = creator.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'admin' ||
        trimmed.toLowerCase() == 'null' ||
        trimmed.toLowerCase() == 'unknown' ||
        trimmed.toLowerCase() == 'undefined') {
      return 'Undefined';
    }
    return trimmed;
  }

  factory SupplierPurchaseBill.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    final List<PurchaseBillItem> itemsList = list
        .map((i) => PurchaseBillItem.fromJson(i))
        .toList();

    return SupplierPurchaseBill(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      date: json['date'] != null ? json['date'].toString() : '',
      dueDate: json['dueDate'] != null ? json['dueDate'].toString() : '',
      totalAmount: Supplier._parseDouble(json['totalAmount']),
      amountPaid: Supplier._parseDouble(json['amountPaid']),
      status: json['status']?.toString() ?? 'Unpaid',
      notes: json['notes']?.toString() ?? '',
      items: itemsList,
      createdBy: Supplier._parseCreatedBy(json),
    );
  }
}

class SupplierPayment {
  final String? _id;
  final double? _amount;
  final String? _paymentDate;
  final String? _paymentMode; // 'Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Other'
  final String? _referenceNumber;
  final String? _notes;
  final String? _createdBy;

  SupplierPayment({
    String? id,
    double? amount,
    String? paymentDate,
    String? paymentMode,
    String? referenceNumber,
    String? notes,
    String? createdBy,
  })  : _id = id,
        _amount = amount,
        _paymentDate = paymentDate,
        _paymentMode = paymentMode,
        _referenceNumber = referenceNumber,
        _notes = notes,
        _createdBy = createdBy;

  String get id => _id ?? '';
  double get amount => _amount ?? 0.0;
  String get paymentDate => _paymentDate ?? '';
  String get paymentMode {
    final mode = _paymentMode;
    return (mode != null && mode.trim().isNotEmpty) ? mode : 'Bank Transfer';
  }
  String get referenceNumber => _referenceNumber ?? '';
  String get notes => _notes ?? '';
  String get createdBy {
    final creator = _createdBy;
    if (creator == null) return 'Admin';
    final trimmed = creator.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'undefined' ||
        trimmed.toLowerCase() == 'null') {
      return 'Admin';
    }
    return trimmed;
  }

  factory SupplierPayment.fromJson(Map<String, dynamic> json) {
    return SupplierPayment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      amount: Supplier._parseDouble(json['amount']),
      paymentDate: json['paymentDate'] != null
          ? json['paymentDate'].toString()
          : (json['date'] != null ? json['date'].toString() : ''),
      paymentMode: json['paymentMode']?.toString() ?? 'Bank Transfer',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdBy: Supplier._parseCreatedBy(json),
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
              totalPurchased: purchasedMap[s.id] ?? s.totalPurchased,
              totalPaid: s.totalPaid > 0 ? s.totalPaid : (paidMap[s.id] ?? 0.0),
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

      // Fetch bills and payments in parallel with independent error handling
      await Future.wait([
        () async {
          try {
            final billsRes = await ApiService.get(
              '${ApiConstants.suppliers}/purchases/all?supplierId=$supplierId',
            );
            if (billsRes.statusCode == 200) {
              final Map<String, dynamic> body = jsonDecode(billsRes.body);
              if (body['success'] == true) {
                final List<dynamic> data = body['data'] ?? [];
                supplierBills[supplierId] = data
                    .map((b) => SupplierPurchaseBill.fromJson(b))
                    .toList();
              }
            }
          } catch (e) {
            debugPrint('Error fetching supplier bills for $supplierId: $e');
          }
        }(),
        () async {
          try {
            final paymentsRes = await ApiService.get(
              '${ApiConstants.suppliers}/$supplierId/payments',
            );
            if (paymentsRes.statusCode == 200) {
              final Map<String, dynamic> body = jsonDecode(paymentsRes.body);
              if (body['success'] == true) {
                final List<dynamic> data = body['data'] ?? [];
                supplierPayments[supplierId] = data
                    .map((p) => SupplierPayment.fromJson(p))
                    .toList();
              }
            }
          } catch (e) {
            debugPrint('Error fetching supplier payments for $supplierId: $e');
          }
        }(),
      ]);

      _recomputeSupplierStats(supplierId);
      supplierBills.refresh();
      supplierPayments.refresh();
      suppliers.refresh();
    } catch (e) {
      debugPrint('Error in fetchSupplierDetails for $supplierId: $e');
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
      suppliers.refresh();
    }
  }
}
