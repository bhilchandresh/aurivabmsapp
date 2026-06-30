import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('filtered_strings.json');
  final Map<String, dynamic> strings = jsonDecode(file.readAsStringSync());

  final dir = Directory('lib');
  int totalReplacements = 0;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (entity.path.contains('app_translations.dart') ||
          entity.path.contains('localization'))
        continue;

      String content = entity.readAsStringSync();
      bool changed = false;

      // We sort strings by length descending to replace longer strings first
      // (e.g. "Save Bill" before "Save")
      var sortedKeys = strings.keys.toList();
      sortedKeys.sort(
        (a, b) => strings[b]!.length.compareTo(strings[a]!.length),
      );

      for (var key in sortedKeys) {
        final value = strings[key]!;

        // Escape special characters in value if they exist, but simple string interpolation issues might occur.
        // We will just do a standard replaceAll for exact literal matches.

        final replacements = [
          ['Text(\'$value\'', 'Text(\'$key\'.tr'],
          ['Text("$value"', 'Text(\'$key\'.tr'],
          ['const Text(\'$value\'', 'Text(\'$key\'.tr'],
          ['const Text("$value"', 'Text(\'$key\'.tr'],
          ['hintText: \'$value\'', 'hintText: \'$key\'.tr'],
          ['hintText: "$value"', 'hintText: \'$key\'.tr'],
          ['labelText: \'$value\'', 'labelText: \'$key\'.tr'],
          ['labelText: "$value"', 'labelText: \'$key\'.tr'],
          ['tooltip: \'$value\'', 'tooltip: \'$key\'.tr'],
          ['tooltip: "$value"', 'tooltip: \'$key\'.tr'],
        ];

        for (var pair in replacements) {
          String pattern = pair[0];
          String replacement = pair[1];
          if (content.contains(pattern)) {
            content = content.replaceAll(pattern, replacement);
            changed = true;
            totalReplacements++;
          }
        }
      }

      if (changed) {
        entity.writeAsStringSync(content);
        print('Updated ${entity.path}');
      }
    }
  }

  print('Total replacements: $totalReplacements');
}
