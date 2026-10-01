import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_routes.dart';
import 'core/localization/app_translations.dart';

import 'package:get_storage/get_storage.dart';
import 'core/theme/theme_service.dart';
import 'core/services/notification_service.dart';

import 'core/di/dependency_injection.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/monitoring/monitoring_service.dart';
import 'core/monitoring/crash_service.dart';
import 'core/monitoring/analytics_service.dart';
import 'core/monitoring/performance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DependencyInjection.init();

  // Try initializing Firebase Core (gracefully falls back if config is missing)
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('[MONITORING] Firebase Core failed to initialize (Offline stub fallback): $e');
  }

  // Update initialization states of logging sub-services
  Get.find<CrashService>().setFirebaseInitialized(firebaseInitialized);
  Get.find<AnalyticsService>().setFirebaseInitialized(firebaseInitialized);
  Get.find<PerformanceService>().setFirebaseInitialized(firebaseInitialized);

  final monitoring = Get.find<MonitoringService>();

  // Attach global error boundaries
  FlutterError.onError = (FlutterErrorDetails details) {
    monitoring.recordError(details.exception, details.stack, reason: 'Global Flutter Error', fatal: true);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    monitoring.recordError(error, stack, reason: 'Platform Dispatcher Fatal Error', fatal: true);
    return true;
  };

  Get.put(ThemeService());

  // Initialize OneSignal Push Notifications asynchronously to prevent black screen
  NotificationService.init();

  // Set current locale in AppTheme so it is available before GetMaterialApp loads
  AppTheme.currentLocale = const Locale('en', 'US');

  runApp(const AurivaApp());
}

class AurivaApp extends StatelessWidget {
  const AurivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auriva-BMS',
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeService>().theme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final double scale = mediaQueryData.textScaler.scale(1.0).clamp(1.0, 1.15);
        final clampedTextScaler = TextScaler.linear(scale);
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
          child: child!,
        );
      },
    );
  }
}
