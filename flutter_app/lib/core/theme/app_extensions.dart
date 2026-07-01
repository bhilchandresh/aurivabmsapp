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

  /// Access to standard Material 3 color scheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Access to standard Material 3 text theme.
  TextTheme get textTheme => Theme.of(this).textTheme;

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
