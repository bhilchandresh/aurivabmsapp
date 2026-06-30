import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  final content = file.readAsStringSync();

  // Count how many keys each language has
  final languages = [
    'en_US',
    'hi_IN',
    'gu_IN',
    'mr_IN',
    'ta_IN',
    'te_IN',
    'bn_IN',
    'ml_IN',
    'kn_IN',
    'or_IN',
    'ur_IN',
  ];

  for (var lang in languages) {
    // Find the block for this language
    final startIndex = content.indexOf("'$lang': {");
    if (startIndex == -1) {
      print('$lang block not found!');
      continue;
    }
    int bracketCount = 1;
    int currentIndex = startIndex + "'$lang': {".length;
    while (bracketCount > 0 && currentIndex < content.length) {
      if (content[currentIndex] == '{') bracketCount++;
      if (content[currentIndex] == '}') bracketCount--;
      currentIndex++;
    }

    final block = content.substring(startIndex, currentIndex);
    // Count the number of colons (approximate number of keys)
    final lines = block.split('\n').where((l) => l.contains("': '")).length;
    print('$lang has approximately $lines keys.');
  }
}
