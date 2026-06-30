import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  final content = file.readAsStringSync();

  Map<String, List<String>> languageKeys = {};
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
    final startIndex = content.indexOf("'$lang': {");
    if (startIndex == -1) continue;

    int bracketCount = 1;
    int currentIndex = startIndex + "'$lang': {".length;
    while (bracketCount > 0 && currentIndex < content.length) {
      if (content[currentIndex] == '{') bracketCount++;
      if (content[currentIndex] == '}') bracketCount--;
      currentIndex++;
    }

    final block = content.substring(startIndex, currentIndex);
    final lines = block.split('\n');
    List<String> keys = [];
    for (var line in lines) {
      if (line.contains("': '")) {
        final keyPart = line.split("': '")[0].trim();
        // Remove leading quote
        final key = keyPart.replaceAll("'", "");
        keys.add(key);
      }
    }
    languageKeys[lang] = keys;
  }

  final enKeys = languageKeys['en_US'] ?? [];
  for (var lang in languages) {
    if (lang == 'en_US') continue;
    final keys = languageKeys[lang] ?? [];
    final missing = enKeys.where((k) => !keys.contains(k)).toList();
    if (missing.isNotEmpty) {
      print('$lang is missing: $missing');
    }
  }
}
