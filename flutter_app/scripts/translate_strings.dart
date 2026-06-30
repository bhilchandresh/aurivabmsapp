import 'dart:io';
import 'dart:convert';
import 'package:translator/translator.dart';

void main() async {
  final file = File('filtered_strings.json');
  final Map<String, dynamic> enStrings = jsonDecode(file.readAsStringSync());

  final translator = GoogleTranslator();
  final Map<String, String> hiStrings = {};
  final Map<String, String> guStrings = {};

  print('Translating ${enStrings.length} strings...');

  int i = 0;
  for (var entry in enStrings.entries) {
    String key = entry.key;
    String value = entry.value;

    try {
      var hiTranslation = await translator.translate(
        value,
        from: 'en',
        to: 'hi',
      );
      hiStrings[key] = hiTranslation.text;

      var guTranslation = await translator.translate(
        value,
        from: 'en',
        to: 'gu',
      );
      guStrings[key] = guTranslation.text;

      i++;
      if (i % 10 == 0) {
        print('Translated $i strings...');
      }

      // Add a small delay to avoid rate limiting
      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      print('Error translating "$value": $e');
      hiStrings[key] = value;
      guStrings[key] = value;
    }
  }

  final output = {'en_US': enStrings, 'hi_IN': hiStrings, 'gu_IN': guStrings};

  File(
    'new_translations_maps.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  print('Done! Saved to new_translations_maps.json');
}
