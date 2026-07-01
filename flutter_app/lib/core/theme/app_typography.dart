import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

/// Centralized Typography system for AurivaBMS.
class AppTypography {
  // ---------------------------------------------------------------------------
  // FONT FAMILY STRATEGY
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

  static TextStyle _baseStyle(double size, FontWeight weight, [Color? color]) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // Material 3 Base Specifications
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

  // Material 3 TextThemes (Export for app_theme.dart)
  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.lightTextPrimary),
        displayMedium: displayMedium.copyWith(color: AppColors.lightTextPrimary),
        displaySmall: displaySmall.copyWith(color: AppColors.lightTextPrimary),
        headlineLarge: headlineLarge.copyWith(color: AppColors.lightTextPrimary),
        headlineMedium: headlineMedium.copyWith(color: AppColors.lightTextPrimary),
        headlineSmall: headlineSmall.copyWith(color: AppColors.lightTextPrimary),
        titleLarge: titleLarge.copyWith(color: AppColors.lightTextPrimary),
        titleMedium: titleMedium.copyWith(color: AppColors.lightTextPrimary),
        titleSmall: titleSmall.copyWith(color: AppColors.lightTextPrimary),
        bodyLarge: bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium: bodyMedium.copyWith(color: AppColors.lightTextPrimary),
        bodySmall: bodySmall.copyWith(color: AppColors.lightTextPrimary),
        labelLarge: labelLarge.copyWith(color: AppColors.lightTextPrimary),
        labelMedium: labelMedium.copyWith(color: AppColors.lightTextPrimary),
        labelSmall: labelSmall.copyWith(color: AppColors.lightTextPrimary),
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.darkTextPrimary),
        displayMedium: displayMedium.copyWith(color: AppColors.darkTextPrimary),
        displaySmall: displaySmall.copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: headlineLarge.copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: headlineMedium.copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: headlineSmall.copyWith(color: AppColors.darkTextPrimary),
        titleLarge: titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: titleMedium.copyWith(color: AppColors.darkTextPrimary),
        titleSmall: titleSmall.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge: bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        bodySmall: bodySmall.copyWith(color: AppColors.darkTextSecondary),
        labelLarge: labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: labelMedium.copyWith(color: AppColors.darkTextPrimary),
        labelSmall: labelSmall.copyWith(color: AppColors.darkTextPrimary),
      );
}

