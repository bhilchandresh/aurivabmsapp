import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:get/get.dart';

class AppTypography {
  // Helper to determine if we should use Hind font
  static TextStyle _getFont({required double fontSize, required FontWeight fontWeight}) {
    if (Get.locale?.languageCode == 'hi' || Get.locale?.languageCode == 'mr') {
      return GoogleFonts.hind(fontSize: fontSize, fontWeight: fontWeight);
    } else if (Get.locale?.languageCode == 'gu') {
      return GoogleFonts.hindVadodara(fontSize: fontSize, fontWeight: fontWeight);
    } else if (Get.locale?.languageCode == 'bn') {
      return GoogleFonts.hindSiliguri(fontSize: fontSize, fontWeight: fontWeight);
    } else if (Get.locale?.languageCode == 'te') {
      return GoogleFonts.hindGuntur(fontSize: fontSize, fontWeight: fontWeight);
    } else if (Get.locale?.languageCode == 'ta') {
      return GoogleFonts.hindMadurai(fontSize: fontSize, fontWeight: fontWeight);
    }
    return TextStyle(fontSize: fontSize, fontWeight: fontWeight);
  }

  // Matching Tailwind default font and sizing scale
  static TextStyle get heading1 => _getFont(fontSize: 30, fontWeight: FontWeight.w700); // text-3xl
  static TextStyle get heading2 => _getFont(fontSize: 24, fontWeight: FontWeight.w700); // text-2xl
  static TextStyle get heading3 => _getFont(fontSize: 20, fontWeight: FontWeight.w600); // text-xl
  static TextStyle get bodyLarge => _getFont(fontSize: 18, fontWeight: FontWeight.w400); // text-lg
  static TextStyle get body => _getFont(fontSize: 16, fontWeight: FontWeight.w400); // text-base
  static TextStyle get label => _getFont(fontSize: 14, fontWeight: FontWeight.w500); // text-sm
  static TextStyle get caption => _getFont(fontSize: 12, fontWeight: FontWeight.w400); // text-xs
}
