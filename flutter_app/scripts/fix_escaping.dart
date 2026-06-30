import 'dart:io';

void main() {
  void fixFile(String filePath) {
    final file = File(filePath);
    String content = file.readAsStringSync();

    content = content.replaceAll(
      r'Text("${\"discount\".tr}" (${discountPct.toStringAsFixed(0)}%)',
      r"Text('${'discount'.tr} (${discountPct.toStringAsFixed(0)}%)'",
    );

    content = content.replaceAll(
      r'buildRow("${\"discount\".tr}" (${double.tryParse(_discountPercentageController.text)',
      r"buildRow('${'discount'.tr} (${double.tryParse(_discountPercentageController.text)'",
    );

    content = content.replaceAll(
      r'Text("${\"total_amount\".tr}": ${formatCurrency.format(_total)}',
      r"Text('${'total_amount'.tr}: ${formatCurrency.format(_total)}'",
    );

    content = content.replaceAll(
      r'Text("${\"total_amount\".tr}":',
      r"Text('${'total_amount'.tr}:'",
    );

    file.writeAsStringSync(content);
    print('Restored $filePath');
  }

  fixFile('lib/features/invoices/create_invoice_screen.dart');
  fixFile('lib/features/quotations/create_quotation_screen.dart');
}
