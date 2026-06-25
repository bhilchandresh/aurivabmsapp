import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';
import '../models/super_admin_stats_model.dart';
import '../models/tenant_model.dart';

class SuperAdminDashboardController extends GetxController {
  var isLoading = true.obs;
  var tenantsList = <TenantModel>[].obs;
  var stats = Rxn<SuperAdminStatsModel>();
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final results = await Future.wait([
        ApiService.get('/auth/tenants'),
        ApiService.get('/auth/stats'),
      ]);

      final tenantsResponse = results[0];
      final statsResponse = results[1];

      if (tenantsResponse.statusCode == 200) {
        final data = jsonDecode(tenantsResponse.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          tenantsList.value = list
              .map((e) => TenantModel.fromJson(e))
              .where((t) => t.email.toLowerCase() != 'riva@auriva.in' && t.name.toLowerCase() != 'platform hq') // filter main admin
              .toList();
        }
      }

      if (statsResponse.statusCode == 200) {
        final data = jsonDecode(statsResponse.body);
        if (data['success'] == true && data['data'] != null) {
          stats.value = SuperAdminStatsModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      print("Error fetching super admin data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchTenantUsage(String tenantId) async {
    try {
      final response = await ApiService.get('/auth/tenants/$tenantId/usage');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      print("Error fetching tenant usage: $e");
    }
    return null;
  }

  Future<void> deleteCompany(String tenantId) async {
    try {
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final response = await ApiService.delete('/auth/tenants/$tenantId');
      if (Get.isDialogOpen ?? false) Get.back(); // close loading

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Company and all associated data deleted successfully', backgroundColor: Colors.green.shade100);
        fetchDashboardData(); // Refresh the list
      } else {
        Get.snackbar('Error', 'Failed to delete company', backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); // close loading
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.shade100);
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<TenantModel> get filteredTenants {
    if (searchQuery.value.isEmpty) {
      return tenantsList;
    }
    final q = searchQuery.value.toLowerCase();
    return tenantsList.where((t) => 
      t.name.toLowerCase().contains(q) ||
      t.email.toLowerCase().contains(q)
    ).toList();
  }
}
