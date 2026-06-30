import 'package:flutter/material.dart';
import '../constants/app_typography.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // Centralized text styles
  static TextStyle get heading1 =>
      AppTypography.heading1.copyWith(color: AppColors.textPrimary);
  static TextStyle get heading2 =>
      AppTypography.heading2.copyWith(color: AppColors.textPrimary);
  static TextStyle get heading3 =>
      AppTypography.heading3.copyWith(color: AppColors.textPrimary);
  static TextStyle get bodyLarge =>
      AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle get body =>
      AppTypography.body.copyWith(color: AppColors.textPrimary);
  static TextStyle get label =>
      AppTypography.label.copyWith(color: AppColors.textPrimary);
  static TextStyle get caption =>
      AppTypography.caption.copyWith(color: AppColors.textSecondary);
}
