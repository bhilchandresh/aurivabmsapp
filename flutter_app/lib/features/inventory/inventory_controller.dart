import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';

class InventoryItem {
  final String id;
  final String sku;
  final String itemName;
  final double unitPrice;
  final int currentStock;
  final String description;

  InventoryItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.unitPrice,
    required this.currentStock,
    required this.description,
  });

  InventoryItem copyWith({
    String? id,
    String? sku,
    String? itemName,
    double? unitPrice,
    int? currentStock,
    String? description,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      itemName: itemName ?? this.itemName,
      unitPrice: unitPrice ?? this.unitPrice,
      currentStock: currentStock ?? this.currentStock,
      description: description ?? this.description,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? json['id'] ?? '',
      sku: json['sku'] ?? '',
      itemName: json['itemName'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      currentStock: (json['currentStock'] ?? 0).toInt(),
      description: json['description'] ?? '',
    );
  }
}

class InventoryTransaction {
  final String id;
  final String date;
  final String type; // 'Sale', 'Restock', 'Adjustment'
  final String description;
  final int quantity;

  InventoryTransaction({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.quantity,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      date: json['date'] ?? json['createdAt'] ?? '',
      type: json['type'] ?? 'Adjustment',
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
    );
  }
}

class InventoryController extends GetxController {
  // Subscription Plan simulation (syncs with auth controller)
  var subscriptionPlan = 'premium'.obs; // 'basic', 'premium', 'enterprise'

  var items = <InventoryItem>[].obs;
  var transactions = <String, List<InventoryTransaction>?>{}.obs;
  var isLoading = false.obs;

  // Multiple selection state
  var selectedItems = <String>{}.obs;
  var isSelectionMode = false.obs;

  void toggleSelection(String id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
      if (selectedItems.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedItems.add(id);
      isSelectionMode.value = true;
    }
  }

  void clearSelection() {
    selectedItems.clear();
    isSelectionMode.value = false;
  }

  Future<bool> deleteSelectedItems() async {
    if (selectedItems.isEmpty) return false;
    try {
      isLoading.value = true;
      List<Future> futures = [];
      for (String id in selectedItems) {
        futures.add(ApiService.delete('${ApiConstants.inventory}/$id'));
      }
      await Future.wait(futures);

      clearSelection();
      await fetchItems();
      return true;
    } catch (e) {
      debugPrint('Error in bulk delete: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Sync subscription plan from AuthController
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(), permanent: true);

    if (authController.tenantInfo.value != null) {
      subscriptionPlan.value =
          authController.tenantInfo.value?['subscriptionPlan'] ?? 'premium';
    }

    // Listen to changes in tenantInfo
    ever(authController.tenantInfo, (tenant) {
      if (tenant != null) {
        subscriptionPlan.value = tenant['subscriptionPlan'] ?? 'premium';
      }
    });

    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(ApiConstants.inventory);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          items.assignAll(data.map((c) => InventoryItem.fromJson(c)).toList());
        }
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTransactions(String itemId) async {
    try {
      transactions[itemId] = null; // Set to null to indicate loading state
      final response = await ApiService.get(
        '${ApiConstants.inventory}/$itemId/transactions',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          transactions[itemId] = data
              .map((t) => InventoryTransaction.fromJson(t))
              .toList();
        } else {
          transactions[itemId] = [];
        }
      } else {
        transactions[itemId] = [];
      }
    } catch (e) {
      debugPrint('Error fetching transactions for item $itemId: $e');
      transactions[itemId] = [];
    }
  }

  // Plan metrics
  int get maxItems {
    switch (subscriptionPlan.value) {
      case 'basic':
        return 0; // locked completely
      case 'premium':
        return 100;
      default:
        return 99999; // unlimited
    }
  }

  bool get isLocked => subscriptionPlan.value == 'basic';

  bool get isAtLimit {
    if (maxItems == 99999) return false;
    return items.length >= maxItems;
  }

  double get usagePercentage {
    if (maxItems == 99999 || maxItems == 0) return 0.0;
    return (items.length / maxItems).clamp(0.0, 1.0);
  }

  Future<bool> addItem(
    String name,
    String sku,
    double price,
    int stock,
    String description,
  ) async {
    if (isAtLimit) return false;
    try {
      isLoading.value = true;
      final response = await ApiService.post(ApiConstants.inventory, {
        'itemName': name,
        'sku': sku.isNotEmpty ? sku : 'SKU-${1000 + items.length + 1}',
        'unitPrice': price,
        'currentStock': stock,
        'description': description,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateItem(
    String id,
    String name,
    String sku,
    double price,
    String description,
  ) async {
    try {
      isLoading.value = true;
      final response = await ApiService.put('${ApiConstants.inventory}/$id', {
        'itemName': name,
        'sku': sku,
        'unitPrice': price,
        'description': description,
      });
      if (response.statusCode == 200) {
        await fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete('${ApiConstants.inventory}/$id');
      if (response.statusCode == 200) {
        await fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> restockItem(String id, int quantity) async {
    try {
      isLoading.value = true;
      final index = items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final currentStock = items[index].currentStock;
        final response = await ApiService.put('${ApiConstants.inventory}/$id', {
          'currentStock': currentStock + quantity,
          'transactionDescription': 'Restocked Inventory',
        });
        if (response.statusCode == 200) {
          await fetchItems();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error restocking item: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
