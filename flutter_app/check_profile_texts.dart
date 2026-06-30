import 'dart:io';

void main() {
  final files = [
    'lib/features/profile/profile_screen.dart',
    'lib/features/profile/your_information_screen.dart',
    'lib/features/notifications/notification_screen.dart',
  ];

  for (final filePath in files) {
    print('Checking $filePath');
    final file = File(filePath);
    if (!file.existsSync()) continue;
    final lines = file.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains("Text('") || line.contains('Text("')) {
        if (!line.contains('.tr')) {
          print('Line ${i + 1}: ${line.trim()}');
        }
      }
    }
  }
}
