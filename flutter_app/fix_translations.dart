import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  String content = file.readAsStringSync();

  final additions = '''
          'customer_registers': 'Customer Registers',
          'pending_due': 'PENDING DUE',
          'business_name': 'Business Name',
''';

  content = content.replaceAllMapped(RegExp(r"'\w{2}_\w{2}': \{\r?\n"), (
    match,
  ) {
    return "${match.group(0)}$additions";
  });

  file.writeAsStringSync(content);
  print('Translations updated successfully.');
}
