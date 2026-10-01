# DEAD CODE INVENTORY

## CATEGORY A — SAFE TO DELETE
**Unused Imports:**
- `lib\core\theme\app_typography.dart`: `package:get/get.dart`
- `lib\features\auth\login_screen.dart`: `../../core/theme/app_extensions.dart`, `../../shared/widgets/app_button.dart`, `../../shared/widgets/app_input_field.dart`
- `lib\features\auth\view_legal_screen.dart`: `package:get/get.dart`
- `lib\features\clients\client_details_screen.dart`: `../../core/theme/app_text_styles.dart`
- `lib\features\expenses\all_expenses_screen.dart`: `package:fl_chart/fl_chart.dart`, `../../shared/widgets/app_input_field.dart`
- `lib\features\expenses\expense_components.dart`: `all_expenses_screen.dart`
- `lib\features\expenses\expenses_screen.dart`: `dart:math`, `../../shared/widgets/app_input_field.dart`
- `lib\features\expenses\widgets\expense_details_bottom_sheet.dart`: `../../../core/constants/app_colors.dart`
- `lib\features\expenses\widgets\expense_list_item.dart`: `package:lucide_icons/lucide_icons.dart`
- `lib\features\profile\your_information_screen.dart`: `../../core/theme/app_extensions.dart`
- `lib\main.dart`: `package:flutter_secure_storage/flutter_secure_storage.dart`
- `lib\navigation\main_layout.dart`: `../features/invoices/create_invoice_screen.dart`, `../features/quotations/create_quotation_screen.dart`, `app_routes.dart`, `widgets/auriva_expandable_fab.dart`
- `lib\shared\widgets\custom_notification_overlay.dart`: `../../core/theme/app_extensions.dart`

**Unused Variables/Fields:**
- `lib\features\clients\clients_screen.dart`: `_indianStates`, `isMobile`, `isDark`
- `lib\features\dashboard\dashboard_screen.dart`: `_chartView`, `_isManualRefreshing`, `successRate`, `expense`
- `lib\features\expenses\expenses_screen.dart`: `categories`
- `lib\features\settings\settings_screen.dart`: `_hoveredCardIndex`
- `lib\shared\widgets\custom_notification_overlay.dart`: `_textDark`

**Unused Elements (Methods):**
- `lib\features\dashboard\dashboard_screen.dart`: `_buildQuickActions`
- `lib\features\profile\your_information_screen.dart`: `_buildTopIconText`
- `lib\features\suppliers\supplier_details_screen.dart`: `_showAddBillDialog`, `_buildCustomDropdownField`

**Dead Code:**
- `lib\features\dashboard\dashboard_screen.dart`: line 2052
- `lib\shared\widgets\custom_notification_overlay.dart`: line 330

## CATEGORY B — NEEDS VERIFICATION
- Template files in `lib/features/invoices/templates` and `lib/features/quotations/templates`. Are they used?
- Any other widgets/screens.

## CATEGORY C — DO NOT DELETE
- Core app configuration
- Navigation routing
- Main widgets
