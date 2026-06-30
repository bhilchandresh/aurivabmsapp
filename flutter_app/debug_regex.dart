import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final regex = RegExp("'your_information':\\s*'.*?',");
  print(regex.hasMatch(content));
  print(regex.firstMatch(content)?.group(0));
}