/// Semantic Typography Theme Extension
/// This provides business-specific typography that responds natively to Dark/Light themes.
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  // ---------------------------------------------------------------------------
  // LAYOUT & STRUCTURE
  // ---------------------------------------------------------------------------
  /// Use for: Main screen headers (e.g., "Dashboard", "Invoices").
  /// Do NOT use for: Dialog titles or Card headers.
  final TextStyle screenTitle;

  /// Use for: Distinct sections within a scrolling screen.
  /// Do NOT use for: Titles inside a Card widget.
  final TextStyle sectionTitle;

  /// Use for: The main title of a card (e.g., "Recent Activity").
  /// Do NOT use for: Full screen titles.
  final TextStyle cardTitle;

  /// Use for: Descriptive text immediately below a Card title.
  /// Do NOT use for: General body paragraphs.
  final TextStyle cardSubtitle;

  // ---------------------------------------------------------------------------
  // CARD & KPI TYPOGRAPHY
  // ---------------------------------------------------------------------------
  /// Use for: High-level KPI values in cards (size 24, w900).
  /// Do NOT use for: Invoice list totals or screen headers.
  final TextStyle kpiValue;

  /// Use for: Descriptive labels above or below KPI values (size 12, bold, letterSpacing 1.0).
  /// Do NOT use for: Form inputs labels.
  final TextStyle kpiLabel;

  /// Use for: Main statistic display numbers (size 24, bold).
  /// Do NOT use for: Table headers.
  final TextStyle statisticValue;

  /// Use for: Labels describing a statistic (size 12, bold, letterSpacing 1.0, uppercase).
  /// Do NOT use for: Table values.
  final TextStyle statisticLabel;

  /// Use for: Secondary descriptive paragraph text inside a card.
  /// Do NOT use for: Form hints or warning messages.
  final TextStyle cardDescription;

  /// Use for: Small caption or detail text at the bottom of a card.
  /// Do NOT use for: Main paragraph text.
  final TextStyle cardCaption;

  /// Use for: Card footers or action label text at the bottom.
  /// Do NOT use for: Main button text.
  final TextStyle cardFooter;

  /// Use for: Trend indicators, positive/negative changes (size 12, bold).
  /// Do NOT use for: Status labels.
  final TextStyle trendText;

  // ---------------------------------------------------------------------------
  // NAVIGATION & APP BAR TYPOGRAPHY
  // ---------------------------------------------------------------------------
  /// Use for: Main app bar title (size 20, bold, letterSpacing -0.5).
  /// Do NOT use for: Screen titles or section titles.
  final TextStyle topBarTitle;

  /// Use for: Subtitle inside app bar (size 11, w500).
  /// Do NOT use for: Badge labels.
  final TextStyle topBarSubtitle;

  /// Use for: Tiny status indicators, like "SYSTEM LIVE" (size 10, bold, letterSpacing -0.5).
  /// Do NOT use for: Main status badges.
  final TextStyle liveIndicator;

  /// Use for: Tiny role badge texts (size 10, w900).
  /// Do NOT use for: Button labels.
  final TextStyle roleBadgeText;

  /// Use for: Notification count badge text inside app bar (size 8, bold).
  /// Do NOT use for: Card subtitles.
  final TextStyle badgeCountText;

  /// Use for: Profile avatar fallback letters (size 16, w900).
  /// Do NOT use for: General titles.
  final TextStyle avatarLetter;

  // ---------------------------------------------------------------------------
  // DASHBOARD & ANALYTICS
  // ---------------------------------------------------------------------------
  /// Use for: Hero-sized total numbers on the Dashboard.
  /// Do NOT use for: Values inside standard lists or tables.
  final TextStyle dashboardValue;

  /// Use for: The descriptive label above/below a dashboard value (e.g., "Total Revenue").
  /// Do NOT use for: Form input labels.
  final TextStyle dashboardLabel;

  /// Use for: Top-level revenue numbers. Styled for success/growth.
  /// Do NOT use for: Small line-item amounts.
  final TextStyle revenueValue;

  /// Use for: Top-level profit numbers.
  /// Do NOT use for: Standard currency display.
  final TextStyle profitValue;

  /// Use for: Specifically highlighting a successful/positive financial amount.
  /// Do NOT use for: Standard invoice totals.
  final TextStyle successAmount;

  /// Use for: Specifically highlighting a financial loss or negative growth.
  /// Do NOT use for: Deletion warnings.
  final TextStyle lossAmount;

  /// Use for: Pending or outstanding payment amounts (usually warning/amber).
  /// Do NOT use for: Profit values.
  final TextStyle outstandingAmount;

  /// Use for: Tax breakdown values (GST/IGST).
  /// Do NOT use for: Grand totals.
  final TextStyle taxAmount;

  /// Use for: Discount breakdown values.
  /// Do NOT use for: Standard body text.
  final TextStyle discountAmount;

  // ---------------------------------------------------------------------------
  // INVOICES & SALES
  // ---------------------------------------------------------------------------
  /// Use for: The large header on an Invoice Details screen.
  /// Do NOT use for: Invoice list item titles.
  final TextStyle invoiceTitle;

  /// Use for: Displaying the unique Invoice ID (e.g., "INV-2026-001").
  /// Do NOT use for: Other generic IDs.
  final TextStyle invoiceNumber;

  /// Use for: The grand total amount of an invoice.
  /// Do NOT use for: Subtotals or individual item prices.
  final TextStyle invoiceAmount;

  /// Use for: General currency formatting outside of Dashboard/Invoices.
  /// Do NOT use for: Non-financial numbers.
  final TextStyle currencyText;

  /// Use for: Discount rates, GST percentages, tax rates.
  /// Do NOT use for: Standard counts.
  final TextStyle percentageText;

  /// Use for: Name of the client in lists or detail views.
  /// Do NOT use for: The current user's profile name.
  final TextStyle clientName;

  /// Use for: Client company name specifically.
  /// Do NOT use for: Contact person name.
  final TextStyle clientCompany;

  /// Use for: Supplier company name specifically.
  /// Do NOT use for: Client company.
  final TextStyle supplierCompany;

  /// Use for: Standard status badges (e.g., "Pending", "Paid").
  /// Do NOT use for: Button text.
  final TextStyle statusLabel;

  /// Use for: The specific status of an invoice.
  /// Do NOT use for: Inventory statuses.
  final TextStyle invoiceStatus;

  /// Use for: The specific status of a payment/transaction.
  /// Do NOT use for: Invoice statuses.
  final TextStyle paymentStatus;

  /// Use for: Due dates on invoices or bills.
  /// Do NOT use for: Creation dates.
  final TextStyle dueDate;

  // ---------------------------------------------------------------------------
  // INVENTORY & TABLES
  // ---------------------------------------------------------------------------
  /// Use for: The available stock count of an item.
  /// Do NOT use for: Financial amounts.
  final TextStyle stockCount;

  /// Use for: The header row of any data table.
  /// Do NOT use for: Standard list view titles.
  final TextStyle tableHeader;

  /// Use for: The data cells inside any data table.
  /// Do NOT use for: Paragraph text.
  final TextStyle tableCell;

  // ---------------------------------------------------------------------------
  // NAVIGATION & MENUS
  // ---------------------------------------------------------------------------
  /// Use for: Bottom navigation bar labels.
  /// Do NOT use for: Drawer labels.
  final TextStyle navigationLabel;

  /// Use for: Sidebar / Drawer menu item labels.
  /// Do NOT use for: Bottom navigation labels.
  final TextStyle drawerLabel;

  // ---------------------------------------------------------------------------
  // OVERLAYS & DIALOGS
  // ---------------------------------------------------------------------------
  /// Use for: The main title of an AlertDialog.
  /// Do NOT use for: Dialog body text.
  final TextStyle dialogTitle;

  /// Use for: The descriptive text inside an AlertDialog.
  /// Do NOT use for: Form inputs inside a dialog.
  final TextStyle dialogContent;

  /// Use for: The main title of a ModalBottomSheet.
  /// Do NOT use for: List items inside the sheet.
  final TextStyle bottomSheetTitle;

  // ---------------------------------------------------------------------------
  // FORMS & FEEDBACK
  // ---------------------------------------------------------------------------
  /// Use for: Primary and Secondary button labels.
  /// Do NOT use for: TextButtons that look like standard links.
  final TextStyle buttonText;

  /// Use for: The floating or static label above a TextField.
  /// Do NOT use for: The actual typed text.
  final TextStyle inputLabel;

  /// Use for: The text currently being typed by the user in a TextField.
  /// Do NOT use for: Read-only body text.
  final TextStyle inputText;

  /// Use for: Hint text inside an empty TextField.
  /// Do NOT use for: Error text.
  final TextStyle searchHint;

  /// Use for: Instructional text below a TextField.
  /// Do NOT use for: Error warnings.
  final TextStyle helperText;

  /// Use for: Validation error messages below a TextField.
  /// Do NOT use for: General info messages.
  final TextStyle errorText;

  /// Use for: The title when a list or screen is empty.
  /// Do NOT use for: Error dialog titles.
  final TextStyle emptyStateTitle;

  /// Use for: The sub-description explaining why the state is empty.
  /// Do NOT use for: Error descriptions.
  final TextStyle emptyStateDescription;

  /// Use for: Inline success feedback (e.g., "Saved successfully").
  /// Do NOT use for: Error states.
  final TextStyle successMessage;

  /// Use for: Inline warning feedback.
  /// Do NOT use for: Critical errors.
  final TextStyle warningMessage;

  /// Use for: Inline informational notes.
  /// Do NOT use for: Validation errors.
  final TextStyle infoMessage;

  // ---------------------------------------------------------------------------
  // CHARTS & REPORTS
  // ---------------------------------------------------------------------------
  /// Use for: The X/Y axis labels on charts.
  /// Do NOT use for: Dashboard hero values.
  final TextStyle chartLabel;

  /// Use for: Tooltip or highlighted values inside a chart.
  /// Do NOT use for: Dashboard hero values.
  final TextStyle chartValue;

  /// Use for: The title of a generated or displayed report.
  /// Do NOT use for: Section titles.
  final TextStyle reportTitle;

  /// Use for: The subtitle (date range, etc.) of a report.
  /// Do NOT use for: Chart labels.
  final TextStyle reportSubtitle;

  /// Use for: Extracted values inside a report grid.
  /// Do NOT use for: Dashboard hero values.
  final TextStyle reportValue;

  // ---------------------------------------------------------------------------
  // PROFILE, SETTINGS & NOTIFICATIONS
  // ---------------------------------------------------------------------------
  /// Use for: The logged-in user's name on their profile.
  /// Do NOT use for: Client names.
  final TextStyle profileName;

  /// Use for: The user's role (e.g., "Super Admin").
  /// Do NOT use for: Settings subtitles.
  final TextStyle profileRole;

  /// Use for: The title of a settings category.
  /// Do NOT use for: Form labels.
  final TextStyle settingsTitle;

  /// Use for: The main heading of a notification card.
  /// Do NOT use for: Notification body text.
  final TextStyle notificationTitle;

  /// Use for: The description/timestamp of a notification card.
  /// Do NOT use for: Notification title.
  final TextStyle notificationSubtitle;

  /// Use for: The timestamp of a notification.
  /// Do NOT use for: General body text.
  final TextStyle notificationTime;

  const AppTypographyExtension({
    required this.screenTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.kpiValue,
    required this.kpiLabel,
    required this.statisticValue,
    required this.statisticLabel,
    required this.cardDescription,
    required this.cardCaption,
    required this.cardFooter,
    required this.trendText,
    required this.topBarTitle,
    required this.topBarSubtitle,
    required this.liveIndicator,
    required this.roleBadgeText,
    required this.badgeCountText,
    required this.avatarLetter,
    required this.dashboardValue,
    required this.dashboardLabel,
    required this.revenueValue,
    required this.profitValue,
    required this.successAmount,
    required this.lossAmount,
    required this.outstandingAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.invoiceTitle,
    required this.invoiceNumber,
    required this.invoiceAmount,
    required this.currencyText,
    required this.percentageText,
    required this.clientName,
    required this.clientCompany,
    required this.supplierCompany,
    required this.statusLabel,
    required this.invoiceStatus,
    required this.paymentStatus,
    required this.dueDate,
    required this.stockCount,
    required this.tableHeader,
    required this.tableCell,
    required this.navigationLabel,
    required this.drawerLabel,
    required this.dialogTitle,
    required this.dialogContent,
    required this.bottomSheetTitle,
    required this.buttonText,
    required this.inputLabel,
    required this.inputText,
    required this.searchHint,
    required this.helperText,
    required this.errorText,
    required this.emptyStateTitle,
    required this.emptyStateDescription,
    required this.successMessage,
    required this.warningMessage,
    required this.infoMessage,
    required this.chartLabel,
    required this.chartValue,
    required this.reportTitle,
    required this.reportSubtitle,
    required this.reportValue,
    required this.profileName,
    required this.profileRole,
    required this.settingsTitle,
    required this.notificationTitle,
    required this.notificationSubtitle,
    required this.notificationTime,
  });

  /// Factory for Light Theme Typography
  factory AppTypographyExtension.light() {
    return AppTypographyExtension(
      screenTitle: AppTypography.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
      sectionTitle: AppTypography.titleMedium.copyWith(color: AppColors.lightTextPrimary),
      cardTitle: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
      cardSubtitle: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      kpiValue: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.lightTextPrimary),
      kpiLabel: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.lightTextSecondary),
      statisticValue: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      statisticLabel: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.lightTextSecondary),
      cardDescription: AppTypography.bodyMedium.copyWith(height: 1.4, color: AppColors.lightTextSecondary),
      cardCaption: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
      cardFooter: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.lightTextSecondary),
      trendText: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
      topBarTitle: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: AppColors.lightTextPrimary),
      topBarSubtitle: AppTypography.labelSmall.copyWith(color: AppColors.lightTextSecondary),
      liveIndicator: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppColors.lightTextSecondary),
      roleBadgeText: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
      badgeCountText: AppTypography.labelSmall.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
      avatarLetter: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      
      dashboardValue: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      dashboardLabel: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
      revenueValue: AppTypography.titleLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
      profitValue: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      successAmount: AppTypography.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
      lossAmount: AppTypography.titleMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
      outstandingAmount: AppTypography.titleMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
      taxAmount: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      discountAmount: AppTypography.bodyMedium.copyWith(color: AppColors.success),
      
      invoiceTitle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      invoiceNumber: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      invoiceAmount: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.lightTextPrimary),
      currencyText: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      percentageText: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      clientName: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      clientCompany: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.lightTextSecondary),
      supplierCompany: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.lightTextSecondary),
      statusLabel: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      invoiceStatus: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      paymentStatus: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      dueDate: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.error),
      
      stockCount: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      tableHeader: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
      tableCell: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
      
      navigationLabel: AppTypography.labelSmall,
      drawerLabel: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
      
      dialogTitle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      dialogContent: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
      bottomSheetTitle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      
      buttonText: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      inputLabel: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      inputText: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
      searchHint: AppTypography.bodyMedium.copyWith(color: Colors.grey),
      helperText: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      errorText: AppTypography.bodySmall.copyWith(color: AppColors.error),
      emptyStateTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      emptyStateDescription: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      successMessage: AppTypography.bodyMedium.copyWith(color: AppColors.success),
      warningMessage: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
      infoMessage: AppTypography.bodyMedium.copyWith(color: AppColors.info),
      
      chartLabel: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      chartValue: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      reportTitle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      reportSubtitle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      reportValue: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      
      profileName: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      profileRole: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      settingsTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
      notificationTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
      notificationSubtitle: AppTypography.bodyMedium.copyWith(height: 1.4, color: AppColors.lightTextSecondary),
      notificationTime: AppTypography._baseStyle(13, FontWeight.w500, AppColors.lightTextSecondary),
    );
  }

  /// Factory for Dark Theme Typography
  factory AppTypographyExtension.dark() {
    return AppTypographyExtension(
      screenTitle: AppTypography.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
      sectionTitle: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
      cardTitle: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
      cardSubtitle: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
      kpiValue: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.darkTextPrimary),
      kpiLabel: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.darkTextSecondary),
      statisticValue: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      statisticLabel: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: AppColors.darkTextSecondary),
      cardDescription: AppTypography.bodyMedium.copyWith(height: 1.4, color: AppColors.darkTextSecondary),
      cardCaption: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
      cardFooter: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary),
      trendText: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
      topBarTitle: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5, color: AppColors.darkTextPrimary),
      topBarSubtitle: AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary),
      liveIndicator: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: AppColors.darkTextSecondary),
      roleBadgeText: AppTypography.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
      badgeCountText: AppTypography.labelSmall.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
      avatarLetter: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      
      dashboardValue: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      dashboardLabel: AppTypography.labelMedium.copyWith(color: AppColors.darkTextSecondary),
      revenueValue: AppTypography.titleLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
      profitValue: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      successAmount: AppTypography.titleMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
      lossAmount: AppTypography.titleMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
      outstandingAmount: AppTypography.titleMedium.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
      taxAmount: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      discountAmount: AppTypography.bodyMedium.copyWith(color: AppColors.success),
      
      invoiceTitle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
      invoiceNumber: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      invoiceAmount: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.darkTextPrimary),
      currencyText: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      percentageText: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      clientName: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      clientCompany: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary),
      supplierCompany: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: AppColors.darkTextSecondary),
      statusLabel: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      invoiceStatus: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      paymentStatus: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
      dueDate: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.error),
      
      stockCount: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      tableHeader: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkTextSecondary),
      tableCell: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      
      navigationLabel: AppTypography.labelSmall,
      drawerLabel: AppTypography.titleSmall.copyWith(color: AppColors.darkTextPrimary),
      
      dialogTitle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
      dialogContent: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      bottomSheetTitle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
      
      buttonText: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      inputLabel: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      inputText: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
      searchHint: AppTypography.bodyMedium.copyWith(color: Colors.grey),
      helperText: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
      errorText: AppTypography.bodySmall.copyWith(color: AppColors.error),
      emptyStateTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      emptyStateDescription: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      successMessage: AppTypography.bodyMedium.copyWith(color: AppColors.success),
      warningMessage: AppTypography.bodyMedium.copyWith(color: AppColors.warning),
      infoMessage: AppTypography.bodyMedium.copyWith(color: AppColors.info),
      
      chartLabel: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary),
      chartValue: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      reportTitle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
      reportSubtitle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      reportValue: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      
      profileName: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      profileRole: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      settingsTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
      notificationTitle: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary),
      notificationSubtitle: AppTypography.bodyMedium.copyWith(height: 1.4, color: AppColors.darkTextSecondary),
      notificationTime: AppTypography._baseStyle(13, FontWeight.w500, AppColors.darkTextSecondary),
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> copyWith() {
    return this; // For simplicity, we return the same instance as fields are immutable and we don't need partial copy in this app.
  }

  @override
  ThemeExtension<AppTypographyExtension> lerp(ThemeExtension<AppTypographyExtension>? other, double t) {
    if (other is! AppTypographyExtension) return this;
    return AppTypographyExtension(
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      cardSubtitle: TextStyle.lerp(cardSubtitle, other.cardSubtitle, t)!,
      kpiValue: TextStyle.lerp(kpiValue, other.kpiValue, t)!,
      kpiLabel: TextStyle.lerp(kpiLabel, other.kpiLabel, t)!,
      statisticValue: TextStyle.lerp(statisticValue, other.statisticValue, t)!,
      statisticLabel: TextStyle.lerp(statisticLabel, other.statisticLabel, t)!,
      cardDescription: TextStyle.lerp(cardDescription, other.cardDescription, t)!,
      cardCaption: TextStyle.lerp(cardCaption, other.cardCaption, t)!,
      cardFooter: TextStyle.lerp(cardFooter, other.cardFooter, t)!,
      trendText: TextStyle.lerp(trendText, other.trendText, t)!,
      topBarTitle: TextStyle.lerp(topBarTitle, other.topBarTitle, t)!,
      topBarSubtitle: TextStyle.lerp(topBarSubtitle, other.topBarSubtitle, t)!,
      liveIndicator: TextStyle.lerp(liveIndicator, other.liveIndicator, t)!,
      roleBadgeText: TextStyle.lerp(roleBadgeText, other.roleBadgeText, t)!,
      badgeCountText: TextStyle.lerp(badgeCountText, other.badgeCountText, t)!,
      avatarLetter: TextStyle.lerp(avatarLetter, other.avatarLetter, t)!,
      dashboardValue: TextStyle.lerp(dashboardValue, other.dashboardValue, t)!,
      dashboardLabel: TextStyle.lerp(dashboardLabel, other.dashboardLabel, t)!,
      revenueValue: TextStyle.lerp(revenueValue, other.revenueValue, t)!,
      profitValue: TextStyle.lerp(profitValue, other.profitValue, t)!,
      successAmount: TextStyle.lerp(successAmount, other.successAmount, t)!,
      lossAmount: TextStyle.lerp(lossAmount, other.lossAmount, t)!,
      outstandingAmount: TextStyle.lerp(outstandingAmount, other.outstandingAmount, t)!,
      taxAmount: TextStyle.lerp(taxAmount, other.taxAmount, t)!,
      discountAmount: TextStyle.lerp(discountAmount, other.discountAmount, t)!,
      invoiceTitle: TextStyle.lerp(invoiceTitle, other.invoiceTitle, t)!,
      invoiceNumber: TextStyle.lerp(invoiceNumber, other.invoiceNumber, t)!,
      invoiceAmount: TextStyle.lerp(invoiceAmount, other.invoiceAmount, t)!,
      currencyText: TextStyle.lerp(currencyText, other.currencyText, t)!,
      percentageText: TextStyle.lerp(percentageText, other.percentageText, t)!,
      clientName: TextStyle.lerp(clientName, other.clientName, t)!,
      clientCompany: TextStyle.lerp(clientCompany, other.clientCompany, t)!,
      supplierCompany: TextStyle.lerp(supplierCompany, other.supplierCompany, t)!,
      statusLabel: TextStyle.lerp(statusLabel, other.statusLabel, t)!,
      invoiceStatus: TextStyle.lerp(invoiceStatus, other.invoiceStatus, t)!,
      paymentStatus: TextStyle.lerp(paymentStatus, other.paymentStatus, t)!,
      dueDate: TextStyle.lerp(dueDate, other.dueDate, t)!,
      stockCount: TextStyle.lerp(stockCount, other.stockCount, t)!,
      tableHeader: TextStyle.lerp(tableHeader, other.tableHeader, t)!,
      tableCell: TextStyle.lerp(tableCell, other.tableCell, t)!,
      navigationLabel: TextStyle.lerp(navigationLabel, other.navigationLabel, t)!,
      drawerLabel: TextStyle.lerp(drawerLabel, other.drawerLabel, t)!,
      dialogTitle: TextStyle.lerp(dialogTitle, other.dialogTitle, t)!,
      dialogContent: TextStyle.lerp(dialogContent, other.dialogContent, t)!,
      bottomSheetTitle: TextStyle.lerp(bottomSheetTitle, other.bottomSheetTitle, t)!,
      buttonText: TextStyle.lerp(buttonText, other.buttonText, t)!,
      inputLabel: TextStyle.lerp(inputLabel, other.inputLabel, t)!,
      inputText: TextStyle.lerp(inputText, other.inputText, t)!,
      searchHint: TextStyle.lerp(searchHint, other.searchHint, t)!,
      helperText: TextStyle.lerp(helperText, other.helperText, t)!,
      errorText: TextStyle.lerp(errorText, other.errorText, t)!,
      emptyStateTitle: TextStyle.lerp(emptyStateTitle, other.emptyStateTitle, t)!,
      emptyStateDescription: TextStyle.lerp(emptyStateDescription, other.emptyStateDescription, t)!,
      successMessage: TextStyle.lerp(successMessage, other.successMessage, t)!,
      warningMessage: TextStyle.lerp(warningMessage, other.warningMessage, t)!,
      infoMessage: TextStyle.lerp(infoMessage, other.infoMessage, t)!,
      chartLabel: TextStyle.lerp(chartLabel, other.chartLabel, t)!,
      chartValue: TextStyle.lerp(chartValue, other.chartValue, t)!,
      reportTitle: TextStyle.lerp(reportTitle, other.reportTitle, t)!,
      reportSubtitle: TextStyle.lerp(reportSubtitle, other.reportSubtitle, t)!,
      reportValue: TextStyle.lerp(reportValue, other.reportValue, t)!,
      profileName: TextStyle.lerp(profileName, other.profileName, t)!,
      profileRole: TextStyle.lerp(profileRole, other.profileRole, t)!,
      settingsTitle: TextStyle.lerp(settingsTitle, other.settingsTitle, t)!,
      notificationTitle: TextStyle.lerp(notificationTitle, other.notificationTitle, t)!,
      notificationSubtitle: TextStyle.lerp(notificationSubtitle, other.notificationSubtitle, t)!,
      notificationTime: TextStyle.lerp(notificationTime, other.notificationTime, t)!,
    );
  }
}
