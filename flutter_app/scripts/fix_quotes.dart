import 'dart:io';

void main() {
  void fixFile(String filePath) {
    final file = File(filePath);
    String content = file.readAsStringSync();

    // Fix double quotes ending strings
    content = content.replaceAll(r"%)'',", r"%)',");

    content = content.replaceAll(r"(_total)}'',", r"(_total)}',");

    // Fix string start quotes if any (just in case)
    content = content.replaceAll(r"Text(''${'discount'", r"Text('${'discount'");
    content = content.replaceAll(
      r"buildRow(''${'discount'",
      r"buildRow('${'discount'",
    );
    content = content.replaceAll(
      r"Text(''${'total_amount'",
      r"Text('${'total_amount'",
    );

    // Fix any other weird occurrences in create_invoice_screen
    content = content.replaceAll(r"%)'', style", r"%)', style");
    content = content.replaceAll(r"_total)}'', style", r"_total)}', style");

    file.writeAsStringSync(content);
    print('Fixed quotes in $filePath');
  }

  fixFile('lib/features/invoices/create_invoice_screen.dart');
  fixFile('lib/features/quotations/create_quotation_screen.dart');
}
