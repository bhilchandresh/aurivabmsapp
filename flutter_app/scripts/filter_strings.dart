import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('untranslated_strings.json');
  final Map<String, dynamic> rawStrings = jsonDecode(file.readAsStringSync());

  final Map<String, String> filteredStrings = {};

  for (var entry in rawStrings.entries) {
    String key = entry.key;
    String value = entry.value;

    // Skip interpolated strings
    if (key.startsWith('var_')) continue;

    // Skip numbers and symbols
    if (RegExp(r'^[0-9\W_]+$').hasMatch(value)) continue;
    if (RegExp(r'^\d+%?$').hasMatch(value)) continue; // like 5%, 18%
    if (value.startsWith('₹') || value.startsWith('Rs')) continue;
    if (key.contains('0_00')) continue;

    // Some specific junk
    if (key == '22aaaaa0000a1z5' || key == 'asdasd' || key == '91') continue;

    filteredStrings[key] = value;
  }

  File('filtered_strings.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(filteredStrings),
  );
  print('Filtered down to ${filteredStrings.length} strings.');
}
