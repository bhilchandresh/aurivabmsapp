import 'dart:io';

void main() {
  final files = [
    'lib/features/profile/profile_screen.dart',
    'lib/features/profile/your_information_screen.dart',
    'lib/features/notifications/notification_screen.dart',
  ];

  final Set<String> neededKeys = {};

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();

    // Find all 'some_key'.tr or "some_key".tr
    final matches = RegExp(r"'([^']+)'\.tr").allMatches(content);
    for (var match in matches) {
      neededKeys.add(match.group(1)!);
    }
    final matches2 = RegExp(r'"([^"]+)"\.tr').allMatches(content);
    for (var match in matches2) {
      neededKeys.add(match.group(1)!);
    }
  }

  print('Needed Keys from the 3 files:');
  for (var k in neededKeys) {
    print(k);
  }
}
