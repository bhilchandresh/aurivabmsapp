import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  final Map<String, String> replacements = {
    "'John Doe'": "'eg_name'.tr",
    "'john@example.com'": "'eg_email'.tr",
    "'123 Business Park, Block A, City'": "'eg_address'.tr",
    "'+91 9876543210'": "'eg_phone'.tr",
    "'YYYY-MM-DD'": "'yyyy_mm_dd'.tr",
    "'QTY *'": "'qty_star'.tr",
    "'RATE *'": "'rate_star'.tr",
    "'Code'": "'code'.tr",
    "'GSTIN'": "'gstin'.tr", // Might be used as hint
    // Let's also check if I missed some things that were in apply_quotation_translations.dart
    // because they didn't match exactly. E.g. maybe 'Search Existing Client...' instead of 'Search Existing Client'
    "'Search Existing Client'": "'search_existing_client'.tr",
    "'Type to search clients...'": "'type_to_search_clients'.tr",
    "'Add extra details...'": "'add_extra_details'.tr",
    "'DETAILED DESCRIPTION (OPTIONAL)'": "'detailed_description_optional'.tr",
    "'LINE ITEMS'": "'line_items'.tr",
    "'AMOUNT'": "'amount_caps'.tr",
    "'+ Add New Item Line'": "'add_new_item_line'.tr",
    "'Remove Item'": "'remove_item'.tr",
    "'TERMS & NOTES'": "'terms_notes'.tr",
    "'FINANCIAL SUMMARY'": "'financial_summary'.tr",
    "'Save'": "'save'.tr",
    "'Enable GST'": "'enable_gst'.tr",
  };

  for (var entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // Also catch double quotes if any
  final Map<String, String> doubleQuoteReplacements = {
    '"John Doe"': "'eg_name'.tr",
    '"john@example.com"': "'eg_email'.tr",
    '"123 Business Park, Block A, City"': "'eg_address'.tr",
    '"+91 9876543210"': "'eg_phone'.tr",
    '"YYYY-MM-DD"': "'yyyy_mm_dd'.tr",
    '"QTY *"': "'qty_star'.tr",
    '"RATE *"': "'rate_star'.tr",
    '"Code"': "'code'.tr",
  };

  for (var entry in doubleQuoteReplacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  file.writeAsStringSync(content);
  print('Replaced remaining static strings in create_quotation_screen.dart!');
}
