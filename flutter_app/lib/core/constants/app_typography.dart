import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Matching Tailwind default font (Inter) and sizing scale
  static TextStyle get heading1 => GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700); // text-3xl
  static TextStyle get heading2 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700); // text-2xl
  static TextStyle get heading3 => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600); // text-xl
  static TextStyle get bodyLarge => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w400); // text-lg
  static TextStyle get body => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400); // text-base
  static TextStyle get label => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500); // text-sm
  static TextStyle get caption => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400); // text-xs
}
