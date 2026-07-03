import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';
import '../dashboard/super_admin_dashboard_controller.dart';

class SuperAdminAddCompanyController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final companyNameController = TextEditingController();
  final slugController = TextEditingController();
  final adminNameController = TextEditingController();
  final adminEmailController = TextEditingController();
  final passwordController = TextEditingController();

  var selectedPlan = 'basic'.obs;
  var validUntil = DateTime.now().add(const Duration(days: 365)).obs;

  var invoiceDesign = 'standard'.obs;
  var quotationDesign = 'standard'.obs;

  var isLoading = false.obs;
  bool _isSlugManuallyEdited = false;

  var selectedDuration = 12.obs;

  @override
  void onInit() {
    super.onInit();
    companyNameController.addListener(_onCompanyNameChanged);
  }

  void _onCompanyNameChanged() {
    if (!_isSlugManuallyEdited) {
      slugController.text = companyNameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
    }
  }

  void onSlugChangedManually() {
    _isSlugManuallyEdited = true;
  }

  @override
  void onClose() {
    companyNameController.dispose();
    slugController.dispose();
    adminNameController.dispose();
    adminEmailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void setSubscriptionDuration(int months) {
    selectedDuration.value = months;
    final now = DateTime.now();
    validUntil.value = DateTime(now.year, now.month + months, now.day);
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final payload = {
        'companyName': companyNameController.text.trim(),
        'slug': slugController.text.trim(),
        'name': adminNameController.text.trim(),
        'email': adminEmailController.text.trim(),
        'password': passwordController.text,
        'plan': selectedPlan.value,
        'subscriptionEnd': validUntil.value.toIso8601String(),
        'templatePreference': invoiceDesign.value,
        'quotationTemplate': quotationDesign.value,
      };

      final response = await ApiService.post('/auth/tenants', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'Company Created Successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          if (Get.isRegistered<SuperAdminDashboardController>()) {
            Get.find<SuperAdminDashboardController>().fetchDashboardData();
          }
          Get.back();
        } else {
          throw Exception(data['message'] ?? 'Failed to create company');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

//   void _resetForm() {
//     companyNameController.clear();
//     slugController.clear();
//     adminNameController.clear();
//     adminEmailController.clear();
//     passwordController.clear();
//     selectedPlan.value = 'basic';
//     validUntil.value = DateTime.now().add(const Duration(days: 365));
//     selectedDuration.value = 12;
//     invoiceDesign.value = 'standard';
//     quotationDesign.value = 'standard';
//   }
}
