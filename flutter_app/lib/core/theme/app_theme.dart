import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static Locale? currentLocale;

  static String? get _fontFamily {
    if (Get.locale?.languageCode == 'hi' || Get.locale?.languageCode == 'mr') {
      return GoogleFonts.hind().fontFamily;
    } else if (Get.locale?.languageCode == 'gu') {
      return GoogleFonts.hindVadodara().fontFamily;
    } else if (Get.locale?.languageCode == 'bn') {
      return GoogleFonts.hindSiliguri().fontFamily;
    } else if (Get.locale?.languageCode == 'te') {
      return GoogleFonts.hindGuntur().fontFamily;
    } else if (Get.locale?.languageCode == 'ta') {
      return GoogleFonts.hindMadurai().fontFamily;
    }
    return GoogleFonts.inter().fontFamily;
  }

  static ThemeData get lightTheme {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Dark text/icons for light background
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        surfaceContainerHighest: Color(0xFFF8FAFC),
        outline: Color(0xFFE2E8F0),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF0F172A),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        bodyLarge: AppTextStyles.body,
        bodyMedium: TextStyle(color: Color(0xFF64748B)),
        bodySmall: AppTextStyles.caption,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light, // Light text/icons for dark background
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF1E293B),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFF0F172A),
        outline: Color(0xFF334155),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E293B),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.heading2.copyWith(color: Colors.white),
        bodyLarge: AppTextStyles.body.copyWith(color: const Color(0xFFE2E8F0)),
        bodyMedium: const TextStyle(color: Color(0xFF94A3B8)),
        bodySmall: AppTextStyles.caption.copyWith(color: const Color(0xFF94A3B8)),
      ),
      useMaterial3: true,
    );
  }
}
