import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class AppTypography {
  /// Returns 'serif' for Latin languages, null for Indic languages.
  /// When null, Flutter uses the locale-appropriate system font.
  static String? get serifFontFamily {
    final lang =
        AppTheme.currentLocale?.languageCode ?? Get.locale?.languageCode;
    if (lang == 'hi' || lang == 'mr') {
      return GoogleFonts.hind().fontFamily;
    } else if (lang == 'gu') {
      return GoogleFonts.hindVadodara().fontFamily;
    } else if (lang == 'bn') {
      return GoogleFonts.hindSiliguri().fontFamily;
    } else if (lang == 'te') {
      return GoogleFonts.hindGuntur().fontFamily;
    } else if (lang == 'ta') {
      return GoogleFonts.hindMadurai().fontFamily;
    }
    const indicLanguages = {'ur', 'kn', 'or', 'ml'};
    if (lang != null && indicLanguages.contains(lang)) {
      return null; // Let system fonts handle these
    }
    return GoogleFonts.inter().fontFamily;
  }

  // Helper to determine if we should use Hind font
  static TextStyle _getFont({
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final lang =
        AppTheme.currentLocale?.languageCode ?? Get.locale?.languageCode;
    if (lang == 'hi' || lang == 'mr') {
      return GoogleFonts.hind(fontSize: fontSize, fontWeight: fontWeight);
    } else if (lang == 'gu') {
      return GoogleFonts.hindVadodara(
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
    } else if (lang == 'bn') {
      return GoogleFonts.hindSiliguri(
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
    } else if (lang == 'te') {
      return GoogleFonts.hindGuntur(fontSize: fontSize, fontWeight: fontWeight);
    } else if (lang == 'ta') {
      return GoogleFonts.hindMadurai(
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
    }
    return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight);
  }

  // Matching Tailwind default font and sizing scale
  static TextStyle get heading1 =>
      _getFont(fontSize: 30, fontWeight: FontWeight.w700); // text-3xl
  static TextStyle get heading2 =>
      _getFont(fontSize: 24, fontWeight: FontWeight.w700); // text-2xl
  static TextStyle get heading3 =>
      _getFont(fontSize: 20, fontWeight: FontWeight.w600); // text-xl
  static TextStyle get bodyLarge =>
      _getFont(fontSize: 18, fontWeight: FontWeight.w400); // text-lg
  static TextStyle get body =>
      _getFont(fontSize: 16, fontWeight: FontWeight.w400); // text-base
  static TextStyle get label =>
      _getFont(fontSize: 14, fontWeight: FontWeight.w500); // text-sm
  static TextStyle get caption =>
      _getFont(fontSize: 12, fontWeight: FontWeight.w400); // text-xs
}
