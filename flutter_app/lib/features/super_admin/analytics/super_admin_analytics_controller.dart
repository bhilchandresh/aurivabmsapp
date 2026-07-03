// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';

class SuperAdminAnalyticsController extends GetxController {
  var isLoading = true.obs;
  var isFirstLoad = true.obs;

  // Dashboard Metrics
  var platformGMV = 0.0.obs;
  var invoicesProcessed = 0.obs;
  var endClientsManaged = 0.obs;

  // Chart Data
  var growthData = <dynamic>[].obs;
  var planDistribution = <dynamic>[].obs;
  var featureAdoption = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics({bool isRefresh = false}) async {
    try {
      isLoading.value = true;
      final response = await ApiService.get('/auth/stats');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final stats = data['data'];

          platformGMV.value = (stats['platformGMV'] ?? 0).toDouble();
          invoicesProcessed.value = stats['platformInvoicesCount'] ?? 0;
          endClientsManaged.value = stats['platformClientsCount'] ?? 0;

          growthData.value = stats['growthData'] ?? [];
          planDistribution.value = stats['planDistribution'] ?? [];
          featureAdoption.value = stats['featureAdoption'] ?? [];
        }
      } else {
        print('Error fetching analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetching analytics: $e');
    } finally {
      isLoading.value = false;
      isFirstLoad.value = false;
    }
  }
}
