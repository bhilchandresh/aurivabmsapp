import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/notification_service.dart';
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

      final response = await ApiService.get(ApiConstants.notifications);
      debugPrint('Notification Fetch Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          notifications.value = list
              .map((json) => AppNotification.fromJson(json))
              .toList();
          _updateUnreadCount();
          await _showLocalNotificationsForUnread();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _showLocalNotificationsForUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Implement daily reset logic
      final today = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // "YYYY-MM-DD"
      final lastShownDate = prefs.getString('last_notification_shown_date');

      if (lastShownDate != today) {
        // First time opening app today: clear previously shown IDs
        await prefs.remove('shown_local_notifications');
        await prefs.setString('last_notification_shown_date', today);
      }

      List<String> shownIds =
          prefs.getStringList('shown_local_notifications') ?? [];

      bool updated = false;
      int localIdCounter = 1000; // start id offset to avoid collision

      for (var notif in notifications) {
        if (!notif.isRead && !shownIds.contains(notif.id)) {
          String title = 'AurivaBMS Alert';
          String body = notif.message;
          String? chipText;
          String illustrationType = 'envelope'; // Default is envelope

          final msgLower = notif.message.toLowerCase();
          if (msgLower.contains('payment') || msgLower.contains('received')) {
            title = 'Payment Received';
            illustrationType = 'invoice';
            
            if (notif.target.isNotEmpty && notif.target.contains('INV-')) {
              chipText = 'Invoice ${notif.target}';
            } else {
              final match = RegExp(r'INV-\d+-\d+').firstMatch(notif.message);
              if (match != null) {
                chipText = 'Invoice ${match.group(0)}';
              } else {
                chipText = 'Payment Details';
              }
            }
          } else if (msgLower.contains('login')) {
            title = 'Security Alert';
            illustrationType = 'lock';
            chipText = 'Login Security';
          } else if (msgLower.contains('invoice') || msgLower.contains('quotation')) {
            title = msgLower.contains('invoice') ? 'Invoice Alert' : 'Quotation Alert';
            illustrationType = 'invoice';
            if (notif.target.isNotEmpty && notif.target.contains('INV-')) {
              chipText = 'Invoice ${notif.target}';
            } else {
              final match = RegExp(r'INV-\d+-\d+').firstMatch(notif.message);
              if (match != null) {
                chipText = 'Invoice ${match.group(0)}';
              }
            }
          }

          // REMOVED: NotificationService.showLocalNotification(...)
          // Reason: OneSignal already handles remote push notifications natively. 
          // Firing a local notification here causes duplicate notifications in the system tray.
          shownIds.add(notif.id);
          updated = true;
        }
      }

      if (updated) {
        await prefs.setStringList('shown_local_notifications', shownIds);
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
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
        final response = await ApiService.put(
          '${ApiConstants.notifications}/$id/read',
          {},
        );
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
