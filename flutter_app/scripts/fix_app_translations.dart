import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  // Regex to match lines ending with \', and remove the backslash.
  // Actually, the line is: 'key': 'Value\',
  // Which causes a syntax error. We should just replace `\',` with `',` globally if it's right before the closing quote.
  // We can just use string replacement:
  content = content.replaceAll(r"\',", "',");

  file.writeAsStringSync(content);
  print('Fixed backslash errors in app_translations.dart');
}
