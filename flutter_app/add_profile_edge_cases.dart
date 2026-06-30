import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final newKeysEN = '''
          'app_name_auriva': 'Auriva',
          'app_name_bms': 'BMS',
          'user_role_default': 'USER',
''';

  final newKeysHI = '''
          'app_name_auriva': 'ऑरिवा',
          'app_name_bms': 'बीएमएस',
          'user_role_default': 'उपयोगकर्ता',
''';

  final regex = RegExp(r"('[a-z]{2}_[A-Z]{2}'):\s*\{");
  final matches = regex.allMatches(content).toList();

  for (var match in matches) {
    String localeStr = match.group(0)!;
    String localeName = match.group(1)!;

    String keysToAdd = newKeysEN;
    if (localeName == "'hi_IN'") keysToAdd = newKeysHI;

    content = content.replaceFirst(localeStr, localeStr + '\n' + keysToAdd);
  }

  file.writeAsStringSync(content);
}
