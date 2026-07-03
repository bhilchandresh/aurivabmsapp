import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/tenant_model.dart';
import '../../../core/utils/api_service.dart';
import '../dashboard/super_admin_dashboard_controller.dart';
import 'package:intl/intl.dart';

class SuperAdminEditCompanyController extends GetxController {
  final TenantModel tenant;

  SuperAdminEditCompanyController({required this.tenant});

  // Form Controllers
  late TextEditingController companyNameController;
  late TextEditingController adminEmailController;
  late TextEditingController phoneController;
  late TextEditingController websiteController;
  late TextEditingController addressController;
  late TextEditingController gstinController;

  // Observables
  var gstEnabled = false.obs;
  var accountStatus = 'Active'.obs;
  var subscriptionPlan = 'Starter'.obs;

  var validUntil = Rx<DateTime?>(null);
  var selectedDuration = 0.obs;
  final RxString invoiceTemplate = 'standard'.obs;
  final RxString quotationTemplate = 'standard'.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize with existing data
    companyNameController = TextEditingController(text: tenant.name);
    adminEmailController = TextEditingController(text: tenant.email);
    phoneController = TextEditingController(text: tenant.phone ?? '');
    websiteController = TextEditingController(text: tenant.website ?? '');
    addressController = TextEditingController(text: tenant.address ?? '');
    gstinController = TextEditingController(text: tenant.gstNumber ?? '');

    invoiceTemplate.value = tenant.templatePreference;
    quotationTemplate.value = tenant.quotationTemplate;

    gstEnabled.value = tenant.gstEnabled;
    accountStatus.value = tenant.status == 'active' ? 'Active' : 'Inactive';

    String planLabel = 'Starter';
    if (tenant.subscriptionPlan == 'premium') planLabel = 'Pro';
    if (tenant.subscriptionPlan == 'enterprise') planLabel = 'Business';
    subscriptionPlan.value = planLabel;

    validUntil.value = tenant.subscriptionEnd;
  }

  @override
  void onClose() {
    companyNameController.dispose();
    adminEmailController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    addressController.dispose();
    gstinController.dispose();
    super.onClose();
  }

  // Formatting helpers
  String get validityDateString {
    if (validUntil.value == null) return 'Not Set';
    return DateFormat('dd-MM-yyyy').format(validUntil.value!);
  }

  String get daysRemainingString {
    if (validUntil.value == null) return '0 Days Remaining';
    final diff = validUntil.value!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    return '$diff Days Remaining';
  }

  // Actions
  void resetAdminPassword() {
    final passwordController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('reset_admin_password'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('enter_a_new_password_for_this_company'.tr),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'new_password'.tr,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                Get.snackbar('Error', 'Password must be at least 6 characters');
                return;
              }
              Get.back();
              try {
                final response = await ApiService.put(
                  '/auth/tenants/${tenant.id}/password',
                  {'password': passwordController.text},
                );
                if (response.statusCode == 200) {
                  Get.snackbar(
                    'Success',
                    'Password reset successfully',
                    backgroundColor: Colors.green.shade100,
                  );
                } else {
                  throw Exception('Failed to reset password');
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  e.toString(),
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            child: Text('reset'.tr),
          ),
        ],
      ),
    );
  }

  void setSubscriptionDuration(int months) {
    selectedDuration.value = months;
    final now = DateTime.now();
    validUntil.value = DateTime(now.year, now.month + months, now.day);
  }

  void resetDefaultValidity() {
    validUntil.value = tenant.subscriptionEnd;
  }

  void applySystemChanges() async {
    isLoading.value = true;

    try {
      final payload = {
        'name': companyNameController.text.trim(),
        'email': adminEmailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'website': websiteController.text.trim(),
        'gstEnabled': gstEnabled.value,
        'gstNumber': gstinController.text.trim(),
        'status': accountStatus.value == 'Active' ? 'active' : 'inactive',
        'subscriptionPlan': subscriptionPlan.value
            .toLowerCase(), // basic, premium, enterprise... wait, web uses dropdown options.
        'subscriptionEnd': validUntil.value?.toIso8601String(),
        'templatePreference': invoiceTemplate.value,
        'quotationTemplate': quotationTemplate.value,
      };

      // backend might map 'starter' to 'basic', etc. let's just send what we have and let backend handle or send exact string.
      if (subscriptionPlan.value == 'Starter') {
        payload['subscriptionPlan'] = 'basic';
      }
      if (subscriptionPlan.value == 'Pro') {
        payload['subscriptionPlan'] = 'premium';
      }
      if (subscriptionPlan.value == 'Business') {
        payload['subscriptionPlan'] = 'enterprise';
      }

      final response = await ApiService.put(
        '/auth/tenants/${tenant.id}',
        payload,
      );

      if (response.statusCode == 200) {
        // Refresh dashboard
        if (Get.isRegistered<SuperAdminDashboardController>()) {
          Get.find<SuperAdminDashboardController>().fetchDashboardData();
        }

        Get.back();
        Get.snackbar(
          'Success',
          'Company details updated successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          margin: const EdgeInsets.all(16),
        );
      } else {
        throw Exception('Failed to update company');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
