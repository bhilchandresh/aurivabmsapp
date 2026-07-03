// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';

class SuperAdminBroadcastController extends GetxController {
  final messageController = TextEditingController();
  var selectedType = 'info'.obs;
  var isLoading = false.obs;

  // SMTP Config state
  var smtpHostController = TextEditingController();
  var smtpPortController = TextEditingController();
  var smtpUserController = TextEditingController();
  var smtpPassController = TextEditingController();

  var isSmtpLoading = false.obs;
  var isSmtpSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSmtpConfig();
  }

  @override
  void onClose() {
    messageController.dispose();
    smtpHostController.dispose();
    smtpPortController.dispose();
    smtpUserController.dispose();
    smtpPassController.dispose();
    super.onClose();
  }

  Future<void> sendBroadcast() async {
    final message = messageController.text.trim();
    if (message.isEmpty) {
      Get.snackbar(
        'Error',
        'Message content is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final payload = {
        'message': message,
        'type': selectedType.value,
        'target': 'all_admins',
      };

      final response = await ApiService.post('/notifications', payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'Notification broadcasted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // Reset form
          messageController.clear();
          selectedType.value = 'info';
        } else {
          throw Exception(data['message'] ?? 'Failed to broadcast');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSmtpConfig() async {
    try {
      isSmtpLoading.value = true;
      final response = await ApiService.get('/settings');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final settings = data['data'] as Map<String, dynamic>;
          smtpHostController.text = settings['SMTP_HOST'] ?? '';
          smtpPortController.text = settings['SMTP_PORT'] ?? '';
          smtpUserController.text = settings['SMTP_USER'] ?? '';
          smtpPassController.text = settings['SMTP_PASS'] ?? '';
        }
      }
    } catch (e) {
      print('Error fetching SMTP settings: $e');
    } finally {
      isSmtpLoading.value = false;
    }
  }

  Future<void> saveSmtpConfig() async {
    final host = smtpHostController.text.trim();
    final port = smtpPortController.text.trim();
    final user = smtpUserController.text.trim();
    final pass = smtpPassController.text.trim();

    if (host.isEmpty || port.isEmpty || user.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required SMTP fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isSmtpSaving.value = true;
      final payload = {
        'SMTP_HOST': host,
        'SMTP_PORT': port,
        'SMTP_USER': user,
        if (pass.isNotEmpty) 'SMTP_PASS': pass,
      };

      final response = await ApiService.put('/settings', payload);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'SMTP Configuration saved successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to save settings');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSmtpSaving.value = false;
    }
  }
}
