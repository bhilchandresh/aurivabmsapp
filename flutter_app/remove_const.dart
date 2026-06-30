import 'dart:io';

void main() {
  final file = File('lib/features/quotations/create_quotation_screen.dart');
  String content = file.readAsStringSync();

  // Find all instances of "const SnackBar(" that contain ".tr"
  // It's easier to just do:
  content = content.replaceAllMapped(
    RegExp(r'const\s+SnackBar\s*\(\s*content:\s*Text\s*\(\s*[^)]+\.tr'),
    (match) {
      return match.group(0)!.replaceFirst('const ', '');
    },
  );

  // Also replace "const Text(" containing ".tr"
  content = content.replaceAllMapped(RegExp(r'const\s+Text\s*\(\s*[^)]+\.tr'), (
    match,
  ) {
    return match.group(0)!.replaceFirst('const ', '');
  });

  // Also replace "const Tab(" containing ".tr"
  content = content.replaceAllMapped(
    RegExp(r'const\s+Tab\s*\(\s*text:\s*[^)]+\.tr'),
    (match) {
      return match.group(0)!.replaceFirst('const ', '');
    },
  );

  // For any generic const Widget(...) containing .tr, we can just replace "const " if .tr is within the next 100 characters before a closing bracket.
  // Actually, replacing all `const Text` with `Text` inside the file is totally safe in Flutter.
  // But let's just do a simpler search and replace:
  // We'll read the file line by line. If a line has "const " and ".tr", we'll just replace "const " with "".

  final lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('const ') && lines[i].contains('.tr')) {
      lines[i] = lines[i].replaceAll('const SnackBar', 'SnackBar');
      lines[i] = lines[i].replaceAll('const Text', 'Text');
      lines[i] = lines[i].replaceAll('const Tab', 'Tab');
      // Some might have const Padding or const Align. We can just replace "const " entirely for that line if it's causing issues.
      // But let's be more surgical:
      lines[i] = lines[i].replaceAll(RegExp(r'const\s+([A-Z]\w*)'), r'\1');
    }
  }

  file.writeAsStringSync(lines.join('\n'));
  print('Removed const from translated expressions!');
}
