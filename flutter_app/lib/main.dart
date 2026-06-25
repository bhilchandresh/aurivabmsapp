import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_routes.dart';
import 'core/localization/app_translations.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize OneSignal Push Notifications asynchronously to prevent black screen
  NotificationService.init();

  // Load saved language
  const storage = FlutterSecureStorage();
  final savedLangCode = await storage.read(key: 'app_lang_code');
  final savedCountryCode = await storage.read(key: 'app_country_code');
  
  Locale initialLocale = Get.deviceLocale ?? const Locale('en', 'US');
  if (savedLangCode != null && savedLangCode.isNotEmpty) {
    initialLocale = Locale(savedLangCode, savedCountryCode ?? '');
  }

  runApp(ProviderScope(child: AurivaApp(initialLocale: initialLocale)));
}

class AurivaApp extends StatelessWidget {
  final Locale initialLocale;
  const AurivaApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Auriva-BMS',
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
