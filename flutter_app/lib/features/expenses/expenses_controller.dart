import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';

class Expense {
  final String id;
  final String category;
  final double amount;
  final String description;
  final String date; // Format: yyyy-MM-dd

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  Expense copyWith({
    String? id,
    String? category,
    double? amount,
    String? description,
    String? date,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final String rawDate = json['date'] ?? '';
    String formattedDate = '';
    if (rawDate.length >= 10) {
      formattedDate = rawDate.substring(0, 10);
    } else {
      formattedDate = rawDate;
    }
    return Expense(
      id: json['_id'] ?? json['id'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      date: formattedDate,
    );
  }
}

class ExpensesController extends GetxController {
  var expenses = <Expense>[].obs;
  var filterMonth = ''.obs; // Format: yyyy-MM
  var sortBy = 'date-desc'.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Default current month to current real-time month
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    filterMonth.value = '$year-$month';

    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(ApiConstants.expenses);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          expenses.assignAll(data.map((e) => Expense.fromJson(e)).toList());
        }
      }
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Expense> get processedExpenses {
    List<Expense> list = [...expenses];

    // Filter by Month
    if (filterMonth.value.isNotEmpty) {
      list = list
          .where((exp) => exp.date.startsWith(filterMonth.value))
          .toList();
    }

    // Sort
    if (sortBy.value == 'date-desc') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else if (sortBy.value == 'date-asc') {
      list.sort((a, b) => a.date.compareTo(b.date));
    } else if (sortBy.value == 'amount-desc') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (sortBy.value == 'amount-asc') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return list;
  }

  double get totalFilteredSpent {
    return processedExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
  }

  double get totalAllTimeSpent {
    return expenses.fold(0.0, (sum, exp) => sum + exp.amount);
  }

  Future<bool> addExpense(
    String category,
    double amount,
    String date,
    String description,
  ) async {
    try {
      isLoading.value = true;
      final response = await ApiService.post(ApiConstants.expenses, {
        'category': category,
        'amount': amount,
        'date': date,
        'description': description,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchExpenses();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      isLoading.value = true;
      final response = await ApiService.delete('${ApiConstants.expenses}/$id');
      if (response.statusCode == 200) {
        await fetchExpenses();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    for (var exp in processedExpenses) {
      final cat = exp.category.trim();
      final capitalized = cat.isEmpty
          ? 'Other'
          : '${cat[0].toUpperCase()}${cat.substring(1)}';
      breakdown[capitalized] = (breakdown[capitalized] ?? 0.0) + exp.amount;
    }
    return breakdown;
  }
}
