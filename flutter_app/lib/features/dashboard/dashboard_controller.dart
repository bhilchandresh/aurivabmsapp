import 'package:get/get.dart';
import 'dart:convert';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardController extends GetxController {
  final isLoading = true.obs;
  
  // Visibility State
  final isAmountsVisible = true.obs;

  // Stats
  final totalRevenue = 0.0.obs;
  final totalExpenses = 0.0.obs;
  final totalPurchases = 0.0.obs;
  final netProfit = 0.0.obs;
  final totalPendingAmount = 0.0.obs;
  final totalInvoices = 0.obs;
  final paidInvoices = 0.obs;
  final pendingCount = 0.obs;

  // Recent Items
  final recentInvoices = <Map<String, dynamic>>[].obs;
  final recentExpenses = <Map<String, dynamic>>[].obs;

  // Chart Data
  final chartDataMonthly = <Map<String, dynamic>>[].obs;
  final chartDataYearly = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    try {
      isLoading(true);
      final response = await ApiService.get(ApiConstants.dashboardStats);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          final stats = data['stats'] ?? {};
        totalRevenue.value = (stats['totalRevenue'] ?? 0).toDouble();
        totalExpenses.value = (stats['totalExpenses'] ?? 0).toDouble();
        totalPurchases.value = (stats['totalPurchases'] ?? 0).toDouble();
        netProfit.value = (stats['netProfit'] ?? 0).toDouble();
        totalPendingAmount.value = (stats['totalPendingAmount'] ?? 0).toDouble();
        totalInvoices.value = stats['totalInvoices'] ?? 0;
        paidInvoices.value = stats['paidInvoices'] ?? 0;
        pendingCount.value = stats['pendingCount'] ?? 0;

        final invoicesList = List<Map<String, dynamic>>.from(data['recentInvoices'] ?? []);
        invoicesList.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? a['date']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? b['date']?.toString() ?? '';
          final int comp = dateB.compareTo(dateA);
          if (comp == 0) {
            final invA = a['invoiceNumber']?.toString() ?? '';
            final invB = b['invoiceNumber']?.toString() ?? '';
            return invB.compareTo(invA);
          }
          return comp;
        });
        recentInvoices.assignAll(invoicesList);
        
        final expensesList = List<Map<String, dynamic>>.from(data['recentExpenses'] ?? []);
        expensesList.sort((a, b) {
          final dateA = a['createdAt']?.toString() ?? a['date']?.toString() ?? '';
          final dateB = b['createdAt']?.toString() ?? b['date']?.toString() ?? '';
          return dateB.compareTo(dateA); // Sort descending by date
        });
        recentExpenses.assignAll(expensesList);
        
        chartDataMonthly.assignAll(List<Map<String, dynamic>>.from(data['chartDataMonthly'] ?? []));
        chartDataYearly.assignAll(List<Map<String, dynamic>>.from(data['chartDataYearly'] ?? []));
        }
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    } finally {
      isLoading(false);
    }
  }
}
