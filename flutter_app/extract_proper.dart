import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  final lines = file.readAsLinesSync();

  final Set<String> strings = {};

  final patterns = [
    RegExp(r"Text\(\s*'([^']+)'"),
    RegExp(r'Text\(\s*"([^"]+)"'),
    RegExp(r"pw\.Text\(\s*'([^']+)'"),
    RegExp(r'pw\.Text\(\s*"([^"]+)"'),
    RegExp(r"hintText:\s*'([^']+)'"),
    RegExp(r'hintText:\s*"([^"]+)"'),
    RegExp(r"labelText:\s*'([^']+)'"),
    RegExp(r'labelText:\s*"([^"]+)"'),
    RegExp(r"title:\s*Text\(\s*'([^']+)'"),
  ];

  for (final line in lines) {
    for (final pattern in patterns) {
      final matches = pattern.allMatches(line);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          strings.add(match.group(1)!);
        }
      }
    }
  }

  print('Extracted ' + strings.length.toString() + ' strings:');
  for (final s in strings) {
    print('- ' + s);
  }
}
