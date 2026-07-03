// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:get/get.dart';
import '../../../core/utils/api_service.dart';

class SuperAdminNotificationsController extends GetxController {
  var isLoading = true.obs;
  var notifications = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    try {
      if (!isRefresh) isLoading.value = true;
      final response = await ApiService.get('/notifications');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          notifications.value = data['data'];
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id, int index) async {
    // Optimistic update
    final notif = notifications[index];
    if (notif['isRead'] == true) return;

    final updatedNotif = Map<String, dynamic>.from(notif);
    updatedNotif['isRead'] = true;
    notifications[index] = updatedNotif;

    try {
      await ApiService.put('/notifications/$id/read', {});
    } catch (e) {
      // Revert on error
      notifications[index] = notif;
      print('Error marking notification as read: $e');
    }
  }
}
