import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final Map<String, Map<String, String>> newTranslations = {
    'en_US': {
      'eg_name': 'John Doe',
      'eg_email': 'john@example.com',
      'eg_address': '123 Business Park, Block A, City',
      'eg_phone': '+91 98765 43210',
      'yyyy_mm_dd': 'YYYY-MM-DD',
      'qty_star': 'QTY *',
      'rate_star': 'RATE *',
      'code': 'Code',
    },
    'gu_IN': {
      'eg_name': 'જ્હોન ડો (John Doe)',
      'eg_email': 'john@example.com',
      'eg_address': '123 બિઝનેસ પાર્ક, બ્લોક A, સિટી',
      'eg_phone': '+91 98765 43210',
      'yyyy_mm_dd': 'વર્ષ-મહિનો-તારીખ (YYYY-MM-DD)',
      'qty_star': 'જથ્થો (QTY) *',
      'rate_star': 'દર (RATE) *',
      'code': 'કોડ',
    },
    'hi_IN': {
      'eg_name': 'जॉन डो (John Doe)',
      'eg_email': 'john@example.com',
      'eg_address': '123 बिजनेस पार्क, ब्लॉक ए, सिटी',
      'eg_phone': '+91 98765 43210',
      'yyyy_mm_dd': 'वर्ष-महीना-तारीख (YYYY-MM-DD)',
      'qty_star': 'मात्रा (QTY) *',
      'rate_star': 'दर (RATE) *',
      'code': 'कोड',
    },
  };

  List<String> langs = [
    'en_US',
    'hi_IN',
    'bn_IN',
    'te_IN',
    'ta_IN',
    'ur_IN',
    'kn_IN',
    'or_IN',
    'ml_IN',
    'gu_IN',
    'mr_IN',
  ];

  for (String lang in langs) {
    Map<String, String> toAdd =
        newTranslations[lang] ?? newTranslations['en_US']!;

    int index = content.indexOf("'\$lang': {");
    if (index != -1) {
      int insertIndex = content.indexOf('\n', index) + 1;

      String stringsToAdd = '';
      toAdd.forEach((k, v) {
        if (!content.contains("'\$k':")) {
          String escapedValue = v
              .replaceAll("'", "\\'")
              .replaceAll('\n', '\\n');
          stringsToAdd += "          '\$k': '\$escapedValue',\n";
        }
      });

      if (stringsToAdd.isNotEmpty) {
        content =
            content.substring(0, insertIndex) +
            stringsToAdd +
            content.substring(insertIndex);
      }
    }
  }

  file.writeAsStringSync(content);
  print('Added more missing hint keys to app_translations.dart!');
}
