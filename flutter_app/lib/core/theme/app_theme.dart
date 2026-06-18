import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        bodyLarge: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: Color(0xFF1E293B),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.heading2.copyWith(color: Colors.white),
        bodyLarge: AppTextStyles.body.copyWith(color: const Color(0xFFE2E8F0)),
        bodySmall: AppTextStyles.caption.copyWith(color: const Color(0xFF94A3B8)),
      ),
      useMaterial3: true,
    );
  }
}
