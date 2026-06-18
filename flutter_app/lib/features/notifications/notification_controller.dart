import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import 'notification_model.dart';
import '../auth/auth_controller.dart';

class NotificationController extends GetxController {
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    ever(authController.token, (String tokenStr) {
      if (tokenStr.isNotEmpty) {
        fetchNotifications();
        _startPolling();
      } else {
        _stopPolling();
        notifications.clear();
        unreadCount.value = 0;
      }
    });

    if (authController.token.value.isNotEmpty) {
      fetchNotifications();
      _startPolling();
    }
  }

  @override
  void onClose() {
    _stopPolling();
    super.onClose();
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchNotifications();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications() async {
    try {
      if (notifications.isEmpty) isLoading.value = true;
      
      final response = await ApiService.get('${ApiConstants.baseUrl}/notifications');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          notifications.value = list.map((json) => AppNotification.fromJson(json)).toList();
          _updateUnreadCount();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !notifications[index].isRead) {
      final updatedNotif = notifications[index].copyWith(isRead: true);
      notifications[index] = updatedNotif;
      _updateUnreadCount();

      try {
        final response = await ApiService.put('${ApiConstants.baseUrl}/notifications/$id/read', {});
        if (response.statusCode != 200) {
          // Revert if failed
          notifications[index] = updatedNotif.copyWith(isRead: false);
          _updateUnreadCount();
        }
      } catch (e) {
        // Revert if failed
        notifications[index] = updatedNotif.copyWith(isRead: false);
        _updateUnreadCount();
        debugPrint('Failed to mark notification as read: $e');
      }
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
}

