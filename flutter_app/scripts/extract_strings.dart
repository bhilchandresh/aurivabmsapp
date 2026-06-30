import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib');
  final Map<String, String> extractedStrings = {};
  int count = 0;

  void processFile(File file) {
    if (file.path.contains('app_translations.dart') ||
        file.path.contains('localization'))
      return;

    final content = file.readAsStringSync();

    // Regex for Text('...') or Text("...")
    // Also matches hintText: '...', labelText: '...', tooltip: '...'
    final textRegex = RegExp(r'''Text\(\s*(['"])(.*?)\1''');
    final hintRegex = RegExp(r'''hintText:\s*(['"])(.*?)\1''');
    final labelRegex = RegExp(r'''labelText:\s*(['"])(.*?)\1''');
    final tooltipRegex = RegExp(r'''tooltip:\s*(['"])(.*?)\1''');

    // Also find standard string assignments for specific properties if needed, but the above covers most.

    void extractFromMatches(Iterable<Match> matches) {
      for (final match in matches) {
        final str = match.group(2) ?? '';

        // Skip empty strings
        if (str.trim().isEmpty) continue;

        // Check if there's a `.tr` immediately after the string
        final end = match.end;
        final nextChars = content.substring(
          end,
          (end + 4).clamp(0, content.length),
        );
        if (nextChars.startsWith('.tr')) {
          continue; // Already localized
        }

        // Let's also check if the string contains a '$' indicating interpolation.
        // If it does, we'll prefix the key with 'var_' so we know to handle it carefully.
        bool hasVars = str.contains(r'$');

        // Generate a key
        String key = str.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        key = key.replaceAll(RegExp(r'^_+|_+$'), ''); // Trim underscores

        // Truncate key if it's too long
        if (key.length > 40) {
          key = key.substring(0, 40);
          key = key.replaceAll(
            RegExp(r'_+$'),
            '',
          ); // Trim trailing underscores again
        }

        if (key.isEmpty) continue;
        if (hasVars) {
          key = 'var_$key';
        }

        // Avoid overwriting with different values if key clashes, append a number
        String finalKey = key;
        int duplicateCount = 1;
        while (extractedStrings.containsKey(finalKey) &&
            extractedStrings[finalKey] != str) {
          finalKey = '${key}_$duplicateCount';
          duplicateCount++;
        }

        if (!extractedStrings.containsKey(finalKey)) {
          extractedStrings[finalKey] = str;
          count++;
        }
      }
    }

    extractFromMatches(textRegex.allMatches(content));
    extractFromMatches(hintRegex.allMatches(content));
    extractFromMatches(labelRegex.allMatches(content));
    extractFromMatches(tooltipRegex.allMatches(content));
  }

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      processFile(entity);
    }
  }

  final file = File('untranslated_strings.json');
  // Sort the map by key
  final sortedKeys = extractedStrings.keys.toList()..sort();
  final Map<String, String> sortedMap = {};
  for (var key in sortedKeys) {
    sortedMap[key] = extractedStrings[key]!;
  }

  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sortedMap));
  print('Extracted $count strings to untranslated_strings.json');
}
