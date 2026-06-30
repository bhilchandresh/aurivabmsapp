import 'dart:io';
import 'dart:convert';

void main() {
  final newTranslationsFile = File('new_translations_maps.json');
  if (!newTranslationsFile.existsSync()) return;

  final Map<String, dynamic> newMaps = jsonDecode(
    newTranslationsFile.readAsStringSync(),
  );

  final appTransFile = File('lib/core/localization/app_translations.dart');
  String content = appTransFile.readAsStringSync();

  void appendToLanguage(String langCode, Map<String, dynamic> newStrings) {
    // find '$langCode': {
    int idx = content.indexOf('\'$langCode\': {');
    if (idx == -1) {
      idx = content.indexOf('"$langCode": {');
    }

    if (idx != -1) {
      // Find the end of the opening brace
      int braceIdx = content.indexOf('{', idx);

      // We will insert right after the opening brace
      String insertStr = '\n          // --- Auto Generated Translations ---\n';
      newStrings.forEach((key, val) {
        // escape quotes
        String escapedVal = val
            .toString()
            .replaceAll('\'', '\\\'')
            .replaceAll('\n', '\\n');
        insertStr += "          '$key': '$escapedVal',\n";
      });

      content =
          content.substring(0, braceIdx + 1) +
          insertStr +
          content.substring(braceIdx + 1);
      print('Appended strings to $langCode');
    } else {
      print('Could not find language $langCode in app_translations.dart');
      if (langCode == 'gu_IN') {
        int mapEndIdx = content.lastIndexOf('};');
        if (mapEndIdx != -1) {
          String guMap =
              "\n        'gu_IN': {\n          // --- Auto Generated Translations ---\n";
          newStrings.forEach((key, val) {
            String escapedVal = val
                .toString()
                .replaceAll('\'', '\\\'')
                .replaceAll('\n', '\\n');
            guMap += "          '$key': '$escapedVal',\n";
          });
          guMap += "        },\n";
          content =
              content.substring(0, mapEndIdx) +
              guMap +
              content.substring(mapEndIdx);
          print('Created gu_IN map.');
        }
      }
    }
  }

  appendToLanguage('en_US', newMaps['en_US']);
  appendToLanguage('hi_IN', newMaps['hi_IN']);
  appendToLanguage('gu_IN', newMaps['gu_IN']);

  appTransFile.writeAsStringSync(content);
  print('Updated app_translations.dart with new strings.');
}
