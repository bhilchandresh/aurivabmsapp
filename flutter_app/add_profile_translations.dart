import 'dart:io';

void main() {
  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  final newKeysEN = '''
          // Profile & Notifications strings
          'bms_full_caps': 'BUSINESS MANAGEMENT SYSTEM',
          'your_information': 'Your Information',
          'your_info_sub': 'View your personal details and role',
          'notifications': 'Notifications',
          'notifications_sub': 'Your recent updates',
          'no_notifications': 'No notifications yet',
          'view_details': 'View Details',
          'full_name': 'Full Name',
          'email_address': 'Email Address',
          'access_level': 'Access Level',
''';

  final newKeysHI = '''
          // Profile & Notifications strings
          'bms_full_caps': 'व्यवसाय प्रबंधन प्रणाली',
          'your_information': 'आपकी जानकारी',
          'your_info_sub': 'अपना व्यक्तिगत विवरण और भूमिका देखें',
          'notifications': 'सूचनाएं',
          'notifications_sub': 'आपके हाल के अपडेट',
          'no_notifications': 'अभी तक कोई सूचना नहीं',
          'view_details': 'विवरण देखें',
          'full_name': 'पूरा नाम',
          'email_address': 'ईमेल पता',
          'access_level': 'पहुंच स्तर',
''';

  final regex = RegExp(r"('[a-z]{2}_[A-Z]{2}'):\s*\{");
  final matches = regex.allMatches(content).toList();
  print('Found matches: ' + matches.length.toString());

  for (var match in matches) {
    String localeStr = match.group(0)!;
    String localeName = match.group(1)!;

    String keysToAdd = newKeysEN;
    if (localeName == "'hi_IN'") keysToAdd = newKeysHI;

    content = content.replaceFirst(localeStr, localeStr + '\n' + keysToAdd);
  }

  file.writeAsStringSync(content);
  print('Done adding to ' + matches.length.toString() + ' locales');
}
