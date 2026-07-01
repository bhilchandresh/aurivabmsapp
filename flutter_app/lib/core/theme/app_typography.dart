import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class AppTypography {
  // ---------------------------------------------------------------------------
  // FONT FAMILY STRATEGY
  // ---------------------------------------------------------------------------
  // English: Inter
  // Gujarati: Hind Vadodara
  // Hindi/Marathi: Hind
  // Bengali: Hind Siliguri
  // Telugu: Hind Guntur
  // Tamil: Hind Madurai
  // ---------------------------------------------------------------------------
  static String? get fontFamily {
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

  // Helper method to create standard TextStyle with consistent font family
  static TextStyle _baseStyle(double size, FontWeight weight, [Color? color]) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // ---------------------------------------------------------------------------
  // MATERIAL 3 STANDARD TYPOGRAPHY
  // ---------------------------------------------------------------------------
  static TextStyle get displayLarge => _baseStyle(57, FontWeight.w400);
  static TextStyle get displayMedium => _baseStyle(45, FontWeight.w400);
  static TextStyle get displaySmall => _baseStyle(36, FontWeight.w400);

  static TextStyle get headlineLarge => _baseStyle(32, FontWeight.w600);
  static TextStyle get headlineMedium => _baseStyle(28, FontWeight.w600);
  static TextStyle get headlineSmall => _baseStyle(24, FontWeight.w600);

  static TextStyle get titleLarge => _baseStyle(22, FontWeight.w600);
  static TextStyle get titleMedium => _baseStyle(16, FontWeight.w600);
  static TextStyle get titleSmall => _baseStyle(14, FontWeight.w600);

  static TextStyle get bodyLarge => _baseStyle(16, FontWeight.w400);
  static TextStyle get bodyMedium => _baseStyle(14, FontWeight.w400);
  static TextStyle get bodySmall => _baseStyle(12, FontWeight.w400);

  static TextStyle get labelLarge => _baseStyle(14, FontWeight.w500);
  static TextStyle get labelMedium => _baseStyle(12, FontWeight.w500);
  static TextStyle get labelSmall => _baseStyle(11, FontWeight.w500);

  // ---------------------------------------------------------------------------
  // SEMANTIC TYPOGRAPHY (AurivaBMS Specific)
  // ---------------------------------------------------------------------------

  // Screen & Sections
  static TextStyle get screenTitle => headlineSmall;
  static TextStyle get sectionTitle => titleMedium;
  static TextStyle get cardTitle => titleSmall;
  static TextStyle get cardSubtitle => bodySmall.copyWith(color: AppColors.textSecondary);

  // Dashboard
  static TextStyle get dashboardValue => headlineMedium.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get dashboardLabel => labelMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get revenueValue => titleLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold);
  static TextStyle get profitValue => titleLarge.copyWith(fontWeight: FontWeight.bold);

  // Formatting
  static TextStyle get currencyText => titleMedium.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get percentageText => labelMedium.copyWith(fontWeight: FontWeight.w600);

  // Invoices & Quotes
  static TextStyle get invoiceTitle => titleLarge;
  static TextStyle get invoiceNumber => titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold);
  static TextStyle get invoiceAmount => titleMedium.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5);
  static TextStyle get clientName => titleSmall.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get statusLabel => labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5);

  // Tables
  static TextStyle get tableHeader => labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary);
  static TextStyle get tableCell => bodyMedium;

  // Navigation
  static TextStyle get navigationLabel => labelSmall;
  static TextStyle get drawerLabel => titleSmall;

  // Dialogs & Overlays
  static TextStyle get dialogTitle => titleLarge;
  static TextStyle get dialogContent => bodyMedium;
  static TextStyle get bottomSheetTitle => titleLarge;

  // Forms & Inputs
  static TextStyle get buttonText => labelLarge;
  static TextStyle get searchHint => bodyMedium.copyWith(color: Colors.grey);
  static TextStyle get inputLabel => labelMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get inputText => bodyMedium;
  static TextStyle get helperText => bodySmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get errorText => bodySmall.copyWith(color: AppColors.error);

  // States
  static TextStyle get emptyStateTitle => titleMedium.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get emptyStateDescription => bodyMedium.copyWith(color: AppColors.textSecondary);

  // Messages
  static TextStyle get successMessage => bodyMedium.copyWith(color: AppColors.success);
  static TextStyle get warningMessage => bodyMedium.copyWith(color: AppColors.warning);
  static TextStyle get infoMessage => bodyMedium.copyWith(color: Colors.blue);

  // Charts
  static TextStyle get chartLabel => bodySmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get chartValue => labelMedium.copyWith(fontWeight: FontWeight.w600);

  // Reports
  static TextStyle get reportTitle => titleLarge;
  static TextStyle get reportSubtitle => bodyMedium.copyWith(color: AppColors.textSecondary);

  // Profile & Settings
  static TextStyle get profileName => headlineSmall.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get profileRole => bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get settingsTitle => titleMedium.copyWith(fontWeight: FontWeight.w600);

  // Notifications
  static TextStyle get notificationTitle => titleSmall.copyWith(fontWeight: FontWeight.bold);
  static TextStyle get notificationSubtitle => bodySmall.copyWith(color: AppColors.textSecondary);

  // ---------------------------------------------------------------------------
  // THEME INTEGRATION EXPORTS
  // ---------------------------------------------------------------------------
  
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: Colors.black87),
        displayMedium: displayMedium.copyWith(color: Colors.black87),
        displaySmall: displaySmall.copyWith(color: Colors.black87),
        headlineLarge: headlineLarge.copyWith(color: Colors.black87),
        headlineMedium: headlineMedium.copyWith(color: Colors.black87),
        headlineSmall: headlineSmall.copyWith(color: Colors.black87),
        titleLarge: titleLarge.copyWith(color: Colors.black87),
        titleMedium: titleMedium.copyWith(color: Colors.black87),
        titleSmall: titleSmall.copyWith(color: Colors.black87),
        bodyLarge: bodyLarge.copyWith(color: Colors.black87),
        bodyMedium: bodyMedium.copyWith(color: Colors.black87),
        bodySmall: bodySmall.copyWith(color: Colors.black87),
        labelLarge: labelLarge.copyWith(color: Colors.black87),
        labelMedium: labelMedium.copyWith(color: Colors.black87),
        labelSmall: labelSmall.copyWith(color: Colors.black87),
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: Colors.white),
        displayMedium: displayMedium.copyWith(color: Colors.white),
        displaySmall: displaySmall.copyWith(color: Colors.white),
        headlineLarge: headlineLarge.copyWith(color: Colors.white),
        headlineMedium: headlineMedium.copyWith(color: Colors.white),
        headlineSmall: headlineSmall.copyWith(color: Colors.white),
        titleLarge: titleLarge.copyWith(color: Colors.white),
        titleMedium: titleMedium.copyWith(color: Colors.white),
        titleSmall: titleSmall.copyWith(color: Colors.white),
        bodyLarge: bodyLarge.copyWith(color: const Color(0xFFE2E8F0)),
        bodyMedium: bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
        bodySmall: bodySmall.copyWith(color: const Color(0xFF94A3B8)),
        labelLarge: labelLarge.copyWith(color: Colors.white),
        labelMedium: labelMedium.copyWith(color: Colors.white),
        labelSmall: labelSmall.copyWith(color: Colors.white),
      );
}
