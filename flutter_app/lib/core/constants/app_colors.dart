import 'package:flutter/material.dart';

class AppColors {
  // Premium Brand Colors (Linear/Notion style)
  static const Color primary = Color(0xFF5E6AD2); // Indigo/Purple mix
  static const Color primaryDark = Color(0xFF4C55B5);
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  static const Color accent = Color(0xFF8B5CF6); // Violet 500

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D1117); // GitHub Dark background
  static const Color darkSurface = Color(0xFF161B22); // GitHub Dark surface
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500
  
  // Legacy mappings for backwards compatibility (used across the app)
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color border = lightBorder;
}
