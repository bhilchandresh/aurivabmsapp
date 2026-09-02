import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PermissionManager {
  static Future<bool> _requestPermission(Permission permission, String name, {bool showSettingsOnDenied = true}) async {
    if (kIsWeb) return true;

    var status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (showSettingsOnDenied) _showSettingsDialog(name);
      return false;
    }

    status = await permission.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (showSettingsOnDenied) _showSettingsDialog(name);
    } else {
      if (showSettingsOnDenied) Fluttertoast.showToast(msg: "$name permission denied");
    }
    return false;
  }

  static void _showSettingsDialog(String permissionName) {
    if (Get.context != null) {
      Get.dialog(
        AlertDialog(
          title: const Text('Permission Required'),
          content: Text('This feature requires $permissionName permission. Please enable it in the app settings.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Please enable $permissionName permission in settings.");
    }
  }

  static Future<bool> requestCameraPermission() async {
    return await _requestPermission(Permission.camera, 'Camera');
  }

  static Future<bool> requestGalleryPermission() async {
    if (kIsWeb) return true;
    // Android 13+ use photos/media permissions, older uses storage
    final bool photoStatus = await _requestPermission(Permission.photos, 'Gallery');
    if (photoStatus) return true;
    
    return await _requestPermission(Permission.storage, 'Storage');
  }

  static Future<bool> requestStoragePermission() async {
    return await _requestPermission(Permission.storage, 'Storage');
  }

  static Future<bool> requestNotificationWithExplanationDialog() async {
    if (kIsWeb) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) {
      await OneSignal.Notifications.requestPermission(true);
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showSettingsDialog('Notifications');
      return false;
    }

    final box = GetStorage();
    final hasRequested = box.read('has_requested_notification') ?? false;

    // Only show our custom explanation once to avoid spamming the user
    if (hasRequested && status.isDenied) {
        return false;
    }

    if (Get.context != null) {
      final bool? userAgreed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Stay Updated'),
          content: const Text(
            'Enable notifications to receive invoice reminders, payment reminders, and important business alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      // Save that we have shown the prompt so we don't bother them again
      await box.write('has_requested_notification', true);

      if (userAgreed == true) {
        final newStatus = await Permission.notification.request();
        if (newStatus.isGranted) {
          await OneSignal.Notifications.requestPermission(true);
          return true;
        } else if (newStatus.isPermanentlyDenied) {
           _showSettingsDialog('Notifications');
        }
      }
    }
    return false;
  }
}
