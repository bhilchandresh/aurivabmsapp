import 'dart:io';

void main() {
  final translationsFile = File('lib/core/localization/app_translations.dart');
  String translationsContent = translationsFile.readAsStringSync();

  if (!translationsContent.contains("'name_colon':")) {
    translationsContent = translationsContent.replaceAll(
      "'name': 'Name',",
      "'name': 'Name',\n          'name_colon': 'Name: ',",
    );
    translationsContent = translationsContent.replaceAll(
      "'name': 'नाम',",
      "'name': 'नाम',\n          'name_colon': 'नाम: ',",
    );
    translationsContent = translationsContent.replaceAll(
      "'name': 'નામ',",
      "'name': 'નામ',\n          'name_colon': 'નામ: ',",
    );
  }

  if (!translationsContent.contains("'bank_colon':")) {
    translationsContent = translationsContent.replaceAll(
      "'bank': 'Bank',",
      "'bank': 'Bank',\n          'bank_colon': 'Bank: ',",
    );
    translationsContent = translationsContent.replaceAll(
      "'bank': 'बैंक',",
      "'bank': 'बैंक',\n          'bank_colon': 'बैंक: ',",
    );
    translationsContent = translationsContent.replaceAll(
      "'bank': 'બેંક',",
      "'bank': 'બેંક',\n          'bank_colon': 'બેંક: ',",
    );

    // If 'bank' doesn't exist, just add 'bank_colon' anywhere. Let's add it after 'name_colon'.
    if (!translationsContent.contains("'bank_colon':")) {
      translationsContent = translationsContent.replaceAll(
        "'name_colon': 'Name: ',",
        "'name_colon': 'Name: ',\n          'bank_colon': 'Bank: ',",
      );
      translationsContent = translationsContent.replaceAll(
        "'name_colon': 'नाम: ',",
        "'name_colon': 'नाम: ',\n          'bank_colon': 'बैंक: ',",
      );
      translationsContent = translationsContent.replaceAll(
        "'name_colon': 'નામ: ',",
        "'name_colon': 'નામ: ',\n          'bank_colon': 'બેંક: ',",
      );
    }
  }

  translationsFile.writeAsStringSync(translationsContent);
  print('Added name_colon and bank_colon');

  void fixFile(String filePath) {
    final file = File(filePath);
    String content = file.readAsStringSync();

    // TextSpan(text: 'Name: ')
    content = content.replaceAll(
      "const TextSpan(text: 'Name: '),",
      "TextSpan(text: 'name_colon'.tr),",
    );
    // TextSpan(text: 'Bank: ')
    content = content.replaceAll(
      "const TextSpan(text: 'Bank: '),",
      "TextSpan(text: 'bank_colon'.tr),",
    );
    // TextSpan(text: 'A/C: ')
    content = content.replaceAll(
      "const TextSpan(text: 'A/C: '),",
      "TextSpan(text: 'ac_colon'.tr),",
    );
    // TextSpan(text: 'IFSC: ')
    content = content.replaceAll(
      "const TextSpan(text: 'IFSC: '),",
      "TextSpan(text: 'ifsc_colon'.tr),",
    );

    // Text('Discount (${...}%)' -> Text('${'discount'.tr} (${...}%)'
    content = content.replaceAll(
      "Text('Discount (\${discountPct.toStringAsFixed(0)}%)'",
      "Text('\${\\'discount\\'.tr} (\${discountPct.toStringAsFixed(0)}%)'",
    );

    // buildRow('Discount (${...}%)' -> buildRow('${'discount'.tr} (${...}%)'
    content = content.replaceAll(
      "buildRow('Discount (\${double.tryParse(_discountPercentageController.text)",
      "buildRow('\${\\'discount\\'.tr} (\${double.tryParse(_discountPercentageController.text)",
    );

    // Text('Total Amount: ${formatCurrency.format(_total)}' -> Text('${'total_amount'.tr}: ${formatCurrency.format(_total)}'
    content = content.replaceAll(
      "Text('Total Amount: \${formatCurrency.format(_total)}'",
      "Text('\${\\'total_amount\\'.tr}: \${formatCurrency.format(_total)}'",
    );

    file.writeAsStringSync(content);
    print('Fixed $filePath');
  }

  fixFile('lib/features/invoices/create_invoice_screen.dart');
  fixFile('lib/features/quotations/create_quotation_screen.dart');
}
