import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/api_service.dart';

class NotificationService {
  // Use the App ID provided by the user
  static const String _oneSignalAppId = "ae78db29-5631-45b0-b385-d288de528141";
  
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Remove this method to stop OneSignal Debugging
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    OneSignal.initialize(_oneSignalAppId);

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(settings: initializationSettings);

    // Request permissions
    await OneSignal.Notifications.requestPermission(true);

    if (Platform.isAndroid) {
      _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      _localNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Optional: Add listeners for notifications
    OneSignal.Notifications.addClickListener((event) {
      if (kDebugMode) {
        print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      if (kDebugMode) {
        print('NOTIFICATION WILL DISPLAY LISTENER CALLED WITH EVENT: $event');
      }
      // You can prevent the notification from displaying by calling event.preventDefault()
      // event.preventDefault();
    });

    // Listen for changes in the Push Subscription
    OneSignal.User.pushSubscription.addObserver((state) {
      if (kDebugMode) {
        print('PUSH SUBSCRIPTION STATE CHANGED: ${state.current.id}');
      }
      
      // If the subscription ID changes and we have it, register with backend immediately
      if (state.current.id?.isNotEmpty == true) {
         registerDeviceWithBackend();
      }
    });
  }

  static const MethodChannel _channel = MethodChannel('com.aurivabms.app/notifications');

  /// Shows a local notification in the system tray
  static Future<void> showLocalNotification({required int id, required String title, required String body}) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('showCustomNotification', {
          'id': id,
          'title': title,
          'body': body,
        });
      } else {
        const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails();
        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          iOS: iosPlatformChannelSpecifics,
        );
        
        await _localNotificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: platformChannelSpecifics,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing custom notification: $e');
      }
    }
  }

  /// Gets the OneSignal Player ID (Device Token)
  static String? getPlayerId() {
    return OneSignal.User.pushSubscription.id;
  }

  /// Sends the Player ID to the AurivaBMS backend
  static Future<void> registerDeviceWithBackend() async {
    final playerId = getPlayerId();
    if (playerId == null || playerId.isEmpty) {
      if (kDebugMode) {
        print('NotificationService: Player ID is null. Cannot register with backend.');
      }
      return;
    }

    String platform = 'web';
    if (!kIsWeb) {
      platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
    }

    try {
      final response = await ApiService.registerDeviceToken(playerId, platform);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('NotificationService: Device registered successfully with backend.');
        }
      } else {
        if (kDebugMode) {
          print('NotificationService: Failed to register device. Status code: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error registering device - $e');
      }
    }
  }

  /// Sets the OneSignal External ID and User Tags
  static void setExternalIdAndTags(String userId, String userEmail) {
    if (userId.isNotEmpty) {
      OneSignal.login(userId); // Sets the External ID
    }
    if (userEmail.isNotEmpty) {
      OneSignal.User.addTagWithKey("email", userEmail); // Adds a tag
    }
  }
}
