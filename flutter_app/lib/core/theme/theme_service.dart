import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  final _box = GetStorage();
  final _key = 'isDarkMode';
  
  // Reactive variable for theme state
  late final RxBool isDarkMode;

  ThemeService() {
    bool isDark = _box.read<bool>(_key) ?? false;
    isDarkMode = RxBool(isDark);
  }

  /// Get ThemeMode
  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// Switch theme and save to local storage
  void switchTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _box.write(_key, isDarkMode.value);
  }

  /// Explicitly set theme
  void setTheme(bool isDark) {
    isDarkMode.value = isDark;
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    _box.write(_key, isDark);
  }
}
