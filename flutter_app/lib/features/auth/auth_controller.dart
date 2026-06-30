import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/notification_service.dart';
import '../../navigation/app_routes.dart';

class AuthController extends GetxController {
  final _storage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var token = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userRole = ''.obs;
  var userId = ''.obs;
  var userSignature = ''.obs;
  var tenantInfo = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final savedToken = await _storage.read(key: 'auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      token.value = savedToken;
      userName.value = await _storage.read(key: 'user_name') ?? '';
      userEmail.value = await _storage.read(key: 'user_email') ?? '';
      userRole.value = await _storage.read(key: 'user_role') ?? '';
      userId.value = await _storage.read(key: 'user_id') ?? '';
      userSignature.value = await _storage.read(key: 'user_signature') ?? '';
      fetchTenantSettings();

      // Register Device for Push Notifications
      NotificationService.registerDeviceWithBackend();
      NotificationService.setExternalIdAndTags(userId.value, userEmail.value);

      // Auto login and navigate to main dashboard only if we are currently on the login or root screen
      if (Get.currentRoute == AppRoutes.login ||
          Get.currentRoute == '/' ||
          Get.currentRoute.isEmpty) {
        // Handled by splash screen or manual check now to avoid race conditions
      }
    }
  }

  Future<void> determineInitialRoute() async {
    await checkLoginStatus();

    // Add a small delay to allow splash animation to show
    await Future.delayed(const Duration(seconds: 2));

    final hasSeenOnboarding = await _storage.read(key: 'has_seen_onboarding');

    if (hasSeenOnboarding != 'true') {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (token.value.isNotEmpty) {
      if (userRole.value.toLowerCase().contains('superadmin') ||
          userRole.value.toLowerCase().contains('super_admin') ||
          userEmail.value.toLowerCase() == 'riva@auriva.in') {
        Get.offAllNamed(AppRoutes.superAdminMain);
      } else {
        Get.offAllNamed(AppRoutes.main);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.write(key: 'has_seen_onboarding', value: 'true');
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> fetchTenantSettings() async {
    if (token.isEmpty) return;
    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.settings),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token.value}',
            },
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        tenantInfo.value = data['data'];
      }
    } catch (e) {
      // Silently ignore
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await http
          .post(
            Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);

      debugPrint("============== LIVE SERVER LOGIN LOGS ==============");
      debugPrint("URL: ${ApiConstants.baseUrl + ApiConstants.login}");
      debugPrint("Email sent: $email");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("====================================================");

      if (response.statusCode == 200 && data['success'] == true) {
        final authToken = data['token'];
        final user = data['user'];

        token.value = authToken;
        userName.value = user['name'] ?? '';
        userEmail.value = user['email'] ?? '';
        userRole.value = user['role'] ?? '';
        userId.value = user['_id'] ?? '';
        userSignature.value = user['signatureImage'] ?? '';

        // Save locally for persistence
        await _storage.write(key: 'auth_token', value: authToken);
        await _storage.write(key: 'user_name', value: user['name'] ?? '');
        await _storage.write(key: 'user_email', value: user['email'] ?? '');
        await _storage.write(key: 'user_role', value: user['role'] ?? '');
        await _storage.write(key: 'user_id', value: userId.value);
        await _storage.write(key: 'user_signature', value: userSignature.value);

        await fetchTenantSettings();

        // Register Device for Push Notifications
        NotificationService.registerDeviceWithBackend();
        NotificationService.setExternalIdAndTags(userId.value, userEmail.value);

        // Request essential permissions on login
        try {
          await [
            Permission.notification,
            Permission.camera,
            Permission.storage,
            Permission.sms,
            Permission.phone,
            Permission.contacts,
          ].request();
        } catch (e) {
          debugPrint('Error requesting permissions: $e');
        }

        Fluttertoast.showToast(
          msg: "Welcome back, ${user['name']}!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFF10B981),
          textColor: Colors.white,
          fontSize: 14.0,
        );

        if (userRole.value.toLowerCase().contains('superadmin') ||
            userRole.value.toLowerCase().contains('super_admin') ||
            userEmail.value.toLowerCase() == 'riva@auriva.in') {
          Get.offAllNamed(AppRoutes.superAdminMain);
        } else {
          Get.offAllNamed(AppRoutes.main);
        }
        return true;
      } else {
        final msg = data['message'] ?? 'Invalid credentials';
        Fluttertoast.showToast(
          msg: msg,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Color(0xFFEF4444),
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg:
            "Connection Failed: Please ensure server is running and accessible.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(0xFFEF4444),
        textColor: Colors.white,
        fontSize: 14.0,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    token.value = '';
    userName.value = '';
    userEmail.value = '';
    userRole.value = '';
    userId.value = '';
    userSignature.value = '';
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_signature');
    await _storage.delete(key: 'app_lang_code');
    await _storage.delete(key: 'app_country_code');

    // Reset locale to English
    Get.updateLocale(const Locale('en', 'US'));

    // Log out from OneSignal
    OneSignal.logout();

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> updateSignatureLocal(String signatureBase64) async {
    userSignature.value = signatureBase64;
    await _storage.write(key: 'user_signature', value: signatureBase64);
  }
}
