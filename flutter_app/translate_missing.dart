import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final keysMap = {
    'business_operations': 'Business Operations',
    'your_information': 'Your Information',
    'your_info_sub': 'View and edit your personal details',
    'inventory': 'Inventory',
    'inventory_sub': 'Manage your products and stock',
    'suppliers': 'Suppliers',
    'suppliers_sub': 'Manage vendors and purchases',
    'expenses': 'Expenses',
    'expenses_sub': 'Track your business expenses',
    'import_data': 'Import Data',
    'import_data_sub': 'Bulk import clients and products',
    'notifications': 'Notifications',
    'notifications_sub': 'View alerts and messages',
    'language': 'Language',
    'change_language_sub': 'Change application language',
    'administration': 'Administration',
    'team_access': 'Team & Access',
    'team_access_sub': 'Manage users and roles',
    'settings': 'Settings',
    'settings_sub': 'App configuration and preferences',
    'sign_out': 'Sign Out',
    'my_account': 'My Account',
    'full_name': 'Full Name',
    'email_address': 'Email Address',
    'access_level': 'Access Level',
    'user_role_default': 'Administrator',
    'no_notifications': 'No new notifications',
    'view_details': 'View Details',
  };

  final languages = {
    'en_US': 'en',
    'hi_IN': 'hi',
    'bn_IN': 'bn',
    'te_IN': 'te',
    'ta_IN': 'ta',
    'mr_IN': 'mr',
    'gu_IN': 'gu',
    'ur_IN': 'ur',
    'kn_IN': 'kn',
    'or_IN': 'or',
    'ml_IN': 'ml',
  };

  final file = File('lib/core/localization/app_translations.dart');
  String content = file.readAsStringSync();

  for (var lang in languages.keys) {
    print('Processing $lang...');
    final tl = languages[lang]!;

    // Check which keys are missing
    for (var entry in keysMap.entries) {
      final key = entry.key;
      final enText = entry.value;

      // Look for the language block
      final langBlockStart = content.indexOf("'$lang': {");
      if (langBlockStart == -1) continue;

      int currentIndex = langBlockStart + "'$lang': {".length;
      int bracketCount = 1;
      while (bracketCount > 0 && currentIndex < content.length) {
        if (content[currentIndex] == '{') bracketCount++;
        if (content[currentIndex] == '}') bracketCount--;
        currentIndex++;
      }

      final block = content.substring(langBlockStart, currentIndex);
      if (!block.contains("'$key':")) {
        // Missing! We need to translate.
        String translatedText = enText;
        if (tl != 'en') {
          translatedText = await translate(enText, tl);
        }

        // Escape quotes
        translatedText = translatedText.replaceAll("'", "\\'");

        // Inject into content
        final insertIndex = currentIndex - 1; // Before the closing '}'
        final insertString = "          '$key': '$translatedText',\n";

        content =
            content.substring(0, insertIndex) +
            insertString +
            content.substring(insertIndex);
      }
    }
  }

  file.writeAsStringSync(content);
  print('Done! Missing translations injected.');
}

Future<String> translate(String text, String targetLang) async {
  try {
    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json[0][0][0].toString();
    }
  } catch (e) {
    print('Error translating $text to $targetLang: $e');
  }
  return text; // Fallback to english
}
