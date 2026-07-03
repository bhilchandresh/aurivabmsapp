import 'package:flutter/material.dart';
import 'app_typography.dart';
import '../constants/app_colors.dart';

/// Provides convenient getters on BuildContext for faster UI development.
/// 
/// Instead of writing:
/// `Theme.of(context).extension<AppTypographyExtension>()!.invoiceAmount`
/// 
/// Developers can simply write:
/// `context.typography.invoiceAmount`
extension ThemeContextExtension on BuildContext {
  /// Access to business-specific semantic typography.
  AppTypographyExtension get typography {
    final extension = Theme.of(this).extension<AppTypographyExtension>();
    if (extension == null) {
      // Fallback in case the extension isn't registered properly, 
      // though it always should be in AppTheme.
      return Theme.of(this).brightness == Brightness.dark
          ? AppTypographyExtension.dark()
          : AppTypographyExtension.light();
    }
    return extension;
  }

  /// Access to custom semantic colors scheme extension.
  AppColorSchemeExtension get colorSchemeExtension {
    final extension = Theme.of(this).extension<AppColorSchemeExtension>();
    if (extension == null) {
      return Theme.of(this).brightness == Brightness.dark
          ? AppColorSchemeExtension.dark()
          : AppColorSchemeExtension.light();
    }
    return extension;
  }

  /// Access to standard Material 3 color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;


  // ---------------------------------------------------------------------------
  // LAYOUT HELPERS (Spacing, Radius, Shadows)
  // ---------------------------------------------------------------------------
  // Since spacing/radius weren't fully defined as classes yet, we provide 
  // standard getters here to enforce consistency across the app.

  /// Standard border radius for cards, dialogs, etc.
  BorderRadius get appRadius => BorderRadius.circular(16);
  
  /// Smaller border radius for inputs, buttons, chips.
  BorderRadius get appRadiusSmall => BorderRadius.circular(8);

  /// Standard shadow for elevated cards or floating elements.
  List<BoxShadow> get appShadows => [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ];
}

/// Semantic Color Scheme Theme Extension
/// This provides custom semantic color tokens that respond natively to Dark/Light themes.
class AppColorSchemeExtension extends ThemeExtension<AppColorSchemeExtension> {
  final Color borderColor;
  final Color dividerColor;
  final Color drawerBackground;
  final Color sidebarBackground;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;
  final Color cardBackground;
  final Color kpiCardBackground;

  const AppColorSchemeExtension({
    required this.borderColor,
    required this.dividerColor,
    required this.drawerBackground,
    required this.sidebarBackground,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.cardBackground,
    required this.kpiCardBackground,
  });

  factory AppColorSchemeExtension.light() {
    return const AppColorSchemeExtension(
      borderColor: AppColors.lightBorder,
      dividerColor: AppColors.lightBorder,
      drawerBackground: AppColors.lightSurface,
      sidebarBackground: AppColors.lightSurface,
      shimmerBase: Color(0xFFE2E8F0),
      shimmerHighlight: Color(0xFFF1F5F9),
      statusSuccess: AppColors.success,
      statusWarning: AppColors.warning,
      statusError: AppColors.error,
      statusInfo: AppColors.info,
      cardBackground: AppColors.lightCard,
      kpiCardBackground: AppColors.lightCard,
    );
  }

  factory AppColorSchemeExtension.dark() {
    return const AppColorSchemeExtension(
      borderColor: AppColors.darkBorder,
      dividerColor: AppColors.darkBorder,
      drawerBackground: AppColors.darkSurface,
      sidebarBackground: AppColors.darkSurface,
      shimmerBase: Color(0xFF1E293B),
      shimmerHighlight: Color(0xFF334155),
      statusSuccess: AppColors.success,
      statusWarning: AppColors.warning,
      statusError: AppColors.error,
      statusInfo: AppColors.info,
      cardBackground: AppColors.darkCard,
      kpiCardBackground: AppColors.darkCard,
    );
  }

  @override
  AppColorSchemeExtension copyWith({
    Color? borderColor,
    Color? dividerColor,
    Color? drawerBackground,
    Color? sidebarBackground,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? statusSuccess,
    Color? statusWarning,
    Color? statusError,
    Color? statusInfo,
    Color? cardBackground,
    Color? kpiCardBackground,
  }) {
    return AppColorSchemeExtension(
      borderColor: borderColor ?? this.borderColor,
      dividerColor: dividerColor ?? this.dividerColor,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
      statusInfo: statusInfo ?? this.statusInfo,
      cardBackground: cardBackground ?? this.cardBackground,
      kpiCardBackground: kpiCardBackground ?? this.kpiCardBackground,
    );
  }

  @override
  ThemeExtension<AppColorSchemeExtension> lerp(
    ThemeExtension<AppColorSchemeExtension>? other,
    double t,
  ) {
    if (other is! AppColorSchemeExtension) return this;
    return AppColorSchemeExtension(
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      drawerBackground: Color.lerp(drawerBackground, other.drawerBackground, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      kpiCardBackground: Color.lerp(kpiCardBackground, other.kpiCardBackground, t)!,
    );
  }
}
